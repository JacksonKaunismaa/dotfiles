#!/bin/bash

echo "Running assuming that cwd is ~/dotfiles"
./install.sh --is-root
# Set zsh as default shell so tmux new panes use it
chsh -s "$(which zsh)"
# Disable vast.ai's auto-tmux in .bashrc (our SSH config handles tmux)
touch ~/.no_auto_tmux
./deploy.sh
echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
echo "Finished deploying"
apt-get install -y vim
# tmux is already installed by install.sh
echo "Done installing deps!"
