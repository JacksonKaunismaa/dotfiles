#!/bin/bash
# Python linting hook - ruff format + lint + pyright type checking
# Auto-detects venv in project directory
#
# Modes (2026-08-10; design story in commits 0854aa4..14ad7bc + two Codex
# adversarial review rounds — triage in commit messages):
#   parent   — PostToolUse asyncRewake entry, MAIN-agent edits only. Fail-closed
#              budget inside the 90s hook timeout: lock 20s + slot 10s + pyright
#              45s; on any miss it skips WITHOUT touching dedup state (next edit
#              retries) rather than half-running.
#   subagent — PostToolUse sync entry, SUBAGENT edits only: detaches a `worker`,
#              waits ~≤1s for its liveness ack, exits. No-ack -> failure notice.
#   worker   — detached: per-file flock singleflight + one-waiter coalescing,
#              machine-wide slot semaphore (flock, kernel-released), pyright +
#              dedup; publishes findings atomically to the file's LATEST editor;
#              explicit busy/failure notices instead of silence.
#   deliver  — PreToolUse entry (all tools): injects pending findings for the
#              calling agent via additionalContext. NEVER add permissionDecision
#              here — it would auto-approve tool calls.
#   stopcheck— SubagentStop entry: blocks a premature stop while pid-checked
#              markers are live (absolute 38s deadline per sweep, 240s hostage
#              cap) or findings are pending; reaps dead checks into an explicit
#              died-notice. Emits payload BEFORE deleting pending files, so a
#              kill mid-hook duplicates (benign) instead of losing findings.
#
# Locking (no cycle; verified round 2): fd 9 per-file lock -> fd 8 slot -> fd 7
# per-agent pending lock. ALL flock waits are FAIL-CLOSED: on timeout we never
# enter the critical section. Lock files are NEVER unlinked while their path can
# recur (unlink+recreate splits the lock domain); growth is ~1 empty inode per
# red file / agent and is accepted.
# NOTE: never attach 2>/dev/null to a bare `exec` — it permanently redirects the
# whole script's stderr (it silently ate stopcheck's exit-2 payload once).
# fd closes for children must wrap the WHOLE pipeline: `{ a | b; } 8>&- 9>&-`.
#
# Accepted gaps (rare, bounded; do not re-litigate without new evidence):
# 3+ agents editing one file inside a pyright window can leave a non-latest
# editor uninformed; editor.<fhash> is a last-HOOK-writer heuristic, not true
# edit order (hook-start skew can misroute in the multi-agent same-file case);
# main-agent edits don't update editor routing; dead-waiter takeover can
# double-run once; a waiter chain where pyright takes >100s twice can outlive
# stopcheck's 240s hostage cap; ms kill-windows around hash-write-vs-publish;
# exotic paths (spaces in venv path, trailing-newline filenames); ruff output
# remains advisory-silent (original design).
# Dedup state is shared across agents: one signal per per-file error-set change.
# Subagent transcripts do NOT persist injected content — verify delivery by
# subagent SELF-REPORT (harness: claude-workbench artifacts/hook-delivery-harness/).
# Decision log: ~/.local/state/python-lint-hook/events.jsonl (rotates at 5MB).

# The lock/stat/timeout plumbing below is Linux-only (flock, stat -c, setsid). Without
# flock, stopcheck mis-reads every lock failure as "result being written" and blocks
# SubagentStop forever (macOS, 2026-10-13) — so no flock = no hook, fail open.
command -v flock >/dev/null 2>&1 || exit 0

mode="${1:-parent}"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/python-lint-hook"
pending_root="$state_dir/pending"
SLOTS=3          # max concurrent pyright runs machine-wide (~0.5-1G RAM each)

mkdir -p "$state_dir" "$pending_root"

log() {  # log <event> <file> <agent>
  printf '{"ts":"%s","file":"%s","agent":"%s","mode":"%s","event":"%s"}\n' \
    "$(date -u +%FT%TZ)" "${2:--}" "${3:-main}" "$mode" "$1" >> "$state_dir/events.jsonl"
}

