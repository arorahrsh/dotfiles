typeset -U path PATH

# Find Homebrew even when a fresh login has not added it to PATH yet.
if (( $+commands[brew] )); then
    eval "$(brew shellenv)"
else
    for _dotfiles_brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [[ -x "$_dotfiles_brew" ]]; then
            eval "$("$_dotfiles_brew" shellenv)"
            break
        fi
    done
    unset _dotfiles_brew
fi

if [[ -d "$HOME/.local/bin" ]]; then
    path=("$HOME/.local/bin" "${path[@]}")
fi
