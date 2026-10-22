#!/bin/bash
# Auto-retry after Claude Code API errors via the StopFailure asyncRewake hook.
#
# Wired in global settings.json on the StopFailure event with matcher "" (match ALL
# StopFailure events). The matcher is intentionally a catch-all: this script is the sole
# decision point. It bails (exit 0, no wake) on anything not provably transient, so a
# permanent failure (bad model id, auth, billing) can never trigger an endless wake loop.
#
# Why match-all instead of a "rate_limit|server_error" matcher: the docs and the installed
# runtime disagree on the payload field name (docs say `error_type`/`error_message`; the
# actual runtime payloads we've logged use `error`/`last_assistant_message`), and no
# rate_limit/server_error event has ever fired, so we have no proof a value-matcher works.
# Matching all events + classifying in-script is immune to that uncertainty. We read both
# field-name spellings defensively.
#
# When triggered:
#   1. Read the hook payload (JSON) from stdin: error type + human-readable message + sid.
#   2. Classify. Retryable -> sleep a type-appropriate backoff, emit a contextual message,
#      exit 2 (asyncRewake injects stdout as a system-reminder + wakes the model).
#      Non-retryable -> log and exit 0 (no wake).
#
# Backoff windows (retryable types only):
#   rate_limit                  -> 120-180s   (rate limits typically reset at minute boundary)
#   overloaded / server_error   -> 30-60s     (overload usually resolves fast)
#   unknown + transient message -> 30-60s     (socket/connection drops; detail is in the message)
#
# Bailed (exit 0, no wake) — NOT retryable, retrying can't help:
#   unknown + non-transient message, model_not_found, authentication_failed,
#   oauth_org_not_allowed, billing_error, invalid_request, max_output_tokens, anything else.
#
# Documented error-type values (per Claude Code docs, 2026-06): rate_limit, overloaded,
# authentication_failed, oauth_org_not_allowed, billing_error, invalid_request,
# model_not_found, server_error, max_output_tokens, unknown.
#
# Log: /tmp/claude-rl-watcher.log (shared with the old watcher's log path).

set -uo pipefail

LOG=/tmp/claude-rl-watcher.log

now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

PAYLOAD=$(cat)

# Read both the runtime spelling (.error / .last_assistant_message) and the documented
# spelling (.error_type / .error_message), whichever is present.
ERROR_TYPE=$(jq -r '.error // .error_type // "unknown"' <<<"$PAYLOAD" 2>/dev/null || echo "unknown")
MSG=$(jq -r '.last_assistant_message // .error_message // ""' <<<"$PAYLOAD" 2>/dev/null || echo "")
SESSION_ID=$(jq -r '.session_id // "?"' <<<"$PAYLOAD" 2>/dev/null || echo "?")
SHORT_ID=${SESSION_ID:0:8}

# Messages that mark an `unknown` error as a transient transport/network drop worth retrying.
# Observed examples: "socket connection was closed unexpectedly", "Unable to connect to API
# (ConnectionRefused)", "Unable to connect to API (FailedToOpenSocket)".
TRANSIENT_RE='socket|connection|unable to connect|closed unexpectedly|network|timed out|timeout|econnreset|etimedout|fetch failed'

case "$ERROR_TYPE" in
    rate_limit)
        DELAY=$((120 + RANDOM % 61))
        DESC="rate-limit (429)"
        ;;
    server_error|overloaded)
        DELAY=$((30 + RANDOM % 31))
        DESC="server overload (5xx)"
        ;;
    unknown)
        if grep -qiE "$TRANSIENT_RE" <<<"$MSG"; then
            DELAY=$((30 + RANDOM % 31))
            DESC="connection drop (transient)"
        else
            echo "[$(now)] [$SHORT_ID] non-retryable unknown error; not waking: ${MSG:0:140}" >> "$LOG"
            exit 0
        fi
        ;;
    *)
        echo "[$(now)] [$SHORT_ID] non-retryable error type '$ERROR_TYPE'; not waking: ${MSG:0:140}" >> "$LOG"
        exit 0
        ;;
esac

echo "[$(now)] [$SHORT_ID] $DESC detected; backoff ${DELAY}s" >> "$LOG"

sleep "$DELAY"

echo "[$(now)] [$SHORT_ID] waking model" >> "$LOG"

cat <<EOF
Auto-retry: the previous turn was interrupted by a $DESC. Waited ${DELAY}s and is now automatically resuming. Continue where you left off — the conversation context is intact, no acknowledgement needed.
EOF

exit 2
