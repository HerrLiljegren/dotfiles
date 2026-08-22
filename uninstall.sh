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

unlink_path "$ROOT/config/bat" "$XDG_CONFIG_HOME/bat"
unlink_path "$ROOT/config/btop" "$XDG_CONFIG_HOME/btop"
unlink_path "$ROOT/config/delta" "$XDG_CONFIG_HOME/delta"
unlink_path "$ROOT/config/ghostty" "$XDG_CONFIG_HOME/ghostty"
unlink_path "$ROOT/config/glow" "$XDG_CONFIG_HOME/glow"
unlink_path "$ROOT/config/herdr" "$XDG_CONFIG_HOME/herdr"
unlink_path "$ROOT/config/hunk" "$XDG_CONFIG_HOME/hunk"
unlink_path "$ROOT/config/lazygit" "$XDG_CONFIG_HOME/lazygit"
unlink_path "$ROOT/config/nvim" "$XDG_CONFIG_HOME/nvim"
unlink_path "$ROOT/config/ov" "$XDG_CONFIG_HOME/ov"
unlink_path "$ROOT/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
unlink_path "$ROOT/config/worktrunk" "$XDG_CONFIG_HOME/worktrunk"
unlink_path "$ROOT/config/yazi" "$XDG_CONFIG_HOME/yazi"
unlink_path "$ROOT/git/ignore" "$XDG_CONFIG_HOME/git/ignore"
unlink_path "$ROOT/bin/git-aliases" "$HOME/.local/bin/git-aliases"
unlink_path "$ROOT/bin/skillset" "$HOME/.local/bin/skillset"
unlink_path "$ROOT/bin/ssh-to" "$HOME/.local/bin/ssh-to"
unlink_path "$ROOT/agents/AGENTS.md" "$HOME/.agents/AGENTS.md"
unlink_path "$ROOT/agents/AGENTS.md" "$HOME/.codex/AGENTS.md"
unlink_path "$ROOT/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
unlink_path "$ROOT/agents/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
unlink_path "$ROOT/agents/AGENTS.md" "$XDG_CONFIG_HOME/opencode/AGENTS.md"
unlink_path "$ROOT/agents/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"

remove_block "$HOME/.bashrc" 'bash'
remove_block "$HOME/.zshrc" 'zsh'
remove_block "$HOME/.gitconfig" 'git'

log 'uninstall complete'
