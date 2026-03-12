#!/bin/bash
set -uo pipefail
# Deploy Claude Code config only (settings, hooks, rules, skills, docs, etc.)
# Called by deploy.sh, or run standalone to redeploy just Claude config.

DOT_DIR="${DOT_DIR:-$(dirname "$(realpath "$0")")}"

mkdir -p $HOME/.claude
ln -sf $DOT_DIR/config/claude/CLAUDE.md $HOME/.claude/CLAUDE.md
# Remove existing directories/symlinks before creating new symlinks
# (ln -sf doesn't replace directories, only files)
rm -rf $HOME/.claude/hooks $HOME/.claude/skills $HOME/.claude/rules $HOME/.claude/docs $HOME/.claude/templates
ln -s $DOT_DIR/config/claude/hooks $HOME/.claude/hooks
ln -s $DOT_DIR/config/claude/skills $HOME/.claude/skills
ln -s $DOT_DIR/config/claude/rules $HOME/.claude/rules
ln -s $DOT_DIR/config/claude/docs $HOME/.claude/docs
ln -s $DOT_DIR/config/claude/templates $HOME/.claude/templates
# Output styles (custom output style definitions)
rm -rf $HOME/.claude/output-styles
ln -s $DOT_DIR/config/claude/output-styles $HOME/.claude/output-styles
# Create saved_agents directory for agent lifecycle management
mkdir -p $HOME/.claude/saved_agents
# Generate settings.json with correct home path
sed "s|__HOME__|$HOME|g" $DOT_DIR/config/claude/settings.json.template > $HOME/.claude/settings.json
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
