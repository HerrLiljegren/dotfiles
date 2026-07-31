#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
: "${HOME:?HOME must be set}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_SUFFIX=".pre-dotfiles"

log() {
  printf 'dotfiles: %s\n' "$*"
}

die() {
  printf 'dotfiles: error: %s\n' "$*" >&2
  exit 1
}

link_path() {
  local source=$1
  local destination=$2
  local legacy_source=${3:-}
  local backup="${destination}${BACKUP_SUFFIX}"

  [[ -e "$source" || -L "$source" ]] || die "missing source: $source"
  mkdir -p -- "$(dirname -- "$destination")"

  if [[ -L "$destination" ]] && [[ "$(readlink -- "$destination")" == "$source" ]]; then
    log "unchanged $destination"
    return
  fi

  if [[ -n "$legacy_source" ]] &&
    [[ -L "$destination" ]] &&
    [[ "$(readlink -- "$destination")" == "$legacy_source" ]]
  then
    ln -sfn -- "$source" "$destination"
    log "migrated $destination"
    return
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    if [[ -e "$backup" || -L "$backup" ]]; then
      die "cannot replace $destination; backup already exists at $backup"
    fi

    mv -- "$destination" "$backup"
    log "backed up $destination to $backup"
  fi

  ln -s -- "$source" "$destination"
  log "linked $destination"
}

ensure_block() {
  local destination=$1
  local name=$2
  local body=$3
  local start="# >>> dotfiles:${name} >>>"
  local end="# <<< dotfiles:${name} <<<"
  local starts=0
  local ends=0
  local current=''
  local temp=''

  mkdir -p -- "$(dirname -- "$destination")"
  touch -- "$destination"

  starts="$(grep -Fxc -- "$start" "$destination" || true)"
  ends="$(grep -Fxc -- "$end" "$destination" || true)"

  if [[ "$starts" != "$ends" ]] || ((starts > 1)); then
    die "malformed managed block in $destination"
  fi

  if ((starts == 1)); then
    current="$(awk -v start="$start" -v end="$end" '
      $0 == start { inside = 1; next }
      $0 == end { inside = 0; next }
      inside { print }
    ' "$destination")"

    if [[ "$current" == "$body" ]]; then
      log "unchanged $destination"
      return
    fi

    temp="$(mktemp "${destination}.tmp.XXXXXX")"
    awk -v start="$start" -v end="$end" '
      $0 == start { inside = 1; next }
      $0 == end { inside = 0; next }
      !inside { print }
    ' "$destination" >"$temp"
    mv -- "$temp" "$destination"
  fi

  if [[ -s "$destination" ]]; then
    printf '\n' >>"$destination"
  fi

  printf '%s\n%s\n%s\n' "$start" "$body" "$end" >>"$destination"
  log "updated $destination"
}

configure_bat_cache() {
  local theme="$ROOT/config/bat/themes/Catppuccin Mocha.tmTheme"
  local cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
  local marker="$cache_home/bat/.dotfiles-theme.sha256"
  local expected=''
  local current=''

  command -v bat >/dev/null 2>&1 || return 0
  command -v sha256sum >/dev/null 2>&1 || return 0

  expected="$(sha256sum "$theme" | awk '{ print $1 }')"
  [[ -f "$marker" ]] && current="$(<"$marker")"
  [[ "$current" == "$expected" ]] && return

  bat cache --build >/dev/null
  mkdir -p -- "$(dirname -- "$marker")"
  printf '%s\n' "$expected" >"$marker"
  log 'rebuilt Bat theme cache'
}

link_path "$ROOT/config/bat/config" "$XDG_CONFIG_HOME/bat/config"
link_path "$ROOT/config/bat/themes/Catppuccin Mocha.tmTheme" "$XDG_CONFIG_HOME/bat/themes/Catppuccin Mocha.tmTheme"
link_path "$ROOT/config/delta/config.gitconfig" "$XDG_CONFIG_HOME/delta/config.gitconfig"
link_path "$ROOT/config/glow/glow.yml" "$XDG_CONFIG_HOME/glow/glow.yml"
link_path "$ROOT/config/herdr/config.toml" "$XDG_CONFIG_HOME/herdr/config.toml"
link_path "$ROOT/config/hunk/config.toml" "$XDG_CONFIG_HOME/hunk/config.toml"
link_path "$ROOT/config/nvim" "$XDG_CONFIG_HOME/nvim"
link_path "$ROOT/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
link_path "$ROOT/config/worktrunk/config.toml" "$XDG_CONFIG_HOME/worktrunk/config.toml"
link_path "$ROOT/git/ignore" "$XDG_CONFIG_HOME/git/ignore"
link_path "$ROOT/bin/git-aliases" "$HOME/.local/bin/git-aliases"
link_path "$ROOT/agents/AGENTS.md" "$HOME/.agents/AGENTS.md"
link_path \
  "$ROOT/agents/AGENTS.md" \
  "$HOME/.codex/AGENTS.md" \
  "$ROOT/agents/codex/AGENTS.md"
link_path "$ROOT/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link_path "$ROOT/agents/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
link_path "$ROOT/agents/AGENTS.md" "$XDG_CONFIG_HOME/opencode/AGENTS.md"
link_path "$ROOT/agents/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"

configure_bat_cache
ensure_block \
  "$HOME/.bashrc" \
  'bash' \
  "[ -r \"$ROOT/shell/bash.sh\" ] && . \"$ROOT/shell/bash.sh\""

ensure_block \
  "$HOME/.zshrc" \
  'zsh' \
  "[ -r \"$ROOT/shell/zsh.sh\" ] && source \"$ROOT/shell/zsh.sh\""

ensure_block \
  "$HOME/.gitconfig" \
  'git' \
  "[include]
    path = \"$ROOT/git/config\""

log 'installation complete'
