#!/usr/bin/env bash

############################
# install.sh
# This script creates symlinks for dotfiles and installs Vundle/Vim plugins
############################

is_sourced=0
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    is_sourced=1
fi

original_shell_options="$(set +o)"
set -euo pipefail

canonical_path() {
    local path="$1"
    local link
    local dir
    local base

    if command -v realpath >/dev/null 2>&1; then
        realpath "$path" 2>/dev/null && return
    fi

    if [ -L "$path" ]; then
        link="$(readlink "$path")"
        case "$link" in
            /*) path="$link" ;;
            *) path="$(dirname "$path")/$link" ;;
        esac
    fi

    dir="$(cd -P "$(dirname "$path")" >/dev/null 2>&1 && pwd)"
    base="$(basename "$path")"
    printf '%s/%s\n' "$dir" "$base"
}

info() {
    printf '\033[1;36m%s\033[0m\n' "$1"
}

file_header() {
    printf '\033[1;35m[%s]\033[0m\n' "$1"
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

    git config --file "$local_gitconfig" user.name "$configured_name"
    git config --file "$local_gitconfig" user.email "$configured_email"
    info "Configured Git identity in $local_gitconfig"
}

main() {
    local sourcedir
    local targetdir
    local backupdir
    local sourcefile
    local targetfile
    local file
    local -a dotfiles

    sourcedir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)" # dotfiles directory
    targetdir="$HOME"                                            # target directory
    backupdir="$HOME/.dotfiles_bkup"                             # old dotfiles backup directory

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
        sourcefile="$sourcedir/.$file"
        targetfile="$targetdir/.$file"

        file_header "$sourcefile"

        if [ ! -e "$sourcefile" ]; then
            echo "-> Missing source file $sourcefile"
            return 1
        fi

        # Existing symlink, whether valid or broken.
        if [ -L "$targetfile" ]; then
            if [ "$(canonical_path "$targetfile")" = "$(canonical_path "$sourcefile")" ]; then
                echo "-> Already correctly linked to $sourcefile"
                printf '\n'
                continue
            fi

            echo "-> Removing existing symlink $targetfile (from $(readlink "$targetfile"))"
            unlink "$targetfile"

        # move old file (not a symlink) into $backupdir
        elif [ -e "$targetfile" ]; then
            echo "-> Moving existing file $targetfile to $backupdir"
            mkdir -p "$backupdir"
            mv -f "$targetfile" "$backupdir/${file}_$(date +%Y%m%d_%H%M%S)"
        fi

        # symlink file
        echo "-> Creating symlink to $sourcefile at $targetfile"
        ln -s "$sourcefile" "$targetfile"
        printf '\n'
    done

    configure_git_identity || return 1

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

    if [ "$is_sourced" -eq 1 ]; then
        info "Sourcing $HOME/.bashrc into the current shell..."
        eval "$original_shell_options"
        # shellcheck source=/dev/null
        source "$HOME/.bashrc"
    else
        info "Dotfiles installed. Open a new shell or run: source $HOME/.bashrc"
    fi
}

if main "$@"; then
    status=0
else
    status=$?
fi

eval "$original_shell_options"
unset original_shell_options

if [ "$is_sourced" -eq 1 ]; then
    return_status="$status"
    unset is_sourced status
    unset -f canonical_path info file_header configure_git_identity main
    return "$return_status"
fi

exit "$status"
