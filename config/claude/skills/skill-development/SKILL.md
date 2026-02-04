---
name: skill-development
description: "Use when creating or debugging Claude Code skills. Covers YAML frontmatter gotchas, skill discovery vs loading, and how to verify skills work."
---

# Skill Development

Guide for creating Claude Code skills that actually load properly.

## Skill Structure

```
~/.claude/skills/<skill-name>/
└── SKILL.md          # Required - the skill definition
└── other-files.py    # Optional - reference files the skill can mention
```

## YAML Frontmatter

Every SKILL.md must start with YAML frontmatter:

```yaml
---
name: my-skill
description: "What this skill does and when to use it."
---
```

### Critical: Quote Descriptions with Colons

**This will silently break:**
```yaml
description: Use when user needs to: create things
```

**This works:**
```yaml
description: "Use when user needs to: create things"
```

YAML interprets `needs to:` as a key, breaking the parse. Claude Code fails silently - the skill appears in `/skills` but with truncated tokens and won't load into context.

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase, hyphens, max 64 chars |
| `description` | Yes | When to trigger this skill. **Quote if it contains colons.** |
| `disable-model-invocation` | No | `true` to hide from Claude's auto-triggering |
| `user-invocable` | No | `false` to hide from `/` menu |

## Debugging Skills

### Check if skill is discovered
```
/skills
```
Lists all skills with description token counts.

### Check if skill is loaded into context
```
/context
```
Shows skills actually loaded. If a skill appears in `/skills` but not `/context`, the YAML is probably broken.

### Red flags
- Token count way lower than expected → YAML parsing failed
- Skill in `/skills` but not `/context` → invalid frontmatter
- Skill not in `/skills` at all → missing SKILL.md or wrong directory structure

## Common Mistakes

1. **Unquoted colons in description** - Most common. Always quote descriptions with special characters.

2. **No frontmatter delimiters** - Must have `---` at start and end of frontmatter.

3. **Wrong directory structure** - Must be `~/.claude/skills/<name>/SKILL.md`, not `~/.claude/skills/<name>.md`.

4. **Special characters in name** - Use only lowercase letters, numbers, and hyphens.

## Testing a New Skill

1. Create the skill directory and SKILL.md
2. Restart Claude Code
3. Run `/skills` - verify token count looks reasonable
4. Run `/context` - verify skill appears in loaded skills
5. Test triggering the skill by describing a relevant task
