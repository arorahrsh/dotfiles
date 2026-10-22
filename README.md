# dotfiles

Personal Bash, Zsh, Git, tmux, and Vim configuration for Ubuntu and macOS.

## Prerequisites

### Ubuntu

```sh
sudo apt-get update
sudo apt-get install -y bash-completion git vim
```

### macOS

Install the Xcode Command Line Tools and [Homebrew](https://brew.sh/).
The Command Line Tools provide Git for the initial clone.

```sh
xcode-select --install
```

The optional Brewfile installs Homebrew Bash, Bash completion, Git, tmux, Vim,
Starship, zsh-autocomplete, iTerm2, and the Meslo LG Nerd Font. macOS already
provides Zsh, so the Brewfile does not replace it. Homebrew Bash is not made
your login shell; use it explicitly if you want Bash 4.2+ completion. The
default dotfiles installation configures Bash. To use it from a Zsh terminal,
start Bash before
loading the Bash configuration (use `exec bash -l` if you did not install
Homebrew Bash):

```sh
exec "$(brew --prefix)/bin/bash" -l
```

## Install

```sh
git clone https://github.com/arorahrsh/dotfiles.git ~/.dotfiles
```

On macOS, optionally install the tools listed in the Brewfile before running
the dotfiles installer. `--no-upgrade` avoids upgrading tools you already have:

```sh
brew bundle --file "$HOME/.dotfiles/Brewfile" --no-upgrade
```

Then install the dotfiles:

```sh
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

## Zsh Prompt

Zsh support is opt-in and uses a customised
[Starship Tokyo Night prompt](https://starship.rs/presets/tokyo-night).
It keeps folder names readable, shows Git status and relevant language versions,
and omits the clock. Your hostname appears only over SSH; your username appears
over SSH or when running as root.

On macOS, if you skipped the Brewfile, install Starship and a Nerd Font:

```sh
brew install starship
brew install --cask font-meslo-lg-nerd-font
```

On Ubuntu, install Zsh with `sudo apt-get install -y zsh`, then follow the
[Starship installation instructions](https://starship.rs/guide/#installation)
for your release and install a [Nerd Font](https://www.nerdfonts.com/).
Select the Nerd Font in your terminal's font settings on either OS; installing
it alone does not enable it. A dark terminal background suits this preset.

Install the Zsh configuration and start a Zsh login shell:

```sh
INSTALL_ZSH=1 INSTALL_VIM_PLUGINS=0 ~/.dotfiles/install.sh
env -u ZDOTDIR zsh -l
```

The installer symlinks the tracked Starship configuration and individual Zsh
files. It does not install packages or change your login shell. Existing
home-directory Zsh startup files are left in place but are no longer loaded;
review them and put machine-specific settings in `~/.config/zsh/local.zsh`
(or `$XDG_CONFIG_HOME/zsh/local.zsh`). Oh My Zsh is not required. Without
Starship, Zsh uses the basic prompt; the Bash prompt remains unchanged.

## Zsh Autocomplete

[zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete) is optional.
When installed, matching directories appear as you type `cd test`, without
pressing Tab to display them. Press Tab to select a suggestion, Enter to accept
it, and Enter again to run the command. To search command history, type a
prefix such as `git push` and press Up to cycle through earlier commands
starting with that prefix. Down moves forward through those matches. With an
empty prompt, Up and Down navigate history normally.

On macOS, if you skipped the Brewfile:

```sh
brew install zsh-autocomplete
```

On Ubuntu (or for a pinned user-local installation on either OS):

```sh
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
git clone --depth 1 --branch 26.08.04 \
  https://github.com/marlonrichert/zsh-autocomplete.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/zsh-autocomplete"
```

The config prefers that user-local installation, then checks Homebrew and
`/usr/share/zsh-autocomplete`. Plugin code stays outside this repository; the
installer does not download it. Homebrew updates it with
`brew upgrade zsh-autocomplete`; the user-local checkout stays on the documented
release until you deliberately update it.

Restart after installing or removing the plugin:

```sh
exec zsh -l
```

When the plugin is absent or `TERM=dumb`, ordinary Tab completion remains
available. To disable live suggestions for a new shell:

```sh
DOTFILES_ZSH_AUTOCOMPLETE=0 zsh -l
```

For a custom install location, set `ZSH_AUTOCOMPLETE_PLUGIN` to the full path of
`zsh-autocomplete.plugin.zsh` before starting Zsh. A missing override path uses
ordinary completion instead. Startup controls must be set before `.zshrc`, not
in `local.zsh`, which loads last. That file can still override plugin `zstyle`
settings, such as `zstyle ':autocomplete:*' delay 0.2`.

The macOS and Ubuntu CI jobs test plugin loading, ordinary-completion
fallbacks, Tab selection, and prefix history search in an isolated terminal.
To run the same check locally with the Homebrew plugin:

```sh
python3 tests/verify-zsh.py --plugin-dir "$(brew --prefix)/share/zsh-autocomplete"
```

For a user-local checkout, pass
`"${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/zsh-autocomplete"` instead.

## Update

Pull the latest changes and rerun the installer. Correct existing symlinks and
an existing local Git identity are preserved.

```sh
cd ~/.dotfiles
git pull --ff-only
./install.sh
```

On macOS, run `brew bundle --file "$HOME/.dotfiles/Brewfile" --no-upgrade`
after pulling to install any newly listed tools without upgrading existing ones.

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
