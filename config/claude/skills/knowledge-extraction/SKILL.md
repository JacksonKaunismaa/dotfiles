---
name: knowledge-extraction
description: Use when you've completed a deep technical investigation (debugging, performance analysis, library internals, infrastructure) and findings should be preserved for future sessions. Also use when the user asks for a "braindump", "writeup", "document what we learned", or "extract what we know".
---

# Knowledge Extraction

Extract the useful knowledge from an investigation into `./docs/` so future Claudes (with zero context) can reference it without repeating the work.

## When to Use

- After resolving a non-obvious technical problem (performance, compatibility, infrastructure)
- When the user asks for a "braindump" or "writeup" of what was learned
- When you discovered something that took multiple failed attempts to figure out
- When the fix required understanding library internals, not just changing a config value

**Don't use for**: Simple bug fixes, one-line config changes with obvious rationale, project-specific decisions that belong in CLAUDE.md.

## The Test: Would a Future Claude Get It?

Before writing, imagine a Claude that:
- Has never seen this codebase
- Doesn't know what you tried or why
- Will encounter the same problem and reach for the same wrong solutions you did
- Needs to understand *when the fix is wrong* (not just when it's right)

If your doc wouldn't stop that Claude from spending 2 hours on the same dead ends, rewrite it.

## Structure

Every doc needs these two things. Everything else is optional.

### Always include

**Mental model first (not the fix).** Start with HOW the system works, not what to change. A future Claude needs to reason about novel situations, not just copy your solution.

The shape of the mental model depends on the investigation — e.g., component lifecycles and where they collide, a causal chain from symptom to root cause, an elimination process across candidates, or the decision point that controls divergent behavior. Whatever it is, show the actual source code, config, or system state where the critical behavior is determined. File paths, line numbers, exact conditionals. This lets a future Claude verify the analysis still holds on newer versions.

**Transparent reasoning:** mark which parts of the mental model you verified vs. inferred. "Confirmed" is a high bar — it means you read the source code, correlated with logs, or ran a controlled experiment (e.g., an ablation that isolates the variable). "The fix worked" is not confirmation of your theory of *why* it worked. A future Claude needs to know which links in the chain are solid and which are plausible but untested.

**Things that didn't work (and why).** This is the highest-value section. Without it, a future Claude will try these same approaches, burn context and wall-clock time, and arrive where you started. For each failed approach: what you tried, why it seemed like it should work, and why it actually didn't. Transparent reasoning matters here too — sometimes you know the exact mechanism, sometimes you just know it didn't help and have a theory. Say which.

### Include when relevant

Use your judgment on which of these to include and in what order. Not every investigation needs all of them.

- **Root causes** — when there are multiple contributing causes, list each with its mechanism, why it exists (don't frame tradeoffs as bugs), the fix, and what you give up
- **When the fix is wrong** — when the fix could be blindly applied in contexts where it would break things
- **Measured results** — when you have actual timings/measurements (not estimates) that future Claudes need to calibrate expectations
- **Quick reference** — when there's a copy-pasteable config block or command sequence that a Claude who already understands the doc can grab and go

## Writing Style

- **Show primary evidence** (source code, config files, log output, system state), not just descriptions. Future Claudes can verify against newer versions.
- **Use "we tried X" not "you should avoid X"** — the narrative of failed attempts is more memorable and informative than abstract warnings.
- **Name the specific versions** where behavior was observed. Library internals change between versions.
- **Include the contrast** that made the problem visible (e.g., "Axolotl loads in 30s, our code takes 15 min — what's different?").
- **Don't editorialize about the library being bad** — explain the design tradeoff the authors made.
- **Resist the completeness instinct.** A concise doc that covers the main path is more useful than an exhaustive doc that covers every edge case. If a detail only matters in a rare scenario, leave it out. Future Claudes can investigate edge cases themselves — what they can't do is redo your core investigation.

## Final Check

Re-read what you wrote and ask: could a Claude with zero context read this and avoid all the dead ends? Are confidence levels marked — which findings are confirmed vs. best guesses? If not, fix it before saving to `./docs/`.
