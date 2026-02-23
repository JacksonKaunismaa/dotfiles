---
name: pipeline-audit
description: "Audit all pipelines in a codebase for robustness. Use when user asks for a 'pipeline audit', 'pipeline review', or wants to see the state of all data/ML/processing pipelines — checks for intermediate logging, crash resilience, and provides an at-a-glance inventory."
---

# Pipeline Audit

**Trigger: When the user asks for a "pipeline audit", audit every pipeline in the codebase for robustness and produce an at-a-glance inventory.**

## IMPORTANT: Do NOT fix code without confirmation

Report findings first. Do NOT automatically fix issues — wait for the user to review and confirm.

## IMPORTANT: Use subagents to read everything

1. Do initial searches to understand the codebase structure and identify all pipelines (entry points, scripts, workflow orchestrators, batch jobs)
2. Launch subagents in parallel using the Task tool — one per pipeline or logical group. **Do NOT give subagents a fixed reading list.** Tell each subagent what entry point it's auditing and instruct it to follow the code wherever it leads — reading any files that come up as relevant during its investigation until it has a full picture of how the pipeline works.

## CRITICAL: What counts as a pipeline

A pipeline is an **entry point** — a file the user runs directly. In most research codebases, these are `run_*.py` files that have `Config.setup()` or equivalent config initialization in them. That's it.

**These are pipelines:**
- `run_*.py` files with config setup — these are the entry points

**These are NOT pipelines — do NOT list them:**
- Helper functions or utility modules called by pipelines (those are *steps within* a pipeline)
- Sub-steps or phases of a pipeline (describe them as steps inside the parent pipeline's listing)
- Scripts in `experiments/` or `scratch/` that chain together multiple pipelines (those are orchestration, not pipelines themselves)
- Utility functions, data loaders, API wrappers, or any other internal code

**Start by finding entry points.** Search for `run_*.py` files and files with `Config.setup()` (or the project's equivalent config initialization pattern). Those are your pipelines. Everything else is either a step within one of those pipelines or not a pipeline at all.

## CRITICAL: Deduplicate aggressively

Subagents will report the same pipeline multiple times from different angles. You MUST deduplicate before presenting results.

- **Each pipeline appears exactly once** in the inventory table
- **Merge subagent findings** — if two subagents both report on `run_scoring.py`, combine their findings into one entry
- **Nest sub-steps** — if a subagent reports a helper function as a "pipeline", find which actual pipeline calls it and describe it as a step within that pipeline
- **Note optional steps** — if a pipeline has steps that can be disabled via flags or config, say so (e.g., "Step 3 (optional, disabled with `--skip-scoring`): ...")

If you're unsure whether something is a pipeline or a sub-step, trace it: does it have its own config setup and get invoked directly by the user? If not, it's a sub-step.

## CRITICAL: Subagents must follow the code, not stop at a reading list

**Do NOT pre-determine which files a subagent should read.** Tell the subagent which entry point to audit and let it follow the call chain on its own. If the entry point calls `inference.run_batch()` in another file, the subagent should read that file. If that function delegates to a subprocess or remote call, the subagent should follow that too.

The failure mode: you give a subagent a fixed list of files, it reads those files, and correctly reports what it found — but misses relevant code in files it was never told to read. The subagent is the one exploring the code; it's in the best position to decide what's relevant.

## IMPORTANT: Precision over recall

**Prefer high precision over high recall.** Only flag concrete issues with evidence. Before reporting a finding, subagents must verify their claims by reading the actual code.

## What to check

### 1. Intermediate logging (Critical)

Every pipeline step should log:
- **What it's starting** (step name, input description)
- **How long it took** (wall-clock time per step)
- **How many items it processed** (counts, batch sizes)
- **Completion status** (success/failure with context)

**Red flags:**
- Pipeline runs for minutes/hours with no output until the end
- No timing information — impossible to estimate how long a re-run will take
- Silent failures where a step produces 0 results but the pipeline continues
- `print()` used instead of proper logging (loses timestamps, levels, context)

### 2. Intermediate result persistence (Critical)

After each major step, results should be saved to disk so the pipeline can resume from the last checkpoint.

**Red flags:**
- Large lists/dicts accumulated in memory across steps with no disk writes until the end
- No checkpoint files between expensive operations (API calls, model inference, large transforms)
- Pipeline must restart from scratch after any error
- Results written only at the very end — a crash at 95% loses everything
- No resume/restart capability for long-running jobs

### 3. Pipeline inventory (Always produce)

For every pipeline found, produce a summary row:

| Pipeline | Entry point | Steps | Logging? | Checkpoints? | Est. runtime | Robustness |
|----------|-------------|-------|----------|--------------|-------------|------------|

Where:
- **Pipeline**: Human-readable name/description of what it does
- **Entry point**: File path and function/command to run it
- **Steps**: Detailed description of each step — not just labels, but what each step actually does, what data it consumes and produces, and how it connects to the next step. A reader who has never seen this code should understand the pipeline from this description alone. Write full sentences, not arrow diagrams.
- **Logging?**: Yes/No/Partial — does it log progress and timing?
- **Checkpoints?**: Yes/No/Partial — does it save intermediate results?
- **Est. runtime**: Short/Medium/Long based on what the code does (API calls, model inference, large data)
- **Robustness**: Green/Yellow/Red — overall assessment

**Example of good vs bad step descriptions:**

Bad: "fetch → parse → score → export"

Good: "Step 1: Fetches all conversation transcripts from the API using paginated requests (~500 per batch). Step 2: Parses each transcript into structured turn objects, extracting speaker labels and timestamps. Step 3: Sends each turn to GPT-4 for refusal classification, collecting scores and reasoning. Step 4: Writes scored results to a CSV with one row per turn, including the original transcript ID and classification."

## Output format

### Section 1: Pipeline Inventory (always first)

The at-a-glance table described above. This is the most important deliverable — the user should be able to scan this and immediately see which pipelines are robust and which aren't.

### Section 2: Findings (grouped by pipeline)

For each pipeline with issues, list findings:

- **Finding number and severity** (e.g., "**1. [Critical]**")
- **Pipeline name and file path**
- **What the pipeline does** — enough context to understand without opening the file
- **The specific issue** — what's missing or broken
- **Code snippet** — include enough surrounding context (10-20 lines minimum)
- **What could go wrong** — concrete failure scenario (e.g., "If the API returns a 429 at step 3, you lose 2 hours of step 1-2 results")
- **Suggested fix** — specific, actionable recommendation

**Number findings sequentially: 1, 2, 3...** across all pipelines. Group by pipeline, not by issue type.

### Section 3: Summary

- Total pipelines found
- How many are robust (green)
- How many need work (yellow/red)
- Highest-priority fixes (the ones that would save the most time/money if a crash happened)
