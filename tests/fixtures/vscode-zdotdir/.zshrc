# Minimal reproduction of VS Code's injected shellIntegration-rc.zsh.
if [[ "$VSCODE_INJECTION" == 1 && -f "$USER_ZDOTDIR/.zshrc" ]]; then
  VSCODE_ZDOTDIR="$ZDOTDIR"
  ZDOTDIR="$USER_ZDOTDIR"
  . "$USER_ZDOTDIR/.zshrc"
fi

source "$DOTFILES_CONTRACT_ASSERT"