# consume_pending <agent_id>: gathers as many WHOLE pending findings as fit the
# cap into $msg and PENDING_TAKEN, under the per-agent lock, which it leaves
# HELD on success — callers must emit the payload, then call finish_consume to
# delete what was read and release the lock (emit-before-delete: a kill between
# the two duplicates a delivery instead of destroying it).
# Returns: 0 gathered (fd 7 held), 1 nothing pending, 2 lock timeout.
consume_pending() {
  local dir="$pending_root/$1" f files=() total=0 size
  PENDING_TAKEN=()
  exec 7>"$pending_root/$1.lock"
  flock -w 5 7 || { exec 7>&-; return 2; }
  for f in "$dir"/*.txt; do [[ -f "$f" ]] && files+=("$f"); done
  (( ${#files[@]} )) || { exec 7>&-; return 1; }
  msg=""
  for f in "${files[@]}"; do
    size=$(stat -c%s "$f" 2>/dev/null || echo 0)
    if (( total == 0 && size > 4000 )); then
      msg="$(head -c 4000 "$f")"$'\n(truncated)'
      PENDING_TAKEN+=("$f")
      break
    fi
    (( total + size > 4000 )) && break
    msg+="$(cat "$f")"$'\n'
    (( total += size ))
    PENDING_TAKEN+=("$f")
  done
  [[ -n "$msg" ]] || { exec 7>&-; return 1; }
  return 0
}

finish_consume() {
  (( ${#PENDING_TAKEN[@]} )) && rm -f "${PENDING_TAKEN[@]}"
  exec 7>&-
}

# publish_pending <agent_id> <fhash> <text>: atomic tmp+mv under the per-agent
# lock; fail-closed on lock timeout; retries once if housekeeping pruned the dir.
publish_pending() {
  local dir="$pending_root/$1" tmp
  exec 7>"$pending_root/$1.lock"
  flock -w 10 7 || { exec 7>&-; return 1; }
  for _ in 1 2; do
    mkdir -p "$dir" 2>/dev/null
    tmp="$dir/.tmp.$$"
    if printf '%s\n' "$3" > "$tmp" 2>/dev/null && mv -f "$tmp" "$dir/$2.txt" 2>/dev/null; then
      exec 7>&-
      return 0
    fi
    rm -f "$tmp" 2>/dev/null
  done
  exec 7>&-
  return 1
}

# acquire_slot <max_wait_s>: flock semaphore over slot.0..N-1 — released by the
# kernel on process death. Holds fd 8 on success.
acquire_slot() {
  local deadline=$(( SECONDS + $1 )) i
  while :; do
    for i in $(seq 0 $(( SLOTS - 1 ))); do
      exec 8>"$state_dir/slot.$i"
      flock -n 8 && return 0
    done
    (( SECONDS >= deadline )) && { exec 8>&-; return 1; }
    sleep 2
  done
}

# ---------------------------------------------------------------- deliver ----
# PreToolUse, every tool call. Fast path first: no pending findings anywhere ->
# exit before even reading stdin (keeps per-call overhead to a few ms).
if [[ "$mode" == "deliver" ]]; then
  compgen -G "$pending_root/*/*" >/dev/null 2>&1 || exit 0
  input=$(cat)
  agent_id=$(jq -r '.agent_id // empty' <<<"$input" 2>/dev/null)
  [[ -n "$agent_id" ]] || exit 0
  consume_pending "$agent_id" || exit 0   # lock-busy: findings deliver next call
  log delivered - "$agent_id"
  jq -n --arg ctx "Async pyright check on file(s) you edited found errors (as of that edit — re-verify if you have changed the file since):
$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$ctx}}'
  finish_consume
  exit 0
fi

# -------------------------------------------------------------- stopcheck ----
if [[ "$mode" == "stopcheck" ]]; then
  input=$(cat)
  agent_id=$(jq -r '.agent_id // empty' <<<"$input" 2>/dev/null)
  [[ -n "$agent_id" ]] || exit 0
  deadline=$(( SECONDS + 38 ))   # absolute; leaves output headroom in the 60s hook cap
  while :; do
    live=0
    now=$(date +%s)
    for m in "$state_dir/inflight/$agent_id".*; do
      [[ -f "$m" ]] || continue
      age=$(( now - $(stat -c%Y "$m" 2>/dev/null || echo "$now") ))
      wpid=$(cat "$m" 2>/dev/null)
      if [[ -n "$wpid" ]] && kill -0 "$wpid" 2>/dev/null; then
        (( age < 240 )) && (( live++ ))    # alive but ancient -> stop holding the agent hostage
      elif (( age < 20 )); then
        (( live++ ))                        # just spawned; worker may not have acked yet
      else
        rm -f "$m"                          # dead or never launched (SIGKILL leaves no trap)
        log stop_reaped_dead "$(basename "$m")" "$agent_id"
        publish_pending "$agent_id" "died.$(basename "$m" | cut -d. -f2)" \
          "Note: an async pyright check on a file you recently edited died before reporting (possibly OOM). Run pyright on your recently edited files manually if type-correctness matters."
      fi
    done
    (( live == 0 || SECONDS >= deadline )) && break
    sleep 1
  done
  consume_pending "$agent_id"
  case $? in
    0)
      log stop_delivered - "$agent_id"
      {
        echo "Before finishing: an async pyright check found errors in file(s) you edited (as of those edits):"
        echo "$msg"
        (( live > 0 )) && echo "(More checks are still running — try to finish again in a moment to collect them.)"
        echo "Fix them if they are yours; if they are pre-existing/expected, state that briefly in your final answer. Then finish."
      } >&2
      finish_consume
      exit 2
      ;;
    2)
      log stop_lockbusy - "$agent_id"
      echo "A type-check result for a file you just edited is being written right now; wait a moment and try to finish again." >&2
      exit 2
      ;;
  esac
  if (( live > 0 )); then
    log stop_holdoff - "$agent_id"
    echo "A type-check on a file you just edited is still running; wait a moment and try to finish again (it will deliver any findings then)." >&2
    exit 2
  fi
  exit 0
