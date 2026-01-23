# Claude Code Guide

## Git Commits

**Do not add the co-authored-by footer or emoji to commit messages.**

Just write a normal commit message. No `🤖 Generated with Claude Code` or `Co-Authored-By: Claude` footer. These add unnecessary clutter.

## Environment Setup

**Use `uv` for package management. Virtual environment is at `.venv`.**

## Backwards Compatibility

**NEVER add backwards compatibility. No exceptions.**

This is a research codebase, not a production library. Backwards compatibility leads to bloated and confusing code.

When changing an interface:
1. Change it
2. Update all call sites
3. Delete the old way

No deprecated parameters. No compatibility shims. No legacy code paths.

## Documentation Lookup

**When uncertain about external library behavior, look up the documentation first.**

Don't guess or assume how external libraries work. Use web search and web fetch to find official documentation before implementing solutions that depend on library behavior.

## File Search and Globbing

**Glob patterns are case-sensitive. Try alternative cases when searching.**

When searching for files, remember that glob patterns are case-sensitive on Linux. Users don't always provide the exact case. If `**/Config.py` returns nothing, also try `**/config.py`.

## Best Practices

- **CSV files**: Always use pandas (`pd.read_csv()`), never `csv.DictReader`
- **Prompts**: Always use Jinja templates, never inline Python strings. Even short prompts. All formatting should be done in Jinja, not Python.

### Config Structure

**Never use global variables for configuration.** Everything related to experiment configuration belongs in a config object.

Structure configs with inheritance:
- A top-level base config contains typical/global parameters (model name, max tokens, etc.)
- Each experiment subclasses the base config and adds additional parameters as needed

Use pydantic-settings with `cli_parse_args=True` for CLI argument parsing from BaseSettings subclasses.

This keeps all experiment parameters explicit, traceable, and easy to modify per-experiment.

### Config Passing

Pass config objects when parameter count gets unwieldy. If a function needs more than ~5 parameters that all come from a config object, just pass the whole config instead of unpacking each field.

Never pass both a config object AND attributes extracted from that config. If you're passing the config, get values from it inside the function.

## Anti-Patterns

**CRITICAL: Write code a thoughtful senior engineer would write, not code that merely "completes the task."**

These are anti-patterns that Claude tends to fall into. They lead to crappy code. NEVER NEVER NEVER do these:

- **Modify tests to make them pass** - If tests fail, fix the code, not the tests (unless the test itself is genuinely wrong)
- **Add `# type: ignore`, `# noqa`, `# pylint: disable`** to silence errors instead of fixing them (unless explicitly instructed to by the user)
- **Broad try/except blocks** that swallow errors to prevent crashes. Especially bad: `except Exception:` followed by `return False` or `return 0` — this makes errors look like valid "clean" results. If you can't determine an answer, return `None`, not a default that corrupts data.
- **Inline imports inside functions** to avoid import errors or circular dependencies—fix the actual dependency issue
- **Delete or comment out code** that's causing problems without understanding why
- **Hardcode expected values** to make tests pass
- **Add `Optional` or default values** to parameters just to avoid type errors from improper calls
- **Skip validation or error handling** because "it works for this case"
- **Add parallel output paths hoping one works** - If something isn't working, don't add redundant paths hoping one of them will work. Understand WHY the existing path isn't working and fix that.
- **Duplicate config fields across classes** - If ConfigB needs the same fields as ConfigA, make ConfigB extend ConfigA. Don't copy fields and manually copy values at runtime.
- **Duplicate code** - Check if something is already implemented before adding it. Duplicated logic becomes a maintenance burden and leads to bugs when one copy is updated but not the others.
- **Monkey-patch library modules** - Never patch, override, or modify third-party library internals to "fix" behavior. If a library isn't doing what you need, you're either using it wrong (read the docs) or you need a different library. Monkey-patching hides the real problem and breaks unpredictably on library updates.
- **Remove `# AUDIT-OK` comments** - These comments mark code that has been reviewed and approved during scientific audits. They are critical for automated code review. Never remove them.
- **Write prompts as Python strings** - All prompts and instructions for language models/classifiers must be in Jinja template files, not inline Python strings scattered throughout the code.
- **Delete commented-out code** - Never delete it unless the user explicitly asks. Commented-out code (especially experiment configs) often serves as useful reference for past experiments or alternative approaches.

## Research Integrity

**NEVER compromise experimental validity for convenience.**

It is much better for code to crash with an error than to silently continue with a default value. Crashes are noticed immediately; invalid results from silent defaults can go undetected and corrupt your analysis.

### Default Values for Results — NEVER NEVER NEVER

**Defaults in config objects** (pydantic models, config classes) are fine — they're explicit, centralized, and documented.

**Default keyword arguments in function definitions** (like `def foo(x=0):`) are NOT okay. Keep defaults in the config, not scattered across function signatures.

**Intermediate results** (parsed values, API responses, measurements) must NEVER return a default value when the actual result couldn't be obtained. If you can't get the real value, throw an error.

Examples of what NOT to do:
- Parsing a score from an AI response fails → return 0 ❌
- API call fails → return empty string ❌
- Can't find expected field in response → return False ❌
- Use `.get(key, default)` to hide missing data ❌

Instead:
- Throw an error if required data is missing
- **Let the code crash** — this is GOOD. Crashes are noticed immediately; invalid results from silent defaults can go undetected and corrupt your analysis.
- Use `None` only when the data is genuinely optional and you'll handle the None case explicitly
- Log warnings about excluded/failed data points
