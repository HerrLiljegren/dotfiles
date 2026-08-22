# shellcheck shell=bash

DOTFILES_SHELL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
. "$DOTFILES_SHELL_DIR/common.sh"
unset DOTFILES_SHELL_DIR

alias reload='exec bash'

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

if command -v wt >/dev/null 2>&1; then
  eval "$(wt config shell init bash)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd bash)"
fi

