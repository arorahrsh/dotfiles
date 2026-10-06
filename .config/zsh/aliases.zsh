# (N) allows a listing to be empty without a Zsh "no matches found" error.
alias l.='print -rl -- .*(N)'
alias la='ls -a'
alias ll='ls -lh'
alias ldir='print -rl -- */(N)'

# Navigation
alias 'cd..'='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias doc='cd ~/Documents'
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias dotf='cd ~/.dotfiles'

alias g='git'
alias t4='tmux new-session \; split-window -h \; split-window -v -t 1 \; split-window -v -t 2'
alias c='clear'
alias h='history'
alias path='print -rl -- "${path[@]}"'

case "$OSTYPE" in
    darwin*) alias ls='ls -G' ;;
    linux*) alias ls='ls --color=auto' ;;
esac
