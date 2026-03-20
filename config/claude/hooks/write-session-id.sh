#!/bin/bash
# Write current session ID to /tmp/claude-session-<CR_PID>.
# Hooks receive session_id in JSON via stdin — always correct,
# even after /resume switches sessions.
[[ -z "$CR_PID" ]] && exit 0
input=$(cat)
sid=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)
[[ -n "$sid" ]] && echo "$sid" > "/tmp/claude-session-$CR_PID"
exit 0
