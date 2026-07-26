#!/usr/bin/env bash
set -euo pipefail

tools=(
  bash
  zsh
  git
  nvim
  starship
  delta
  fzf
  zoxide
  bat
  glow
  hunk
  wt
  herdr
  codex
)

missing=0

for tool in "${tools[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf 'ok      %s\n' "$tool"
  else
    printf 'missing %s\n' "$tool"
    missing=1
  fi
done

if ((missing)); then
  printf '\nInstall missing tools through the Dev Container Feature or workstation setup.\n'
  exit 1
fi

printf '\nAll configured tools are available.\n'
