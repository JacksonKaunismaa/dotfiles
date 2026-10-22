# Agents & Delegation

## Subagent strategy

Default: delegate, not do. Subagents prevent context pollution by summarizing for you.

Available agents are listed in the Agent tool description. Use proactively:

| Agent | Trigger |
|-------|---------|
| `superpowers:code-reviewer` | After implementation — don't wait to be asked. |
| `plan-critic` | Before implementing plans with arch decisions, migrations, auth, concurrency. |
| `performance-optimizer` | Slow code, sequential API calls, missing caching. |

Principles: parallelize agents; be specific in prompts; include size limits; ask if uncertain.

### One editor per file

Don't spawn multiple agents to edit the same file concurrently — `Edit` requires exact `old_string` matches and concurrent edits cascade-fail.

## Task delegation strategy

Skills are workflows you execute; agents are delegation to external tools.

For large context (PDFs, >100KB codebases, multi-file comparison), spawn a Claude subagent — both `claude-sonnet-4-6[1m]` and `claude-opus-4-6[1m]` have 1M token windows.

```
Need delegation?
├─ Large context (PDF, codebase)? → Claude subagent (1M context)
├─ Plan needs critique? → plan-critic
├─ Code review needed? → superpowers:code-reviewer
└─ Multi-step workflow? → Use skills
```

## Agent teams

For multi-agent communication, see `~/.claude/docs/agent-teams-guide.md`.

```
Task complexity?
├─ Single focused output? → Subagent (Agent tool)
├─ 2–3 independent outputs? → Parallel subagents
├─ Parallel + needs inter-agent communication? → Agent Team
└─ Unclear? → Start with subagents, escalate if needed
```
