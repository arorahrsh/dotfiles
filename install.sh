#!/usr/bin/env bash

############################
# install.sh
# This script creates symlinks for dotfiles and installs Vundle/Vim plugins
############################

if [ -z "${BASH_VERSION:-}" ]; then
    printf 'Run this installer with Bash: bash ./install.sh\n' >&2
    return 1 2>/dev/null || exit 1
fi

is_sourced=0
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    is_sourced=1
fi

original_shell_options="$(set +o)"

info() {
    printf '\033[1;36m%s\033[0m\n' "$1"
}

file_header() {
    printf '\033[1;35m[%s]\033[0m\n' "$1"
}

link_dotfile() {
    local sourcefile="$1"
    local targetfile="$2"
    local backupdir="$3"
    local backupname="$4"
    local backupbase
    local backupfile
    local backup_index=0

    file_header "$sourcefile"

    if [ ! -f "$sourcefile" ]; then
        echo "-> Missing source file $sourcefile"
        return 1
    fi

    mkdir -p "$(dirname "$targetfile")" || return 1

    # A symlinked parent directory can already point at the source file.
    if [ "$sourcefile" -ef "$targetfile" ]; then
        echo "-> Already correctly linked to $sourcefile"
        printf '\n'
        return 0
    fi

    if [ -L "$targetfile" ]; then
        echo "-> Removing existing symlink $targetfile (from $(readlink "$targetfile"))"
        unlink "$targetfile" || return 1
    elif [ -e "$targetfile" ]; then
        mkdir -p "$backupdir" || return 1
        backupbase="$backupdir/${backupname}_$(date +%Y%m%d_%H%M%S)"
        backupfile="$backupbase"
        while [ -e "$backupfile" ] || [ -L "$backupfile" ]; do
            backup_index=$((backup_index + 1))
            backupfile="${backupbase}_$backup_index"
        done
        echo "-> Moving existing file $targetfile to $backupfile"
        mv "$targetfile" "$backupfile" || return 1
    fi

    echo "-> Creating symlink to $sourcefile at $targetfile"
    ln -s "$sourcefile" "$targetfile" || return 1
    printf '\n'
}

configure_git_identity() {
    local local_gitconfig="$HOME/.gitconfig.local"
    local configured_name
    local configured_email
    local default_name
    local default_email
    local input_name
    local input_email

    if [ -n "${GIT_IDENTITY_NAME:-}" ] || [ -n "${GIT_IDENTITY_EMAIL:-}" ]; then
        if [ -z "${GIT_IDENTITY_NAME:-}" ] || [ -z "${GIT_IDENTITY_EMAIL:-}" ]; then
            echo "GIT_IDENTITY_NAME and GIT_IDENTITY_EMAIL must be set together"
            return 1
        fi

        configured_name="$GIT_IDENTITY_NAME"
        configured_email="$GIT_IDENTITY_EMAIL"
    else
        configured_name="$(git config --file "$local_gitconfig" --get user.name 2>/dev/null || true)"
        configured_email="$(git config --file "$local_gitconfig" --get user.email 2>/dev/null || true)"

        if [ -n "$configured_name" ] && [ -n "$configured_email" ]; then
            info "Keeping existing Git identity in $local_gitconfig"
            return 0
        fi

        if [ ! -t 0 ]; then
            info "Skipping Git identity setup in a non-interactive shell"
            return 0
        fi

        default_name="${configured_name:-$(git config --file "$HOME/.gitconfig" --no-includes --get user.name 2>/dev/null || true)}"
        default_email="${configured_email:-$(git config --file "$HOME/.gitconfig" --no-includes --get user.email 2>/dev/null || true)}"

        if ! IFS= read -r -p "Git user name${default_name:+ [$default_name]}: " input_name; then
            echo "Unable to read Git user name"
            return 1
        fi

        if ! IFS= read -r -p "Git user email${default_email:+ [$default_email]}: " input_email; then
            echo "Unable to read Git user email"
            return 1
        fi

        configured_name="${input_name:-$default_name}"
        configured_email="${input_email:-$default_email}"

        if [ -z "$configured_name" ] || [ -z "$configured_email" ]; then
            echo "Git user name and email cannot be empty"
            return 1
        fi
    fi

    git config --file "$local_gitconfig" user.name "$configured_name" || return 1
    git config --file "$local_gitconfig" user.email "$configured_email" || return 1
    info "Configured Git identity in $local_gitconfig"
}

