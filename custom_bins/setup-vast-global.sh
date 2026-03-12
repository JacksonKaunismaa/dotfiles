#!/bin/bash

echo "Running assuming that cwd is ~/dotfiles"
./install.sh --tmux --zsh --extras --is-root
# Set zsh as default shell so tmux new panes use it
chsh -s "$(which zsh)"
./deploy.sh
echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
echo "Finished deploying"
apt-get install -y vim
# tmux is already installed via install.sh --tmux
echo "Done installing deps!"
