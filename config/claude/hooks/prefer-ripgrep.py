#!/usr/bin/env python3
# PreToolUse hook for Bash:
#   1. HARD BLOCK on patterns known to OOM NFA-backtracking regex engines —
#      specifically `grep -o` combined with two bounded `.{0,N}` / `[^X]{0,N}`
#      quantifiers. Caused a 10 GB OOM on 2026-05-22 (3 GB in 60 s against a
#      1.3 MB file via bundled ugrep). Applies to ANY grep flavor (bundled,
#      \grep, command grep, /usr/bin/grep) — GNU grep is the same category of
#      bug, just lower intensity. The fix is `rg -ao 'SAME_REGEX' FILE`.
#   2. SOFT NUDGE on any other grep call, with diminishing returns
#      (1st, 6th, 16th, 31st, 51st, 76th, … — gaps 5, 10, 15, 20, …).
# Counter is per-session via session_id; state under XDG_CACHE_HOME.
import json
import os
import re
import sys
import time
from pathlib import Path

CLEANUP_MAX_AGE_SECS = 30 * 24 * 3600  # 30 days


def state_dir() -> Path:
    override = os.environ.get("CLAUDE_RIPGREP_STATE_DIR")
    if override:
        return Path(override)
    base = os.environ.get("XDG_CACHE_HOME") or os.path.join(
        os.environ.get("HOME", "/tmp"), ".cache"
    )
    return Path(base) / "claude-prefer-ripgrep"


def state_path(session_id: str) -> Path:
    return state_dir() / f"{session_id}.json"


def read_state(session_id: str) -> dict:
    try:
        return json.loads(state_path(session_id).read_text())
    except (FileNotFoundError, ValueError, json.JSONDecodeError):
        return {}


def write_state(session_id: str, state: dict) -> None:
    d = state_dir()
    d.mkdir(parents=True, exist_ok=True)
    state["ts"] = time.time()
    try:
        state_path(session_id).write_text(json.dumps(state))
    except OSError:
        pass


def cleanup_old_state_files() -> None:
    d = state_dir()
    if not d.is_dir():
        return
    now = time.time()
    for f in d.iterdir():
        if not f.is_file():
            continue
        try:
            if now - f.stat().st_mtime > CLEANUP_MAX_AGE_SECS:
                f.unlink()
        except OSError:
            continue


# --- OOM-pattern detector ---------------------------------------------------
# Match the OOM-class regex: `-o` flag (incl. combined short flags like -aoE)
# AND two bounded `.{0,N}` or `[^X]{0,N}` quantifiers in the same command.
RE_O_FLAG = re.compile(r'(?:^|\s)-[a-zA-Z]*o[a-zA-Z]*(?=\s|$|=)|--only-matching')
# Negated-class regex: [^X]. `]` immediately after `^` is a literal (POSIX),
# so we accept an optional leading `]` before the non-`]` body. Otherwise
# `[^]]` (the dangerous "any byte but `]`" shape) slips past detection.
_NEG_CLASS = r'\[\^\]?[^\]]*\]'
_BOUNDED = r'\{[0-9]*,[0-9]+\}'
RE_TWO_DANGER = re.compile(
    rf'(?:\.|{_NEG_CLASS}){_BOUNDED}.*?(?:\.|{_NEG_CLASS}){_BOUNDED}'
)


def is_oom_pattern(cmd: str) -> bool:
    return bool(RE_O_FLAG.search(cmd)) and bool(RE_TWO_DANGER.search(cmd))


def is_trigger(c: int) -> bool:
    # Triggers at C where (C - 1) == 5 * N * (N + 1) / 2 for some N >= 0.
    x = c - 1
    if x < 0 or x % 5 != 0:
        return c == 1
    k = (x * 2) // 5  # = N*(N+1)
    n = int(((1 + 4 * k) ** 0.5 - 1) / 2 + 0.5)
    return n * (n + 1) == k


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return

    cmd = data.get("tool_input", data.get("input", {})).get("command", "")

    # Skip when the command obviously embeds a script body — heredocs and
    # `python -c "..."` literals contain text that may look like grep
    # invocations but won't actually run that way. Trust the user/agent
    # for those; the block is for accidental direct invocations.
    is_script_embed = "<<" in cmd or re.search(r"\bpython\d*\s+-c\b", cmd)

    # ---- HARD BLOCK: OOM-class regex pattern on ANY grep flavor ----
    # GNU grep also uses NFA backtracking and can OOM on the pathological
    # shape (observed 200 MB on a 1.3 MB file with today's incident regex).
    # Only rg is structurally safe. So we block all grep variants, not just
    # the bundled-ugrep shadow.
    broad_match = re.search(r"\b(\w*grep)\b\s", cmd)
    if (broad_match and broad_match.group(1) != "pgrep"
            and is_oom_pattern(cmd) and not is_script_embed):
        print(
            "BLOCKED: 'grep -o' with nested .{0,N} / [^X]{0,N} quantifiers "
            "triggers catastrophic memory growth in NFA-backtracking regex "
            "engines. The bundled ugrep allocated 3 GB in 60s against a 1.3 MB "
            "file on 2026-05-22; GNU grep (/usr/bin/grep, command grep, \\grep) "
            "is the same category of bug at lower intensity — 200 MB on the "
            "same input, and potentially OOM-prone on larger ones.\n"
            "\n"
            "Rewrite as:\n"
            "  rg -ao 'YOUR_REGEX' FILE      # same regex, same matches\n"
            "\n"
            "rg's default engine is DFA-based with linear-time matching "
            "guarantees, so this category of pathology structurally cannot "
            "occur. No grep flavor (bundled, GNU, BSD) is a safe substitute.\n"
            "\n"
            "Notes:\n"
            "  - If you actually want LINE context: rg -C N 'KEYWORD' FILE\n"
            "  - If you genuinely need lookaround/backrefs (rare): "
            "rg -ao --pcre2 'YOUR_REGEX' FILE",
            file=sys.stderr,
        )
        sys.exit(2)

    # ---- SOFT NUDGE: only for the bundled-ugrep route ----
    # Skip explicit-intent invocations: `\grep`, `command grep`, `/usr/bin/grep`.
    # They route to GNU grep / explicit binaries — the agent has signalled they
    # know what they're invoking, no nudge needed.
    m = re.search(
        r"(?:^|[|;&(\s])(?<![\\/])(?<!command\s)(?<!builtin\s)(\w*grep)\s",
        cmd,
    )
    if not m or m.group(1) == "pgrep":
        return
    tool = m.group(1)

    session_id = data.get("session_id") or "unknown"
    session_id = re.sub(r"[^A-Za-z0-9_\-]", "_", session_id)[:64]

    is_first = not state_path(session_id).exists()
    if is_first:
        cleanup_old_state_files()

    prev = read_state(session_id)
    count = prev.get("grep_count", 0) + 1
    write_state(session_id, {"grep_count": count})

    if is_trigger(count):
        suffix = "" if count == 1 else f" ({count} grep-family calls this session)"
        extra = (
            " ugrep in particular can chew through tens of GB of RAM on large "
            "trees and has crashed the desktop before — strongly prefer rg."
            if tool == "ugrep"
            else ""
        )
        print(
            f"Reminder{suffix}: prefer 'rg' (ripgrep) over '{tool}' — faster, "
            "respects .gitignore by default, prettier output, bounded memory."
            f"{extra} No need to redo this command if '{tool}' is what you "
            "actually want.",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
    sys.exit(0)
