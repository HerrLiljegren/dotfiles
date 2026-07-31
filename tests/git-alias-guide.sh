#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
ALIASES_FILE="$ROOT/shell/git-aliases.sh"
GUIDE_FILE="$ROOT/shell/git-alias-guide.tsv"
GUIDE_COMMAND="$ROOT/bin/git-aliases"

fail() {
  printf 'test failure: %s\n' "$*" >&2
  exit 1
}

declare -A selected=()
declare -A documented=()

while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  selected[$name]=1
done < <(sed -n "s/^alias \([^=]*\)=.*/\1/p" "$ALIASES_FILE")

while IFS=$'\t' read -r category name what when why example; do
  [[ -n "$category" && ${category:0:1} != '#' ]] || continue
  [[ -n "$name" && -n "$what" && -n "$when" && -n "$why" && -n "$example" ]] ||
    fail "incomplete guide entry for ${name:-unknown alias}"
  [[ -z "${documented[$name]:-}" ]] || fail "duplicate guide entry for $name"
  documented[$name]=1
done <"$GUIDE_FILE"

for name in "${!selected[@]}"; do
  [[ -n "${documented[$name]:-}" ]] || fail "$name has no guide entry"
done

for name in "${!documented[@]}"; do
  [[ -n "${selected[$name]:-}" ]] || fail "$name is documented but not selected"
done

DOTFILES_SHELL_DIR="$ROOT/shell" \
XDG_CONFIG_HOME="$ROOT/tests/fixtures/no-personal-config" \
  bash --noprofile --norc -c '
    source "$DOTFILES_SHELL_DIR/common.sh"
    [[ "$(alias gsb)" == "alias gsb='"'"'git status --short --branch'"'"'" ]]
    [[ "$(alias ghelp)" == "alias ghelp='"'"'git-aliases'"'"'" ]]
  ' || fail 'Git aliases are not Bash-compatible'

compact_output="$($GUIDE_COMMAND --plain)"
[[ "$compact_output" == *'Git alias guide'* ]] || fail 'compact guide has no heading'
[[ "$compact_output" == *'gsb'* ]] || fail 'compact guide omits gsb'

detail_output="$($GUIDE_COMMAND --plain glg)"
[[ "$detail_output" == *'git log --stat'* ]] || fail 'glg detail omits its command'
[[ "$detail_output" == *'When:'* ]] || fail 'glg detail omits when guidance'
[[ "$detail_output" == *'Why:'* ]] || fail 'glg detail omits rationale'
[[ "$detail_output" == *'Try:'* ]] || fail 'glg detail omits an example'

all_output="$(NO_COLOR=1 "$GUIDE_COMMAND" --all)"
[[ "$all_output" != *$'\033'* ]] || fail 'NO_COLOR output contains ANSI escapes'

color_output="$(env -u NO_COLOR TERM=xterm-256color script -qefc "$GUIDE_COMMAND glg" /dev/null)"
[[ "$color_output" == *$'\033['* ]] || fail 'interactive guide output has no ANSI styling'

if "$GUIDE_COMMAND" --plain unknown-alias >/dev/null 2>&1; then
  fail 'unknown alias unexpectedly succeeded'
fi

printf 'Git alias guide contract passed\n'
