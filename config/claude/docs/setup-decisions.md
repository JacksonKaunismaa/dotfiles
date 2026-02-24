# Setup Decisions (vs. yulonglin/dotfiles reference)

Last reviewed: 2026-02-22

Reference repos:
- https://github.com/yulonglin/dotfiles
- https://github.com/yulonglin/ai-safety-plugins

## Skipped (with reasons)

| Item | Type | Why skipped |
|---|---|---|
| `plugin-configuration.md` | doc | Don't care about plugin config tweaks. Don't plan to install many plugins. |
| `plugin-maintenance.md` | doc | Don't plan to rename plugins. |
| `tmux-reference.md` | doc | Don't use tmux. |
| `experiment-registry-conventions.md` | doc | Too extra. Structured experiment tracking in markdown feels like overkill. |
| `check_webfetch_domain.sh` | hook | Prefer letting Claude fetch freely. Accept prompt injection risk; will be careful about what gets searched. |
| Watchdog system (5 scripts) | hooks | Sessions sit around for a long time intentionally. Don't want them flagged as stuck. |
| `llm-billing` agent | agent | Don't track billing across providers. No use case. |
| Settings hardening (permissions, sandbox, defaultMode) | settings | Run with bypass permissions. Fastest workflow. |
| Codex CLI config | config | Don't use Codex. |
| Gemini GitHub Commands | config | Don't use Gemini CLI. |
| `ENABLE_TOOL_SEARCH` | env var | Only 2 MCPs. Irrelevant. |
| `BASH_MAX_OUTPUT_LENGTH` | env var | 30k default is fine. |
| `teammateMode` | setting | Don't use tmux, so auto falls back to in-process anyway. |
| `aichat-search` | tool | Never needed to search past sessions. Revisit if that changes. |
| `hooks/README.md` | doc | Just hook documentation. Don't need it. |
| `skills/.gitignore` | file | Runtime symlink ignoring. Housekeeping. |
| `skills/commit/` | skill | Covered by commit-commands plugin. |
| `skills/commit-push-sync/` | skill | Covered by commit-commands plugin. |
| `skills/llm-billing/references/` | skill | Related to llm-billing skip. |

## Changed (2026-02-24)

**`rules/agents-and-delegation.md` cleanup:**
- Removed `core:codex` and `codex-reviewer` — don't use Codex CLI
- Removed `efficient-explorer` — redundant with built-in `Explore` subagent_type in Task tool
- Changed `code-reviewer` → `superpowers:code-reviewer` — point to actual plugin agent
- Added **Claude Code MCP** section documenting "nested orchestration" pattern:
  - Use `mcp__claude-code-mcp__claude_code` when you need an orchestrator that spawns its own subagents
  - Nested instance manages complexity internally, returns clean summary
  - Saves top-level context vs. spawning many Task subagents directly

---

## Added (2026-02-22 session)

- `docs/anthroplot.md` — Anthropic plotting reference
- `docs/apollo-eval-types.md` — Apollo Research eval taxonomy
- `docs/petri-plotting.md` — Petri paper visual style
- `docs/visual-layout-quality.md` — CSS spacing safety net
- `docs/environment-setup.md` — CLAUDE_CODE_TMPDIR fix, SERVER_NAME
- `docs/tool-installation.md` — aichat-search/tmux-cli install (not in CLAUDE.md, just on disk)
- `docs/humanizer-patterns.md` — 15 LLM-ism detection patterns
- `docs/paper-writing-style-guide.md` — ICML-derived writing standards
- `skills/anthropic-style/SKILL.md` — Anthropic brand colors/typography
- `skills/merge-worktree/SKILL.md` — Worktree merge + conflict resolution
- `hooks/check_loop_bypass.sh` — Blocks denied commands inside for/while loops
- `config/git-hooks/pre-commit` — Global gitleaks secret scanning
- `templates/research-spec.md` — Research project spec template
- `CLAUDE.md` restructured — added Communication Style, Directory Convention, Plugin Org, Notes, expanded Default Behaviors, removed redundant rules listing
- `deploy.sh` — added git hooks path
- `settings.json` — removed duplicate hooks, added PreToolUse:Bash loop bypass, added plansDirectory
- `settings.json.template` — same changes for future deploys
