---
name: experiment-infrastructure
description: "Design spec for experiment infrastructure. Use when: setting up experiment infrastructure in a new repo, or need to understand how experiment configs and results directories work."
---

# Experiment Infrastructure Spec

One file, one classmethod. Without it, experiment results end up scattered with no way to know which code or parameters produced them. This enforces consistent directory layout, git hash tracking, and config saved alongside results.

Copy `experiment_config.py` from this skill's directory and adjust the import.

## How It Works

Inherit from `BaseExperimentConfig`, call `.setup()` in your entry point:

```python
# config_my_experiment.py
from myproject.experiment_config import BaseExperimentConfig

class MyExperimentConfig(BaseExperimentConfig):
    model: str = "gpt-4"
    num_samples: int = 100
```

```python
# run_my_experiment.py
def main() -> None:
    config = MyExperimentConfig.setup()            # standard mode
    # config = MyExperimentConfig.setup(inspect=True)  # for Inspect AI

    # config.output_dir is set, config.json already saved
    # ... do work, save results to config.output_dir ...
```

```bash
python run_my_experiment.py --project feb19-hardcode-auditbench-ct-qwen-32b --experiment auditbench-eval-matched-categories --variant gpt4-baseline --model gpt-4
```

`setup()` parses CLI args, validates `--project`, `--experiment`, and `--variant` are provided, computes `output_dir`, creates the directory, saves `config.json`, and prints the path.

## Directory Layout

Three levels: **project** (research thread) > **experiment** (specific investigation) > **run** (single execution).

**Standard** (`setup()`):
```
results/{project}/{experiment}/{variant}-{entry_point}_{timestamp}_{git_hash}/
  config.json, results.json, ...
```

**Inspect** (`setup(inspect=True)`) — flat within experiment dir, sets `INSPECT_LOG_DIR` and `INSPECT_EVAL_LOG_FILE_PATTERN` env vars:
```
results/{project}/{experiment}/
  {variant}-{entry_point}_{git_hash}_{id}.eval
```

An older version of this spec used only `--experiment` and `--variant`, with no `--project` level. This produced a flat `results/` directory where all experiments lived side by side. After a week of work you'd end up with 30+ cryptically named folders where you can't tell what belongs together. **If you see a project with this flat layout, it's using the outdated convention — new experiments should use `--project`.**

```
# Without --project: flat, vague, unreadable at scale
results/
  feb19-ct-data/
  feb19-ct-training/
  feb19-hardcode-ct-auditbench-eval-n50/
  feb19-hardcode-ct-auditbench-eval-matched/
  feb24-qwen32b-hardcode-ga-eval/

# With --project: grouped by research thread, verbose experiment names
results/
  feb19-hardcode-auditbench-ct-qwen-32b/
    ct-sft-training-data-generation/
    ct-lora-training-run/
    auditbench-eval-matched-categories/
    auditbench-eval-n50-samples/
    organism-ablation-baseline/
    llama70b-hardcode-validation/
```

## Experiment Scripts

Every experiment MUST be a committed shell script in `experiments/{project}/`. This ensures there's always a record of exactly what was run. The script filename is the experiment name.

```
experiments/
  feb19-hardcode-auditbench-ct-qwen-32b/
    ct-lora-training-run.sh
    ct-temperature-sweep.sh
    auditbench-eval-matched-categories.sh
```

Example script (`experiments/feb19-hardcode-auditbench-ct-qwen-32b/auditbench-eval-matched-categories.sh`):

```bash
#!/bin/bash
set -euo pipefail

python -m myproject.run_eval \
    --project feb19-hardcode-auditbench-ct-qwen-32b \
    --experiment auditbench-eval-matched-categories \
    --variant gpt4-baseline \
    --model gpt-4
```

The script can point to a different `--project` if needed (e.g. writing results into a shared project).

## Running Experiments

```bash
# Single run
bash experiments/feb19-hardcode-auditbench-ct-qwen-32b/auditbench-eval-matched-categories.sh

# Parallel ablations — just use & and wait
bash experiments/feb19-hardcode-auditbench-ct-qwen-32b/ct-temperature-sweep.sh &
bash experiments/feb19-hardcode-auditbench-ct-qwen-32b/ct-temperature-sweep-high.sh &
wait

# Resume a failed run — pass --output_dir to reuse existing directory
python -m myproject.run_eval \
    --project feb19-hardcode-auditbench-ct-qwen-32b \
    --experiment ct-lora-training-run \
    --variant baseline \
    --output_dir results/feb19-hardcode-auditbench-ct-qwen-32b/ct-lora-training-run/baseline-run-eval_20260219_143052_a1b2c3d
```

For resume, the entry point must handle idempotency (check if results already exist, skip if so).

## Naming Conventions

| Level | Flag | Semantics | Examples |
|-------|------|-----------|----------|
| **Project** | `--project` | Date + full research description, stable across days/weeks | `feb19-hardcode-auditbench-ct-qwen-32b`, `mar03-scheming-replication-sonnet`, `jan15-sycophancy-ablation` |
| **Experiment** | `--experiment` | Specific investigation within the project (no date). Be maximally verbose — you'll run similar experiments later | `auditbench-eval-matched-categories`, `ct-lora-training-run`, `ct-temperature-sweep`, `dpo-data-generation-from-refusals` |
| **Variant** | `--variant` | Experimental condition within one experiment | `gpt4-baseline`, `n50`, `no-system-prompt` |

All lowercase, hyphens only, no underscores (underscores are reserved for the auto-generated run directory separator).

## Important Details

- **CLI args use underscores**: `--num_samples 100` (correct), `--num-samples 100` (will error). This is a pydantic-settings convention.
- **Always use `Config.setup()`**, never raw `Config()` — `setup()` handles output_dir, config.json, and validation.
- **Git dirty detection**: Hash includes `-dirty` suffix when uncommitted changes exist.
- **Install the project**: Run `pip install -e .` so imports work from anywhere.
