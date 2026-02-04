---
name: kill-frozen-agent
description: "Find and kill frozen Claude Code agents. Use when user mentions a frozen/stuck Claude window, or needs to identify which Claude process to kill."
---

# Kill Frozen Agent

**Trigger: When user has a frozen Claude Code window and needs to identify/kill it.**

This is a DANGEROUS operation. You must be rigorous and get user confirmation before killing anything.

## Step 1: Get context from the user

Ask the user for ANY identifying information about the frozen agent:
- What was the first message they sent to it?
- What project/task was it working on?
- What directory was it running in?
- Approximately when did they start it?
- Any other distinguishing features?

## Step 2: List all Claude processes with their working directories

```bash
ps aux | grep -i claude | grep -v grep | awk '{print $2, $9, $10}' | while read pid start time; do
  cwd=$(readlink -f /proc/$pid/cwd 2>/dev/null)
  echo "PID: $pid | Start: $start | Time: $time | CWD: $cwd"
done
```

## Step 3: Identify candidate sessions

For the relevant project directory, find the sessions:

```bash
ls -la ~/.claude/projects/-<project-path-with-dashes>/
```

Session files are `.jsonl` files. Check their sizes and modification times:
- Large files (hundreds of MB) = long-running sessions
- Recently modified = actively working
- Not modified in a while = potentially frozen

## Step 4: Match sessions to user's description

For each candidate session, check the first user message:

```bash
head -100 <session-file>.jsonl | grep -o '"role":"user","content":"[^"]*"' | head -1
```

Or extract more carefully:
```bash
head -20 <session-file>.jsonl | grep -o '"content":"[^"]*"' | head -3
```

## Step 5: Verify CPU activity

Check which processes are actually working vs frozen:

```bash
top -b -n 1 -p <pid1>,<pid2> | tail -5
```

- High CPU (50%+) = actively working
- 0% CPU = frozen/idle

## Step 6: Check file descriptors

See what session files each process has open:

```bash
ls -la /proc/<pid>/fd/ | grep -E '\.jsonl|\.json'
```

Processes actively working on a session will have task files open for that session ID.

## Step 7: Verify command line

```bash
cat /proc/<pid>/cmdline | tr '\0' ' '; echo
```

- `--resume` = resumed an existing session
- No `--resume` = fresh start

## Step 8: Present evidence to user

Create a summary table with ALL evidence:

| Evidence | PID X (suspected frozen) | PID Y (suspected good) |
|----------|--------------------------|------------------------|
| CPU usage | X% | Y% |
| First message | "..." | "..." |
| Session last modified | time | time |
| Session size | X KB | Y MB |
| File descriptors | description | description |
| Command line | ... | ... |

## Step 9: Get EXPLICIT confirmation

**NEVER kill without explicit user confirmation.**

Ask: "Based on this evidence, I believe PID X is the frozen agent. Are you 100% certain you want me to kill it?"

Wait for explicit "yes" or confirmation.

## Step 10: Kill the process

First try graceful kill:
```bash
kill <pid>
```

Verify it's dead:
```bash
ps aux | grep <pid> | grep -v grep
```

If still alive, force kill:
```bash
kill -9 <pid>
```

Verify again and confirm to user.

## Safety Rules

1. **NEVER kill a process without explicit user confirmation**
2. **NEVER kill based on guesswork** - must have concrete evidence
3. **Always show ALL evidence** before asking for confirmation
4. **When in doubt, ask more questions** rather than risk killing the wrong process
5. **The working agent is precious** - it may have hours of context and work
