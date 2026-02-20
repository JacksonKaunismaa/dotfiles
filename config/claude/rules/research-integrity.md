# Research Integrity

**NEVER compromise experimental validity for convenience.**

It is much better for code to crash with an error than to silently continue with a default value. Crashes are noticed immediately; invalid results from silent defaults can go undetected and corrupt your analysis.

## Default Values for Results — NEVER NEVER NEVER

**Defaults in config objects** (pydantic models, config classes) are fine — they're explicit, centralized, and documented.

**Default keyword arguments in function definitions** (like `def foo(x=0):`) are NOT okay. Keep defaults in the config, not scattered across function signatures.

**Intermediate results** (parsed values, API responses, measurements) must NEVER return a default value when the actual result couldn't be obtained. If you can't get the real value, throw an error.

Examples of what NOT to do:
- Parsing a score from an AI response fails → return 0 ❌
- API call fails → return empty string ❌
- Can't find expected field in response → return False ❌
- Use `.get(key, default)` to hide missing data ❌

Instead:
- **Let the code crash** — this is GOOD.
- Use `None` only when the data is genuinely optional and you'll handle the None case explicitly
- Log warnings about excluded/failed data points

## Global Variables — NEVER

**Never use global variables.** Not for directories, loggers, prompt names, or "constants" that vary between runs. Global state destroys reproducibility. Pass everything through config objects.

Structure configs with inheritance:
- A top-level base config contains typical/global parameters (model name, max tokens, etc.)
- Each experiment subclasses the base config and adds additional parameters as needed

Use pydantic-settings for CLI argument parsing: `class Config(BaseSettings, cli_parse_args=True)`.

## Config Passing

Pass config objects when parameter count gets unwieldy. If a function needs more than ~5 parameters that all come from a config object, just pass the whole config instead of unpacking each field.

Never pass both a config object AND attributes extracted from that config. If you're passing the config, get values from it inside the function.
