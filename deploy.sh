#!/bin/bash
set -uo pipefail
USAGE=$(cat <<-END
    Usage: ./deploy.sh [OPTIONS], eg. ./deploy.sh --local --vim
    Creates ~/.zshrc and ~/.tmux.conf with location
    specific config

    OPTIONS:
        --local                 deploy local config only, only common aliases are sourced
        --vim                   deploy very simple vimrc config 
END
)

export DOT_DIR=$(dirname $(realpath $0))

LOC="remote"
VIM="false"
while (( "$#" )); do
    case "$1" in
        -h|--help)
            echo "$USAGE" && exit 1 ;;
        --local)
            LOC="local" && shift ;;
        --vim)
            VIM="true" && shift ;;
        --) # end argument parsing
            shift && break ;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2 && exit 1 ;;
    esac
done


echo "deploying on $LOC machine..."

# Tmux setup
echo "source $DOT_DIR/config/tmux.conf" > $HOME/.tmux.conf

# screen setup
cp $DOT_DIR/config/screenrc $HOME/.screenrc


if [[ $VIM == "true" ]]; then
    echo "deploying .vimrc"
    echo "source $DOT_DIR/config/vimrc" > $HOME/.vimrc
fi

# zshrc setup
echo "source $DOT_DIR/config/zshrc.sh" > $HOME/.zshrc
# conifg/aliases_speechmatics.sh adds remote specific aliases and cmds
[ $LOC = 'remote' ] &&  echo \
    "source $DOT_DIR/config/aliases_speechmatics.sh" >> $HOME/.zshrc

# Removed since we do agent forwarding now
#ssh-keygen -t ed25519
#cat ~/.ssh/id_ed25519.pub

git config --global user.name "JacksonKaunismaa"
git config --global user.email "jackkaunis@protonmail.com"

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
