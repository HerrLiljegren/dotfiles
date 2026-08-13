#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
: "${HOME:?HOME must be set}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_SUFFIX=".pre-dotfiles"
OPTIONAL_SETUPS=()
BOLD=''
RESET=''

if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != 'dumb' ]]; then
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
fi

log() {
  printf 'dotfiles: %s\n' "$*"
}

section() {
  printf '\n%s==> %s%s\n' "$BOLD" "$*" "$RESET"
}

die() {
  printf 'dotfiles: error: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf 'usage: install.sh [--with NAME]...\n'
  printf '\n'
  printf 'Link the shared dotfiles and optionally run additional setup.\n'
  printf '\n'
  printf 'Optional setup names:\n'
  printf '  all             Run every optional setup.\n'
  printf '  herdr-plugins   Install or refresh the latest Herdr plugins.\n'
  printf '  none            Link dotfiles only.\n'
  printf '\n'
  printf 'With no arguments, both interactive and non-interactive runs link\n'
  printf 'dotfiles only. Interactive runs can select additional setup.\n'
}

add_optional_setup() {
  local requested=$1
  local existing=''

  case "$requested" in
    all | herdr-plugins | none) ;;
    *) die "unknown optional setup: $requested" ;;
  esac

  for existing in "${OPTIONAL_SETUPS[@]}"; do
    [[ "$existing" == "$requested" ]] && return
  done

  OPTIONAL_SETUPS+=("$requested")
}

normalize_optional_setups() {
  local setup=''

  if ((${#OPTIONAL_SETUPS[@]} > 1)); then
    for setup in "${OPTIONAL_SETUPS[@]}"; do
      if [[ "$setup" == 'all' || "$setup" == 'none' ]]; then
        die "$setup cannot be combined with another optional setup"
      fi
    done
  fi

  if ((${#OPTIONAL_SETUPS[@]} == 1)); then
    case "${OPTIONAL_SETUPS[0]}" in
      all) OPTIONAL_SETUPS=('herdr-plugins') ;;
      none) OPTIONAL_SETUPS=() ;;
    esac
  fi
}

choose_optional_setup() {
  local selection=''

  printf '\n%sDotfiles installer%s\n\n' "$BOLD" "$RESET"
  printf 'Choose what to install:\n\n'
  printf '  1. Dotfiles only (default)\n'
  printf '     Link configuration without downloading or updating plugins.\n\n'
  printf '  2. Everything\n'
  printf '     Link dotfiles and run every optional setup.\n\n'
  printf '     Includes:\n'
  printf '       - Herdr plugins\n\n'
  printf '     Requires network access and may run third-party build commands.\n\n'

  while true; do
    printf 'Selection [1]: '
    IFS= read -r selection || die 'installation cancelled'

    case "$selection" in
      '' | 1)
        OPTIONAL_SETUPS=()
        return
        ;;
      2)
        OPTIONAL_SETUPS=('herdr-plugins')
        return
        ;;
      *)
        printf 'Please enter 1 or 2.\n\n' >&2
        ;;
    esac
  done
}

if (($# == 1)) && [[ "$1" == '--help' ]]; then
  usage
  exit 0
elif (($# == 0)) && [[ -t 0 && -t 1 ]]; then
  choose_optional_setup
else
  while (($#)); do
    [[ "$1" == '--with' ]] || die "unknown argument: $1"
    (($# >= 2)) || die '--with requires a setup name'
    add_optional_setup "$2"
    shift 2
  done

  normalize_optional_setups
fi

for optional_setup in "${OPTIONAL_SETUPS[@]}"; do
  case "$optional_setup" in
    herdr-plugins)
      command -v herdr >/dev/null 2>&1 || die 'herdr is required for herdr-plugins'
      ;;
  esac
done

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

section 'Dotfiles'

[[ ! -L "$HOME/.local/bin" ]] ||
  die "$HOME/.local/bin must be a real directory, not a symlink"
mkdir -p -- "$HOME/.local/bin"

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
link_path "$ROOT/bin/skillset" "$HOME/.local/bin/skillset"
link_path "$ROOT/bin/ssh-to" "$HOME/.local/bin/ssh-to"
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

for optional_setup in "${OPTIONAL_SETUPS[@]}"; do
  case "$optional_setup" in
    herdr-plugins)
      section 'Herdr plugins'
      bash "$ROOT/install/optional/herdr-plugins.sh" "$ROOT/config/herdr/plugins.tsv"
      ;;
  esac
done

section 'Complete'
log 'installation complete'
