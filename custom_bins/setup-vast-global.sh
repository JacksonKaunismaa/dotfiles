#!/bin/bash

echo "Running assuming that cwd is ~/dotfiles"
./install.sh --tmux --zsh --extras --is-root
# Source cargo env so deploy.sh can find cargo for Rust tool builds
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
./deploy.sh
echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
echo "Finished deploying"
apt-get install -y vim
# tmux is already installed via install.sh --tmux
echo "Done installing deps!"
