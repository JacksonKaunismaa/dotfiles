#!/bin/bash
# Notify via ntfy when Claude Code task takes > threshold minutes
# Used by UserPromptSubmit and Stop hooks
#
# On Stop: extracts last assistant message from transcript, summarizes
# via Haiku API call, sends condensed notification. Falls back to
# truncated raw text if API call fails.

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
    NOW=$(date +%s)
    INPUT_KEYS=$(echo "$INPUT" | jq -r 'keys | join(", ")' 2>/dev/null)
    # Try known field names for the user's prompt
    USER_PROMPT=$(echo "$INPUT" | jq -r '.user_prompt // .prompt // .user_message // empty')
    jq -n --arg ts "$NOW" --arg prompt "$USER_PROMPT" \
        '{"start_time": $ts, "user_prompt": $prompt}' > "$TIMESTAMP_FILE"
    echo "  -> wrote timestamp $NOW, input_keys=[$INPUT_KEYS], prompt_len=${#USER_PROMPT}" >> "$LOG_FILE"
    exit 0
fi

if [ "$HOOK_EVENT" = "Stop" ]; then
    if [ ! -f "$TIMESTAMP_FILE" ]; then
        echo "  -> no timestamp file found, exiting" >> "$LOG_FILE"
        exit 0
    fi

    SESSION_DATA=$(cat "$TIMESTAMP_FILE")
    START_TIME=$(echo "$SESSION_DATA" | jq -r '.start_time // empty' 2>/dev/null)
    # Backwards compat: old format was just a bare timestamp
    [ -z "$START_TIME" ] && START_TIME="$SESSION_DATA"
    [ -z "$START_TIME" ] && exit 0

    USER_PROMPT=$(echo "$SESSION_DATA" | jq -r '.user_prompt // empty' 2>/dev/null)

    NOW=$(date +%s)
    ELAPSED_SECS=$((NOW - START_TIME))
    ELAPSED_MINS=$((ELAPSED_SECS / 60))
    INPUT_KEYS=$(echo "$INPUT" | jq -r 'keys | join(", ")' 2>/dev/null)
    echo "  -> read timestamp $START_TIME, now=$NOW, elapsed=${ELAPSED_MINS}m, input_keys=[$INPUT_KEYS]" >> "$LOG_FILE"

    if [ "$ELAPSED_MINS" -ge "$THRESHOLD_MINS" ]; then
        # Load ntfy config
        [ -f "$CONF_FILE" ] && source "$CONF_FILE"

        # Get project name from cwd
        CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
        PROJECT=$(basename "$CWD")

        # --- Extract assistant text ---
        # Priority: last_assistant_message (from hook input) > transcript parsing
        # last_assistant_message is provided by Claude Code directly (no race condition).
        LAST_ASSISTANT_TEXT=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')
        TOOL_NAMES=""

        if [ -n "$LAST_ASSISTANT_TEXT" ]; then
            echo "  -> last_assistant_message (${#LAST_ASSISTANT_TEXT} chars): ${LAST_ASSISTANT_TEXT:0:80}..." >> "$LOG_FILE"
        else
            echo "  -> last_assistant_message empty, falling back to transcript" >> "$LOG_FILE"
            # Fall back to transcript parsing — search recent messages for text
            TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
            if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
                TRANSCRIPT_LINES=$(wc -l < "$TRANSCRIPT")
                LAST_TYPE=$(tail -1 "$TRANSCRIPT" | jq -r '.type // empty' 2>/dev/null)
                echo "  -> transcript: $TRANSCRIPT ($TRANSCRIPT_LINES lines, last_type=$LAST_TYPE)" >> "$LOG_FILE"

                # Search up to 10 recent assistant messages for text content
                LAST_ASSISTANT_TEXT=$(tac "$TRANSCRIPT" \
                    | grep -m10 '"role":"assistant"' \
                    | jq -r '
                        [.message.content[] | select(.type=="text") | .text]
                        | select(length > 0)
                        | map(gsub("\n"; " ")) | join(" | ")' 2>/dev/null \
                    | sed '/^[[:space:]]*$/d' \
                    | head -1 \
                    | head -c 8000)

                if [ -n "$LAST_ASSISTANT_TEXT" ]; then
                    echo "  -> transcript text (${#LAST_ASSISTANT_TEXT} chars): ${LAST_ASSISTANT_TEXT:0:80}..." >> "$LOG_FILE"
                else
                    # Collect tool names as minimal context
                    TOOL_NAMES=$(tac "$TRANSCRIPT" \
                        | grep -m10 '"role":"assistant"' \
                        | jq -r '[.message.content[] | select(.type=="tool_use") | .name] | .[]' 2>/dev/null \
                        | sort -u | paste -sd', ')
                    echo "  -> no text in last 10 assistant msgs, tool names: ${TOOL_NAMES:-none}" >> "$LOG_FILE"
                fi
            elif [ -n "$TRANSCRIPT" ]; then
                echo "  -> transcript path set but file missing: $TRANSCRIPT" >> "$LOG_FILE"
            else
                echo "  -> no transcript_path in hook input" >> "$LOG_FILE"
            fi
        fi

        # Also grab the stop reason
        STOP_REASON=$(echo "$INPUT" | jq -r '.reason // empty')

        # Try summarizing via Haiku API call
        SUMMARY=""
        HAIKU_INPUT=""
        if [ -n "$LAST_ASSISTANT_TEXT" ]; then
            HAIKU_INPUT="${LAST_ASSISTANT_TEXT:0:4000}"
        elif [ -n "$TOOL_NAMES" ]; then
            HAIKU_INPUT="[No text output — assistant used these tools: $TOOL_NAMES]"
        fi

        if [ -n "$HAIKU_INPUT" ] && [ -n "$ANTHROPIC_API_KEY" ]; then
            echo "  -> haiku prompt: user_asked='${USER_PROMPT:0:1000}' assistant_output='${HAIKU_INPUT:0:1000}'" >> "$LOG_FILE"
            PROMPT_SECTION=""
            [ -n "$USER_PROMPT" ] && PROMPT_SECTION="User asked: $USER_PROMPT\n\n"
            API_BODY=$(jq -n \
                --arg text "$HAIKU_INPUT" \
                --arg ctx "$PROMPT_SECTION" \
                '{
                    "model": "claude-haiku-4-5-20251001",
                    "max_tokens": 150,
                    "messages": [{
                        "role": "user",
                        "content": ("You are generating a phone notification summary. Output ONLY a factual summary of what was done (max 280 chars). Never ask questions. Never say you lack context. If the text is unclear, summarize what you can see (e.g. tool names used, files edited). No preamble.\n\n" + $ctx + "Assistant output:\n" + $text)
                    }]
                }')

            SUMMARY=$(curl -s --max-time 10 \
                -H "x-api-key: $ANTHROPIC_API_KEY" \
                -H "anthropic-version: 2023-06-01" \
                -H "content-type: application/json" \
                -d "$API_BODY" \
                "https://api.anthropic.com/v1/messages" \
                | jq -r '.content[0].text // empty' 2>/dev/null)

            echo "  -> haiku summary: ${SUMMARY:0:100}..." >> "$LOG_FILE"
        fi

        # Fallback: truncated raw text → tool names → stop reason
        if [ -z "$SUMMARY" ]; then
            if [ -n "$LAST_ASSISTANT_TEXT" ]; then
                SUMMARY="${LAST_ASSISTANT_TEXT:0:280}"
                [ ${#LAST_ASSISTANT_TEXT} -gt 280 ] && SUMMARY="${SUMMARY}..."
            elif [ -n "$TOOL_NAMES" ]; then
                SUMMARY="Used tools: $TOOL_NAMES"
            elif [ -n "$STOP_REASON" ]; then
                SUMMARY="$STOP_REASON"
            else
                SUMMARY="(no summary available)"
            fi
            echo "  -> using fallback summary" >> "$LOG_FILE"
        fi

        # Build notification
        SHORT_SID="${SESSION_ID:0:8}"
        TITLE="CC Done (${ELAPSED_MINS}m) — ${PROJECT}"
        MSG="$SUMMARY"

        # Send notification
        echo "  -> SENDING: title='$TITLE' body='${MSG:0:100}...' (start=$START_TIME)" >> "$LOG_FILE"
        curl -s -u "$NTFY_USERNAME:$NTFY_PASSWORD" \
            -d "$MSG" \
            -H "Title: $TITLE" \
            -H "Priority: urgent" \
            "https://$NTFY_URL/$NTFY_TOPIC_CC" >/dev/null 2>&1
    else
        echo "  -> below threshold, no notification" >> "$LOG_FILE"
    fi
    exit 0
fi

exit 0
