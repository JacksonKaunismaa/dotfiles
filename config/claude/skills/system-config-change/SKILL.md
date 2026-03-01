---
name: system-config-change
description: Post-change checklist for system/dotfiles config changes (PipeWire, Hyprland, WireGuard, etc). Use after making any system configuration change that affects docs in claude-workbench.
---

# System Config Change — Post-Change Checklist

Run through this after any system-level config change (audio, network, desktop, drivers, etc).

## Checklist

1. **Read affected docs** — read `~/Work-Stuff/claude-workbench/CLAUDE.md` and any matching doc in `docs/` (e.g., `docs/bt-a2dp-fix.md` for audio changes). Check that the *content* still describes reality — not just that paths exist, but that descriptions, workflows, and explanations match the new state.

2. **Update CLAUDE.md** — the file has a section per subsystem. Update the relevant section: key files, key concepts, cleanup notes. Remove stale references (old scripts, renamed configs, deleted services). If the change replaced one system with another (e.g., DeepFilter → RNNoise), rewrite the section — don't just patch it.

3. **Update or create detailed docs** — if the change is non-trivial, update the matching doc in `docs/`, or create one if the diagnosis/fix was complex enough to forget.

4. **Check for stale file references** — grep for paths that no longer exist on disk:
   ```bash
   cd ~/Work-Stuff/claude-workbench
   grep -rohP '~/[^\s`]+|~/.config/[^\s`]+|~/.local/[^\s`]+' CLAUDE.md docs/*.md | sort -u | while read f; do
     expanded=$(eval echo "$f" 2>/dev/null)
     [ ! -e "$expanded" ] && echo "STALE: $f"
   done
   ```

5. **Check cleanup notes** — search for version-gated cleanup TODOs that may now be actionable:
   ```bash
   grep -n -i "cleanup\|remove.*when\|delete.*when\|≥.*ships\|fixed →" CLAUDE.md docs/*.md
   ```

6. **Verify dates** — double-check any dates you wrote are the correct year.

7. **Commit** — this repo is local-only but version-controlled. Commit the doc changes with a message that explains what changed and why.
