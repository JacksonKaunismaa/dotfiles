# Coding Conventions

## Python Basics

- Run from project root with `uv` and `python -m`
- Type hints required, imports at top
- Let errors propagate (no unnecessary try/except)
- Testing: `pytest` exclusively
- **No inline Python commands**: Never run complex Python via `python -c "..."` in Bash. Write to a file, then execute. Scratch scripts go in `./scratch/` or `/tmp/`.
- **CSV files**: Always use pandas (`pd.read_csv()`), never `csv.DictReader`
- **Prompts**: Always use Jinja templates, never inline Python strings. Even short prompts.
- **Model inference**: Always use Inspect or Safety Tooling for model calls, never raw OpenAI/Anthropic clients. Safety Tooling is a research library for unified LLM inference. See `~/.claude/docs/safety-tooling.md`.
- **Concurrent API calls**: Never serial in a loop. Use `asyncio.gather()` for independent API calls.
- **GitHub operations**: Always use `gh` CLI for PRs, issues, and GitHub API queries
- **Glob patterns are case-sensitive**: Try alternative cases when searching (`**/Config.py` → also `**/config.py`)
- **Read .eval files** using Inspect AI's `read_eval_log()` (look up via MCP server)
- **Load `.env` before API calls**:
  ```python
  from dotenv import load_dotenv
  load_dotenv()  # Call before os.getenv() or API client init
  ```

### sys.path.insert (Safe Pattern)

```python
# src/utils/paths.py
import sys
from pathlib import Path

def add_project_root():
    project_root = Path(__file__).resolve().parent.parent.parent
    if project_root not in sys.path:
        sys.path.insert(0, str(project_root))

# In scripts (only in __main__ block):
if __name__ == "__main__":
    from src.utils.paths import add_project_root
    add_project_root()
```

## TypeScript

- Prefer TypeScript over JavaScript for all frontend/Node work
- Tooling: bun (runtime + pkg mgr) + tsc (types) + Biome (lint + format)
- Biome replaces ESLint + Prettier — single Rust-based binary

## Date & Timestamp Formatting

- **Always use UTC timezone** for all timestamps
- **Standard format**: `YYYYMMDD` for dates, `YYYYMMDD_HHMMSS` for timestamps
- **Helper commands** (in PATH):
  - `$(utc_date)` → outputs `YYYYMMDD` (e.g., `20260125`)
  - `$(utc_timestamp)` → outputs `YYYYMMDD_HHMMSS` (e.g., `20260125_143022`)

## Shell Scripts

- Run `shellcheck script.sh` before committing
- Fix all errors; warnings are usually worth addressing
- For zsh scripts, use `# shellcheck shell=bash` at top (closest approximation)
- Suppress false positives with `# shellcheck disable=SCXXXX` (include reason)

## General Programming

- Match existing code style
- Run linting (`ruff`) and type checking (`pyright`) after changes
- Refactor when unwieldy (>50 lines/function, >500 lines/file)

## Package Managers

**npm** is installed. Check for `package-lock.json` to confirm. Use `npx` for executing CLI tools.

## Language Selection

| Need | Default | When to reconsider |
|------|---------|-------------------|
| ML / research / prototyping | Python | — |
| Frontend / scripting / APIs | TypeScript | Plain JS only for trivial scripts |
| Performance-critical CLI/tools | Rust | Go if team familiarity matters; Zig for low-level/embedded |
| Shell glue | Bash/Zsh | Python if >50 lines or needs error handling |

This is a preference order, not a mandate. Match the tool to the job.

## CLI Tools Available

ripgrep (`rg`), fd, fzf, bat, eza, zoxide (`z`), delta, jq, jless, btop, dust, duf, sd (prefer over `sed`), npm/npx

## Visual Output Quality

When generating any visual output (TikZ, HTML/CSS, Slidev, matplotlib):

- **Verify visually** — CSS/TikZ/layout changes MUST be checked against rendered output (Playwright screenshot, compiled PDF, browser preview). Accessibility snapshots do NOT reveal spacing issues
- **Act on reviewer layout feedback immediately** — visual bugs from CSS fragility are invisible in code review; when a reviewer flags it, fix it
- **Use layout systems, not manual coordinates** — flexbox/grid (CSS), `positioning` library (TikZ), CSS Grid (Slidev). Manual pixel/pt values drift and overlap
- **Container padding > per-child padding** — pad the container itself, not each child with `> :not(x)` selectors. Markdown renderers produce varying DOM structures
- **Test with variable content** — would this layout still work if text were 20% longer or a list had 2x items?

### Minimum Spacing (hard floor — never go below)

| Domain | Container padding | Content-to-edge gap | Between sibling elements |
|--------|------------------|--------------------|-----------------------|
| **HTML/CSS** | `p-3` / `0.75rem` / `12px` | `p-2` / `0.5rem` / `8px` | `gap-2` / `0.5rem` |
| **TikZ** | `inner sep>=10pt` | `inner sep>=8pt` | `node distance>=1.5cm` |
| **Slidev** | `p-4` / `1rem` on slide content | `p-2` on nested elements | `gap-3` / `0.75rem` |
