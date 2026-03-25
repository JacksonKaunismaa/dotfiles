# Agents & Delegation Rules

## Subagent Strategy

**Default: delegate, not do.** Prevent context pollution by letting agents summarize.

Available agents are listed in Agent tool description. Use **PROACTIVELY**:

| Agent | Trigger |
|-------|---------|
| `superpowers:code-reviewer` | After ANY implementation — don't wait to be asked |
| `plan-critic` | Before implementing plans with arch decisions, migrations, auth, concurrency |
| `performance-optimizer` | Slow code, sequential API calls, missing caching |

**Principles**: Parallelize agents • Be specific • Include size limits in prompts • ASK if unclear

### Concurrent Edit Constraint

**One editor per file.** Never spawn multiple agents to edit the same file.

## Claude Code MCP (Nested Orchestration)

Use `mcp__claude-code-mcp__claude_code` when you want to spawn an orchestrator that can itself spawn subagents. The nested instance handles multi-agent complexity internally and returns a clean, deduplicated summary — saving top-level context.

**When to use:**
- Recursive workflows (codebase audits, multi-file analysis) where many parallel workers are needed
- Complex tasks where you want the nested orchestrator to manage its own subagent pool
- Situations where raw subagent output would pollute top-level context

**When NOT to use:**
- Simple single-output tasks → use Agent tool directly
- Tasks that don't benefit from nested parallelism

## Task Delegation Strategy

**Principle:** Skills = workflows you execute, Agents = delegation to external tools.

**Large context (PDFs, >100KB codebases, multi-file comparison):** Spawn a Claude subagent. Both `claude-sonnet-4-6[1m]` and `claude-opus-4-6[1m]` have 1M token context windows.

```
Need delegation?
├─ Large context (PDF, codebase)? → Claude subagent (1M context)
├─ Plan needs critique? → plan-critic
├─ Code review needed? → superpowers:code-reviewer
├─ Nested multi-agent workflow? → Claude Code MCP
└─ Multi-step workflow? → Use skills
```

## Agent Teams (Escalation)

For multi-agent communication, see `~/.claude/docs/agent-teams-guide.md`.

```
Task complexity?
├─ Single focused output? → Subagent (Agent tool)
├─ 2-3 independent outputs? → Parallel subagents
├─ Parallel + needs inter-agent communication? → Agent Team
└─ Unclear? → Start with subagents, escalate if needed
```

## Known Issue: `classifyHandoffIfNeeded` False Failures (Temporary)

**Bug:** Claude Code agents crash on completion with `classifyHandoffIfNeeded is not defined`. This is a build bug — the function is referenced but never defined. Tracked in 16+ issues: https://github.com/anthropics/claude-code/issues?q=classifyHandoffIfNeeded

**What actually happens:** Agent work completes successfully (files written, commits made, all tool calls finish). The crash occurs AFTER completion during the handoff step. Agent tool falsely reports `status: failed`.

**Required behavior when you see this error:**

1. **Do NOT treat as a real failure** — the work is done
2. **Verify the output exists** — check files, git log, or expected artifacts on disk
3. **If output exists → proceed as if agent succeeded** — use the results normally
4. **Do NOT retry the agent** — retrying wastes context and produces duplicate work
5. **For background agents** — read the output file; the data is there despite the failure notification

**Remove this section** when the upstream fix lands (check: `claude --version` changelog).
