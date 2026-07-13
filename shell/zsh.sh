# shellcheck shell=zsh

DOTFILES_SHELL_DIR="${${(%):-%N}:A:h}"
source "$DOTFILES_SHELL_DIR/common.sh"
unset DOTFILES_SHELL_DIR

setopt auto_cd interactive_comments

autoload -Uz compinit
mkdir -p -- "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

