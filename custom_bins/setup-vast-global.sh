#!/bin/bash

echo "Running assuming that cwd is ~/dotfiles"
./install.sh --tmux --zsh --extras --is-root
./deploy.sh
echo "Installing uv..."
yes | curl -LsSf https://astral.sh/uv/install.sh | sh
echo "Finished deploying"
apt-get install -y vim
echo "Installing screen..."
apt-get install -y screen
echo "Done installing deps!"
