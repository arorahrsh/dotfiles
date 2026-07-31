# dotfiles

## Installation

```sh
# Install dependencies
$ sudo apt-get install git vim 

# Clone the repository and install the dotfiles
$ git clone https://github.com/arorahrsh/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh && source ~/.bashrc
```

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
