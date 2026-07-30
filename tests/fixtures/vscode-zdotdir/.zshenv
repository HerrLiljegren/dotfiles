# Minimal reproduction of VS Code's injected shellIntegration-env.zsh.
if [[ -f "$USER_ZDOTDIR/.zshenv" ]]; then
  VSCODE_ZDOTDIR="$ZDOTDIR"
  ZDOTDIR="$USER_ZDOTDIR"

  if [[ "$USER_ZDOTDIR" != "$VSCODE_ZDOTDIR" ]]; then
    . "$USER_ZDOTDIR/.zshenv"
  fi

  USER_ZDOTDIR="$ZDOTDIR"
  ZDOTDIR="$VSCODE_ZDOTDIR"
fi
