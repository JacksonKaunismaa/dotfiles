---
name: scientific-audit
description: "Scientific audit of codebase for research integrity violations. Use when user asks for a 'scientific audit' to search for patterns that compromise experimental validity."
---

# Scientific Audit

**Trigger: When the user asks for a "scientific audit", search the codebase for violations of research integrity principles.**

Search for patterns that compromise experimental validity.

## IMPORTANT: Do NOT fix code without confirmation

Report findings first. Do NOT automatically fix issues — wait for the user to review each finding and confirm what action to take. Only make edits (fixes or `# AUDIT-OK` markers) after the user explicitly approves.

## IMPORTANT: Use subagents to read everything

1. Do some initial searches to understand the codebase structure and figure out how to split up the work
2. Launch subagents in parallel using the Task tool to read files and check for the patterns below. Every file should be read.
3. As a final step, grep for the patterns to make sure you didn't miss anything

## Patterns to search for

### Critical severity

- **Hardcoded fake data** — Any data that looks like it could be real but was invented/hardcoded instead of coming from actual sources. Examples: hardcoded example strings that "look like" real AI outputs, fabricated sample responses, placeholder text that resembles genuine data. If data appears realistic but isn't traced to a real source (file, API, database), flag it. This is the most severe violation — it completely invalidates any analysis built on top of it.
- **Global variables** — Module-level state that affects experiment behavior (directories, loggers, prompt names, thresholds). Must go through config objects. True constants like `PI = 3.14159` are fine.
- **Magic values in function bodies** — Configuration values (model names, prompt names, thresholds, file paths, URLs) hardcoded inside functions instead of coming from config objects. These are impossible to override without editing code and easy to miss when reviewing experiment parameters. If a value could reasonably vary between runs or experiments, it belongs in a config object.
- `except Exception:` followed by `return 0`, `return False`, or a default value
- `or 0`, `or 0.0`, `or ""` patterns that substitute defaults for missing data
- `param = param or default` inside functions — this is just a default argument written sneakily to look like there isn't one
- Default keyword arguments in function definitions (defaults belong in config objects, not scattered in function signatures)
- `# type: ignore`, `# noqa` without clear justification

### Moderate severity

- Broad try/except blocks that swallow errors
- Missing logging for excluded/filtered data points
- Prompts or instructions for language models/classifiers written as inline Python strings instead of Jinja templates — every prompt, even tiny ones, must be in a `.jinja` template file
- Backwards compatibility code: legacy code paths, deprecated parameters, compatibility shims, or any code that exists solely to support old interfaces
- Dead/stale code: unused function parameters, config fields that nothing reads, variables set but never used — these leave the code in a confusing state where names imply things that aren't true. **This requires active tracing** — see guidance below.
- Add `Optional` or default values to parameters just to avoid type errors from improper calls
- Skip validation or error handling because "it works for this case"
- Add parallel output paths hoping one works — if something isn't working, don't add redundant paths hoping one will work. Understand WHY the existing path isn't working and fix that.
- Duplicated config fields across classes
- Duplicated code in general — check if something is already implemented before adding it

### Minor severity

- Inline imports inside functions

## Checking for dead/stale code

This check requires active tracing, not just pattern matching.

**Config files**: Read each config class and list all fields. Then trace through the code to verify each field is actually read and used somewhere. If a field exists but nothing uses it, flag it. Consider launching a sub-agent specifically for this.

**Function parameters**: For each function, check that every parameter is actually used in the function body. Unused parameters suggest the function signature is out of sync with its implementation.

**Functions and variables**: Look for functions that are defined but never called, variables that are assigned but never read. These indicate stale code that should be removed.

The goal is to ensure the code's structure (what's defined) matches its behavior (what's actually used).

### General code smells (use judgment)

The patterns above are not exhaustive. Also flag code that seems hacky or sloppy, including but not limited to:
- Monkey-patching or overwriting library internals
- Workarounds that paper over a problem instead of fixing it
- TODO comments that should have been addressed
- Overly clever code that's hard to follow
- Any code where you think "a senior engineer would not write this"

## Previously audited code

Lines marked with `# AUDIT-OK` have been reviewed and approved by the user. **Skip these silently** — do not flag them, list them, or mention them in your summary. The user already knows what they approved. (Exception: if the user requests a **re-audit**, ignore these markers and re-evaluate everything.)

**Every line** of the flagged code block must have `# AUDIT-OK` on the same line. The first line includes the full marker with pattern and reason: `# AUDIT-OK: <pattern> - <reason>`. Subsequent lines just need `# AUDIT-OK`. If the reason is long, it can continue on the next line's marker.

Example markers:
```python
timeout = config.get("timeout") or 30  # AUDIT-OK: default-value - network timeout, not experimental parameter
```

```python
except Exception:  # AUDIT-OK: broad-except - cleanup handler, logs error before re-raising
    logger.error(f"Cleanup failed: {e}")  # AUDIT-OK
    raise  # AUDIT-OK
```

```python
try:  # AUDIT-OK: broad-except - this wraps an external API call where any exception
    result = external_api.fetch(query)  # AUDIT-OK: means the service is unavailable, and we want to
    return result  # AUDIT-OK: surface that clearly rather than crash mid-pipeline
except Exception as e:  # AUDIT-OK
    raise ServiceUnavailableError(f"External API failed: {e}")  # AUDIT-OK
```

**Important:** The marker must be on the same line as the code — every single line. If code is edited and any marker is removed, that code should be re-flagged in future audits.

## When to add AUDIT-OK markers

When reporting a finding, if the user reviews it and decides the code is acceptable as-is, add an `AUDIT-OK` marker to every line of the flagged code:
- First line: `# AUDIT-OK: <pattern> - <reason>` (e.g., `default-value`, `broad-except`, `type-ignore`)
- Remaining lines: `# AUDIT-OK`

This allows future audits to skip known exceptions while still catching new violations or edits to previously-approved code.

## Output format

Report findings ranked by severity. For each finding, provide ENOUGH CONTEXT for someone unfamiliar with the code to understand the problem. **Assume the user does not have the code open** — your report must be fully understandable on its own.

- **File path and line number**
- **Pipeline context** — A full paragraph explaining: What part of the system is this? (e.g., "data ingestion", "model training", "result export", "API endpoint") What does this module/file do in the broader architecture? How does data flow into and out of this component? What depends on its output? Be thorough — this context is essential both for the user to understand the finding and for you to verify whether the pattern is actually problematic or legitimate in this context.
- **Function role** — What is this specific function responsible for? What calls it, and what does it produce?
- **Code snippet** — Include generous context. Not just the flagged line, but the entire function or at minimum 10-20 lines surrounding the issue. The user needs to see enough code to understand the problem without opening the file.
- **Why it's problematic** (explain the specific failure mode — what bad thing could happen because of this pattern?)
- **Suggested fix**

Do not assume the user can fill in context themselves. Your report should be self-contained.
