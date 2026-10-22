#!/bin/bash

echo "Running assuming that cwd is ~/dotfiles"
./install.sh --is-root
./deploy.sh
echo "Installing uv..."
yes | curl -LsSf https://astral.sh/uv/install.sh | sh
echo "Finished deploying"
apt-get install -y vim
# tmux is already installed by install.sh
echo "Done installing deps!"

/start.sh
