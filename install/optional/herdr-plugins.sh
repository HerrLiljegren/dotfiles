#!/usr/bin/env bash
set -euo pipefail

manifest=${1:?plugin manifest is required}

command -v herdr >/dev/null 2>&1 || {
  printf 'dotfiles: error: herdr is required for herdr-plugins\n' >&2
  exit 1
}

while IFS=$'\t' read -r plugin_id source extra; do
  [[ -z "$plugin_id" || "$plugin_id" == \#* ]] && continue
  [[ -n "$source" && -z "${extra:-}" ]] || {
    printf 'dotfiles: error: malformed Herdr plugin declaration for %s\n' "$plugin_id" >&2
    exit 1
  }

  printf 'dotfiles: installing latest %s\n' "$plugin_id"
  herdr plugin install "$source" --yes
done <"$manifest"
