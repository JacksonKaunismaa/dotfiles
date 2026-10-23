#!/bin/bash
set -uo pipefail
# Deploy Claude Code config only (settings, hooks, rules, skills, docs, etc.)
# Called by deploy.sh, or run standalone to redeploy just Claude config.

DOT_DIR="${DOT_DIR:-$(dirname "$(realpath "$0")")}"
. "$DOT_DIR/overlay.sh"

mkdir -p $HOME/.claude
ln -sf $DOT_DIR/config/claude/CLAUDE.md $HOME/.claude/CLAUDE.md
# hooks/skills/rules/docs/templates/output-styles: a symlink to this repo's dir — or, when the
# overlay has the same dir, a real dir with one symlink per entry from both (overlay wins).
# rm -rf first: ln -sf doesn't replace directories (on a dir of symlinks it removes only links).
link_claude_dir() {
    local name=$1 dst="$HOME/.claude/$1" src
    rm -rf "$dst"
    if [[ -n "$DOTFILES_OVERLAY" && -d "$DOTFILES_OVERLAY/config/claude/$name" ]]; then
        mkdir -p "$dst"
        for src in "$DOT_DIR/config/claude/$name"/* "$DOTFILES_OVERLAY/config/claude/$name"/*; do
            [[ -e "$src" || -L "$src" ]] || continue
            ln -sfn "$src" "$dst/$(basename "$src")"
        done
    else
        ln -s "$DOT_DIR/config/claude/$name" "$dst"
    fi
}
for d in hooks skills rules docs templates output-styles; do link_claude_dir "$d"; done
# Generate settings.json with correct home path — but protect against silent removals
SETTINGS_LIVE="$HOME/.claude/settings.json"
SETTINGS_NEW=$(mktemp)
sed -e "s|__HOME__|$HOME|g" -e "s|__DOT_DIR__|$DOT_DIR|g" $DOT_DIR/config/claude/settings.json.template > "$SETTINGS_NEW"
# Overlay settings fragment: deep-merged in; hook groups are appended by event + matcher.
# __HOME__ / __DOT_DIR__ / __OVERLAY_DIR__ are substituted.
if [[ -n "$DOTFILES_OVERLAY" && -f "$DOTFILES_OVERLAY/config/claude/settings.overlay.json" ]]; then
    python3 - "$SETTINGS_NEW" "$DOTFILES_OVERLAY/config/claude/settings.overlay.json" "$HOME" "$DOT_DIR" "$DOTFILES_OVERLAY" <<'PYEOF' || { echo "ERROR: could not merge overlay settings — aborting settings deploy"; rm "$SETTINGS_NEW"; exit 1; }
import json, sys

new_path, frag_path, home, dot, overlay = sys.argv[1:6]
new = json.load(open(new_path))
frag = json.loads(open(frag_path).read()
                  .replace("__HOME__", home).replace("__DOT_DIR__", dot).replace("__OVERLAY_DIR__", overlay))


def merge(dst, src):
    for k, v in src.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            merge(dst[k], v)
        elif isinstance(v, list) and isinstance(dst.get(k), list):
            dst[k].extend(x for x in v if x not in dst[k])
        else:
            dst[k] = v


hooks = frag.pop("hooks", {})
merge(new, frag)
for event, groups in hooks.items():
    new_groups = new.setdefault("hooks", {}).setdefault(event, [])
    for g in groups:
        target = next((ng for ng in new_groups if ng.get("matcher", "") == g.get("matcher", "")), None)
        if target is None:
            new_groups.append(g)
        else:
            target.setdefault("hooks", []).extend(g.get("hooks", []))

with open(new_path, "w") as f:
    json.dump(new, f, indent=2)
    f.write("\n")
PYEOF
fi

# Preserve machine-local settings that installers wire into the LIVE settings.json (a local
# proxy's ANTHROPIC_BASE_URL, an apiKeyHelper, idleCompaction, an update timer's
# DISABLE_AUTOUPDATER). They're deliberately NOT in the template: a fresh machine must only get
# them from the installer that sets them up. An overlay can name more env keys to keep in
# config/claude/preserve-env.txt (one per line).
# Rule: the listed top-level/env keys, plus any hook whose command lives outside the
# dotfiles-managed ~/.claude/hooks/, are installer-owned — copy them forward from the
# live file. Dotfiles-owned hooks stay template-canonical (removal guard below).
if [ -f "$SETTINGS_LIVE" ]; then
    PRESERVE_ENV=""
    [[ -n "$DOTFILES_OVERLAY" && -f "$DOTFILES_OVERLAY/config/claude/preserve-env.txt" ]] && PRESERVE_ENV="$DOTFILES_OVERLAY/config/claude/preserve-env.txt"
    python3 - "$SETTINGS_LIVE" "$SETTINGS_NEW" "$HOME" "$PRESERVE_ENV" <<'PYEOF' || { echo "ERROR: could not merge machine-local settings from live settings.json — aborting settings deploy"; rm "$SETTINGS_NEW"; exit 1; }
import json, sys

live_path, new_path, home, preserve_env = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
live = json.load(open(live_path))
new = json.load(open(new_path))
preserved = []

# autoMode / fastMode / model: set per machine in Claude Code itself; the template only seeds a
# fresh machine
for key in ("apiKeyHelper", "idleCompaction", "autoMode", "fastMode", "model"):
    if key in live:
        new[key] = live[key]
        preserved.append(key)

extra_env = []
if preserve_env:
    extra_env = [ln.strip() for ln in open(preserve_env) if ln.strip() and not ln.startswith("#")]
for key in ("ANTHROPIC_BASE_URL", "DISABLE_AUTOUPDATER", *extra_env):
    if key in live.get("env", {}):
        new.setdefault("env", {})[key] = live["env"][key]
        preserved.append(f"env.{key}")

dotfiles_hooks = home + "/.claude/hooks/"
new_cmds = {h["command"] for groups in new.get("hooks", {}).values()
            for g in groups for h in g.get("hooks", []) if "command" in h}
for event, groups in live.get("hooks", {}).items():
    for g in groups:
        local = [h for h in g.get("hooks", [])
                 if "command" in h
                 and not h["command"].startswith(dotfiles_hooks)
                 and h["command"] not in new_cmds]
        if not local:
            continue
        new_groups = new.setdefault("hooks", {}).setdefault(event, [])
        target = next((ng for ng in new_groups
                       if ng.get("matcher", "") == g.get("matcher", "")), None)
        if target is None:
            target = {"matcher": g.get("matcher", ""), "hooks": []}
            new_groups.append(target)
        target.setdefault("hooks", []).extend(local)
        preserved.extend(f"hooks.{event}: {h['command']}" for h in local)

with open(new_path, "w") as f:
    json.dump(new, f, indent=2)
    f.write("\n")

if preserved:
    print("preserved machine-local settings from live settings.json:")
    for p in preserved:
        print(f"  - {p}")
PYEOF
fi

if [ -f "$SETTINGS_LIVE" ]; then
    # Compare hook commands: extract all "command": lines from hooks sections
    live_hooks=$(python3 -c "
import json, sys
with open('$SETTINGS_LIVE') as f:
    s = json.load(f)
hooks = s.get('hooks', {})
cmds = set()
for event, matchers in hooks.items():
    for m in matchers:
        for h in m.get('hooks', []):
            if 'command' in h:
                cmds.add(h['command'])
for c in sorted(cmds):
    print(c)
" 2>/dev/null)

    new_hooks=$(python3 -c "
import json, sys
with open('$SETTINGS_NEW') as f:
    s = json.load(f)
hooks = s.get('hooks', {})
cmds = set()
for event, matchers in hooks.items():
    for m in matchers:
        for h in m.get('hooks', []):
            if 'command' in h:
                cmds.add(h['command'])
for c in sorted(cmds):
    print(c)
" 2>/dev/null)

    removed_hooks=$(comm -23 <(echo "$live_hooks") <(echo "$new_hooks"))
    if [ -n "$removed_hooks" ]; then
        echo ""
        echo "WARNING: These hooks exist in the live settings.json but NOT in the template:"
        echo "$removed_hooks" | while read -r h; do echo "  - $h"; done
        echo ""
        echo "Deploying will REMOVE them. This is how supply-chain-guard got silently dropped."
        echo ""
        if [ -t 0 ]; then
            read -p "Overwrite settings.json anyway? [y/N] " answer
            if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
                echo "Aborted. Update settings.json.template first, then re-run."
                rm "$SETTINGS_NEW"
                exit 1
            fi
        else
            echo "Non-interactive — refusing to remove hooks. Update the template first."
            rm "$SETTINGS_NEW"
            exit 1
        fi
    fi
fi

mv "$SETTINGS_NEW" "$SETTINGS_LIVE"
# Copy ntfy.conf if it exists (not symlinked due to credentials)
if [ -f "$DOT_DIR/config/claude/ntfy.conf" ]; then
    cp $DOT_DIR/config/claude/ntfy.conf $HOME/.claude/ntfy.conf
fi
# If root, add infinite permissions (no confirmation prompts)
if [ "$(id -u)" -eq 0 ]; then
    echo "Root detected: adding full permissions to Claude Code settings"
    python3 -c "
import json
path = '$HOME/.claude/settings.json'
with open(path) as f:
    s = json.load(f)
s['permissions'] = {
    'allow': [
        # Shell & file operations
        'Bash(*)',
        'BashOutput',
        'KillShell',
        'Read',
        'Edit',
        'MultiEdit',
        'Write',
        'Glob',
        'Grep',
        'LS',
        'NotebookEdit',
        'LSP',
        # Web
        'WebFetch',
        'WebSearch',
        # Agents & orchestration
        'Agent',
        'Skill',
        'SlashCommand',
        'SendMessage',
        'Team*',
        # Tasks & planning
        'Task*',
        'TodoWrite',
        'EnterPlanMode',
        'ExitPlanMode',
        'EnterWorktree',
        'ExitWorktree',
        'AskUserQuestion',
        'ToolSearch',
        'Cron*',
        # MCP tools (wildcard all servers)
        'mcp__*',
    ],
}
with open(path, 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
"
fi
echo "deployed Claude Code config"
