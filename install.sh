#!/bin/bash

############################
# install.sh
# This script creates symlinks for dotfiles and installs Vundle/Vim plugins
############################

sourcedir="$HOME/.dotfiles"       # dotfiles directory
targetdir="$HOME"                 # target directory
backupdir="$HOME/.dotfiles_bkup"  # old dotfiles backup directory

# list of files/folders to symlink in homedir
dotfiles="bash_aliases bash_profile bash_prompt bashrc git-completion.bash gitconfig inputrc tmux.conf vimrc"

echo ""
echo -e "\033[1;36mLinking dotfiles from $sourcedir to $targetdir, backing up in $backupdir\033[0m"
echo ""

for file in $dotfiles; do
    sourcefile="$sourcedir/.$file"
    targetfile="$targetdir/.$file"

    echo -e "\033[1;35m[$sourcefile]\033[0m"

    # check if file does not exist
    if [ ! -e $targetfile ]; then
        : # do nothing, just wait

    # move old file (not a symlink) into $backupdir
    elif [ ! -h $targetfile ]; then
        echo "-> Moving existing file $targetdir/$file to $backupdir"
        mkdir -p $backupdir
        mv -f $targetfile "$backupdir/$file_$(date +%F_%T)"

    # check symlink already linked correctly
    elif [ "$(readlink -f $targetfile)" == $sourcefile ]; then
        echo "-> Already corrrectly linked to $sourcefile"
        echo ""
        continue

    # otherwise: remove old symlink
    else
        echo "-> Removing existing symlink $targetfile (from $(readlink -f $targetfile))"
        unlink $targetfile
    fi

    # symlink file
    echo "-> Creating symlink to $sourcefile at $targetfile"
    ln -s $sourcefile $targetfile
    echo ""
done

# clone Vundle
if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
    echo -e "\033[1;36mCloning Vundle into ~/.vim/bundle/Vundle.vim\033[0m"
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    echo ""
fi

# install Vundle plugins
echo -e "\033[1;36mInstalling Vundle plugins\033[0m"
echo ""
vim +PluginInstall +qall

# source bashrc
echo -e "\033[1;36mSourcing bashrc...\033[0m"
#source ~/.bashrc # TODO: does not work
