#!/bin/bash
# Write current CC session ID to /tmp/claude-session-<CR_PID>
# so kitty-snapshot can identify which session is in which terminal.
# Same approach as claude-reload but runs on every user message.
[[ -z "$CR_PID" ]] && exit 0
sid=$(tac ~/.claude/history.jsonl 2>/dev/null | grep -m1 "\"project\":\"$PWD\"" | jq -r '.sessionId // empty' 2>/dev/null)
[[ -n "$sid" ]] && echo "$sid" > "/tmp/claude-session-$CR_PID"
exit 0
