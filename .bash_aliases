 
alias l.='ls -d .*' # Show hidden files only
alias la='ls -a'    # Show all files (including hidden ones)
alias ll='ls -l -h' # Show files in listed human readable format
alias ldir='ls -d */' # Show directories only in current path

# Easier navigation: .., ..., ...., ~ and -
alias "cd.."="cd .."
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"  # `cd` is probably faster to type though
alias -- -="cd -"

# Shortcuts
alias doc="cd ~/Documents"
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias dotf="cd ~/.dotfiles"

# Git
alias g="git"
alias gitinspect='~/Downloads/gitinspector/gitinspector.py -r --grading --format=htmlembedded --file-types=** > inspection.html'

# Tmux
alias t4="tmux new-session \; split-window -h \;  split-window -v -t 1 \;  split-window -v -t 2"

# Misc
alias path='echo -e ${PATH//:/\\n}'

alias c="clear"
alias h="history"

alias plantuml='java -jar ~/Downloads/plantuml.jar'

# alias dafny="mono /opt/dafny/Dafny.exe"

