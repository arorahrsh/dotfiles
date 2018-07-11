#!/bin/bash

############################
# install.sh
# This script creates symlinks for dotfiles and installs Vundle/Vim plugins
############################

sourcedir="$HOME/.dotfiles"       # dotfiles directory
targetdir="$HOME"                 # target directory
backupdir="$HOME/.dotfiles_bkup"  # old dotfiles backup directory

# list of files/folders to symlink in homedir
dotfiles=".bash_aliases .bash_profile .bash_prompt .bashrc .git-completion.bash .gitconfig .inputrc .tmux.conf .vimrc"

echo ""
echo -e "\e[1;36mLinking dotfiles from $sourcedir to $targetdir, backing up in $backupdir\e[0m"
echo ""

for file in $dotfiles; do
    echo -e "\e[1;35m [$file]\e[0m"

    # check if file does not exist
    if [ ! -e "$targetdir/$file" ]; then
        : # do nothing, just wait

    # move old file (not a symlink) into $backupdir
    elif [ ! -h "$targetdir/$file" ]; then
        echo " -> Moving existing file $targetdir/$file to $backupdir"
        mkdir -p $backupdir
        mv -f "$targetdir/$file" "$backupdir/${file:1}_$(date +%F_%T)"

    # check symlink already linked correctly
    elif [ "$(readlink -f $targetdir/$file)" == "$sourcedir/$file" ]; then
        echo " -> Already corrrectly linked to $sourcedir/$file"
        echo ""
        continue

    # otherwise: remove old symlink 
    else
        echo " -> Removing existing symlink $targetdir/$file (from $(readlink -f $targetdir/$file))"
        unlink $targetdir/$file
    fi
    
    # symlink file
    echo " -> Creating symlink to $sourcedir/$file at $targetdir/$file"
    ln -s $sourcedir/$file $targetdir/$file
    echo ""
done

# clone Vundle
if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
    echo -e "\e[1;36mCloning Vundle into ~/.vim/bundle/Vundle.vim\e[0m"
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    echo ""
fi

# install Vundle plugins
echo -e "\e[1;36mInstalling Vundle plugins\e[0m"
echo ""
vim +PluginInstall +qall

# source bashrc
echo -e "\e[1;36mSourcing bashrc...\e[0m"
#source ~/.bashrc # TODO: does not work

