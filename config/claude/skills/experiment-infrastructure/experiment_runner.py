"""Generic experiment runner - no dependencies on specific configs or entry points.

Supports two modes:
- "standard": Nested directories, runner saves config.json
  results/{experiment_name}/{timestamp}_{git_hash}/{variant_name}/

- "inspect": Flat directory for Inspect AI evals, config stored in .eval file
  results/{experiment_name}/{git_hash}_{variant_name}_{id}.eval
"""

import argparse
import json
import os
import subprocess
import sys
from collections import Counter
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Generic, Literal, Protocol, TypeVar, runtime_checkable


@runtime_checkable
class ExperimentConfig(Protocol):
    """Protocol for experiment configs. Must support serialization."""

    def model_dump(self) -> dict[str, Any]: ...


C_co = TypeVar("C_co", bound=ExperimentConfig, covariant=True)


@dataclass(frozen=True)
class ExperimentCase(Generic[C_co]):
    """A single experimental condition: a name for the variant + its config.

    Separates infrastructure metadata (variant_name) from experiment parameters (config).
    The variant_name is used by the runner for directory naming and reporting.
    The config contains actual experiment parameters that the entry point uses.

    The type parameter is covariant because ExperimentCase only reads the config (frozen).
    This allows passing Sequence[ExperimentCase[MyConfig]] where Sequence[ExperimentCase[ExperimentConfig]] is expected.
    """

    variant_name: str
    config: C_co


@dataclass
class ExperimentResult:
    """Result of running a single experiment."""

    output_dir: str
    success: bool
    return_code: int
    stdout: str
    stderr: str


