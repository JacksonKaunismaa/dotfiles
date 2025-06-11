#!/bin/bash
git remote remove origin
git remote add origin git@github.com:JacksonKaunismaa/dotfiles.git
cd $HOME
git clone git@github.com:jplhughes/alm-jailbreaks.git
cd alm-jailbreaks
git checkout ft_synthetic_data

# add uv to path
cwd=$(pwd)
source $HOME/.local/bin/env
rm -rf $cwd/.venv
uv venv --python 3.11 $cwd/.venv
source $cwd/.venv/bin/activate
uv pip install -r $cwd/requirements.txt
uv pip install -e $cwd
$cwd/scripts/ft_deps.sh

