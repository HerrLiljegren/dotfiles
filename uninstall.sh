#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
: "${HOME:?HOME must be set}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_SUFFIX=".pre-dotfiles"

log() {
  printf 'dotfiles: %s\n' "$*"
}

unlink_path() {
  local source=$1
  local destination=$2
  local backup="${destination}${BACKUP_SUFFIX}"

  if [[ ! -L "$destination" ]] || [[ "$(readlink -- "$destination")" != "$source" ]]; then
    log "skipped unmanaged $destination"
    return
  fi

  rm -- "$destination"
  log "removed $destination"

  if [[ -e "$backup" || -L "$backup" ]]; then
    mv -- "$backup" "$destination"
    log "restored $destination"
  fi
}

remove_block() {
  local destination=$1
  local name=$2
  local start="# >>> dotfiles:${name} >>>"
  local end="# <<< dotfiles:${name} <<<"
  local temp=''

  [[ -f "$destination" ]] || return
  grep -Fqx -- "$start" "$destination" || return
  grep -Fqx -- "$end" "$destination" || return

  temp="$(mktemp "${destination}.tmp.XXXXXX")"
  awk -v start="$start" -v end="$end" '
    $0 == start { inside = 1; next }
    $0 == end { inside = 0; next }
    !inside { print }
  ' "$destination" >"$temp"
  mv -- "$temp" "$destination"
  log "removed managed block from $destination"
}

unlink_path "$ROOT/config/bat/themes/Catppuccin Mocha.tmTheme" "$XDG_CONFIG_HOME/bat/themes/Catppuccin Mocha.tmTheme"
unlink_path "$ROOT/config/bat/config" "$XDG_CONFIG_HOME/bat/config"
unlink_path "$ROOT/config/delta/config.gitconfig" "$XDG_CONFIG_HOME/delta/config.gitconfig"
unlink_path "$ROOT/config/glow/glow.yml" "$XDG_CONFIG_HOME/glow/glow.yml"
unlink_path "$ROOT/config/herdr/config.toml" "$XDG_CONFIG_HOME/herdr/config.toml"
unlink_path "$ROOT/config/nvim" "$XDG_CONFIG_HOME/nvim"
unlink_path "$ROOT/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
unlink_path "$ROOT/config/worktrunk/config.toml" "$XDG_CONFIG_HOME/worktrunk/config.toml"
unlink_path "$ROOT/git/ignore" "$XDG_CONFIG_HOME/git/ignore"
unlink_path "$ROOT/agents/codex/config.toml" "$HOME/.codex/config.toml"
unlink_path "$ROOT/agents/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

remove_block "$HOME/.bashrc" 'bash'
remove_block "$HOME/.zshrc" 'zsh'
remove_block "$HOME/.gitconfig" 'git'

log 'uninstall complete'

