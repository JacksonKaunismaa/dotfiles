# Fish shell configuration file
set CONFIG_DIR (dirname (realpath (status --current-filename)))
set DOT_DIR (realpath $CONFIG_DIR/..)

# Set terminal type
set -gx TERM "xterm-256color"

# Source configuration files if they exist
if test -f $CONFIG_DIR/aliases.fish
    source $CONFIG_DIR/aliases.fish
end

if test -f $CONFIG_DIR/extras.fish
    source $CONFIG_DIR/extras.fish
end

# FZF integration for Fish
if test -f ~/.config/fish/functions/fzf_key_bindings.fish
    source ~/.config/fish/functions/fzf_key_bindings.fish
end

# Add custom bins to path
fish_add_path $DOT_DIR/custom_bins

# Pyenv setup
if test -d $HOME/.pyenv
    set -gx PYENV_ROOT $HOME/.pyenv
    fish_add_path $PYENV_ROOT/bin
    if command -v pyenv >/dev/null
        pyenv init - | source
    end
end


# FNM (Fast Node Manager) setup
set FNM_PATH $HOME/.local/share/fnm
if test -d $FNM_PATH
    fish_add_path $FNM_PATH
    fnm env --shell fish | source
end

# SSH agent setup for interactive sessions only
if status is-interactive
    if test -z "$SSH_CONNECTION"
        set SOCKET $XDG_RUNTIME_DIR/ssh-agent.socket
        if test -S $SOCKET
            set -gx SSH_AUTH_SOCK $SOCKET
        end
    end
end

# Add common paths
fish_add_path $HOME/bin $HOME/.local/bin $HOME/.cargo/bin

# Environment variables
set -gx EDITOR vim
set -gx GREP_COLORS "ms=01;31:mc=01;31:sl=:cx=:fn=36:ln=32:bn=32:se=36"

# Set file descriptor limit
ulimit -n 16384
