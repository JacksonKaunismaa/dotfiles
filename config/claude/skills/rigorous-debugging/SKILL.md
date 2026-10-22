---
name: rigorous-debugging
description: "Rigorous evidence-based debugging discipline. Use when user says 'rigorous' or when a bug seems tricky and requires careful analysis of all evidence before proposing fixes."
---

# Rigorous Debugging

**Always load `superpowers:systematic-debugging` alongside this skill.** This skill adds reasoning constraints to systematic's 4-phase process. It is not a standalone procedure.

## Before Phase 1: Catalog ALL user-reported evidence

Before you start investigating code, logs, or anything else — write out every piece of evidence from what the user already told you:
- When did it start failing?
- What were the symptoms?
- What was working before?
- Any timing info (e.g., "worked for an hour then stopped")
- What changed recently?

This is your checklist. Every hypothesis and fix must be tested against it.

## During Phase 3: Your hypothesis must explain ALL evidence

Every single piece of evidence must be consistent with your theory. If ANYTHING doesn't fit, your theory is probably wrong.

**Example of BAD reasoning:**
- User: "It worked for an hour, then stopped"
- You find a bug that would fail immediately on startup
- This DOESN'T MATCH - that bug would fail instantly, not after an hour

**Example of GOOD reasoning:**
- User: "It stopped typing after a few minutes, API still working"
- Evidence: logs show data coming in, but not being output
- Evidence: last output was item X, items after X are stuck
- Evidence: item X had a timeout race condition
- Theory: race condition caused item X to never be marked complete, blocking queue
- This explains ALL evidence: why it worked initially, why it stopped, why API looks fine

## During Phase 4: Map your fix to each piece of evidence

Before implementing, explicitly verify your fix addresses every piece of evidence:

"This fix addresses:
- Evidence A: because...
- Evidence B: because...
- Evidence C: because..."

If you can't explain how your fix addresses a piece of evidence, STOP and double-check with the user.
