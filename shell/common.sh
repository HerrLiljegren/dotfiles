# Shared interactive shell configuration for Bash and Zsh.

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH

if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  export VISUAL=nvim
elif command -v vim >/dev/null 2>&1; then
  export EDITOR=vim
  export VISUAL=vim
fi

export PAGER="${PAGER:-less}"
export LESS="${LESS:--FRX}"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height=40% --layout=reverse --border}"

alias ll='ls -alF'

if command -v eza >/dev/null 2>&1; then
  alias l='eza -lh --icons --git --group-directories-first'
  alias ll='eza -lah --icons --git --group-directories-first'
  alias lt='eza --tree --level=4 --git-ignore --icons'
  alias lta='eza --tree --level=4 --all --icons --group-directories-first'
fi
alias gs='git status --short --branch'
alias gd='git diff'
alias gl='git log --oneline --decorate --graph -20'

DOTFILES_LOCAL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local.sh"
if [ -r "$DOTFILES_LOCAL_CONFIG" ]; then
  . "$DOTFILES_LOCAL_CONFIG"
fi
unset DOTFILES_LOCAL_CONFIG

