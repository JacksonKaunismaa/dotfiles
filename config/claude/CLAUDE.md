# Global CLAUDE.md

Global guidance for Claude Code across all repositories.

## Environment Setup

**Use `uv` for package management. Virtual environment is at `.venv`.**

Claude config (`~/.claude/`) is a regular directory. `deploy-claude.sh` symlinks specific subdirectories (rules, skills, hooks, docs, templates, etc.) from `~/Work-Stuff/dotfiles/config/claude/` into it. See `docs/plugin-and-skill-management.md` for the full layout.

## Default Behaviors

- **Interview before planning** — use `/spec-interview-research` for experiments, `/spec-interview` for product features
- **Brainstorm before implementing** — use `/brainstorming` (not `EnterPlanMode`) for non-trivial tasks; don't write code until approach is clear
- **Use existing code** for experiments — correct hyperparams, full data, validated metrics; ad-hoc only for dry runs
- **Delegate to agents** for non-trivial work — use agent teams for parallelizable tasks, subagents for focused single-output tasks
- **Commit frequently** after every meaningful change
- **Update docs when changing code** — keep CLAUDE.md, README.md, and tracked project docs in sync (respect `.gitignore` — if `docs/` is ignored, don't try to commit it)
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

**Naming conventions:**
- `--project`: date + full research description, stable across days/weeks. E.g. `feb19-hardcode-auditbench-ct-qwen-32b`, `mar03-scheming-replication-sonnet`.
- `--experiment`: specific investigation within the project (no date). Be maximally verbose. E.g. `auditbench-eval-matched-categories`, `ct-lora-training-run`, `dpo-data-generation-from-refusals`.
- `--variant`: describes the experimental condition. E.g. `gpt4-baseline`, `sonnet-cot`, `no-system-prompt`, `opus-temp0.7`, `haiku-10shot`.

```bash
python run_my_experiment.py --project feb19-hardcode-auditbench-ct-qwen-32b --experiment auditbench-eval-matched-categories --variant gpt4-baseline --model gpt-4
```

For parallel ablations, use `&` and `wait`.

## Banned Dependencies

| Package | Reason | Date | Reference |
|---------|--------|------|-----------|
| `litellm` | **Supply chain attack.** v1.82.8 on PyPI contained a `.pth` credential stealer that exfiltrates SSH keys, cloud creds, env vars, shell history on *any* Python startup (no import needed). PyPI publishing creds were compromised — do not trust any version until BerriAI confirms root cause and remediates. | 2026-03-24 | [GitHub #24512](https://github.com/BerriAI/litellm/issues/24512) |

**NEVER install, add as dependency, or import any banned package.** If code requires one, find an alternative or ask the user.

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

- `docs/research-methodology.md` — **Always read before planning or running experiments.** Research workflow, uncertainty flagging, experiment running, file organization
- `docs/async-and-performance.md` — **Read before writing any LLM pipeline** (evals, judging, scoring, classification, data gen). Async patterns, batch APIs, caching, memory management
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

**Always-on plugins**: superpowers, hookify, plugin-dev, commit-commands, claude-md-management, context7, core.

**ai-safety-plugins** (`github.com/yulonglin/ai-safety-plugins`):
- `core` — foundational agents, skills, safety hooks (always-on)
- `research` — experiments, evals, analysis, literature
- `writing` — papers, drafts, presentations, multi-critic review
- `code` — dev workflow, debugging, delegation, code review
- `workflow` — agent teams, handover, conversation management, analytics
- `viz` — TikZ diagrams, Anthropic-style visualization

**Context profiles** control which plugins load per-project via `claude-context`:
```bash
claude-context                    # Show current state / apply context.yaml
claude-context code               # Software projects
claude-context code research      # Compose multiple profiles
claude-context --list             # Show active plugins and available profiles
claude-context --clean            # Remove project plugin config
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