main() {
    local sourcedir
    local targetdir
    local backupdir
    local configdir
    local file
    local -a dotfiles
    local -a zshfiles

    sourcedir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)" # dotfiles directory
    targetdir="$HOME"                                            # target directory
    backupdir="$HOME/.dotfiles_bkup"                             # old dotfiles backup directory

    case "${INSTALL_ZSH:-0}" in
        0|1) ;;
        *) echo "INSTALL_ZSH must be 0 or 1"; return 1 ;;
    esac

    zshfiles=(.zprofile .zshrc aliases.zsh local.example.zsh)
    if [ "${INSTALL_ZSH:-0}" = "1" ]; then
        configdir="${XDG_CONFIG_HOME:-$HOME/.config}"
        case "$configdir" in
            /*) ;;
            *) echo "XDG_CONFIG_HOME must be an absolute path"; return 1 ;;
        esac
        command -v zsh >/dev/null 2>&1 || {
            echo "zsh is required when INSTALL_ZSH=1"
            return 1
        }
        for file in "${zshfiles[@]}"; do
            if [ ! -f "$sourcedir/.config/zsh/$file" ]; then
                echo "Missing Zsh source file $sourcedir/.config/zsh/$file"
                return 1
            fi
        done
        if [ ! -f "$sourcedir/.zshenv" ] || [ ! -f "$sourcedir/.config/starship.toml" ]; then
            echo "Missing .zshenv or .config/starship.toml"
            return 1
        fi
    fi

    # list of files/folders to symlink in homedir
    dotfiles=(
        bash_aliases
        bash_profile
        bash_prompt
        bashrc
        gitconfig
        inputrc
        tmux.conf
        vimrc
    )

    printf '\n'
    info "Linking dotfiles from $sourcedir to $targetdir, backing up in $backupdir"
    printf '\n'

    for file in "${dotfiles[@]}"; do
        link_dotfile "$sourcedir/.$file" "$targetdir/.$file" "$backupdir" "$file" || return 1
    done

    configure_git_identity

    if [ "${INSTALL_ZSH:-0}" = "1" ]; then
        for file in "${zshfiles[@]}"; do
            link_dotfile "$sourcedir/.config/zsh/$file" "$configdir/zsh/$file" \
                "$backupdir" "zsh_${file#.}" || return 1
        done
        link_dotfile "$sourcedir/.config/starship.toml" "$configdir/starship.toml" \
            "$backupdir" "starship.toml" || return 1

        for file in .zprofile .zshrc .zlogin .zlogout; do
            if [ -e "$targetdir/$file" ] || [ -L "$targetdir/$file" ]; then
                info "Keeping $targetdir/$file; Zsh will read startup files from $configdir/zsh instead."
                info "Review it for settings to transfer to the new configuration or local.zsh."
            fi
        done

        # Activate the new startup location only after its files are in place.
        link_dotfile "$sourcedir/.zshenv" "$targetdir/.zshenv" "$backupdir" "zshenv" || return 1
        info "Zsh configuration installed. Try it with: env -u ZDOTDIR zsh -l"
        if ! command -v starship >/dev/null 2>&1; then
            info "Starship is not installed; Zsh will use its basic prompt."
        fi
    fi

    if [ "${INSTALL_VIM_PLUGINS:-1}" = "1" ]; then
        command -v git >/dev/null 2>&1 || {
            echo "git is required to install Vundle"
            return 1
        }

        command -v vim >/dev/null 2>&1 || {
            echo "vim is required to install Vundle plugins"
            return 1
        }

        # clone Vundle
        if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
            info "Cloning Vundle into $HOME/.vim/bundle/Vundle.vim"
            mkdir -p "$HOME/.vim/bundle"
            git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
            printf '\n'
        fi

        # install Vundle plugins
        info "Installing Vundle plugins"
        printf '\n'
        vim +PluginInstall +qall
    else
        info "Skipping Vim plugin installation"
    fi

}

if [ "$is_sourced" -eq 1 ]; then
    # Run the install with strict mode without changing the caller's shell options.
    set +e
    (
        set -euo pipefail
        main "$@"
    )
    status=$?

    eval "$original_shell_options"

    if [ "$status" -eq 0 ]; then
        info "Sourcing $HOME/.bashrc into the current shell..."
        set +e
        # shellcheck source=/dev/null
        source "$HOME/.bashrc"
        status=$?
        eval "$original_shell_options"
    fi

    unset original_shell_options
    return_status="$status"
    unset is_sourced status
    unset -f info file_header link_dotfile configure_git_identity main
    return "$return_status"
fi

set -euo pipefail
main "$@"
info "Dotfiles installed. To reload an existing Bash session: source $HOME/.bashrc"
