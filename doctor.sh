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
  btop
  glow
  hunk
  lazygit
  wt
  herdr
  codex
)

missing=0

# macOS installs the configured tools through Homebrew, and the shell tools
# need its Bash ahead of /bin/bash (3.2).
if [[ "$(uname -s)" == Darwin ]]; then
  tools=(brew "${tools[@]}")
  if ((BASH_VERSINFO[0] >= 4)); then
    printf 'ok      bash %s\n' "${BASH_VERSION%%(*}"
  else
    printf 'old     bash %s; put Homebrew Bash ahead of /bin/bash on PATH\n' "${BASH_VERSION%%(*}"
    missing=1
  fi
fi

for tool in "${tools[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf 'ok      %s\n' "$tool"
  else
    printf 'missing %s\n' "$tool"
    missing=1
  fi
done

if [[ -r "$HOME/.zshenv" ]]; then
  zdotdir_probe='/dotfiles-zdotdir-probe'
  if DOTFILES_ZDOTDIR_PROBE="$zdotdir_probe" \
    ZDOTDIR="$zdotdir_probe" \
    zsh -dfc '
      source "$HOME/.zshenv"
      [[ "$ZDOTDIR" == "$DOTFILES_ZDOTDIR_PROBE" ]]
    ' >/dev/null 2>&1; then
    printf 'ok      .zshenv preserves caller-owned ZDOTDIR\n'
  else
    printf 'broken  .zshenv changes caller-owned ZDOTDIR\n'
    missing=1
  fi
fi

if ((missing)); then
  printf '\nResolve the reported shell contract or install missing tools through the Dev Container Feature or workstation setup.\n'
  exit 1
fi

printf '\nAll configured tools are available.\n'
