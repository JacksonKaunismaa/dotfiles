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
. "$DOT_DIR/overlay.sh"

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

# Matplotlib style (macOS matplotlib reads ~/.matplotlib, not ~/.config/matplotlib)
mkdir -p $HOME/.config/matplotlib/stylelib
ln -sf $DOT_DIR/config/matplotlib/anthropic.mplstyle $HOME/.config/matplotlib/stylelib/anthropic.mplstyle
if [[ "$(uname)" == "Darwin" ]]; then
    mkdir -p $HOME/.matplotlib/stylelib
    ln -sf $DOT_DIR/config/matplotlib/anthropic.mplstyle $HOME/.matplotlib/stylelib/anthropic.mplstyle
fi

# Laptop-only configs.
# Note: ~/.config/hypr/custom/ is INTENTIONALLY NOT tracked here — it's
# machine-specific (paths to dots-hyprland scripts, monitor-specific binds, etc.).
# See revert commit 1c6d414 for rationale.
if [[ $LOC == "local" ]]; then
    # Micro colorschemes (currently just `transparent` for notes-scratch).
    # Portable — no machine-specific paths.
    mkdir -p $HOME/.config/micro
    if [[ -e $HOME/.config/micro/colorschemes && ! -L $HOME/.config/micro/colorschemes ]]; then
        mv $HOME/.config/micro/colorschemes $HOME/.config/micro/colorschemes.predotfiles.$(date +%s)
    fi
    ln -sfn $DOT_DIR/config/micro/colorschemes $HOME/.config/micro/colorschemes
fi

# Claude Code config
"$DOT_DIR/deploy-claude.sh"

# Build Rust tools (if cargo is available)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
if command -v cargo &>/dev/null; then
    echo "building Rust tools..."
    cargo_projects=("$DOT_DIR"/builds/*/Cargo.toml)
    [[ -n "$DOTFILES_OVERLAY" ]] && cargo_projects+=("$DOTFILES_OVERLAY"/builds/*/Cargo.toml)
    for proj in "${cargo_projects[@]}"; do
        [[ -f "$proj" ]] || continue
        proj_dir=$(dirname "$proj")
        proj_name=$(basename "$proj_dir")
        echo "  building $proj_name..."
        (cd "$proj_dir" && cargo build --release 2>&1) || echo "  WARNING: $proj_name build failed"
    done
    echo "Rust tools built"
else
    echo "cargo not found, skipping Rust tool builds"
fi

# zshrc setup (not on macOS: the Mac uses fish and has no oh-my-zsh, so a ~/.zshrc would only error)
if [[ "$(uname)" != "Darwin" ]]; then
    echo "source $DOT_DIR/config/zshrc.sh" > $HOME/.zshrc
fi

# Removed since we do agent forwarding now
#ssh-keygen -t ed25519
#cat ~/.ssh/id_ed25519.pub

git config --global user.name "JacksonKaunismaa"
git config --global user.email "jackkaunis@protonmail.com"
# Global git hooks (secret scanning via gitleaks)
git config --global core.hooksPath "$DOT_DIR/config/git-hooks"
# The global hooks include git-lfs ones: without git-lfs, pre-push exits 2 (every push blocked)
# and post-checkout errors. install.sh installs it.
if command -v git-lfs &>/dev/null; then
  git lfs install --skip-repo
else
  echo "WARNING: git-lfs not found — the global pre-push hook blocks every push until it's installed (run install.sh)"
fi
# Verify objects on every transfer; never allow the ext:: transport (runs arbitrary commands)
git config --global transfer.fsckObjects true
git config --global fetch.fsckObjects true
git config --global receive.fsckObjects true
git config --global protocol.ext.allow never

# delta as git pager (pretty diffs)
command -v delta &>/dev/null && {
  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.side-by-side true
  git config --global delta.wrap-max-lines unlimited
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


# --- custom_bins: symlink scripts into ~/.local/bin/ ---
# Scripts may declare `# DEPLOY: laptop` in their first 10 lines.
# Those only get symlinked when --local is passed (i.e. on the laptop).
# Untagged scripts get symlinked everywhere.
# On macOS, custom_bins/darwin/<name> (here or in an overlay) wins over custom_bins/<name>,
# matching the PATH order that config/zshrc.fish sets up. The DEPLOY tag is read from the
# file that gets linked.
echo "Deploying custom_bins..."
mkdir -p "$HOME/.local/bin"
bin_dirs=("$DOT_DIR/custom_bins")  # highest priority first
[[ -n "$DOTFILES_OVERLAY" ]] && bin_dirs=("$DOTFILES_OVERLAY/custom_bins" "${bin_dirs[@]}")
if [[ "$(uname)" == "Darwin" ]]; then
    bin_dirs=("$DOT_DIR/custom_bins/darwin" "${bin_dirs[@]}")
    [[ -n "$DOTFILES_OVERLAY" ]] && bin_dirs=("$DOTFILES_OVERLAY/custom_bins/darwin" "${bin_dirs[@]}")
fi
while IFS= read -r name; do
    # First directory that has this name wins
    for dir in "${bin_dirs[@]}"; do
        src="$dir/$name"
        [[ -f "$src" || -L "$src" ]] && break
    done
    # Read DEPLOY tag from first 10 lines (handles shebang on line 1)
    deploy_tag=$(head -10 "$src" 2>/dev/null | grep -oE '^# DEPLOY: [a-z]+' | head -1 | awk '{print $3}')
    if [[ "$deploy_tag" == "laptop" && "$LOC" != "local" ]]; then
        echo "  skip $name (laptop-only)"
        continue
    fi
    target="$HOME/.local/bin/$name"
    # If target exists and is already the right symlink, skip silently
    if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
        continue
    fi
    # If target exists but is something else, back it up
    if [[ -e "$target" || -L "$target" ]]; then
        mv "$target" "$target.predotfiles.$(date +%s)"
        echo "  backed up existing $name → $target.predotfiles.*"
    fi
    ln -s "$src" "$target"
    echo "  linked $name"
done < <(
    # Union of script names across bin_dirs
    for dir in "${bin_dirs[@]}"; do
        for f in "$dir"/*; do
            [[ -f "$f" || -L "$f" ]] || continue
            [[ "$(basename "$f")" == README ]] && continue
            basename "$f"
        done
    done | sort -u
)

echo "Finished deploying"

# --- overlay home/: each file is symlinked to the same path under $HOME ---
if [[ -n "$DOTFILES_OVERLAY" && -d "$DOTFILES_OVERLAY/home" ]]; then
    echo "Deploying overlay home files..."
    while IFS= read -r -d '' src; do
        rel=${src#"$DOTFILES_OVERLAY/home/"}
        mkdir -p "$HOME/$(dirname "$rel")"
        ln -sfn "$src" "$HOME/$rel"
        echo "  linked ~/$rel"
    done < <(find "$DOTFILES_OVERLAY/home" -type f -print0)
fi

# --- overlay deploy-extra.sh: machine-specific steps the overlay needs (run last) ---
if [[ -n "$DOTFILES_OVERLAY" && -x "$DOTFILES_OVERLAY/deploy-extra.sh" ]]; then
    echo "Running overlay deploy-extra.sh..."
    LOC="$LOC" DOT_DIR="$DOT_DIR" "$DOTFILES_OVERLAY/deploy-extra.sh"
fi
