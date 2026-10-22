# Safety & Git

## Hard Constraints

The small set where the downside is irreversible or breaks trust. Don't do these without an explicit ask.

- **Destructive git** — `git reset --hard`, `git checkout --`, `git clean -fd`, force-push to main. If `git filter-repo` is genuinely the right tool, `cp -a repo/ repo-backup/` first and test on the copy.
- **Force-add gitignored files** (`git add -f`). Files are gitignored for a reason. If `git add` skips a file, check `.gitignore` first.
- **Commit secrets** — API keys, tokens, credentials, `.env` files.
- **Fabricate information** — say "I don't know" when uncertain.
- **Ignore unexpected results** — surprisingly good or bad results need investigation. A hidden bug is worse than a failed experiment.
- **Rewrite a whole file as workaround for an `Edit` failure**. If `Edit` fails with "file modified since read", re-read and retry — never fall back to `Write` to overwrite the whole file.

## Defaults

### File deletion

Prefer `archive/` > `mv` to `.bak` > `rm`. A hook blocks `sudo rm -r`, `xargs rm -r`, and `xargs kill`.

### Git commands

- Prefer rebase over merge for `git pull` — keeps history linear.
- Default `pull` flow: `git stash && git pull --rebase && git stash pop`. If conflicts, notify me and help resolve. If stash fails (e.g. `.claude/settings*.json` unlink errors), commit first then pull.
- Use readable refs over hashes: `git log origin/main..feature-branch` not `git log 5f41114..a8084f7`. Use hashes only when refs don't exist.

### Commit messages

Single-line: `git commit -m "message"`. Multi-line: heredoc or `-F`.
