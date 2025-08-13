#!/bin/bash
apt-get update
apt-get install git curl

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
uv pip install transformers transformer_lens torch optimum peft ipykernel logbar threadpoolctl tokenicer device_smi Pillow 
uv pip install pynvml
cu_ver=$(python3 -c "import pynvml; pynvml.nvmlInit(); ver = str(pynvml.nvmlSystemGetCudaDriverVersion()); print(ver[:2]+'-'+ver[3])")

apt-get install cuda-nvcc-$cu_ver
apt-get install cuda-libraries-dev-$cu_ver

uv pip install gptqmodel --no-build-isolation
