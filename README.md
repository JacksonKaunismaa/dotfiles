# dotfiles

Shell (zsh/fish), tmux, vim and Claude Code setup for a Linux laptop, a Mac, and rented GPU boxes
(RunPod, Vast.ai).

## Install

```bash
./install.sh            # zsh, tmux, CLI tools, rust, claude, oh-my-zsh (skips what's already there)
./install.sh --is-root  # in a container without sudo
./install.sh --no-pkg   # no package manager: build zsh from source

./deploy.sh             # remote / cloud box
./deploy.sh --local     # laptop (also deploys scripts tagged `# DEPLOY: laptop`)
./deploy.sh --no-vim    # skip the vimrc
```

`deploy.sh` writes `~/.zshrc`, `~/.tmux.conf` and `~/.vimrc` stubs that source this repo, symlinks
every script in `custom_bins/` into `~/.local/bin/`,
deploys the Claude Code config in `config/claude/` (`deploy-claude.sh` does just that part), and
builds any Rust tools in `builds/` (here or in an overlay) if cargo is available.

An optional second checkout can be layered on top for machine-specific or private additions; see
`overlay.sh`.

The powerlevel10k prompt (`config/p10k.zsh`) uses icon glyphs, so install a
[Nerd Font](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k).
