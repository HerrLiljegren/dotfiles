# shellcheck shell=zsh

DOTFILES_SHELL_DIR="${${(%):-%N}:A:h}"
DOTFILES_ROOT="${DOTFILES_SHELL_DIR:h}"

source "$DOTFILES_SHELL_DIR/common.sh"
source "$DOTFILES_SHELL_DIR/zsh/history.zsh"
source "$DOTFILES_SHELL_DIR/zsh/completion.zsh"
source "$DOTFILES_SHELL_DIR/zsh/integrations.zsh"
source "$DOTFILES_SHELL_DIR/zsh/keybindings.zsh"

DOTFILES_PERSONAL_ZSH="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/personal.zsh"
if [[ -r "$DOTFILES_PERSONAL_ZSH" ]]; then
  source "$DOTFILES_PERSONAL_ZSH"
fi
unset DOTFILES_PERSONAL_ZSH

# Interactive plugins load last so they can wrap every registered ZLE widget.
source "$DOTFILES_SHELL_DIR/zsh/plugins.zsh"

unset DOTFILES_ROOT
unset DOTFILES_SHELL_DIR
