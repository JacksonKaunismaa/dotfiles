# Claude Code Guide

## Environment Setup

**Use `uv` for package management. Virtual environment is at `.venv`.**

Claude config (`~/.claude/`) is symlinked to `~/Work-Stuff/dotfiles/config/claude/`.

## Default Behaviors

- **Plan before implementing** — use `EnterPlanMode` for non-trivial tasks
- **Delegate to agents** for non-trivial work — use agent teams for parallelizable tasks, subagents for focused single-output tasks
- **Commit frequently** after every meaningful change
- **State confidence levels** ("~80% confident" / "speculative")
- **Run tool calls in parallel** when independent
- **Test on real data** — don't just write unit tests; run e2e on small amounts of real data (e.g., `limit=3-5`)

## Running Experiments

**Always use `Config.setup()` in entry points.** See the `experiment-infrastructure` skill for full spec.

```bash
python run_my_experiment.py --experiment feb26-refusal --variant gpt4-baseline --model gpt-4
```

For parallel ablations, use `&` and `wait`.

## Backwards Compatibility

**NEVER add backwards compatibility. No exceptions.**

This is a research codebase, not a production library.

---

## Rules (auto-loaded from `~/.claude/rules/`)

| File | Purpose |
|------|---------|
| `anti-patterns.md` | Claude-specific code anti-patterns — fake data, magic values, broad try/except, etc. |
| `research-integrity.md` | No default values for results, no global variables, config passing conventions |
| `safety-and-git.md` | Zero tolerance table, sandbox awareness, git safety, commit message format |
| `coding-conventions.md` | Python/TypeScript/shell basics, best practices, language selection, CLI tools |
| `workflow-defaults.md` | Task/agent organization, file creation policy, output strategy, mid-impl checkpoints |
| `context-management.md` | Large file handling, PDF delegation, bulk edit constraints, verbose output |
| `agents-and-delegation.md` | Subagent triggers, delegation decision tree, agent teams |
| `refusal-alternatives.md` | Friction prevention: ambiguity resolution, tool failure pivots, over-caution fixes |

## Docs (on-demand from `~/.claude/docs/`)

| File | Purpose |
|------|---------|
| `research-methodology.md` | Research workflow, experiment running, file organization |
| `async-and-performance.md` | Async patterns, batch APIs, caching, memory management |
| `ci-standards.md` | Confidence intervals, paired comparisons, power analysis, statistical reporting |
| `reproducibility-checklist.md` | NeurIPS Paper Checklist (16 questions) |
| `agent-teams-guide.md` | Team composition, communication, known limitations |
| `documentation-lookup.md` | Context7, GitHub CLI, verified repos, lookup decision tree |
| `experiment-memory-optimization.md` | API experiment memory patterns, batch vs async |

## Learnings

<!-- Timestamped entries about bugs, decisions, and current state.
     Keep under 20 entries. Prune stale ones (>2 weeks old).
     If something appears across multiple projects → promote to global rules. -->

