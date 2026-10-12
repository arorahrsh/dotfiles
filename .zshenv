# Keep the rest of the Zsh configuration under the config directory.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Our .zshrc owns completion setup; prevent Ubuntu from running compinit first.
if [[ -o interactive ]]; then
    skip_global_compinit=1
fi
