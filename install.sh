#!/bin/bash
set -uo pipefail
USAGE=$(cat <<-END
    Usage: ./install.sh [OPTION]
    Install dotfile dependencies on mac, arch linux, or other linux distributions.

    By default, installs everything (zsh, tmux, CLI tools, rust, claude, oh-my-zsh).
    Skips anything already installed. Only uses sudo for system packages.

    OPTIONS:
        --force      force redownload of oh-my-zsh and plugins
        --is-root    run commands without sudo (for containers)
        --no-pkg     skip package manager installs, build zsh from source (restricted environments)
END
)

force=false
is_root=false
no_pkg=false
while (( "$#" )); do
    case "$1" in
        -h|--help)
            echo "$USAGE" && exit 1 ;;
        --force)
            force=true && shift ;;
        --is-root)
            is_root=true && shift ;;
        --no-pkg)
            no_pkg=true && shift ;;
        --) # end argument parsing
            shift && break ;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2 && exit 1 ;;
    esac
done

# Function to conditionally prepend sudo
maybe_sudo() {
    if [ "$is_root" = false ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Collect packages that need installing, then do a single sudo call for the batch
needs_install=()

check_and_collect() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        echo "$cmd already installed, skipping"
    else
        needs_install+=("$pkg")
    fi
}

operating_system="$(uname -s)"
case "${operating_system}" in
    Linux*)
        if [ -f "/etc/arch-release" ]; then
            machine=Arch
        else
            machine=Linux
        fi
        ;;
    Darwin*)    machine=Mac;;
    *)          machine="UNKNOWN:${operating_system}"
esac

if [ "$no_pkg" = true ]; then
    echo "Skipping package manager installs (--no-pkg)"

    # Local zsh install from source
    if [ -x "$HOME/.local/bin/zsh" ] && [ "$force" = false ]; then
        echo "zsh already installed at ~/.local/bin/zsh, skipping (use --force to reinstall)"
    else
        echo "Installing zsh from source to ~/.local..."
        mkdir -p ~/.local
        BUILD_DIR=$(mktemp -d -p "$HOME" .zsh-build.XXXXXX)
        ZSH_VERSION="5.9"
        ZSH_TAR="zsh-${ZSH_VERSION}.tar.xz"
        cd "$BUILD_DIR"
        curl -L "https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VERSION}/${ZSH_TAR}/download" -o "$ZSH_TAR"
        tar xf "$ZSH_TAR"
        cd "zsh-${ZSH_VERSION}"
        if ./configure --prefix="$HOME/.local" && make && make install; then
            echo "zsh built from source and installed to ~/.local/bin/zsh"
        else
            echo "Source build failed, falling back to prebuilt static binary..."
            cd "$HOME"
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)" -- -d ~/.local -q
        fi
        rm -rf "$BUILD_DIR"
        echo "make sure ~/.local/bin is in your PATH"
    fi

elif [ "$machine" == "Arch" ]; then
    check_and_collect zsh
    check_and_collect tmux
    check_and_collect rg ripgrep
    check_and_collect jless
    check_and_collect rustup
    check_and_collect less
    check_and_collect htop
    check_and_collect bat
    check_and_collect duf
    check_and_collect eza
    check_and_collect delta git-delta
    check_and_collect zoxide
    check_and_collect fd
    check_and_collect sd
    check_and_collect btop
    check_and_collect jq

    if [ ${#needs_install[@]} -gt 0 ]; then
        echo "Installing: ${needs_install[*]}"
        maybe_sudo pacman -Syu
        maybe_sudo pacman -S --needed "${needs_install[@]}"
    else
        echo "All pacman packages already installed"
    fi

    if ! command -v yay &>/dev/null; then
        echo "Installing yay..."
        maybe_sudo pacman -S --needed git base-devel
        YAY_DIR=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$YAY_DIR/yay"
        (cd "$YAY_DIR/yay" && makepkg -si)
        rm -rf "$YAY_DIR"
    fi

    needs_install=()
    check_and_collect dust
    check_and_collect peco
    if [ ${#needs_install[@]} -gt 0 ]; then
        yay -S "${needs_install[@]}"
    fi

elif [ "$machine" == "Linux" ]; then
    check_and_collect zsh
    check_and_collect tmux
    check_and_collect rg ripgrep
    check_and_collect less
    check_and_collect htop
    check_and_collect batcat bat
    check_and_collect duf
    check_and_collect delta git-delta
    check_and_collect zoxide
    check_and_collect fdfind fd-find
    check_and_collect btop
    check_and_collect jq

    if [ ${#needs_install[@]} -gt 0 ]; then
        echo "Installing: ${needs_install[*]}"
        maybe_sudo apt-get update -y
        maybe_sudo apt-get install -y "${needs_install[@]}"
    else
        echo "All apt packages already installed"
    fi

    if ! command -v brew &>/dev/null; then
        echo "Installing homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo "Homebrew installed, adding to path..."
    fi
    if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    # eza and sd aren't in default apt repos — install via cargo
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
    fi
    command -v eza &>/dev/null || cargo install eza
    command -v sd &>/dev/null || cargo install sd

    needs_install=()
    check_and_collect dust
    check_and_collect jless
    check_and_collect peco
    if [ ${#needs_install[@]} -gt 0 ]; then
        brew install "${needs_install[@]}"
    fi

elif [ "$machine" == "Mac" ]; then
    if ! command -v realpath &>/dev/null; then
        maybe_sudo brew install coreutils
    fi

    needs_install=()
    check_and_collect rg ripgrep
    check_and_collect dust
    check_and_collect jless
    check_and_collect bat
    check_and_collect duf
    check_and_collect eza
    check_and_collect delta git-delta
    check_and_collect zoxide
    check_and_collect fd
    check_and_collect sd
    check_and_collect btop
    check_and_collect jq
    check_and_collect peco

    if [ ${#needs_install[@]} -gt 0 ]; then
        maybe_sudo brew install "${needs_install[@]}"
    fi

    ! command -v zsh &>/dev/null && maybe_sudo brew install zsh
    ! command -v tmux &>/dev/null && maybe_sudo brew install tmux
    maybe_sudo defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
    maybe_sudo defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)
    maybe_sudo defaults write -g com.apple.mouse.scaling 5.0
    maybe_sudo defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
fi

echo "Done installing basics."

# Ensure local bin is in PATH for oh-my-zsh installer to find zsh
export PATH="$HOME/.local/bin:$PATH"

# Install rust (needed for cargo-installed tools and Claude Code extensions)
if ! command -v rustup &>/dev/null; then
    echo "Installing rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
    echo "rust already installed"
fi
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Install Claude Code CLI (independent of oh-my-zsh)
if ! command -v claude &>/dev/null; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "Claude Code already installed"
fi

# Setting up oh my zsh and oh my zsh plugins
ZSH=~/.oh-my-zsh
ZSH_CUSTOM=$ZSH/custom
if [ -d "$ZSH" ] && [ "$force" = "false" ]; then
    echo "Skipping download of oh-my-zsh and related plugins, pass --force to force redownload"
else
    echo " --------- INSTALLING DEPENDENCIES ⏳ ----------- "
    rm -rf "$ZSH"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    git clone https://github.com/romkatv/powerlevel10k.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    git clone https://github.com/zsh-users/zsh-completions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

    git clone https://github.com/zsh-users/zsh-history-substring-search \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
    git clone https://github.com/jimeh/tmux-themepack.git ~/.tmux-themepack

    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all

    echo " --------- INSTALLED SUCCESSFULLY ✅ ----------- "
    echo " --------- NOW RUN ./deploy.sh [OPTION] -------- "
fi
