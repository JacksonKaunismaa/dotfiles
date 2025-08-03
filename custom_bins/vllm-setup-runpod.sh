#!/bin/bash

echo "Running assuming that cwd is ~/dotfiles"
git remote remove origin
git remote add origin git@github.com:JacksonKaunismaa/dotfiles.git

./install.sh --tmux --zsh --extras --is-root
./deploy.sh
echo "Installing uv..."
yes | curl -LsSf https://astral.sh/uv/install.sh | sh
echo "Finished deploying"
apt-get install -y vim
echo "Installing screen..."
apt-get install -y screen
echo "Done installing deps!"

# add uv to path
source $HOME/.local/bin/env
rm -rf $HOME/.venv
uv venv --python 3.12 $HOME/.venv
source $HOME/.venv/bin/activate
uv pip install vllm --torch-backend=auto
uv pip install flash-attn --no-build-isolation
uv pip install transformers accelerate bitsandbytes huggingface_hub datasets fastapi uvicorn pydantic
ln -s $PWD/custom_bins/launch-vllm.sh $HOME/launch-vllm.sh

/start.sh
