# Research Integrity

Crashes are signals you can act on. Silent defaults that look like clean results sit unnoticed and corrupt analysis. Default to crashing over substituting.

## Don't return defaults for missing intermediate results

Defaults in **config objects** (pydantic models, config classes) are fine — they're explicit and centralized.

Defaults in **function signatures** (`def foo(x=0):`) shouldn't carry experimental parameters. Keep those in the config.

**Intermediate results** — parsed values, API responses, measurements — should not return a default when the real value couldn't be obtained. Examples to avoid:

- Score parsing fails → returns 0
- API call fails → returns empty string
- Field missing → returns `False`
- `.get(key, default)` to hide missing data

Instead, let it crash, or return `None` and handle the `None` case explicitly. Log warnings about excluded data points.

## No global variables

Global state — directories, prompt names, "constants" that vary between runs — destroys reproducibility. Pass everything through config objects. (Module-level loggers via `logging.getLogger(__name__)` are fine — they're a Python convention and don't carry experiment state.)

Structure configs with inheritance: a base config holds typical/global parameters; experiment configs subclass and add more. Use pydantic-settings for CLI args:

```python
class Config(BaseSettings, cli_parse_args=True): ...
```

## Config passing

If a function needs more than ~5 parameters all from the same config, pass the config object instead.

Don't pass both a config and attributes extracted from it — read from the config inside the function.