def _get_git_hash() -> str:
    """Get short git hash of current commit, or 'nogit' if not in a repo."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "nogit"


def _get_timestamp() -> str:
    """Get current timestamp in a filesystem-friendly format."""
    return datetime.now().strftime("%Y%m%d_%H%M%S")


# Sentinel for representing None in CLI args.
# CLI args are strings, so we use this to represent None.
# Base config must have a validator that converts this back to None.
CLI_NONE_SENTINEL = "__none__"


def _config_to_args(config_dict: dict[str, Any]) -> list[str]:
    """Convert a config dict to CLI arguments.

    Uses underscores (--output_dir) to match pydantic-settings convention.
    None values are passed as CLI_NONE_SENTINEL string.
    """
    args = []

    for key, value in config_dict.items():
        cli_key = f"--{key}"  # pydantic-settings uses underscores

        if value is None:
            args.append(cli_key)
            args.append(CLI_NONE_SENTINEL)
            continue

        if isinstance(value, bool):
            args.append(cli_key)
            args.append(str(value).lower())  # "true" or "false"
        elif isinstance(value, dict):
            args.append(cli_key)
            args.append(json.dumps(value))
        elif isinstance(value, list):
            for item in value:
                args.append(cli_key)
                if isinstance(item, dict):
                    args.append(json.dumps(item))
                else:
                    args.append(str(item))
        elif isinstance(value, Enum):
            args.append(cli_key)
            args.append(value.value)
        else:
            args.append(cli_key)
            args.append(str(value))

    return args


def _run_single(
    entry_point: str,
    cli_args: list[str],
    output_dir: str,
    env: dict[str, str] | None = None,
) -> ExperimentResult:
    """Run a single experiment in a subprocess."""
    cmd = [sys.executable, entry_point, *cli_args]

    result = subprocess.run(cmd, capture_output=True, text=True, env=env)

    return ExperimentResult(
        output_dir=output_dir,
        success=result.returncode == 0,
        return_code=result.returncode,
        stdout=result.stdout,
        stderr=result.stderr,
    )


def run_experiments(
    cases: Sequence[ExperimentCase[ExperimentConfig]],
    entry_point: str,
    experiment_name: str,
    parallelism: int | None = None,
    dry_run: bool = False,  # AUDIT-OK: infra-default - dry_run is infrastructure, not experimental parameter
    resume_dir: str | None = None,  # AUDIT-OK: infra-default - resume_dir is infrastructure, not experimental parameter
    mode: Literal["standard", "inspect"] = "standard",  # AUDIT-OK: infra-default - mode is infrastructure
) -> list[ExperimentResult]:
    """
    Run experiments in parallel with process isolation.

    Args:
        cases: List of ExperimentCase objects (variant_name + config)
        entry_point: Path to the entry point script
        experiment_name: Name for this experiment (used in results path)
        parallelism: Number of experiment configs to run concurrently
        dry_run: If True, just print what would run without running
        resume_dir: Resume from existing run directory (standard mode only)
        mode: "standard" for nested dirs + config.json, "inspect" for flat dir + .eval files

    Results are saved to:
        standard: results/{experiment_name}/{timestamp}_{git_hash}/{variant_name}/
        inspect:  results/{experiment_name}/{git_hash}_{variant_name}_{id}.eval
    """
    if not cases:
        raise ValueError("No cases provided")

    if not Path(entry_point).exists():
        raise FileNotFoundError(f"Entry point not found: {entry_point}")

    if resume_dir and mode == "inspect":
        raise ValueError("resume_dir not supported in inspect mode")

    timestamp = _get_timestamp()
    git_hash = _get_git_hash()

    # Mode-specific path computation
    if mode == "standard":
        if resume_dir:
            run_dir = Path(resume_dir)
            if not run_dir.exists():
                raise FileNotFoundError(f"Resume directory not found: {resume_dir}")
            print(f"Resuming from: {run_dir}")
        else:
            run_dir = Path("results") / experiment_name / f"{timestamp}_{git_hash}"
        output_dirs = [str(run_dir / case.variant_name) for case in cases]
    else:  # inspect mode
        results_dir = Path("results") / experiment_name
        run_dir = results_dir  # For display purposes
        output_dirs = [str(results_dir)] * len(cases)  # All cases write to same flat dir

    # Check for duplicate variant_names
    variant_names = [case.variant_name for case in cases]
    if len(variant_names) != len(set(variant_names)):
        dupes = [v for v, count in Counter(variant_names).items() if count > 1]
        raise ValueError(f"Duplicate variant_names: {dupes}")

    if dry_run:
        print(f"Would run {len(cases)} experiments ({mode} mode):")
        print(f"Run directory: {run_dir}")
        for case, output_dir in zip(cases, output_dirs):
            if mode == "inspect":
                print(f"  {case.variant_name} -> {output_dir}/{git_hash}_{case.variant_name}_*.eval")
            else:
                print(f"  {case.variant_name} -> {output_dir}")
        return []

    # Create directories
    run_dir.mkdir(parents=True, exist_ok=True)

    # Save configs BEFORE running (standard mode only - inspect saves in .eval)
    if mode == "standard":
        for case, output_dir in zip(cases, output_dirs):
            output_path = Path(output_dir)
            output_path.mkdir(parents=True, exist_ok=True)
            config_path = output_path / "config.json"
            saved_config = {**case.config.model_dump(), "output_dir": output_dir}
            config_path.write_text(json.dumps(saved_config, indent=2))

    effective_parallelism = parallelism if parallelism is not None else len(cases)
    print(f"Running {len(cases)} experiments ({mode} mode, parallelism={effective_parallelism})")
    print(f"Run directory: {run_dir}")

    results: list[ExperimentResult] = []

    with ThreadPoolExecutor(max_workers=effective_parallelism) as executor:
        futures = {}
        for case, output_dir in zip(cases, output_dirs):
            config_dict = {**case.config.model_dump(), "output_dir": output_dir}
            cli_args = _config_to_args(config_dict)

            if mode == "standard":
                env = None
            else:  # inspect mode
                env = os.environ.copy()
                env["INSPECT_EVAL_LOG_FILE_PATTERN"] = f"{git_hash}_{case.variant_name}_{{id}}"

            future = executor.submit(
                _run_single, entry_point, cli_args, output_dir, env
            )
            futures[future] = case.variant_name

        for future in as_completed(futures):
            variant_name = futures[future]
            result = future.result()
            results.append(result)

            status = "OK" if result.success else "FAILED"
            print(f"[{status}] {variant_name}")

            if not result.success:
                print(result.stderr)

    successes = sum(r.success for r in results)
    print(f"\nCompleted: {successes}/{len(results)} succeeded")

    return results


def run_experiments_cli(
    cases: Sequence[ExperimentCase[ExperimentConfig]],
    entry_point: str,
    experiment_name: str,
    mode: Literal["standard", "inspect"] = "standard",
) -> list[ExperimentResult]:
    """Entry point for suite files - parses CLI args automatically.

    Args:
        cases: List of ExperimentCase objects (variant_name + config)
        entry_point: Path to the entry point script
        experiment_name: Name for this experiment
        mode: "standard" for nested dirs + config.json, "inspect" for flat dir + .eval files
    """
    if not cases:
        raise ValueError("No cases provided")

    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="Print experiments without running")
    parser.add_argument("-p", "--parallelism", type=int, default=1, help="Number of experiment configs to run concurrently")
    if mode == "standard":
        parser.add_argument("--resume", type=str, metavar="RUN_DIR", help="Resume from existing run directory")
    args = parser.parse_args()

    return run_experiments(
        cases=cases,
        entry_point=entry_point,
        experiment_name=experiment_name,
        parallelism=args.parallelism,
        dry_run=args.dry_run,
        resume_dir=getattr(args, "resume", None),
        mode=mode,
    )
