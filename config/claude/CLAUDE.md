# Global CLAUDE.md

Global guidance for Claude Code across all repositories.

## Environment Setup

**Use `uv` for package management. Virtual environment is at `.venv`.**

Claude config (`~/.claude/`) is symlinked to `~/Work-Stuff/dotfiles/config/claude/`.

## Default Behaviors

- **Interview before planning** — use `/spec-interview-research` for experiments, `/spec-interview` for product features
- **Plan before implementing** — use `EnterPlanMode` for non-trivial tasks; don't write code until plan approved
- **Use existing code** for experiments — correct hyperparams, full data, validated metrics; ad-hoc only for dry runs
- **Delegate to agents** for non-trivial work — use agent teams for parallelizable tasks, subagents for focused single-output tasks
- **Commit frequently** after every meaningful change
- **Update docs when changing code** — keep CLAUDE.md, README.md, project docs in sync
- **Flag outdated docs** — proactively ask about updates when you notice inconsistencies
- **Run tool calls in parallel** when independent
- **One editor per file** — never multiple agents editing same file concurrently
- **State confidence levels** ("~80% confident" / "speculative")
- **Use anthroplot for publication-quality figures** (see `docs/anthroplot.md`)
- **Test on real data** — don't just write unit tests; run e2e on small amounts of real data (e.g., `limit=3-5`)

## Communication Style

- **State confidence**: "~80% confident" / "This is speculative"
- **Show, don't tell**: Display results and errors, not explanations
- **Be concise**: Act first, ask only when genuinely blocked
- **Challenge constructively**: Engage as experienced peer, use Socratic questioning
- **Admit limitations**: Never fabricate

### Compacting Conversations
- Preserve user instructions faithfully
- Note tricky conventions
- Don't make up details
- ASK if unclear

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

## Claude Code Directory Convention

| Artifact     | Global (~/.claude/)          | Per-project (<repo>/.claude/) |
|-------------|-------------------------------|-------------------------------|
| Instructions | CLAUDE.md                    | CLAUDE.md                     |
| Rules        | rules/*.md (auto-loaded)     | rules/*.md (auto-loaded)      |
| Knowledge    | docs/ (on-demand, custom)    | docs/ (on-demand, custom)     |
| Plans        | `~/.claude/plans/` (use `plansDirectory` for per-project) | plans/                        |
| Tasks        | `~/.claude/tasks/` (no per-project option yet) | —                             |
| Agents       | agents/*.md                  | agents/*.md                   |
| Skills       | skills/                      | (via plugins)                 |

Global = applies to ALL projects. Per-project = repo-specific, version-controlled.
`docs/` is a custom convention (not auto-loaded by Claude Code) — skills read from it on demand.

## Knowledge Docs (on-demand from `~/.claude/docs/`)

Reference material loaded by skills when relevant, NOT always in context:

- `docs/research-methodology.md` — Research workflow, experiment running, file organization
- `docs/async-and-performance.md` — Async patterns, batch APIs, caching, memory management
- `docs/ci-standards.md` — Confidence intervals, paired comparisons, power analysis, statistical reporting
- `docs/agent-teams-guide.md` — Team composition, communication, known limitations
- `docs/documentation-lookup.md` — Context7, GitHub CLI, verified repos, decision tree
- `docs/anthroplot.md` — Anthropic plotting: colors, gradients, helper functions, mplstyle
- `docs/apollo-eval-types.md` — Apollo Research eval taxonomy (scheming, situational awareness, corrigibility)
- `docs/petri-plotting.md` — Petri paper style: warm ivory, coral/blue/mint, TikZ/matplotlib/Excalidraw
- `docs/environment-setup.md` — CLAUDE_CODE_TMPDIR agent fix, SERVER_NAME machine identification

---

## Learnings (Per-Project CLAUDE.md)

Each project's CLAUDE.md should have a `## Learnings` section at the bottom.
Write to it when you discover:
- Bugs/quirks specific to this project (library incompatibilities, CI gotchas)
- Decisions made and their rationale ("chose X because Y")
- Current state of ongoing work ("migrated 3/7 endpoints, auth next")
- Things that broke unexpectedly and how they were fixed

Rules:
- Timestamp each entry: `- description (YYYY-MM-DD)`
- Keep under 20 entries — prune stale ones (>2 weeks old)
- If something appears across multiple projects → promote to global CLAUDE.md
- Don't duplicate what's already in CLAUDE.md instructions

---

## Plugin Organization & Context Profiles

**Always-on plugins**: superpowers, hookify, plugin-dev, commit-commands, claude-md-management, context7, core-toolkit.

**ai-safety-plugins** (`github.com/yulonglin/ai-safety-plugins`):
- `core-toolkit` — foundational agents, skills, safety hooks (always-on)
- `research-toolkit` — experiments, evals, analysis, literature
- `writing-toolkit` — papers, drafts, presentations, multi-critic review
- `code-toolkit` — dev workflow, debugging, delegation, code review
- `workflow-toolkit` — agent teams, handover, conversation management, analytics
- `viz-toolkit` — TikZ diagrams, Anthropic-style visualization

**Context profiles** control which plugins load per-project via `claude-context`:
```bash
claude-context                    # Show current state / apply context.yaml
claude-context code               # Software projects
claude-context code research      # Compose multiple profiles
claude-context --list             # Show active plugins and available profiles
claude-context --clean            # Remove project plugin config
claude-context --sync [-v]        # Register + update all plugin marketplaces
```

---

## Notes

- User specs: `specs/`
- Knowledge base: `docs/` (search first with `/docs-search`, add useful findings)
- Plans: `.claude/plans/` (per-project via `plansDirectory` setting)
- Tasks: `~/.claude/tasks/` (global, no per-project option)
- Don't be overconfident about recent models — search if unsure
- Debugging: When something doesn't work after a few tries, step back and plan for alternatives
- Permission errors: If sandboxing blocks you, consider using `mv` to `.bak` instead of `rm`
