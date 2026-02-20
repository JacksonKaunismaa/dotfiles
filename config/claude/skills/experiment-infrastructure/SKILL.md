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
python run_my_experiment.py --experiment feb26-refusal --variant gpt4-baseline --model gpt-4
```

`setup()` parses CLI args, validates `--experiment` and `--variant` are provided, computes `output_dir`, creates the directory, saves `config.json`, and prints the path.

## Directory Layout

**Standard** (`setup()`):
```
results/{experiment}/{variant}-{entry_point}_{timestamp}_{git_hash}/
  config.json, results.json, ...
```

**Inspect** (`setup(inspect=True)`) — flat directory, sets `INSPECT_LOG_DIR` and `INSPECT_EVAL_LOG_FILE_PATTERN` env vars:
```
results/{experiment}/
  {variant}-{entry_point}_{git_hash}_{id}.eval
```

## Running Experiments

```bash
# Single run
python run_my_experiment.py --experiment feb26-refusal --variant gpt4-baseline --model gpt-4

# Parallel ablations — just use & and wait
python run_my_experiment.py --experiment feb26-refusal --variant gpt4-t0.0 --model gpt-4 --temperature 0.0 &
python run_my_experiment.py --experiment feb26-refusal --variant gpt4-t0.7 --model gpt-4 --temperature 0.7 &
wait

# Resume a failed run — pass --output_dir to reuse existing directory
python run_my_experiment.py --experiment feb26-refusal --variant gpt4-baseline \
    --output_dir results/feb26-refusal/gpt4-baseline-my-experiment_20260219_143052_a1b2c3d
```

For resume, the entry point must handle idempotency (check if results already exist, skip if so).

## Important Details

- **CLI args use underscores**: `--num_samples 100` (correct), `--num-samples 100` (will error). This is a pydantic-settings convention.
- **Naming**: `--experiment` should include a short date + description (`feb26-refusal-eval`). `--variant` describes the condition (`gpt4-baseline`).
- **Always use `Config.setup()`**, never raw `Config()` — `setup()` handles output_dir, config.json, and validation.
- **Git dirty detection**: Hash includes `-dirty` suffix when uncommitted changes exist.
- **Install the project**: Run `pip install -e .` so imports work from anywhere.
