---
name: modal-training-cost-optimization
description: Use when launching ML training jobs on Modal and need to minimize GPU cost, when seeing high estimated training costs, when choosing between GPU tiers or counts, or when deciding on distributed training strategy (FSDP vs device_map)
---

# Modal Training Cost Optimization

Find the cheapest GPU configuration for a training job on Modal.

## Core Insight

Total cost = **total forward passes** (fixed for a given model+dataset) x **hardware $/FLOP**. Batch size and gradient accumulation trade step count vs step time but don't change total compute. The levers:

1. **Distributed strategy** — FSDP over `device_map="auto"` (usually the single biggest win)
2. **GPU tier** — best FLOP/$ for your model size
3. **GPU count** — more GPUs = faster wall time but same GPU-hours; find the communication overhead sweet spot

## Process

### 1. Naive config, measure, iterate fast

Launch, watch a few steps, compute cost estimate from tqdm (s/step x total steps x GPUs x $/hr). Kill if bad, adjust the biggest lever, relaunch.

Example progression:
- `device_map="auto"`, 8x H200 → 48s/step, $864. Kill immediately.
- `device_map="auto"`, 2x H200 → 48s/step, $216. Same speed, 4x cheaper. Still slow.
- FSDP, 4x H200, bs=2 → 20s/step, $178. Real data parallelism, big win.
- FSDP, 4x H200, bs=4 → 17.5s/step, $156. Marginal gain. Ship it.

### 2. Launch production once cost stabilizes

Once further tweaks yield <20% improvement, launch the real run. Don't wait for perfection.

### 3. Benchmark on a separate Modal app

Create a **separate app name** so `modal app stop` on benchmarks doesn't kill production. Launch full training config, read s/step from tqdm, kill after a few steps. No `--max_steps` needed.

### 4. Continue sweeping in background

Keep testing on the benchmark app. If something dramatically beats production, kill and relaunch. Otherwise let it finish.

Sweep axes:

| Axis | Values to try |
|------|--------------|
| Batch size | 1, 2, 3, 4, 6, 8 (largest that fits in memory) |
| Gradient accumulation | 1, 2, 4, 8 (fewer = faster steps, same total compute) |
| GPU count | 2, 4, 8 (check communication overhead) |
| GPU tier | A100-80G, H100, H200 (cheaper GPUs may lose on $/FLOP) |

Record per run: s/step, effective batch size, peak GPU memory.

### 5. Check memory with nvidia-smi

```bash
modal container exec <container_id> -- nvidia-smi
```

Large free memory → increase batch size. Near-full → at the limit.

### 6. Compute cost from tqdm

```
cost = total_hours * num_gpus * price_per_gpu_hour
```

tqdm shows total steps and s/step directly.

## Quick Reference

| Lesson | Detail |
|--------|--------|
| `device_map="auto"` is NOT data parallelism | Splits model across GPUs but training is single-process. More GPUs = same speed, higher cost. Use FSDP/DDP. |
| Kill early, kill often | $800+ estimate after a few steps? Kill immediately. Minutes of wasted GPU time << hours of bad config. |
| Better GPUs are more cost-efficient | H200 > H100 > A100 on $/FLOP in practice. Don't bother testing A100s for large models. |
| Always measure memory | Don't guess — `nvidia-smi` shows exact batch size headroom. |
| Never benchmark on production app | Separate Modal app name so stops/kills are isolated. |
| Weight loading should take ~5 min | If loading takes >10 min (excluding download), something is likely wrong — investigate. Implausibly long load times usually mean a misconfiguration (wrong dtype, bad sharding, unnecessary conversion). |

## What Typically Happens

Early iterations yield dramatic savings (wrong distributed strategy, too many GPUs). Once fixed, remaining configs converge to roughly the same cost because total forward passes are fixed. Differences come from communication overhead (FSDP all-gather/reduce-scatter grows with GPU count), GPU utilization (larger batch sizes help, with diminishing returns), and memory limits (OOM sets hard ceiling on batch size).
