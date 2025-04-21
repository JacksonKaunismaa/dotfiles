#!/bin/bash

echo "Running assuming that cwd is ~/dotfiles"
./install.sh --tmux --zsh --extras --is-root
./deploy.sh
echo "Installing uv..."
yes | curl -LsSf https://astral.sh/uv/install.sh | sh
echo "Finished deploying"
apt-get install -y vim
apt-get install -y screen

# Function to validate yes/no input
get_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 1;;
            [Nn]* ) return 0;;
            * ) echo "Please answer y or n.";;
        esac
    done
}


# Ask about repository cloning
if get_yes_no "Skip cloning a repository?"; then
    read -p "Input repo to clone: " repo_url
    
    # Ask where to clone
    echo "Where would you like to clone the repository?"
    echo "1) Home directory (~)"
    echo "2) Current directory"
    echo "3) Custom path"
    
    while true; do
        read -p "Enter your choice (1-3): " location_choice
        case $location_choice in
            1)
                cd ~
                break
                ;;
            2)
                break
                ;;
            3)
                read -p "Enter custom path: " custom_path
                cd "$custom_path" || exit 1
                break
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done

    git clone "$repo_url"
    repo_name=$(basename "$repo_url" .git)
    cd "$repo_name"

    # Branch checkout
    read -p "Enter branch name (leave empty to skip checkout): " branch_name
    if [ -n "$branch_name" ]; then
        git checkout "$branch_name"
    fi

    # Initialize and update submodules
    if get_yes_no "Skip initializing and updating submodules?"; then
        git submodule update --init
    fi

    # Python dependencies
    if [ -f requirements.txt ]; then
        if get_yes_no "requirements.txt found. Skip installing Python dependencies?"; then
            uv venv --python 3.11
						source .venv
						uv pip install -r requirements.txt
						uv pip install -e .
        fi
    fi
fi

echo "Setup complete!"

#if get_yes_no "Would you like to run the stress test?"; then
#    echo "Beginning stress test..."
#    time python3 $DOT_DIR/custom_bins/stress-test.py
#fi
echo "zsh" >> ~/.bashrc
# zsh
