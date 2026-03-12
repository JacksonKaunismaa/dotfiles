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

export DOT_DIR=$(dirname "$(realpath "$0")")

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



if [[ $VIM == "true" ]]; then
    echo "deploying .vimrc"
    echo "source $DOT_DIR/config/vimrc" > $HOME/.vimrc
fi

# Claude Code config
"$DOT_DIR/deploy-claude.sh"

# Build Rust tools (if cargo is available)
if command -v cargo &>/dev/null; then
    echo "building Rust tools..."
    for proj in "$DOT_DIR"/builds/*/Cargo.toml; do
        proj_dir=$(dirname "$proj")
        proj_name=$(basename "$proj_dir")
        echo "  building $proj_name..."
        (cd "$proj_dir" && cargo build --release 2>&1) || echo "  WARNING: $proj_name build failed"
    done
    echo "Rust tools built"
else
    echo "cargo not found, skipping Rust tool builds"
fi

# zshrc setup
echo "source $DOT_DIR/config/zshrc.sh" > $HOME/.zshrc
# source remote-specific aliases if they exist
if [ "$LOC" = 'remote' ] && [ -f "$DOT_DIR/config/aliases_speechmatics.sh" ]; then
    echo "source $DOT_DIR/config/aliases_speechmatics.sh" >> $HOME/.zshrc
fi
# cld alias: root gets plain claude, non-root gets dangerously-skip-permissions
if [ "$(id -u)" -eq 0 ]; then
    echo 'alias cld="claude"' >> $HOME/.zshrc
else
    echo 'alias cld="claude --dangerously-skip-permissions"' >> $HOME/.zshrc
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
