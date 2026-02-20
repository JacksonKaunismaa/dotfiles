# -------------------------------------------------------------------
# personal
# -------------------------------------------------------------------

alias zrc "cd $DOT_DIR/zsh"
alias dot "cd $DOT_DIR"
alias jp "jupyter lab"
alias hn "hostname"
alias vikeybind "vim $HOME/.config/hypr/custom/keybinds.conf"
alias hyprconf "cd $HOME/.config/hypr/custom"
alias fishconf "cd $HOME/.config/fish"
alias claude "env -u KITTY_WINDOW_ID $HOME/.local/bin/claude"
alias cld "env -u KITTY_WINDOW_ID $HOME/.local/bin/cr --dangerously-skip-permissions"

# -------------------------------------------------------------------
# general
# -------------------------------------------------------------------

alias cl "clear"

# file and directories
alias rm 'rm -i'
alias rmd 'rm -rf'
alias cp 'cp -i'
alias mv 'mv -i'
alias mkdir 'mkdir -p'

# find/read files
alias h 'head'
alias t 'tail'
# alias rl "readlink -f"
# less uses bat as a preprocessor (LESSOPEN) for syntax highlighting,
# while keeping native less features like :n/:p for multi-file navigation
alias lesser 'command less'
# fd is now the real fd-find binary (installed via pacman)
alias ff 'find . -type f -name'
alias which 'type -a'

# storage
#alias du 'du -kh' # file space
alias df 'duf'     # disk space
alias usage 'du -sh * 2>/dev/null | sort -rh'
alias dus 'du -sckx * | sort -nr'

# add to path
function add_to_path
    set p $1
    if [[ "$PATH" !  *"$p"* ]]; then
      export PATH="$p:$PATH"
		end
	end


#
#-------------------------------------------------------------
# cd
#-------------------------------------------------------------

alias c 'cd'
alias .. 'cd ..'
alias ... 'cd ../../'
alias .... 'cd ../../../'
alias .2 'cd ../../'
alias .3 'cd ../../../'
alias .4 'cd ../../../../'
alias .5 'cd ../../../../..'
# alias / 'cd /'

alias d 'dirs -v'
alias 1 'cd -1'
alias 2 'cd -2'
alias 3 'cd -3'
alias 4 'cd -4'
alias 5 'cd -5'
alias 6 'cd -6'
alias 7 'cd -7'
alias 8 'cd -8'
alias 9 'cd -9'

#-------------------------------------------------------------
# git
#-------------------------------------------------------------

alias g "git"
alias gcl "git clone"
alias ga "git add"
alias gaa "git add ."
alias gau "git add -u"
alias gc "git commit -m"
alias gpu "git push"
alias gpf "git push -f"
alias gpo 'git push origin $(git_current_branch)'
alias gpp 'git push --set-upstream origin $(git_current_branch)'

alias gg 'git gui'
alias gl 'git log'
alias glog 'git log --oneline --all --graph --decorate'

alias gf "git fetch"
alias gpl "git pull"

alias grb "git rebase"
alias grbm "git rebase master"
alias grbc "git rebase --continue"
alias grbs "git rebase --skip"
alias grba "git rebase --abort"

alias gd "git diff"
alias gdc "git diff --cached"
alias gdt "git difftool"
alias gs "git status"

alias gco "git checkout"
alias gcb "git checkout -b"
alias gcm "git checkout master"

alias grhead "git reset HEAD^"
alias grhard "git fetch origin && git reset --hard"

alias gst "git stash"
alias gstp "git stash pop"
alias gsta "git stash apply"
alias gstd "git stash drop"
alias gstc "git stash clear"

alias ggsup 'git branch --set-upstream-to origin/$(git_current_branch)'
alias gpsup 'git push --set-upstream origin $(git_current_branch)'
alias gbc 'git branch | cat'

#-------------------------------------------------------------
# tmux
#-------------------------------------------------------------

alias ta "tmux attach"
alias taa "tmux attach -t"
alias tad "tmux attach -d -t"
alias td "tmux detach"
alias ts "tmux new-session -s"
alias tl "tmux list-sessions"
alias tkill "tmux kill-server"
alias tdel "tmux kill-session -t"

#-------------------------------------------------------------
# ls
#-------------------------------------------------------------

alias l "ls -F --color=auto"                    # classify, color
alias ll "ls -l --group-directories-first"
alias la 'ls -la'                               # show hidden files
alias lx 'ls -l --sort=extension'               # sort by extension
alias lk 'ls -l --sort=size --reverse'          # sort by size, biggest last
alias lc 'ls -l --changed --sort=changed --reverse'  # sort by change time, most recent last
alias lu 'ls -l --accessed --sort=accessed --reverse' # sort by access time, most recent last
alias lt 'ls -l --sort=oldest'                  # sort by modified date, most recent last
alias ltr 'ls -l --sort=newest'                  # sort by modified date, most recent last
alias lm 'ls -la | more'                        # pipe through more
alias lr 'ls -l --tree'                         # recursive tree view
alias tree 'ls --tree'                          # tree using eza
alias ldu 'ls -la --total-size --sort=size'     # recursive size, sorted

#-------------------------------------------------------------
# env
#-------------------------------------------------------------
#-------------------------------------------------------------
# claude code
#-------------------------------------------------------------
alias fx "$HOME/go/bin/fx"
alias cc "claude-context"

alias sv "source .venv/bin/activate"
alias de "deactivate"
alias ma "micromamba activate"
alias md "micromamba deactivate"
