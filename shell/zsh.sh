# shellcheck shell=zsh

DOTFILES_SHELL_DIR="${${(%):-%N}:A:h}"
source "$DOTFILES_SHELL_DIR/common.sh"
unset DOTFILES_SHELL_DIR

setopt auto_cd interactive_comments
alias reload='exec zsh'

HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt share_history


autoload -Uz compinit
mkdir -p -- "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v wt >/dev/null 2>&1; then
  eval "$(wt config shell init zsh)"
fi
