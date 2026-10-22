---
name: scientific-audit
description: "Use when user asks for a 'scientific audit' — searches codebase for patterns that compromise experimental validity."
---

# Scientific Audit

Search the codebase for patterns that compromise experimental validity. Report findings first — do NOT fix code without user confirmation (except auto-fix items below).

## Dispatching subagents

**Do NOT copy the pattern list into the subagent prompt.** Tell each subagent to read this skill file. The path is in the skill metadata ("Base directory for this skill" + `/SKILL.md`).

**Max 8 files per subagent**, grouped by pipeline/module. Spawn as many agents as needed — they run in parallel.

### Pipeline

1. Map the codebase structure (file list, line counts, directory layout)
2. Split files into batches of ≤8
3. **Scan** — launch scanning subagents in parallel
4. Grep for critical patterns to catch anything subagents missed
5. **Verify** — send all findings to verification agents (see below)
6. **Curate** — deduplicate, rank, pick top ~10–20. Raw agent output must NEVER be shown to the user.

## Severity scoring

Every finding gets a score from 1–10:

- **10** — Actively corrupting results right now (e.g., hardcoded fake data fed to a classifier)
- **5** — Code smell, no direct validity risk (e.g., duplicated config fields)
- **1** — Nitpick

The orchestrator picks the **top 20 findings by severity**. Low-severity items can appear if the codebase is otherwise clean.

## Always-report (short-circuit)

Some patterns are low-severity but are almost always worth fixing by default, so they skip the "is this worth reporting?" judgment AND the verification pass entirely. Currently this includes:

1. **Inline imports inside functions** — *except* imports inside a function that runs in a Modal container (an `@app.function`/`@app.cls`-decorated function, or a helper only ever called container-side), and lazy-import accessors whose entire body exists to defer such a dependency. Rationale: the heavy ML stack (torch, transformers, peft, trl, tinker `weights`) lives in the Modal *image*, not the local environment, so importing it at module top would break local import and offline tests. This is the ONLY exception, and it is mechanical — "does this function run container-side?", not "does this import have a good reason?". Every other inline import is reported.
2. **Inline prompts** (including fixed/verbatim system prompts, judge/grader prompts, and hardcoded eval probe sets).
3. **Global variables** — module-level mutable state, or module-level "constants" that could vary between runs and affect experiment behavior (directories, model names, prompt names, thresholds, paths, URLs — these belong on a config object). *Except* genuine never-varying constants (`PI = 3.14159`, frozen literals), module-level loggers (`logging.getLogger(__name__)`), and config-class / pydantic-model *definitions* (config defaults live there by design). The test: would this value change between experimental runs?

Encounter one → report every occurrence as a finding, regardless of severity; the only exemption is an `AUDIT-OK` marker on that code. Always report all
 of these regardless of the top-20 curation cut, and include them in a separate section at the end titled "Short-Circuited Items".

Grep so none slip a prose read: `rg '^\s+(from |import )'` for inline imports; for prompts, check module-level and inline string literals passed to a model or judge; `rg -n '^[A-Za-z_]\w*\s*[:=]'` for module-level assignments (then drop true constants, loggers, and config-class / pydantic definitions before reporting).

## Auto-fix items

These are mechanical, unambiguous fixes. **Fix them silently without reporting** — just list what was fixed at the end of the report (e.g., "Also auto-fixed: removed 2 unused parameters").

- Dead code confirmed unused by verification agents → delete (unused parameters, uncalled functions, unread config fields)

## Scanning subagents

Detect patterns, do basic confirmation (read the code, confirm the pattern exists, quote it), assign a preliminary severity score. Don't over-invest in deep verification — that's the verification agents' job.

Apply the full pattern list to every file; focus areas in your task are additional to it. Three of those patterns take a short-circuit — see **Always-report (short-circuit)** above.

## Verification agents (second pass)

Collect all findings and send to verification agents for deep validation. Each agent receives ~10 findings and must, for each one:

1. **Trace the data flow** — where does the input come from? Where does the output go?
2. **Prove it matters** — articulate a concrete failure scenario grounded in THIS codebase. "This is a bad pattern" is not enough.
3. **Check for mitigating context** — does something else in the code make this safe?
4. **Try to disprove the finding** — actively look for reasons it's NOT a problem. If you succeed, drop it.
5. **Assign a final severity score** — may differ from the preliminary score.

