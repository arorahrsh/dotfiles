# dotfiles

Personal Bash, Git, tmux, and Vim configuration for Ubuntu and macOS.

## Prerequisites

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install -y bash-completion git vim
```

### macOS

Install the Xcode Command Line Tools and [Homebrew](https://brew.sh/), then run:

```sh
xcode-select --install
brew install bash-completion@2 git vim
```

This repository currently configures Bash, not Zsh. In a macOS terminal using
Zsh, start Bash before loading the configuration:

```sh
exec bash -l
```

## Install

```sh
git clone https://github.com/arorahrsh/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

The default install also clones Vundle and installs the Vim plugins. To install
only the dotfiles, skip that optional network-dependent step:

```sh
INSTALL_VIM_PLUGINS=0 ~/.dotfiles/install.sh
```

Open a new Bash shell after installation, or load the configuration into the
current Bash session:

```sh
source ~/.bashrc
```

## Update

Pull the latest changes and rerun the installer. Correct existing symlinks and
an existing local Git identity are preserved.

```sh
cd ~/.dotfiles
git pull --ff-only
./install.sh
```

Use `INSTALL_VIM_PLUGINS=0 ./install.sh` when you do not want to install Vim
plugins during the update.

## Backups

The installer manages these files in your home directory:

```text
.bash_aliases  .bash_profile  .bash_prompt  .bashrc
.gitconfig     .inputrc       .tmux.conf    .vimrc
```

Before replacing a real file or directory, it moves that path to
`~/.dotfiles_bkup/` with a timestamped name such as `bashrc_YYYYMMDD_HHMMSS`.
Correct symlinks are left in place; incorrect symlinks are replaced without a
backup. `~/.gitconfig.local` is never symlinked or backed up by the installer.

## Git Identity

The first interactive install asks for a Git user name and email, using the
tracked `.gitconfig` values as defaults. It writes the selected identity to
`~/.gitconfig.local`, which is not symlinked or committed. Existing local
identity values are preserved.

For non-interactive installs, set both values explicitly:

```sh
GIT_IDENTITY_NAME="Your Name" \
GIT_IDENTITY_EMAIL="you@example.com" \
~/.dotfiles/install.sh
```
