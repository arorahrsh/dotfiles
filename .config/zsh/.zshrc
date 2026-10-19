[[ -o interactive ]] || return 0

typeset -U path PATH fpath

# Keep history and completion caches out of the tracked configuration.
_dotfiles_zsh_state="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
_dotfiles_zsh_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
HISTSIZE=20000
SAVEHIST=10000
if (umask 077; mkdir -p -- "$_dotfiles_zsh_state"); then
    HISTFILE="$_dotfiles_zsh_state/history"
fi
setopt APPEND_HISTORY INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_SAVE_NO_DUPS

if [[ -n ${HOMEBREW_PREFIX:-} && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
    fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" "${fpath[@]}")
fi

bindkey -e
_dotfiles_autocomplete=
if [[ ${DOTFILES_ZSH_AUTOCOMPLETE:-1} != 0 && ${TERM:-dumb} != dumb ]]; then
    _dotfiles_autocomplete_candidates=(
        "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
        "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
        /usr/local/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
        /home/linuxbrew/.linuxbrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
        /usr/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
    )
    if (( ${+ZSH_AUTOCOMPLETE_PLUGIN} )); then
        _dotfiles_autocomplete_candidates=("$ZSH_AUTOCOMPLETE_PLUGIN")
    fi
    for _dotfiles_plugin in "${_dotfiles_autocomplete_candidates[@]}"; do
        if [[ -f "$_dotfiles_plugin" && -r "$_dotfiles_plugin" ]]; then
            _dotfiles_autocomplete="$_dotfiles_plugin"
            break
        fi
    done
fi

if [[ -n "$_dotfiles_autocomplete" ]]; then
    # The plugin runs compinit itself, before the first prompt.
    zstyle ':autocomplete::compinit' arguments -i
    zstyle ':autocomplete:*' delay 0.1
    source "$_dotfiles_autocomplete"
else
    autoload -Uz compinit
    # Ignore insecure completion directories while retaining compinit's checks.
    if (umask 077; mkdir -p -- "$_dotfiles_zsh_cache"); then
        compinit -i -d "$_dotfiles_zsh_cache/.zcompdump-$ZSH_VERSION"
    else
        compinit -i -D
    fi
    zmodload zsh/complist
    zstyle ':completion:*' menu select
fi
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^[OA' history-beginning-search-backward
bindkey '^[OB' history-beginning-search-forward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[3~' delete-char

source "$ZDOTDIR/aliases.zsh"
compdef g=git

if [[ ${TERM:-dumb} == dumb ]]; then
    PROMPT='%n@%m %~ %# '
else
    PROMPT='%F{green}%n@%m%f %F{blue}%~%f %(?.%F{green}.%F{red})%#%f '
fi
PROMPT2='%_> '

if [[ ${TERM:-dumb} != dumb ]] && (( $+commands[starship] )); then
    export STARSHIP_CONFIG="${STARSHIP_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml}"
    eval "$(starship init zsh)"
fi

if [[ ${TERM:-dumb} != dumb ]]; then
    autoload -Uz add-zsh-hook
    _dotfiles_set_title() {
        local title=${PWD:t}
        title=${title//[[:cntrl:]]/}
        printf '\e]0;%s\a' "$title"
    }
    add-zsh-hook precmd _dotfiles_set_title
fi

unset _dotfiles_zsh_state _dotfiles_zsh_cache
unset _dotfiles_autocomplete _dotfiles_autocomplete_candidates _dotfiles_plugin

# Machine-specific overrides take precedence over the shared defaults.
if [[ -f "$ZDOTDIR/local.zsh" && -r "$ZDOTDIR/local.zsh" ]]; then
    source "$ZDOTDIR/local.zsh"
fi
