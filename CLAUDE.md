# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository for managing ZSH, Tmux, Vim, and SSH configurations across local and remote machines. It includes custom shell utilities and setup scripts for development environments including RunPod, Vast.ai, and other cloud platforms.

## Common Commands

### Setup and Installation
```bash
# Install dependencies (oh-my-zsh, plugins)
./install.sh

# Install with specific programs on local/Linux without tmux/zsh
./install.sh --tmux --zsh --extras

# Deploy configurations
./deploy.sh              # For remote Linux machines
./deploy.sh --local      # For local Mac machines  
./deploy.sh --vim        # Include simple vimrc
```

### Cloud Platform Setup
```bash
# RunPod setup scripts
./custom_bins/runpod-serverless-setup.sh      # Serverless setup
./custom_bins/setup-runpod.sh                 # Standard RunPod setup
./custom_bins/setup-vast.sh                   # Vast.ai setup
./custom_bins/vllm-setup-runpod.sh           # VLLM on RunPod
```

### Custom Utilities
The `custom_bins/` directory contains various utilities:
- `ssh-register`: SSH connection management
- `launch-jupyter.sh`, `launch-vllm.sh`: Service launchers  
- `check-pytorch.py`, `stress-test.py`: System testing
- `tsesh`, `twin`: Terminal session management
- `usage_sum`: Storage usage analysis

## Repository Structure

### Core Configuration Files
- `config/zshrc.sh`: Main ZSH configuration sourcing all other configs
- `config/aliases.sh`: General shell aliases and functions
- `config/aliases_speechmatics.sh`: Remote-specific aliases (work environment)
- `config/tmux.conf`: Tmux configuration
- `config/vimrc`: Vim configuration
- `config/p10k.zsh`: Powerlevel10k theme configuration

### Installation Scripts
- `install.sh`: Dependency installation (oh-my-zsh, plugins, tools)
- `deploy.sh`: Configuration deployment and symlinking

### Environment Setup
The dotfiles support multiple environments:
- **Local Mac machines**: Uses homebrew, different key repeat settings
- **Remote Linux machines**: Includes work-specific aliases and paths
- **Cloud platforms**: Specialized setup scripts for RunPod, Vast.ai

### Key Features
- Powerlevel10k ZSH theme with custom singularity container detection
- Oh-my-zsh with plugins: autosuggestions, syntax-highlighting, completions
- Python environment management (pyenv, micromamba)
- FZF fuzzy finder integration
- Custom path management for development tools

## Development Environment Details

The configuration automatically detects and sets up:
- Python environments (pyenv, micromamba integration)
- Node.js environments (fnm integration) 
- Custom binary paths from `custom_bins/`
- Git configuration with user details

The repository includes specialized setups for:
- CUDA development environments
- Machine learning workflows (PyTorch, Transformers)
- Jupyter notebook environments
- SSH key management and forwarding