"""Base config class for experiments.

Provides CLI parsing, immutability, and automatic experiment setup.
Inherit from BaseExperimentConfig in your experiment-specific configs.
"""

import json
import logging
import os
import subprocess
import sys
from datetime import datetime, timezone
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
    """Get current UTC timestamp in a filesystem-friendly format."""
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")


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

    project: str = ""  # e.g. "feb19-hardcode-auditbench-ct-qwen-32b". Date + full research description. Validated in setup().
    experiment: str = ""  # e.g. "auditbench-eval-matched-categories". Be maximally verbose — you'll run similar experiments later. Validated in setup().
    variant: str = ""  # e.g. "gpt4-baseline". Experimental condition. Validated in setup().
    output_dir: str = ""  # Computed by setup(). Pass --output_dir to resume a previous run.
    entry_point: str = ""  # Computed by setup(). The Python module/script that was run (e.g. "run-eval").
    seed: int = 42

    @classmethod
    def setup(cls, *, inspect: bool = False) -> Self:
        """Parse CLI args, compute output_dir, save config.json.

        Args:
            inspect: If True, also set INSPECT_LOG_DIR and INSPECT_EVAL_LOG_FILE_PATTERN
                env vars so Inspect AI writes .eval logs into the same variant run dir.
                config.json and overrides.json are still written (same as normal mode).

        Both modes use the same directory layout:
            results/{project}/{experiment}/{variant}-{entry_point}_{timestamp}_{git_hash}/
              config.json, overrides.json, run.log, results.json, etc.

        Inspect mode additionally writes into that dir:
              {entry_point}_{id}.eval  (written by Inspect via INSPECT_EVAL_LOG_FILE_PATTERN)

        Resume (--output_dir provided):
            Loads the run's saved config.json so the run doesn't silently proceed
            with class defaults. Explicit CLI args still win; any fields that differ
            from the saved config are recorded in resume_overrides.{n}.json. The
            original config.json is never overwritten. Entry point handles idempotency.
        """
        config = cls()
        resuming = bool(config.output_dir)
        output_dir = config.output_dir
        resume_diffs: dict = {}

        if resuming:
            # Resume — user provided --output_dir explicitly.
            # Load the original config.json so we don't run with broken defaults.
            saved_config_path = Path(output_dir) / "config.json"
            if saved_config_path.exists():
                saved = json.loads(saved_config_path.read_text())
                # CLI overrides still win — merge saved config under explicit CLI args
                cli_overrides = {
                    k: v
                    for k, v in config.model_dump().items()
                    if k in config.model_fields_set and k != "output_dir"
                }
                # Compute actual diffs (fields where CLI value != saved value)
                resume_diffs = {
                    k: {"saved": saved.get(k), "override": v}
                    for k, v in cli_overrides.items()
                    if saved.get(k) != v
                }
                saved.update(cli_overrides)
                config = cls.model_validate(saved)
            else:
                print(f"[experiment] WARNING: resuming but no config.json found in {output_dir}")

        if not config.project:
            raise ValueError(
                "--project is required. Use a maximally verbose name: date prefix + full research "
                "description (e.g. 'feb19-hardcode-auditbench-ct-qwen-32b'). "
                "See the experiment-infrastructure skill for naming conventions."
            )
        if not config.experiment:
            raise ValueError(
                "--experiment is required. Use a maximally verbose name that describes exactly what "
                "this specific investigation does (e.g. 'auditbench-eval-matched-categories'). "
                "Vague names like 'eval' or 'training' cause confusion — you'll run similar "
                "experiments later. See the experiment-infrastructure skill for naming conventions."
            )
        if not config.variant:
            raise ValueError("--variant is required (e.g. 'gpt4-baseline')")

        entry_point = Path(sys.argv[0]).stem.removeprefix("run_").replace("_", "-")
        git_hash = _get_git_hash()

        if not resuming:
            timestamp = _get_timestamp()
            run_dir_name = f"{config.variant}-{entry_point}_{timestamp}_{git_hash}"
            output_dir = str(Path("results") / config.project / config.experiment / run_dir_name)

        output_path = Path(output_dir)
        if not resuming and output_path.exists():
            print(f"[experiment] WARNING: output dir already exists: {output_dir}")
        output_path.mkdir(parents=True, exist_ok=True)

        # model_copy is pydantic's built-in way to update frozen models
        config = config.model_copy(update={"output_dir": output_dir, "entry_point": entry_point})

        # Set up file logging to output_dir/run.log BEFORE announcements
        # so they appear in the log file. Entry points must call
        # logging.basicConfig(level=logging.INFO) for INFO logs to propagate.
        logger = logging.getLogger(__name__)
        log_path = Path(output_dir) / "run.log"
        handler = logging.FileHandler(log_path)
        handler.setFormatter(logging.Formatter(
            "%(asctime)s [%(levelname)s] (%(name)s) %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        ))
        logging.getLogger().addHandler(handler)

        if inspect:
            # Inspect AI writes its .eval logs to INSPECT_LOG_DIR using a filename
            # pattern. We put .eval files inside the same variant run dir as
            # config.json so everything for one run lives together.
            os.environ["INSPECT_LOG_DIR"] = output_dir
            os.environ["INSPECT_EVAL_LOG_FILE_PATTERN"] = f"{entry_point}_{{id}}"

        if resuming:
            log_prefix = "[experiment/resume]"
        elif inspect:
            log_prefix = "[experiment/inspect]"
        else:
            log_prefix = "[experiment]"

        if resuming:
            # Don't overwrite config.json from a previous run.
            if resume_diffs:
                n = 1
                while (Path(output_dir) / f"resume_overrides.{n}.json").exists():
                    n += 1
                resume_path = Path(output_dir) / f"resume_overrides.{n}.json"
                resume_path.write_text(json.dumps(resume_diffs, indent=2, default=str))
                logger.warning(
                    f"{log_prefix} CLI overrides differ from saved config: "
                    f"{list(resume_diffs.keys())} — written to {resume_path.name}"
                )
                for k, diff in resume_diffs.items():
                    logger.warning(f"  {k}: {diff['saved']!r} -> {diff['override']!r}")
            logger.info(f"{log_prefix} {config.project}/{config.experiment} {config.variant} -> {output_dir}")
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
            logger.info(f"{log_prefix} {config.project}/{config.experiment} {config.variant} -> {output_dir}")

        return config
