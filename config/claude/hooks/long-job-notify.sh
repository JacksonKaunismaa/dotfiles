#!/bin/bash
# Notify via ntfy when Claude Code task takes > 15 minutes
# Used by UserPromptSubmit and Stop hooks

THRESHOLD_MINS=9
TIMESTAMP_DIR="/tmp/claude-sessions"
CONF_FILE="$HOME/.claude/ntfy.conf"
LOG_FILE="$HOME/.claude/hooks/ntfy-debug.log"

mkdir -p "$TIMESTAMP_DIR"

# Cleanup old timestamp files (older than 7 days)
find "$TIMESTAMP_DIR" -type f -mtime +7 -delete 2>/dev/null

# Read hook input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')

[ -z "$SESSION_ID" ] && exit 0

TIMESTAMP_FILE="$TIMESTAMP_DIR/$SESSION_ID"

# Log every hook invocation
echo "$(date '+%Y-%m-%d %H:%M:%S') | event=$HOOK_EVENT | session=$SESSION_ID | pid=$$ | file=$TIMESTAMP_FILE" >> "$LOG_FILE"

if [ "$HOOK_EVENT" = "UserPromptSubmit" ]; then
    # Record prompt start time
    NOW=$(date +%s)
    echo "$NOW" > "$TIMESTAMP_FILE"
    echo "  -> wrote timestamp $NOW" >> "$LOG_FILE"
    exit 0
fi

if [ "$HOOK_EVENT" = "Stop" ]; then
    if [ ! -f "$TIMESTAMP_FILE" ]; then
        echo "  -> no timestamp file found, exiting" >> "$LOG_FILE"
        exit 0
    fi

    START_TIME=$(cat "$TIMESTAMP_FILE")
    [ -z "$START_TIME" ] && exit 0
    NOW=$(date +%s)
    ELAPSED_SECS=$((NOW - START_TIME))
    ELAPSED_MINS=$((ELAPSED_SECS / 60))
    echo "  -> read timestamp $START_TIME, now=$NOW, elapsed=${ELAPSED_MINS}m" >> "$LOG_FILE"

    if [ "$ELAPSED_MINS" -ge "$THRESHOLD_MINS" ]; then
        # Load ntfy config
        [ -f "$CONF_FILE" ] && source "$CONF_FILE"

        # Get project name from cwd
        CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
        PROJECT=$(basename "$CWD")

        # Get first user message from transcript (truncated)
        TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
        TASK=""
        if [ -f "$TRANSCRIPT" ]; then
            TASK=$(jq -r '[.[] | select(.type=="human") | .message.content] | last // empty' "$TRANSCRIPT" 2>/dev/null | head -c 30)
            [ ${#TASK} -eq 30 ] && TASK="${TASK}..."
        fi

        # Build message - include short session ID for debugging
        SHORT_SID="${SESSION_ID:0:8}"
        MSG="${ELAPSED_MINS}m in ${PROJECT} [${SHORT_SID}]"
        [ -n "$TASK" ] && MSG="$MSG: $TASK"

        # Send notification
        echo "  -> SENDING NOTIFICATION: $MSG (start=$START_TIME)" >> "$LOG_FILE"
        curl -s -u "$NTFY_USERNAME:$NTFY_PASSWORD" \
            -d "$MSG" \
            -H "Title: CC Done" \
            -H "Priority: urgent" \
            "https://$NTFY_URL/$NTFY_TOPIC_CC" >/dev/null 2>&1
    else
        echo "  -> below threshold, no notification" >> "$LOG_FILE"
    fi
    exit 0
fi

exit 0
