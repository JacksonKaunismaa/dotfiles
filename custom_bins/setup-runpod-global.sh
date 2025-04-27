#!/bin/bash

echo "Running assuming that cwd is ~/dotfiles"
./install.sh --tmux --zsh --extras --is-root
./deploy.sh
echo "Installing uv..."
yes | curl -LsSf https://astral.sh/uv/install.sh | sh
echo "Finished deploying"
apt-get install -y vim
apt-get install -y screen


# Ask about repository cloning
repo_url="git@github.com:jplhughes/alm-jailbreaks.git" 
# Ask where to clone

git clone "$repo_url"
repo_name=$(basename "$repo_url" .git)
cd "$repo_name"

echo "Setup complete!"

echo "fully finished setup-runpod"

# add uv to path
source $HOME/.local/bin/env
uv venv --python 3.11
source .venv/bin/activate
uv pip install -r requirements.txt
uv pip install -e .
./scripts/ft_deps.sh

/start.sh
