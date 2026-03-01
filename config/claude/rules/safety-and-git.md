# Safety & Git Rules

## Zero Tolerance Rules

| Rule | Consequence |
|------|-------------|
| **NEVER delete files** (`rm -rf`) unless explicitly asked | Prefer: `archive/` > `mv .bak` > `rm`. A hook blocks `sudo rm -r`, `xargs rm -r`, and `xargs kill`. |
| **NEVER use mock data** in production code | Only in unit tests. ASK if data unavailable |
| **NEVER fabricate information** | Say "I don't know" when uncertain |
| **NEVER ignore unexpected results** | Surprisingly good/bad → investigate before concluding. A hidden bug is worse than a failed experiment |
| **NEVER commit secrets** | API keys, tokens, credentials |
| **NEVER run `git checkout --`** or any destructive Git (e.g. `git reset --hard`, `git clean -fd`): ALWAYS prefer safe, reversible alternatives, and ask the user if best practice is to do so | Can trigger catastrophic, irreversible data loss |
| **NEVER use `sys.path.insert`** directly | Crashes Claude Code session (see `rules/coding-conventions.md` for safe pattern) |
| **NEVER rewrite full file during race conditions** | If Edit fails with "file modified since read", pause and wait (exponential backoff), then ask user—NEVER use Write to overwrite entire file as workaround |

## Dirty State Before Major Changes

Before starting substantial implementation work (editing 3+ files, dispatching subagents for implementation, major refactors), run `git status --porcelain | wc -l` to check dirty file count:

- **10+ dirty files**: Stop and tell the user. Suggest committing or stashing the dirty state before proceeding. Don't start implementation until the user addresses it.
- **5-9 dirty files**: Flag it to the user. "You have N dirty files — want to commit these first?" Then proceed based on their answer.
- **< 5 dirty files**: Normal WIP, proceed without comment.

This protects against making large changes on top of uncommitted work, which makes rollback and `git diff` review painful.

## Git Commands (Readability)

- **Prefer rebase over merge** for `git pull` — keeps history linear and clean
- **Default pull behavior**: When user says "pull", run `git stash && git pull --rebase && git stash pop`
  - Handles unstaged changes automatically
  - If merge conflicts occur after stash pop, notify user and help resolve
  - If stash fails (e.g., `.claude/settings*.json` unlink errors), commit first then pull
- **Use readable refs** over commit hashes: branch names, tags, `origin/branch`
- Examples:
  - ✅ `git log origin/main..feature-branch`
  - ✅ `git diff main..JacksonKaunismaa/dev`
  - ❌ `git log 5f41114..a8084f7` (hard to read)
- Only use hashes when refs don't exist (e.g., comparing arbitrary commits)

### Commit Messages

For single-line messages, use `-m "message"`. For multi-line, use heredoc or `-F`:
```bash
git commit -m "feat: subject line"
```
