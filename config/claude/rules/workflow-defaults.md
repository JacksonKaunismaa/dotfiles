# Workflow Defaults

## File creation

- Prefer editing existing files over creating new ones.
- Don't create documentation (`*.md`) unless asked.
- Don't create ambiguous file variants (no `-simple`, `-updated`, `-new`, `-final` suffixes). Edit the existing file. If a new version is genuinely needed, use clear ordering (`-v2`, `-v3`, or timestamps). Ask if uncertain.
- **Temporary storage:** Use project-local `./tmp/` or `scratch/`, not system `/tmp`, for anything potentially large. On this host `/tmp` and `/dev/shm` are RAM-backed tmpfs and count against Claude's cgroup memory limit. Before downloading, copying, or generating any file larger than 500 MB—or a batch larger than 500 MB total—check the expected size and use a verified disk-backed location. System `/tmp` remains fine for small temporary files.

## Shell commands

- Use a subagent for verbose output (scripts, builds, tests, logs).
- Direct execution is fine for `git status`, `ls`, `pwd`, simple commands.
- Check `history` before running `.sh` / `.py` scripts to match my typical args.
- `tee` doesn't create parent directories — `mkdir -p dir/` first.
- **Piped output appears stuck?** Upstream is block-buffering (libc switches from line to block buffering when stdout isn't a TTY). Fix with `stdbuf -oL cmd | ...` or Python's `-u`.
- Prefer command-specific limits over pipes: `git log -n 10`, not `git log | head -10`.
## Skill invocation

Use the fully-qualified skill name from the available-skills list — the exact string including the colon namespace. The Skill tool's built-in examples show short names like `skill: "commit"` but those don't work for plugin skills. Plugin skills require `namespace:name`.

| Wrong | Right |
|-------|-------|
| `skill: "commit"` | `skill: "commit-commands:commit"` |
| `skill: "commit-push-pr"` | `skill: "commit-commands:commit-push-pr"` |
| `skill: "clean_gone"` | `skill: "commit-commands:clean_gone"` |
| `skill: "brainstorm"` | `skill: "superpowers:brainstorming"` |

Copy the skill name verbatim from the available-skills list. The colon is part of the name, not an optional separator.

## Mid-implementation checkpoints

After exploring/reading code and before writing changes, when the task touches 3+ files or unfamiliar code, do a quick inline checkpoint:

1. **Current state**: what the code does now (1–2 sentences).
2. **Goal mapping**: how planned changes achieve the objective.
3. **Risky assumptions**: what I'm assuming that could be wrong (explicit list).
4. **Scope**: files that will be touched.

Skip when: single-file change, code already read this session, or user says "just do it".

## Pipeline requirements

- **High-frequency progress logging** — log every unit of work (step, batch, item) as it completes, with key state. Without it, you have to wait for the run to finish to know if it's even working — that kills iteration speed. High-frequency logs let you confirm the code's doing the right thing mid-run, get status and ETAs, and debug without re-running.
- **Save intermediate results to disk** — if a pipeline crashes at step N, steps 1–(N–1) should be recoverable. Resume from last checkpoint, don't restart.

## Long-running & external processes

When I ask you to kick off something that then waits on an external process (training run, eval suite, big upload):

- **Clear the immediate failures first.** Verify everything that runs right away — imports, config, the first batch — actually works before retiring to check-ins. Don't schedule a 20-min wakeup on a run that errors in the first 5 seconds.
- **Read real samples — before *and* during the run.** Before scaling, read 3–5 real inputs (as the pipeline sees them) and their outputs yourself, in full — no truncation, no keyword/regex stand-ins for looking. Then spot-check on a backoff: read several of the earliest samples to catch early breakage, and as they keep looking reasonable, check less and less often. You read far faster than any human — spend that speed keeping runs clean; one honest look catches most doomed runs.
- **Then check in autonomously**, starting frequent and easing off as confidence grows. Use `ScheduleWakeup` / the `/loop` skill to self-pace rather than hardcoding a fixed cadence — let how fast the state actually changes set the interval.
- Progress logs (see Pipeline requirements above) are what make remote check-ins cheap — lean on them instead of re-running to find status.

## Output strategy

Programmatic > contextual. Code is reproducible; conversation context is not.

- Generate code/scripts rather than relying on previous context or memory.
  - If a task will be repeated, write a script.
  - If results need verification, produce checkable artifacts.
  - If values come from earlier in conversation, re-derive them programmatically.
- Non-destructive outputs — don't overwrite previous results:
  - Experiment outputs → timestamped dirs (`results/{experiment}/{variant}_{YYYYMMDD_HHMMSS}_{git_hash}/`)
  - Data files → append mode (`>>`) or versioned naming (`-v2`, `-v3`)
  - Figures/tables → new timestamped files; symlink "latest" if needed
  - Analysis results → JSONL append, not JSON overwrite
