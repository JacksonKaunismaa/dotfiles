# Anti-Patterns

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
- **Remove AUDIT-OK markers** (`# AUDIT-OK: ...` inline comments or `# <AUDIT-OK>` / `# </AUDIT-OK>` block tags) - These indicate code reviewed and approved during scientific audits. Never remove them.
- **Write prompts as Python strings** - All prompts and instructions for language models/classifiers must be in Jinja template files, not inline Python strings scattered throughout the code.
- **Delete commented-out code** - Never delete it unless the user explicitly asks. Commented-out code (especially experiment configs) often serves as useful reference for past experiments or alternative approaches.
- **Leave dead/stale code around** - Unused function parameters, config fields that nothing reads, variables that are set but never used. If code isn't being used, delete it. Dead code confuses readers and leaves the codebase in a state where names imply things that aren't true.
- **Use `or` to substitute defaults for missing data** - Patterns like `value or 0`, `value or ""`, `value or []` hide missing data behind plausible defaults. Also `param = param or default` inside functions — this is just a sneaky default argument.
- **Workarounds that paper over problems** - Don't add workarounds that hide the real problem.
- **TODO comments that should have been addressed** - If a TODO is blocking correctness or is trivial to fix, just fix it.
- **Use keyword/regex classifiers for semantic judgments** - Never use substring checks (`if "I can't" in response`), regex patterns, or keyword lists to classify semantic properties like refusals, sentiment, or topic. These are brittle. Use LLM-based classifiers.
- **Overly clever code** - Write code that's easy to read and understand. Cleverness that obscures intent is a liability.
