---
name: modal-training-cost-optimization
description: Use when launching ML training jobs on Modal and need to minimize GPU cost, when seeing high estimated training costs, when choosing between GPU tiers or counts, or when deciding on distributed training strategy (FSDP vs device_map)
---

# Modal Training Cost Optimization

Find the cheapest GPU configuration for a training job on Modal.

## Core Insight

Total cost = **total forward passes** (fixed for a given model+dataset) × **hardware $/FLOP**. Batch size and gradient accumulation trade step count vs step time but don't change total compute. The levers:

1. **Distributed strategy** — FSDP/DDP over `device_map="auto"` (usually the single biggest win)
2. **GPU tier** — best FLOP/$ for your model size
3. **GPU count** — more GPUs = faster wall time but same GPU-hours; find the communication overhead sweet spot

## How to Run Training Commands

**Never run training in a blocking call.** Training commands run for hours. A synchronous Bash call blocks the entire conversation turn with no opportunity to check output, estimate cost, or kill the job.

**The principle: GPU cost must always be bounded.** Before launching any training command, you must be able to answer "what's the worst-case cost if nobody intervenes?" If you can't answer that, you haven't benchmarked yet — and you must monitor closely until you can.

**The pattern: background + periodic checks.**

1. Launch the training command with `run_in_background: true`.
2. Get the container ID: `modal container list`.
3. Wait for training steps to start (tail the output file), then check GPU memory **during training** (not during startup — memory during model loading is meaningless):
   ```bash
   modal container exec <container_id> -- nvidia-smi
   ```
   This tells you batch size headroom. Large free memory → increase batch size next run. Near-full → at the limit. OOM → reduce.
4. Read s/step from tqdm output. **Wait for it to stabilize** — early steps are always slower (JIT compilation, CUDA graph capture, gradient accumulation warmup). Use the steady-state s/step for cost estimates. If s/step is still dropping, keep waiting.
5. Compute cost: `(total_steps × s/step / 3600) × num_gpus × $/gpu/hr`. If bad, `modal app stop <app-name>` to kill it.
6. Never end your turn without either: (a) confirming the job looks healthy with an acceptable cost, or (b) killing it.

## Benchmarking Process

### 1. Benchmark on a separate Modal app

Use a **separate app name** so `modal app stop` on benchmarks doesn't kill production.

### 2. Naive config, measure, iterate fast

Launch in background, follow the monitoring pattern above, compute cost estimate. Kill if bad, adjust the biggest lever, relaunch.

Example progression:
- `device_map="auto"`, 8× H200 → 48s/step, $864. Kill immediately.
- `device_map="auto"`, 2× H200 → 48s/step, $216. Same speed, 4× cheaper. Still slow.
- FSDP, 4× H200, bs=2 → 20s/step, $178. Real data parallelism, big win.
- FSDP, 4× H200, bs=4 → 17.5s/step, $156. Marginal gain. Ship it.

### 3. Sweep axes

| Axis | Values to try |
|------|--------------|
| Batch size | 1, 2, 3, 4, 6, 8 (largest that fits in memory) |
| Gradient accumulation | 1, 2, 4, 8 (fewer = faster steps, same total compute) |
| GPU count | 2, 4, 8 (check communication overhead) |
| GPU tier | A100-80G, H100, H200 (cheaper GPUs may lose on $/FLOP) |

Record per run: s/step, effective batch size, peak GPU memory.

### 4. Launch production once cost stabilizes

Once further tweaks yield <20% improvement, launch the real run on the production app. Don't wait for perfection.

## Quick Reference

| Lesson | Detail |
|--------|--------|
| **GPU cost must be bounded** | Always background + periodic checks. Unbenchmarked → monitor closely, kill if bad. Benchmarked → periodic sanity checks. Never launch and walk away without a cost estimate. |
| `device_map="auto"` is NOT data parallelism | Splits model across GPUs but training is single-process. More GPUs = same speed, higher cost. Use FSDP/DDP. |
| Kill early, kill often | $800+ estimate? Kill immediately. Minutes of wasted GPU time << hours of bad config. |
| Better GPUs are more cost-efficient | H200 > H100 > A100 on $/FLOP in practice. Don't bother testing A100s for large models. |
| Always measure memory during training | `nvidia-smi` during training steps (not startup) shows exact batch size headroom. |
| Never benchmark on production app | Separate Modal app name so stops/kills are isolated. |
| Weight loading should take ~5 min | If loading takes >10 min (excluding download), something is likely wrong — investigate. |

## What Typically Happens

Early iterations yield dramatic savings (wrong distributed strategy, too many GPUs). Once fixed, remaining configs converge to roughly the same cost because total forward passes are fixed. Differences come from communication overhead (FSDP all-gather/reduce-scatter grows with GPU count), GPU utilization (larger batch sizes help, with diminishing returns), and memory limits (OOM sets hard ceiling on batch size).

## When You're Stuck: Search the Internet

If benchmarking isn't converging — you keep hitting the same errors, cost won't come down, or configs that "should work" don't — **stop iterating on your current mental model and search for outside information.**

### The failure mode this prevents

You hit error X. You hypothesize cause Y. Every subsequent experiment is designed to work around Y. But the real cause is stupid thing Z (a flag you set wrong, a library version issue, a misunderstanding of how a tool works). Because you never questioned Y, you keep concluding "this fundamentally can't work because of Y" while Z sits there silently ruining everything.

### When to trigger this

- Same class of error 3+ times across different configs
- You've "explained" the problem but your fix doesn't help
- Cost is stubbornly high and you can't identify where time is going
- Something contradicts documentation or known benchmarks (e.g., "FSDP should be faster but it's 3× slower")

### How to search: biased AND unbiased

Do **both** types of search, not just one:

**Biased searches** (targeted at your specific hypothesis):
- Search for the exact error message
- Search for your specific hypothesis ("FSDP slow on LoRA", "vLLM OOM with quantization")
- Look for GitHub issues on the libraries you're using

**Unbiased searches** (deliberately broad, to surface things you haven't considered):
- "optimize [framework] training cost [model size]" — generic best practices
- "fastest way to finetune [model] on [GPU count]× [GPU tier]" — what are other people doing?
- "[framework] training performance guide" — official docs you may have missed
- "[framework] common mistakes" or "[framework] training gotchas"

The unbiased searches are critical. They surface solutions to problems you don't know you have. If someone's blog post says "make sure to set X=True or training is 5× slower" and you never set X, that's your answer — but you'd never find it by searching for your specific error.

### What to do with results

- **Challenge your hypothesis.** If search results suggest a different cause than Y, test that cause directly before continuing to work around Y.
- **Check your assumptions against docs.** You may be using a flag wrong, passing the wrong dtype, or missing a required config field.
- **Look for other people's benchmarks.** If someone reports 2s/step on your hardware and you're seeing 20s/step, the problem is your config, not the hardware.