fi

# ------------------------------------------------------- shared lint logic ---
# Sets lint_status to findings|clean|unchanged|failed, and $errors on findings.
run_lint() {  # run_lint <file_path> <pyright_timeout_s>
  local fp="$1" to="$2" project_root pyright_args raw prc diags total err_hash max_errors=5
  local orig_pwd="$PWD"
  lint_status=failed
  project_root=$(find_project_root "$fp")
  cd "$project_root" || return 1
  timeout 15 ruff format --check "$fp" 2>/dev/null || true
  timeout 15 ruff check "$fp" 2>/dev/null || true

  pyright_args="--outputjson"
  if [[ -f "$project_root/.venv/bin/python" ]]; then
    pyright_args="$pyright_args --pythonpath $project_root/.venv/bin/python"
  elif [[ -f "$orig_pwd/.venv/bin/python" ]]; then
    # File is outside project (e.g. ~/.claude/skills/) — fall back to the
    # invoking directory's venv (must be the pre-cd PWD, not $PWD).
    pyright_args="$pyright_args --pythonpath $orig_pwd/.venv/bin/python"
  fi

  # Close lock fds for the child (an orphan must not hold file lock + slot).
  # pyright exits 0 (clean) or 1 (errors found); anything else — 124/137
  # timeout, crash — is a FAILED check, as is JSON that isn't a single document
  # with a generalDiagnostics array.
  # shellcheck disable=SC2086  # pyright_args is a deliberately word-split arg list
  raw=$({ timeout -k 5 "$to" pyright $pyright_args "$fp" 2>/dev/null; } 8>&- 9>&-)
  prc=$?
  if (( prc != 0 && prc != 1 )); then
    log pyright_failed "$fp" "$agent_id"
    return 1
  fi
  diags=$(jq -ce '.generalDiagnostics | select(type=="array")' <<<"$raw" 2>/dev/null)
  [[ -n "$diags" ]] || { log pyright_no_output "$fp" "$agent_id"; return 1; }
  total=$(jq 'length' <<<"$diags")

  # Dedup — report only when the error set changed since the last run. Hash
  # messages only (not line numbers), so edits that merely shift unrelated
  # pre-existing errors around stay quiet.
  state_file="$state_dir/$(printf '%s' "$fp" | sha256sum | cut -d' ' -f1)"
  if (( total == 0 )); then
    rm -f "$state_file"
    lint_status=clean
    log clean "$fp" "$agent_id"
    return 1
  fi
  err_hash=$(jq -r 'map(.message) | join(" ")' <<<"$diags" | sha256sum | cut -d' ' -f1)
  if [[ -f "$state_file" ]] && [[ "$(cat "$state_file")" == "$err_hash" ]]; then
    lint_status=unchanged
    log unchanged_suppressed "$fp" "$agent_id"
    return 1
  fi
  echo "$err_hash" > "$state_file"

  errors=$(jq -r --argjson max "$max_errors" '
    .[:$max] | map("Line \(.range.start.line + 1): \(.message)") | join("\n")
  ' <<<"$diags")
  if (( total > max_errors )); then
    errors+=$'\n'"(+$((total - max_errors)) more)"
  fi
  lint_status=findings
  return 0
}

# Find project root by walking up looking for .venv, .git, pyproject.toml
find_project_root() {
  local dir
  dir=$(dirname "$1")
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.venv" ]] || [[ -d "$dir/.git" ]] || [[ -f "$dir/pyproject.toml" ]]; then
      echo "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
  dirname "$1"  # fallback to file's directory
}

# ----------------------------------------------------------------- worker ----
# Detached child of `subagent` mode: argv, no stdin.
if [[ "$mode" == "worker" ]]; then
  agent_id="$2"
  file_path="$3"
  inflight_marker="${4:-}"
  # shellcheck disable=SC2064  # expand paths now, not at exit time
  trap "rm -f '$inflight_marker'" EXIT
  [[ -n "$inflight_marker" ]] && echo $$ > "$inflight_marker" 2>/dev/null  # liveness ack

  # Housekeeping. Stale pending deletion takes the owner's lock (fail-closed:
  # skip on contention, next worker retries) and rolls back the dedup hash so
  # the error set can re-fire. flock lock files are never unlinked (domain
  # split); only 30d-dead agents' pending locks are safe to drop.
  now_hk=$(date +%s)
  while IFS= read -r -d '' pf; do
    ag=$(basename "$(dirname "$pf")")
    exec 7>"$pending_root/$ag.lock"
    if flock -n 7; then
      if [[ -f "$pf" ]] && (( now_hk - $(stat -c%Y "$pf" 2>/dev/null || echo "$now_hk") > 86400 )); then
        fh=$(basename "$pf" .txt)
        [[ "$fh" =~ ^[0-9a-f]{64}$ ]] && rm -f "$state_dir/$fh"
        rm -f "$pf"
      fi
    fi
    exec 7>&-
  done < <(find "$pending_root" -type f -name '*.txt' -mmin +1440 -print0 2>/dev/null)
  # Inflight markers: prune only if old AND the recorded worker pid is dead —
  # a legitimate deep-queue worker can run past 10 minutes.
  for m in "$state_dir/inflight"/*; do
    [[ -f "$m" ]] || continue
    (( now_hk - $(stat -c%Y "$m" 2>/dev/null || echo "$now_hk") > 600 )) || continue
    mp=$(cat "$m" 2>/dev/null)
    [[ -n "$mp" ]] && kill -0 "$mp" 2>/dev/null && continue
    rm -f "$m"
  done
  find "$state_dir" -maxdepth 1 -name 'waiter.*' -type f -mmin +60 -delete 2>/dev/null
  find "$state_dir" -maxdepth 1 -name 'editor.*' -type f -mtime +1 -delete 2>/dev/null
  find "$state_dir" -maxdepth 1 -regextype posix-extended -regex '.*/[0-9a-f]{64}' -type f -mtime +30 -delete 2>/dev/null
  # flock files (lock.*, pending/*.lock) are NEVER unlinked — unlink+recreate
  # splits the lock domain; empty-inode growth is accepted.
  find "$pending_root" -mindepth 1 -type d -empty -mmin +60 -delete 2>/dev/null
  if (( $(stat -c%s "$state_dir/events.jsonl" 2>/dev/null || echo 0) > 5242880 )); then
    mv -f "$state_dir/events.jsonl" "$state_dir/events.jsonl.1"
  fi
  # Absolute paths only: a relative path would make find_project_root loop
  # forever ($dirname "." == ".") while holding a slot.
  [[ -n "$agent_id" && "$file_path" == /* && -f "$file_path" ]] || exit 0
  fhash=$(printf '%s' "$file_path" | sha256sum | cut -d' ' -f1)
  fname=$(basename "$file_path")

  # Per-file singleflight + one-waiter coalescing. A dead waiter (pid check) is
  # taken over rather than poisoning the file; the takeover race can double-run
  # once (accepted).
  exec 9>"$state_dir/lock.$fhash"
  if ! flock -n 9; then
    wf="$state_dir/waiter.$fhash"
    if ! (set -o noclobber; echo $$ > "$wf") 2>/dev/null; then
      wpid=$(cat "$wf" 2>/dev/null)
      if [[ -n "$wpid" ]] && kill -0 "$wpid" 2>/dev/null; then
        log worker_coalesced "$file_path" "$agent_id"
        exit 0
      fi
      echo $$ > "$wf"   # dead waiter — take over
    fi
    if ! flock -w 240 9; then
      rm -f "$wf"
      publish_pending "$agent_id" "$fhash.n$$" "Note: the async pyright check for $fname could not run (file busy). Run pyright on it manually if type-correctness matters." \
        && log worker_lock_timeout "$file_path" "$agent_id"
      exit 0
    fi
    rm -f "$wf"
  fi

  # Machine-wide concurrency slot: real semaphore, auto-released on death.
  # Short wait so the non-waiter worker's total budget (~30+125s) stays well
  # inside stopcheck's 240s hostage cap — an honest busy-notice that can still
  # be DELIVERED beats a perfect result published to an agent that already
  # stopped.
  if ! acquire_slot 30; then
    publish_pending "$agent_id" "$fhash.n$$" "Note: the async pyright check for $fname was skipped (system busy). Run pyright on it manually if type-correctness matters."
    log worker_slot_timeout "$file_path" "$agent_id"
    exit 0
  fi

  run_lint "$file_path" 120
  lint_rc=$?
  # Route findings to the file's LATEST editor, resolved AFTER the check ran
  # (an editor who arrived while we waited/ran owns the content we analyzed).
  pub=$(cat "$state_dir/editor.$fhash" 2>/dev/null)
  pub=${pub:-$agent_id}
  if (( lint_rc == 0 )); then
    if publish_pending "$pub" "$fhash" "Pyright [$fname]:
$errors"; then
      log worker_findings "$file_path" "$pub"
    else
      rm -f "$state_file"   # roll back dedup so the next edit re-fires
      log worker_write_failed "$file_path" "$pub"
    fi
  elif [[ "$lint_status" == "failed" ]]; then
    # Timeout/OOM/malformed output is NOT a clean result — say so. Notices get
    # unique names so they can never overwrite undelivered detailed findings
    # (which live at $fhash.txt and whose dedup hash is already committed).
    publish_pending "$pub" "$fhash.n$$" "Note: the async pyright check for $fname failed or timed out. Run pyright on it manually if type-correctness matters."
    log worker_failed_notice "$file_path" "$pub"
  fi
  exit 0
fi

# ------------------------------------------------------ parent / subagent ----
input=$(cat)
file_path=$(jq -r '.tool_input.file_path // empty' <<<"$input" 2>/dev/null)

# Only process Python files (stubs included); absolute paths only — a relative
# path would make find_project_root loop forever.
[[ "$file_path" =~ \.pyi?$ ]] || exit 0
[[ "$file_path" == /* && -f "$file_path" ]] || exit 0

agent_id=$(jq -r '.agent_id // empty' <<<"$input" 2>/dev/null)

if [[ "$mode" == "parent" ]]; then
  if [[ -n "$agent_id" ]]; then
    log skip_subagent "$file_path" "$agent_id"
    exit 0
  fi
  # Fail-closed budget inside the 90s hook timeout: 20s lock + 10s slot + 45s
  # pyright (+ overhead) < 90s. Any miss skips WITHOUT touching dedup state, so
  # the next edit simply retries — never a half-run near the deadline.
  fhash=$(printf '%s' "$file_path" | sha256sum | cut -d' ' -f1)
  exec 9>"$state_dir/lock.$fhash"
  flock -w 20 9 || { log parent_lock_busy "$file_path" "$agent_id"; exit 0; }
  acquire_slot 10 || { log parent_slot_busy "$file_path" "$agent_id"; exit 0; }
  if run_lint "$file_path" 45; then
    log rewake "$file_path" "$agent_id"
    echo "Pyright [$(basename "$file_path")]:" >&2
    echo "$errors" >&2
    exit 2
  fi
  [[ "$lint_status" == "failed" ]] && log parent_lint_failed "$file_path" "$agent_id"
  exit 0
fi

if [[ "$mode" == "subagent" ]]; then
  [[ -n "$agent_id" ]] || exit 0
  mkdir -p "$state_dir/inflight"
  fhash=$(printf '%s' "$file_path" | sha256sum | cut -d' ' -f1)
  # Record the latest editor for finding-routing; unique marker per spawn so
  # parallel same-file workers can't erase each other's inflight trace.
  printf '%s' "$agent_id" > "$state_dir/editor.$fhash" 2>/dev/null
  marker="$state_dir/inflight/$agent_id.$fhash.$$"
  touch "$marker"
  setsid "$0" worker "$agent_id" "$file_path" "$marker" </dev/null >/dev/null 2>&1 &
  # Launch ack (worker writes its pid into the marker): an exec-failed worker
  # must not masquerade as a running check.
  for _ in 1 2 3 4 5; do
    [[ -s "$marker" ]] && break
    sleep 0.2
  done
  if [[ -s "$marker" ]]; then
    log worker_spawned "$file_path" "$agent_id"
  else
    rm -f "$marker"
    publish_pending "$agent_id" "$fhash.n$$" "Note: the async pyright check for $(basename "$file_path") failed to launch. Run pyright on it manually if type-correctness matters."
    log worker_unacked "$file_path" "$agent_id"
  fi
  exit 0
fi

exit 0
