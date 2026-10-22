# Coding Conventions

Most of this is descriptive — what the codebase looks like, what tooling is available. Read it as orientation, not rules. If something here is costing more than it's saving, push back.

## New codebases & big refactors

When building from scratch or fully refactoring, spend real time upfront on the abstractions before writing much code. Surface likely future features/experiments with me — not because we'll necessarily build them, but as a forcing function for where the design should bend toward extensibility. Keep the result short, crisp, and minimal. This is design-time work — pair it with the `superpowers:brainstorming` skill rather than jumping straight to code.

## Python in this codebase

- `uv` for env/package management; project root + `uv run python -m <module>` to run.
- Type hints throughout, imports at top, `pytest` for tests.
- Run `uv run ruff check` (and `ruff format`) after every major addition or edit — fix lint as you go, don't batch it to the end.
- Errors propagate by default. `try/except` is for cases with a real fallback, not for silencing — `except Exception:` returning a default tends to corrupt downstream analysis.
- For anything past a one-liner, prefer a script over `python -c "..."`. Inline Python in bash is hard to debug and pollutes shell history. Scratch scripts → `./scratch/` or `/tmp/`.
- CSV → pandas (`pd.read_csv()`), not `csv.DictReader`.
- Prompts → Jinja templates, not inline Python strings. Inline strings drift away from version control and don't templatize cleanly when you want variants.
- Model inference → Inspect or Safety Tooling, not raw OpenAI/Anthropic clients. Safety Tooling handles concurrency and rate limiting; raw clients tend to grow ad-hoc retry logic. See `~/.claude/docs/safety-tooling.md`.
- Concurrent API calls → `asyncio.gather()` for independent calls.
- GitHub ops → `gh` CLI.
- `.eval` files → Inspect AI's `read_eval_log()`.
- Glob case can bite — try both cases when searching (`**/Config.py` and `**/config.py`).
- API code that reads env vars: `load_dotenv()` (from `python-dotenv`) before `os.getenv()` or any client init.

## TypeScript

TypeScript over JavaScript for frontend/Node work. Stack: `bun` (runtime + package manager) + `tsc` (types) + Biome (lint + format, replaces ESLint + Prettier).

## Dates and timestamps

UTC throughout. Standard formats: `YYYYMMDD` for dates, `YYYYMMDD_HHMMSS` for timestamps. Helpers on PATH:

- `$(utc_date)` → `20260125`
- `$(utc_timestamp)` → `20260125_143022`

## Shell scripts

`shellcheck script.sh` before committing — errors should be fixed, warnings usually too. For zsh scripts, `# shellcheck shell=bash` at top is the closest approximation. Suppress false positives with `# shellcheck disable=SCXXXX` plus a reason.

## Package managers

`npm` is installed (check for `package-lock.json`). `npx` for one-off CLI tools.

## Language selection

| Need | Default | When to reconsider |
|------|---------|-------------------|
| ML / research / prototyping | Python | — |
| Frontend / scripting / APIs | TypeScript | Plain JS only for trivial scripts |
| Performance-critical CLI/tools | Rust | Go if team familiarity matters; Zig for low-level/embedded |
| Shell glue | Bash/Zsh | Python if >50 lines or needs error handling |

Preference order, not a mandate — match the tool to the job.

## Code navigation

No LSP — the pyright/rust-analyzer LSP plugins were removed 2026-07-20 (never used; no startup benefit either). Use Grep/Glob for navigation: text patterns, symbol names, string literals, file discovery.

## Available CLI tooling

`rg` (ripgrep), `fd`, `fzf`, `bat`, `eza`, `z` (zoxide), `delta`, `jq`, `jless`, `btop`, `dust`, `duf`, `sd`, `npm`/`npx`. (`sd` is the modern `sed` — easier syntax for find/replace; reach for it when `sed` would be fiddly.)

## Visual output quality

Things that cause visible bugs in TikZ, HTML/CSS, Slidev, matplotlib output — these have actually broken figures/slides for me before:

- **Verify visually.** CSS/TikZ/layout changes need a check against the rendered output (Playwright screenshot, compiled PDF, browser preview). Accessibility snapshots don't reveal spacing issues.
- **Reviewer layout feedback isn't optional.** Visual bugs from CSS fragility are invisible in code review — when a reviewer flags one, it's there.
- **Layout systems, not manual coordinates.** Flexbox/grid (CSS), `positioning` library (TikZ), CSS Grid (Slidev). Manual pixel/pt values drift and overlap.
- **Container padding > per-child padding.** Pad the container itself, not each child with `> :not(x)` selectors — markdown renderers produce varying DOM structures.
- **Stress-test with variable content.** Would the layout still work if text were 20% longer or the list had 2× items?

### Minimum spacing (hard floor — below these things start overlapping)

| Domain | Container padding | Content-to-edge gap | Between sibling elements |
|--------|------------------|--------------------|-----------------------|
| **HTML/CSS** | `p-3` / `0.75rem` / `12px` | `p-2` / `0.5rem` / `8px` | `gap-2` / `0.5rem` |
| **TikZ** | `inner sep>=10pt` | `inner sep>=8pt` | `node distance>=1.5cm` |
| **Slidev** | `p-4` / `1rem` on slide content | `p-2` on nested elements | `gap-3` / `0.75rem` |
