# Common Mistakes

Patterns that produce code I'd be unhappy with on review. Each is here because it's caused real problems before.

## Silencing errors

Errors are signals — make them louder, not quieter.

- Use narrow `try/except`, not `except Exception:`. If you must catch broadly, log and re-raise.
- Returning defaults (`0`, `""`, `False`) when the real answer couldn't be computed corrupts downstream analysis. Return `None`, or raise.
- `# type: ignore`, `# noqa`, `# pylint: disable` — fix the underlying issue. If a suppression really is right, leave a one-line comment explaining why.
- `.get(key, default)` to paper over missing data — use `.get(key)` and check, or `[key]` and let the `KeyError` surface.

## Gaming tests or types

- If a test fails, fix the code. Only modify the test if it's genuinely wrong.
- Hardcoding expected values to make assertions pass.
- Adding `Optional` or default arguments just to silence type errors from incorrect call sites — fix the call site.

## Fixing symptoms instead of root causes

Inline imports, parallel "hope-one-works" code paths, monkey-patching library internals, and generic try/except → workaround patterns all hide real problems. If something doesn't work, find out why before adding code that papers over it.

If you don't understand why code is broken, investigate before deleting or commenting it out.

## Scope creep

- Modifying what wasn't asked for — tidying comments, docstrings, or type annotations on adjacent code.
- Deleting commented-out code without being asked. It's often a record of past experiments or alternative configs.
- But do delete code you wrote that turned out to be unused — dead parameters, unread fields, set-but-never-read variables. Dead code makes names lie.

## Fake or default data in results

- Inventing example data that resembles real data — sample outputs, refusals, AI responses must come from real sources. Fabricated examples invalidate analysis.
- Truncating strings (`[:1000]`, `[:500]`) on data that gets scored, classified, or analyzed. Truncation hides information.
- Substituting defaults for missing data with `value or 0`, `value or ""`, etc. — same trap as broad except returns.

## Configuration outside configs

- Magic values inside function bodies (model names, prompt names, thresholds, paths, URLs) belong on a config object. If a value could vary between runs, it's configuration.
- Default values in function signatures that carry an experimental parameter (`def grade(text, threshold=5)`) — same buried config, one layer up from magic values. Config-object field defaults are fine (centralized, explicit); a defaulted signature lets a caller silently get the wrong value. Fix by reading it from the config inside (the house pattern), or by making the parameter required. The smell is the *default* — dropping it is what matters; a keyword-only `*,` arg with a default still buries the value.
- Prompts as inline Python strings instead of Jinja templates. Even short ones — and even fixed/verbatim system prompts, judge/grader prompts, or hardcoded eval probe sets ("it's a constant" / "it's just eval data" is not an exception).
- Substring/regex/keyword classifiers for semantic judgments (refusals, sentiment, topic). These are brittle — use LLM judges.
- Duplicating config fields across classes instead of using inheritance.

## Style

- Clarity over cleverness. Code that's hard to read is hard to maintain.
- Blocking-correctness or trivial TODOs left as comments instead of fixed.
- Duplicating logic — check if something exists before adding it.
- Removing `AUDIT-OK` markers (`# AUDIT-OK: ...` inline or `# <AUDIT-OK>` / `# </AUDIT-OK>` block tags) — they mark code reviewed during scientific audits.
