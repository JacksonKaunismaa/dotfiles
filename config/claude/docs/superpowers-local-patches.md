# Superpowers local patches

Superpowers (`obra/superpowers`, distributed via `anthropics/claude-plugins-official`) is actively updated. The marketplace runs a periodic "Bump SHA pins" job, so the cached version under `~/.claude/plugins/cache/claude-plugins-official/superpowers/<version>/` gets overwritten on plugin updates.

This document records local patches applied to the cache so they can be reapplied after upgrades.

## Why these patches exist

Multiple parts of the upstream plugin use forceful framing — `<EXTREMELY_IMPORTANT>` wrappers, "YOU ABSOLUTELY MUST", "any creative work", "evidence before assertions always", and similar. Some of this leaks into context at every session start (the `using-superpowers` skill is loaded by a SessionStart hook), and the rest leaks via skill descriptions in the `available-skills` listing. The combined effect shapes assistant tone in a way I (the user) want to avoid.

Mere overrides ("ignore the forceful tone") don't work — once forceful text is in context, it's primed the model regardless of any later instruction to disregard it. The fix has to be at the source: change what gets loaded.

## Patch list

Canonical patched copies live in this directory. Filenames mirror the path inside the plugin (`hooks/session-start` → `superpowers-hooks-session-start`, `skills/<name>/SKILL.md` → `superpowers-<name>-SKILL.md`).

### 1. `hooks/session-start`

**Goal**: drop the `<EXTREMELY_IMPORTANT>` wrapper and "You have superpowers." line that the SessionStart hook adds around the `using-superpowers` skill content.

**Changed**: line 35 (the `session_context=...` assignment). The wrapper is replaced with a neutral one-line intro that just notes the plugin is loaded and points at the Skill tool.

### 2. `skills/using-superpowers/SKILL.md`

**Goal**: keep the useful content (skill list intro, priority, platform adaptation, skill types, when-to-invoke flow) and remove the forceful framing in the body.

**Removed**:
- The `<EXTREMELY-IMPORTANT>` block: "If you think there is even a 1% chance...", "YOU ABSOLUTELY MUST", "This is not negotiable. This is not optional. You cannot rationalize your way out of this."
- The "Red Flags" table that lists assistant thoughts (e.g. "This is just a simple question") and labels them as rationalizations.
- Re-framings of "The Rule" that emphasized "BEFORE any response or action" and "1% chance".

**Replaced with**: a "When to invoke" section that says check the skill list when a request might match, invoke if relevant, and proceed normally if nothing fits.

### 3–6. Skill description softenings (frontmatter `description:` only)

These skills' frontmatter descriptions appear in the `available-skills` listing injected at session start. The bodies are untouched; only the description string is patched. If upstream improves the body, merge those changes into our local canonical copy and keep the patched description.

- `skills/brainstorming/SKILL.md` — drop `"You MUST use this before any creative work"` framing.
- `skills/verification-before-completion/SKILL.md` — drop `"evidence before assertions always"` framing.
- `skills/receiving-code-review/SKILL.md` — drop `"not performative agreement or blind implementation"` framing.
- `skills/test-driven-development/SKILL.md` — drop the "any feature or bugfix" universal claim.

## Reapplying after a plugin upgrade

```bash
PLUGIN_CACHE="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers"
LATEST="$(ls -1 "$PLUGIN_CACHE" | sort -V | tail -1)"
DOCS="$HOME/.claude/docs"

cp "$DOCS/superpowers-hooks-session-start"                          "$PLUGIN_CACHE/$LATEST/hooks/session-start"
cp "$DOCS/superpowers-using-superpowers-SKILL.md"                   "$PLUGIN_CACHE/$LATEST/skills/using-superpowers/SKILL.md"
cp "$DOCS/superpowers-brainstorming-SKILL.md"                       "$PLUGIN_CACHE/$LATEST/skills/brainstorming/SKILL.md"
cp "$DOCS/superpowers-verification-before-completion-SKILL.md"      "$PLUGIN_CACHE/$LATEST/skills/verification-before-completion/SKILL.md"
cp "$DOCS/superpowers-receiving-code-review-SKILL.md"               "$PLUGIN_CACHE/$LATEST/skills/receiving-code-review/SKILL.md"
cp "$DOCS/superpowers-test-driven-development-SKILL.md"             "$PLUGIN_CACHE/$LATEST/skills/test-driven-development/SKILL.md"
```

## Detection

To find out if a plugin upgrade has wiped any patch:

```bash
PLUGIN_CACHE="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers"
LATEST="$(ls -1 "$PLUGIN_CACHE" | sort -V | tail -1)"
DOCS="$HOME/.claude/docs"

diff -q "$DOCS/superpowers-hooks-session-start"                     "$PLUGIN_CACHE/$LATEST/hooks/session-start"
diff -q "$DOCS/superpowers-using-superpowers-SKILL.md"              "$PLUGIN_CACHE/$LATEST/skills/using-superpowers/SKILL.md"
diff -q "$DOCS/superpowers-brainstorming-SKILL.md"                  "$PLUGIN_CACHE/$LATEST/skills/brainstorming/SKILL.md"
diff -q "$DOCS/superpowers-verification-before-completion-SKILL.md" "$PLUGIN_CACHE/$LATEST/skills/verification-before-completion/SKILL.md"
diff -q "$DOCS/superpowers-receiving-code-review-SKILL.md"          "$PLUGIN_CACHE/$LATEST/skills/receiving-code-review/SKILL.md"
diff -q "$DOCS/superpowers-test-driven-development-SKILL.md"        "$PLUGIN_CACHE/$LATEST/skills/test-driven-development/SKILL.md"
```

Consider wiring this into `pre_session_start.sh` so a mismatch surfaces at session start.

## When upstream changes

If upstream restructures a skill or adds new substantive content, the local canonical copy needs updating. For each affected file: compare the upstream version against the patched local copy, merge in any new substantive content, keep the same tone changes, then update the local canonical file. The frontmatter-only patches (3–6) should be cheap to maintain — body changes can be copied wholesale; only re-apply the description softening.
