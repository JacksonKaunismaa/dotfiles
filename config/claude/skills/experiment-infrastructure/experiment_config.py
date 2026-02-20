"""Base config class for experiments.

Provides CLI parsing, immutability, and automatic experiment setup.
Inherit from BaseExperimentConfig in your experiment-specific configs.
"""

import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Self

from pydantic_settings import BaseSettings, SettingsConfigDict


def _get_git_hash() -> str:
    """Get short git hash of current commit, or 'nogit' if not in a repo.

    Appends '-dirty' if there are uncommitted changes, so you can tell
    whether the code that produced results was actually committed.
    """
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        git_hash = result.stdout.strip()
        dirty_check = subprocess.run(
            ["git", "diff", "--quiet", "HEAD"],
            capture_output=True,
        )
        if dirty_check.returncode != 0:
            git_hash += "-dirty"
        return git_hash
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "nogit"


def _get_timestamp() -> str:
    """Get current timestamp in a filesystem-friendly format."""
    return datetime.now().strftime("%Y%m%d_%H%M%S")


class BaseExperimentConfig(BaseSettings):
    """Base config class for experiments. Inherit from this in your project.

    Provides:
    - CLI parsing via pydantic-settings
    - Immutability (frozen=True)
    - setup() classmethod that parses CLI, computes output_dir, saves config.json
    """

    model_config = SettingsConfigDict(
        cli_parse_args=True,
        frozen=True,
    )

    experiment: str = ""  # e.g. "feb26-refusal-eval". Validated in setup().
    variant: str = ""  # e.g. "gpt4-baseline". Validated in setup().
    output_dir: str = ""  # Computed by setup(). Pass --output_dir to resume a previous run.
    seed: int = 42

    @classmethod
    def setup(cls, *, inspect: bool = False) -> Self:
        """Parse CLI args, compute output_dir, save config.json.

        Args:
            inspect: If True, use flat directory for Inspect AI .eval files.
                Sets INSPECT_LOG_DIR and INSPECT_EVAL_LOG_FILE_PATTERN env vars.
                Skips config.json (Inspect stores config inside .eval files).

        Standard mode:
            results/{experiment}/{variant}-{entry_point}_{timestamp}_{git_hash}/
              config.json, results.json, etc.

        Inspect mode:
            results/{experiment}/
              {variant}-{entry_point}_{git_hash}_{id}.eval  (written by Inspect)

        Resume (--output_dir provided):
            Uses the given output_dir directly. Entry point handles idempotency.
        """
        config = cls()

        if not config.experiment:
            raise ValueError("--experiment is required (e.g. 'feb26-refusal-eval')")
        if not config.variant:
            raise ValueError("--variant is required (e.g. 'gpt4-baseline')")

        entry_point = Path(sys.argv[0]).stem.removeprefix("run_").replace("_", "-")
        git_hash = _get_git_hash()

        if config.output_dir:
            # Resume — user provided --output_dir explicitly
            output_dir = config.output_dir
        elif inspect:
            # Inspect mode — flat directory, .eval files go here
            output_dir = str(Path("results") / config.experiment)
        else:
            # Standard mode — nested per-run directory
            timestamp = _get_timestamp()
            run_dir_name = f"{config.variant}-{entry_point}_{timestamp}_{git_hash}"
            output_dir = str(Path("results") / config.experiment / run_dir_name)

        output_path = Path(output_dir)
        if not inspect and output_path.exists():
            print(f"[experiment] WARNING: output dir already exists: {output_dir}")
        output_path.mkdir(parents=True, exist_ok=True)

        # model_copy is pydantic's built-in way to update frozen models
        config = config.model_copy(update={"output_dir": output_dir})

        if inspect:
            # Tell Inspect where to write and what to name the files
            os.environ["INSPECT_LOG_DIR"] = output_dir
            os.environ["INSPECT_EVAL_LOG_FILE_PATTERN"] = (
                f"{config.variant}-{entry_point}_{git_hash}_{{id}}"
            )
            print(f"[experiment/inspect] {config.variant} -> {output_dir}/")
        else:
            (Path(output_dir) / "config.json").write_text(
                config.model_dump_json(indent=2)
            )
            # Save which fields were explicitly provided (CLI/env) vs. defaulted
            overrides = {
                k: v
                for k, v in config.model_dump().items()
                if k in config.model_fields_set
            }
            (Path(output_dir) / "overrides.json").write_text(
                json.dumps(overrides, indent=2, default=str)
            )
            print(f"[experiment] {config.variant} -> {output_dir}")

        return config
