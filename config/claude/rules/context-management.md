# Context Management

Large outputs consume context fast and can exhaust the conversation. These are the patterns that have hurt most.

## Reading large files

Use a subagent to read PDFs and long documents. PDFs especially can blow the context window in one go.

```
Agent → subagent_type: "general-purpose" or "literature-scout"
```

Don't read these directly in main context:

- PDFs (research papers, documentation, exported slides)
- Files >500 lines
- Multiple files for comparison or analysis
- Slide decks for review or fixing — `/fix-slide` delegates appropriately

## Codebase exploration

Search first, read targeted sections.

1. **Glob** — map file patterns (`*.py`, `**/cli/*.py`).
2. **Grep** — find specific content (function names, keywords).
3. **Read with limit/offset** — only the relevant 50–100 lines.

| File size | Action |
|-----------|--------|
| < 200 lines | Read directly. |
| 200–500 lines | Grep first, then Read with offset/limit. |
| > 500 lines | Don't Read without offset/limit. |

Threshold is configurable via `CLAUDE_READ_THRESHOLD` (default 500).

## Verbose command output

Run verbose commands in the background or redirect their output. Don't run them synchronously in main context:

- Scripts with verbose output, progress bars, or debug logging
- `pytest` with verbose output
- `make` / build commands
- Experiments with verbose output (redirect to log files)

### Monitoring background tasks (TaskOutput is broken)

Don't use `TaskOutput` with `block=false` to check on running background Bash tasks. It reads from the **head** of the output file (offset 0, first 30K chars), not the tail. You'll get ~8K tokens of stale output from the start of the job and think it's current.

Use `tail` instead:

```bash
tail -20 /tmp/claude-.../{task_id}.output   # path is in the background task message
```

`TaskOutput` with `block=true` blocks until the task completes (default 30s timeout) — also not useful for live monitoring.

`TaskOutput` is fine for checking the `status` field. For actual output, always tail the file.

## Bulk edits

Don't spawn multiple agents to edit the same file concurrently. The Edit tool requires exact `old_string` matches; concurrent edits cascade-fail.

| Batch size | Approach |
|------------|----------|
| 1–15 edits | Single session, sequential, no agents. |
| 15–40 edits | Single session, `/compact` every 15 edits. |
| 40+ edits | Sequential sessions, commit between batches. |
