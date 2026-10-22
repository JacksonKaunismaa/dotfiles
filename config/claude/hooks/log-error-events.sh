#!/bin/bash
# Logs hook payloads for events that *might* fire on Claude Code API/classifier errors,
# so we can pick the right event for auto-retry.
#
# Usage in settings.json: pass the event name as $1, e.g.
#   "command": "~/.claude/hooks/log-error-events.sh PermissionDenied"
#
# Output: JSONL at /tmp/claude-error-events.log, one line per invocation:
#   {"ts": "...", "event": "...", "payload": {...stdin JSON...}}

set -euo pipefail

EVENT="${1:-unknown}"
LOG=/tmp/claude-error-events.log
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Read stdin (the hook payload) — may be JSON or empty
PAYLOAD=$(cat)

# Wrap into one JSONL line. If payload isn't valid JSON, escape it as a string.
if echo "$PAYLOAD" | jq -e . >/dev/null 2>&1; then
    jq -nc \
        --arg ts "$TS" \
        --arg event "$EVENT" \
        --argjson payload "$PAYLOAD" \
        '{ts:$ts, event:$event, payload:$payload}' >> "$LOG"
else
    jq -nc \
        --arg ts "$TS" \
        --arg event "$EVENT" \
        --arg payload "$PAYLOAD" \
        '{ts:$ts, event:$event, payload_raw:$payload}' >> "$LOG"
fi

# Pass through — never block or interfere
exit 0
