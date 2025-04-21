CONFIG_DIR=$(dirname $(realpath ${(%):-%x}))
DOT_DIR=$(realpath $CONFIG_DIR/..)

# Instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export TERM="xterm-256color"

ZSH_DISABLE_COMPFIX=true
ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH=$HOME/.oh-my-zsh

plugins=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search)


source $ZSH/oh-my-zsh.sh
source $CONFIG_DIR/aliases.sh
source $CONFIG_DIR/p10k.zsh
source $CONFIG_DIR/extras.sh
source $CONFIG_DIR/key_bindings.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

add_to_path "${DOT_DIR}/custom_bins"

if [ -d "$HOME/.pyenv" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi


if [ -d "$HOME/.local/bin/micromamba" ]; then
  export MAMBA_EXE="$HOME/.local/bin/micromamba"
  export MAMBA_ROOT_PREFIX="$HOME/micromamba"
  __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__mamba_setup"
  else
      alias micromamba="$MAMBA_EXE"  # Fallback on help from mamba activate
  fi
  unset __mamba_setup
fi

FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

# only in interactive shells …
if [[ $- == *i* ]]; then

  # … and only when NOT in an SSH‐forwarded session …
  if [[ -z "$SSH_CONNECTION" ]]; then

    # … and only if systemd has actually created the socket locally …
    SOCKET="$XDG_RUNTIME_DIR/ssh-agent.socket"
    if [[ -S "$SOCKET" ]]; then
      export SSH_AUTH_SOCK="$SOCKET"
    fi

  fi
fi


export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export EDITOR=vim
export GREP_COLORS="ms=01;31:mc=01;31:sl=:cx=:fn=36:ln=32:bn=32:se=36"

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=5'

export ASK_SH_OPENAI_API_KEY=$(test -f "$HOME/.openai_api_key" && cat "$HOME/.openai_api_key" || echo "")
export ASK_SH_OPENAI_MODEL=gpt-4o-mini
eval "$(ask-sh --init)"



