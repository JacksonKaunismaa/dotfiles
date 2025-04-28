git clone git@github.com:jplhughes/alm-jailbreaks.git
git checkout web_interface
cd alm-jailbreaks

# add uv to path
source $HOME/.local/bin/env
rm -rf .venv
uv venv --python 3.11
source .venv/bin/activate
uv pip install -r requirements.txt
uv pip install -e .
./scripts/ft_deps.sh

