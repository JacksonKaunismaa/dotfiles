#!/bin/bash
set -uo pipefail
USAGE=$(cat <<-END
    Usage: ./install.sh [OPTION]
    Install dotfile dependencies on mac, arch linux, or other linux distributions

    OPTIONS:
        --tmux       install tmux
        --zsh        install zsh
        --extras     install extra dependencies
        --is-root    run commands without sudo
        --no-pkg     skip package manager installs (for restricted environments)

    If OPTIONS are passed they will be installed
    with pacman if on arch, apt if on linux, or brew if on OSX
END
)

zsh=false
tmux=false
extras=false
force=false
is_root=false
no_pkg=false
while (( "$#" )); do
    case "$1" in
        -h|--help)
            echo "$USAGE" && exit 1 ;;
        --zsh)
            zsh=true && shift ;;
        --tmux)
            tmux=true && shift ;;
        --extras)
            extras=true && shift ;;
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

# Installing on Arch Linux with pacman
if [ "$no_pkg" = true ]; then
    echo "Skipping package manager installs (--no-pkg)"
elif [ $machine == "Arch" ]; then
    DOT_DIR=$(dirname $(realpath $0))
    maybe_sudo pacman -Syu
    [ $zsh == true ] && maybe_sudo pacman -S zsh
    [ $tmux == true ] && maybe_sudo pacman -S tmux
    
    if [ $extras == true ]; then
        maybe_sudo pacman -S ripgrep jless rustup less htop
        # Check if yay is installed, if not install it
        if ! command -v yay &> /dev/null; then
            echo "Installing yay..."
            maybe_sudo pacman -S --needed git base-devel
            git clone https://aur.archlinux.org/yay.git
            cd yay
            maybe_sudo makepkg -si
            cd ..
            rm -rf yay
        fi
        yay -S dust peco 
    fi

# Installing on other Linux distributions with apt
elif [ $machine == "Linux" ]; then
    DOT_DIR=$(dirname $(realpath $0))
    maybe_sudo apt-get update -y
    [ $zsh == true ] && maybe_sudo apt-get install -y zsh
    [ $tmux == true ] && maybe_sudo apt-get install -y tmux
    
    if [ $extras == true ]; then
        maybe_sudo apt-get install -y ripgrep less htop

				echo "Installing homebrew..."
        yes | curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash
				echo "Homebrew installed, adding to path..."
				eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

				echo "Installing rust..."
        yes | curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
				echo "Sourcing rust env..."
        . "$HOME/.cargo/env" 
        yes | cargo install 
				yes | brew install dust jless peco
    fi

# Installing on mac with homebrew
elif [ $machine == "Mac" ]; then
    yes | maybe_sudo brew install coreutils  # Mac won't have realpath before coreutils installed

    if [ $extras == true ]; then
        yes | maybe_sudo brew install ripgrep dust jless

        yes | curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        . "$HOME/.cargo/env" 
        yes | cargo install 
        yes | maybe_sudo brew install peco
    fi

    DOT_DIR=$(dirname $(realpath $0))
    [ $zsh == true ] && yes | maybe_sudo brew install zsh
    [ $tmux == true ] && yes | maybe_sudo brew install tmux
    maybe_sudo defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
    maybe_sudo defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)
    maybe_sudo defaults write -g com.apple.mouse.scaling 5.0
    maybe_sudo defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
fi

echo "Done installing basics."

# Setting up oh my zsh and oh my zsh plugins
ZSH=~/.oh-my-zsh
ZSH_CUSTOM=$ZSH/custom
if [ -d $ZSH ] && [ "$force" = "false" ]; then
    echo "Skipping download of oh-my-zsh and related plugins, pass --force to force redeownload"
else
    echo " --------- INSTALLING DEPENDENCIES ⏳ ----------- "
    rm -rf $ZSH
    yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    git clone https://github.com/romkatv/powerlevel10k.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    git clone https://github.com/zsh-users/zsh-completions \
        ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions

    git clone https://github.com/zsh-users/zsh-history-substring-search \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
    git clone https://github.com/jimeh/tmux-themepack.git ~/.tmux-themepack

    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    yes | ~/.fzf/install

    # NO_ASK_OPENAI_API_KEY=1 zsh -c "$(curl -fsSL https://raw.githubusercontent.com/hmirin/ask.sh/main/install.sh)"

    echo " --------- INSTALLED SUCCESSFULLY ✅ ----------- "
    echo " --------- NOW RUN ./deploy.sh [OPTION] -------- "
fi
