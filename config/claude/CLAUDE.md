# Claude Code Guide

## Environment Setup

**Use `uv` for package management. Virtual environment is at `.venv`.**

## Running Experiments

**Always use suite files to run experiments.**

Never run experiment entry points directly (e.g., `python run_my_experiment.py`). All experiments go through suite files:

1. Define configs in a suite file (`experiments/*/suite_*.py`)
2. Run the suite: `python experiments/foo/suite_foo.py --dry-run` then without `--dry-run`

Even for a single condition, use a suite file. The experiment runner automatically saves configs, organizes results into structured directories, and tracks git hashes for reproducibility. Use the `experiment-infrastructure` skill for reference.

## Backwards Compatibility

**NEVER add backwards compatibility. No exceptions.**

This is a research codebase, not a production library. Backwards compatibility leads to bloated and confusing code.

## Documentation Lookup

**When uncertain about external library behavior, look up the documentation first.**

Don't guess or assume how external libraries work. Use web search and web fetch to find official documentation before implementing solutions that depend on library behavior.

## File Search and Globbing

**Glob patterns are case-sensitive. Try alternative cases when searching.**

If `**/Config.py` returns nothing, also try `**/config.py`.

## Best Practices

- **No inline Python commands**: Never run complex Python via `python -c "..."` in Bash. Instead, write the script to a file using the Write tool, then execute it. Temporary/scratch scripts go in `./scratch/` if it exists, otherwise `/tmp/`.
- **GitHub operations**: Always use `gh` CLI for PRs, issues, and GitHub API queries
- **CSV files**: Always use pandas (`pd.read_csv()`), never `csv.DictReader`
- **Prompts**: Always use Jinja templates, never inline Python strings. Even short prompts. All formatting should be done in Jinja, not Python.
- **Model inference**: Always use Inspect or Safety Tooling for model calls, never raw OpenAI/Anthropic clients. These frameworks handle logging, retries, and structured outputs consistently.

### Global Variables — NEVER

**Never use global variables.** Not for directories, loggers, prompt names, or "constants" that vary between runs. Global state destroys reproducibility. Pass everything through config objects.

Structure configs with inheritance:
- A top-level base config contains typical/global parameters (model name, max tokens, etc.)
- Each experiment subclasses the base config and adds additional parameters as needed

Use pydantic-settings for CLI argument parsing: `class Config(BaseSettings, cli_parse_args=True)`.

### Config Passing

Pass config objects when parameter count gets unwieldy. If a function needs more than ~5 parameters that all come from a config object, just pass the whole config instead of unpacking each field.

Never pass both a config object AND attributes extracted from that config. If you're passing the config, get values from it inside the function.

## Anti-Patterns

**CRITICAL: Write code a thoughtful senior engineer would write, not code that merely "completes the task."**

These are anti-patterns that Claude tends to fall into. They lead to crappy code. NEVER NEVER NEVER do these:

- **Hardcode fake data that looks real** - NEVER invent data that resembles real data. If you need example AI responses, sample outputs, or test data, it must come from actual sources (files, APIs, real outputs). Hardcoding plausible-looking fake data (e.g., "here's what a refusal looks like" with made-up text) completely invalidates any analysis. All data must be traceable to real sources.
- **Magic values in function bodies** - Configuration values (model names, prompt names, thresholds, file paths, URLs) hardcoded inside functions instead of coming from config objects. These are impossible to override without editing code and easy to miss when reviewing experiment parameters. If a value could reasonably vary between runs or experiments, it belongs in a config object.
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
- **Leave dead/stale code around** - Unused function parameters, config fields that nothing reads, variables that are set but never used. If code isn't being used, delete it. Dead code confuses readers and leaves the codebase in a state where names imply things that aren't true.
- **Use `or` to substitute defaults for missing data** - Patterns like `value or 0`, `value or ""`, `value or []` hide missing data behind plausible defaults. Also `param = param or default` inside functions — this is just a sneaky default argument.
- **Workarounds that paper over problems** - Don't add workarounds that hide the real problem.
- **TODO comments that should have been addressed** - If a TODO is blocking correctness or is trivial to fix, just fix it.
- **Overly clever code** - Write code that's easy to read and understand. Cleverness that obscures intent is a liability.

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
- **Let the code crash** — this is GOOD.
- Use `None` only when the data is genuinely optional and you'll handle the None case explicitly
- Log warnings about excluded/failed data points
