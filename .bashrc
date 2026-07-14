
# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

_dotfiles_source_first() {
    local file

    for file in "$@"; do
        if [ -r "$file" ] && [ -f "$file" ]; then
            source "$file"
            return 0
        fi
    done

    return 1
}

if command -v brew >/dev/null 2>&1; then
    _dotfiles_brew_prefix="$(brew --prefix 2>/dev/null)"
else
    _dotfiles_brew_prefix=""
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    _dotfiles_source_first \
        /usr/share/bash-completion/bash_completion \
        /etc/bash_completion \
        "${_dotfiles_brew_prefix}/etc/profile.d/bash_completion.sh" \
        /opt/homebrew/etc/profile.d/bash_completion.sh \
        /usr/local/etc/profile.d/bash_completion.sh
fi

# Load the shell dotfiles
for file in ~/.bash_{prompt,aliases}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Allow completion for git commands
if ! declare -F __git_complete >/dev/null 2>&1; then
    _dotfiles_source_first \
        "${_dotfiles_brew_prefix}/etc/bash_completion.d/git-completion.bash" \
        /opt/homebrew/etc/bash_completion.d/git-completion.bash \
        /usr/local/etc/bash_completion.d/git-completion.bash \
        /usr/share/bash-completion/completions/git \
        /usr/share/git/completion/git-completion.bash
fi

# Enable tab completion for `g` by marking it as an alias for `git`
if declare -F __git_complete >/dev/null 2>&1; then
    if declare -F __git_main >/dev/null 2>&1; then
        __git_complete g __git_main
    elif declare -F _git >/dev/null 2>&1; then
        __git_complete g _git
    fi
fi

unset _dotfiles_brew_prefix
unset -f _dotfiles_source_first
