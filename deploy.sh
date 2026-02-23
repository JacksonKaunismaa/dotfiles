#!/bin/bash
set -uo pipefail
USAGE=$(cat <<-END
    Usage: ./deploy.sh [OPTIONS], eg. ./deploy.sh --local
    Creates ~/.zshrc, ~/.tmux.conf, ~/.vimrc with location
    specific config

    OPTIONS:
        --local                 deploy local config only, only common aliases are sourced
        --no-vim                skip deploying vimrc
END
)

export DOT_DIR=$(dirname $(realpath $0))

LOC="remote"
VIM="true"
while (( "$#" )); do
    case "$1" in
        -h|--help)
            echo "$USAGE" && exit 1 ;;
        --local)
            LOC="local" && shift ;;
        --no-vim)
            VIM="false" && shift ;;
        --) # end argument parsing
            shift && break ;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2 && exit 1 ;;
    esac
done


echo "deploying on $LOC machine..."

# Tmux setup
echo "source $DOT_DIR/config/tmux.conf" > $HOME/.tmux.conf

# screen setup - detect zsh path and substitute
if [ -x "$HOME/.local/bin/zsh" ]; then
    ZSH_PATH="$HOME/.local/bin/zsh"
elif command -v zsh &> /dev/null; then
    ZSH_PATH="$(command -v zsh)"
else
    ZSH_PATH="/bin/zsh"
fi
sed "s|__ZSH_PATH__|$ZSH_PATH|g" $DOT_DIR/config/screenrc > $HOME/.screenrc


if [[ $VIM == "true" ]]; then
    echo "deploying .vimrc"
    echo "source $DOT_DIR/config/vimrc" > $HOME/.vimrc
fi

# Claude Code config
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
echo "deployed Claude Code config"

# zshrc setup
echo "source $DOT_DIR/config/zshrc.sh" > $HOME/.zshrc
# source remote-specific aliases if they exist
if [ $LOC = 'remote' ] && [ -f "$DOT_DIR/config/aliases_speechmatics.sh" ]; then
    echo "source $DOT_DIR/config/aliases_speechmatics.sh" >> $HOME/.zshrc
fi

# Removed since we do agent forwarding now
#ssh-keygen -t ed25519
#cat ~/.ssh/id_ed25519.pub

git config --global user.name "JacksonKaunismaa"
git config --global user.email "jackkaunis@protonmail.com"
# Global git hooks (secret scanning via gitleaks)
git config --global core.hooksPath "$DOT_DIR/config/git-hooks"

# delta as git pager (pretty diffs)
command -v delta &>/dev/null && {
  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.side-by-side true
  git config --global merge.conflictstyle diff3
}

# Function to validate yes/no input
#get_yes_no() {
#    while true; do
#        read -p "$1 (y/n): " yn
#        case $yn in
#            [Yy]* ) return 1;;
#            [Nn]* ) return 0;;
#            * ) echo "Please answer y or n.";;
#        esac
#    done
#}
#
## Ask about SSH key setup
#if get_yes_no "Would you like to add a GitHub SSH key?"; then
#    echo "Please add github ssh key at https://github.com/settings/ssh/new"
#    read -p "Press Enter once you have added your key..."
#		git config --global user.signingkey ~/.ssh/id_ed25519.pub
#		git config --global gpg.format ssh
#fi


echo "Finished deploying"
