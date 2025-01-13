#!/bin/bash

echo "Running assuming that cwd is ~/dotfiles"
./install.sh --tmux --zsh --extras --is-root
./deploy.sh
apt-get install vim

ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub

git config --global user.name "JacksonKaunismaa"
git config --global user.email "jackkaunis@gmail.com"


echo "Please add github ssh key at https://github.com/settings/ssh/new"

read -p "Once you have added your key, input repo to clone: " repo_url

cd ~

git clone "$repo_url"

repo_name=$(basename "$repo_url" .git)

cd "$repo_name"

read -p "Enter branch name (leave empty to skip checkout): " branch_name
if [ -n "$branch_name" ]; then
    git checkout "$branch_name"
fi

# Initialize and update submodules
git submodule update --init

# If a requirements.txt file exists, install the Python dependencies
if [ -f requirements.txt ]; then
    pip3 install -r requirements.txt
fi

echo "Setup complete!"

echo "Beginning stress test..."

time python3 ~/useful/stress-test.py
