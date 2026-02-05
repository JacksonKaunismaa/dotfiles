"""Base config class for experiments.

Provides CLI parsing, immutability, and None sentinel handling.
Inherit from BaseExperimentConfig in your experiment-specific configs.
"""

from typing import Any, Self

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


# Sentinel for representing None in CLI args.
# CLI args are strings, so we use this to represent None.
# BaseExperimentConfig has a validator that converts this back to None.
CLI_NONE_SENTINEL = "__none__"


class BaseExperimentConfig(BaseSettings):
    """Base config class for experiments. Inherit from this in your project.

    Provides:
    - CLI parsing via pydantic-settings
    - Immutability (frozen=True)
    - copy_with() for creating variants
    - None sentinel handling for CLI args
    """

    model_config = SettingsConfigDict(
        cli_parse_args=True,
        cli_ignore_unknown_args=True,  # So suite can use --dry-run, --resume, etc.
        frozen=True,  # Configs are immutable once created
    )

    output_dir: str = ""  # Runner fills this via CLI
    seed: int = 42

    @field_validator("*", mode="before")
    @classmethod
    def _convert_none_sentinel(cls, v: Any) -> Any:
        """Convert CLI none sentinel back to Python None.

        CLI args are strings, so None values are passed as a sentinel string.
        This validator converts them back to Python None.

        For list types, pydantic-settings wraps the CLI arg in a list before
        validation, so we also check for [sentinel].
        """
        if v == CLI_NONE_SENTINEL:
            return None
        if isinstance(v, list) and v == [CLI_NONE_SENTINEL]:
            return None
        return v

    def copy_with(self, **updates: Any) -> Self:
        """Create a copy with updated fields. Use this instead of model_copy()."""
        if "output_dir" in updates:
            raise ValueError("output_dir is set by experiment_runner, not suite files")
        return self.__class__.model_validate({**self.model_dump(), **updates})

    def model_copy(self, *args: Any, **kwargs: Any) -> Self:
        raise NotImplementedError("Use copy_with() instead")
