---
name: knowledge-extraction
description: Use when you've completed a deep technical investigation (debugging, performance analysis, library internals, infrastructure) and need to extract findings into a reusable knowledge doc in ./docs/. Also use when the user asks for a "braindump", "writeup", "document what we learned", or "extract what we know".
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

### 1. Mental Model First (not the fix)

Start with HOW the system works, not what to change. A future Claude needs to reason about novel situations, not just copy your solution.

```markdown
## How X Works (Two Paths)

### Fast path: [what happens]
[pseudocode or simplified real code showing the mechanism]

### Slow path: [what happens]
[pseudocode showing the contrasting mechanism]

### What controls which path runs
[the actual gate — show the real code from the library if possible]
```

Show the actual source code from the library where the decision is made. File paths, line numbers, exact conditionals. This lets a future Claude verify the analysis still holds on newer versions.

### 2. What Forces the Bad Path (exhaustive)

List every way the system can end up on the wrong path. For each one:
- **What happens**: The exact mechanism (show the code)
- **Why it exists**: The legitimate reason — don't frame it as a bug if it's a tradeoff
- **Fix**: The specific change
- **Tradeoff**: What you give up

```markdown
### 1. [Cause name]

[Code snippet from library showing the gate]

**Why it exists**: [legitimate reason — memory safety, compatibility, etc.]
**Fix**: [specific change]
**Tradeoff**: [what you give up — more RAM, less compatibility, etc.]
```

### 3. Things That Didn't Work (and why)

This is the highest-value section. Without it, a future Claude will try these same approaches, burn context and wall-clock time, and arrive where you started.

For each failed approach:
- What you tried (be specific)
- Why it seemed like it should work
- Why it actually didn't (the non-obvious reason)

```markdown
## Things We Tried That Didn't Work

### [Approach name]
[What we did and why it seemed right]
[Why it didn't work — the specific mechanism that defeated it]
```

### 4. When the Fix Is Wrong

Prevent blind application. List scenarios where the "slow" path is actually correct:

```markdown
## When the Slow Path Is Actually Correct
- [Scenario]: [why the fix would break things here]
```

### 5. Measured Results

Include actual timings/measurements from your investigation, not theoretical estimates. Future Claudes need to calibrate expectations:

```markdown
## Measured Results

| Configuration | Result |
|---|---|
| Before (describe setup) | [actual measurement] |
| After (describe change) | [actual measurement] |
```

### 6. Quick Reference

End with a copy-pasteable config block. A future Claude who already understands the doc should be able to grab this and go:

```markdown
## Quick Reference

[Exact config/code snippets ready to use]
```

## Writing Style

- **Show library source code**, not just descriptions. Future Claudes can verify against newer versions.
- **Use "we tried X" not "you should avoid X"** — the narrative of failed attempts is more memorable and informative than abstract warnings.
- **Name the specific versions** where behavior was observed. Library internals change between versions.
- **Include the contrast** that made the problem visible (e.g., "Axolotl loads in 30s, our code takes 15 min — what's different?").
- **Don't editorialize about the library being bad** — explain the design tradeoff the authors made.
- **Resist the completeness instinct.** A concise doc that covers the main path is more useful than an exhaustive doc that covers every edge case. If a detail only matters in a rare scenario, leave it out. Future Claudes can investigate edge cases themselves — what they can't do is redo your core investigation.

## Checklist

- [ ] Mental model section explains the mechanism, not just the fix
- [ ] Actual library source code shown (file paths, line numbers, conditionals)
- [ ] Every failed approach documented with why it didn't work
- [ ] "When NOT to apply the fix" section included
- [ ] Measured results from real runs (not estimates)
- [ ] Quick reference block at the end
- [ ] A Claude with zero context could read this and avoid all the dead ends
- [ ] File saved to `./docs/` with a descriptive name