Drop findings that don't hold up. No "might be an issue" hedging.

## Orchestrator curation

After verification agents complete:

1. **Deduplicate** — merge findings that share a root cause.
2. **Rank by severity** — highest first.
3. **Pick top ~10–20** — absolute max 20. When in doubt, cut. (Judgment findings only — **Short-Circuited Items are never cut**; they ship complete in their own section.)

If zero findings survive, say so. Do NOT lower the bar to produce output.

## Scope

**Source code only.** Skip `scratch/`, `tmp/`, `temp/`, and shell scripts for running experiments. Test files ARE in scope.

## Patterns to search for

- **Hardcoded fake data** — data that looks real but was invented. If it's not traced to a real source (file, API, database), flag it.
- **Global variables** — module-level state affecting experiment behavior. True constants (`PI = 3.14159`) are fine.
- **Magic values in function bodies** — config values (model names, thresholds, paths, URLs) hardcoded instead of coming from config objects.
- `except Exception:` followed by `return 0`, `return False`, or any default value
- `or 0`, `or ""`, `param = param or default` — substituting defaults for missing data
- Default keyword arguments in function definitions (defaults belong in config objects)
- **Keyword/regex classifiers for semantic judgments** — substring checks, regex, or keyword lists for semantic classification (refusals, sentiment, safety). Use LLM-based classifiers instead.
- `# type: ignore`, `# noqa` without clear justification
- Broad try/except blocks that swallow errors
- Missing logging for excluded/filtered data points
- Prompts written as inline Python strings instead of Jinja templates — even fixed/verbatim system prompts, LLM-judge/grader prompts, and hardcoded eval prompt or probe sets
- Backwards compatibility code, legacy paths, deprecated parameters
- Dead/stale code: unused parameters, unread config fields, uncalled functions
- Inline imports inside functions (imports belong at module top)
- Duplicated config fields across classes, duplicated code in general
- `Optional` or default values added just to avoid type errors
- Anything else a senior engineer would not write — also check the anti-patterns in `rules/anti-patterns.md`

## Known exceptions — skip silently

- `load_dotenv()` calls
- Hardcoded strings in Modal decorator arguments (`gpu="A100"`, `image=modal.Image...`, etc.)

## AUDIT-OK markers

Code marked with AUDIT-OK has been reviewed and approved. **Skip silently.** (Exception: **re-audit** requests ignore markers.)

```python
x = config.get("timeout") or 30  # AUDIT-OK: default-value - network timeout, not experimental parameter

# <AUDIT-OK: broad-except - cleanup handler, logs error before re-raising>
except Exception:
    logger.error(f"Cleanup failed: {e}")
    raise
# </AUDIT-OK>
```

When the user approves a finding as acceptable, add the appropriate marker. If markers are later removed during edits, re-flag in future audits.

## Output format

Number findings sequentially (1, 2, 3...), sorted by severity. For each finding:

- **Finding number and severity** (e.g., "**1. [9/10]**")
- **File path and line number**
- **Context** — what part of the system is this, what does this module do, how does data flow through it
- **Code snippet** — generous context, not just the flagged line
- **Why it's problematic** — the specific failure mode
- **Suggested fix**

Assume the user does not have the code open. The report must be self-contained.

## Working through findings

The user will review each finding and request fixes, investigations, or something else. In a single pass, apply all unambiguous fixes AND run all requested investigations. Present a summary of what was fixed and what was investigated. **Stop and wait** before acting further on investigated findings.

## Post-audit report

**Trigger: user asks for "post-audit report", "wrap-up", or "summary".**

For each finding in original order:

```
#: [number] — [severity/10]
Finding: [one-line description]
Context: [one sentence — what part of the system]
What you said: "[direct quote]"
What I did: [action taken]
Ambiguity?: 🟢 None | 🟡 [minor ambiguity] | 🔴 [contradictory instructions]
Status: ✅ Done | ⏭️ Skipped | ❌ Reverted | 🔍 Investigating | 🔶 Partial
```

Rules: every finding must appear, quote the user directly, flag ambiguity honestly, deferred items must stand out.
