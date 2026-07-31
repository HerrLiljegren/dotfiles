#!/usr/bin/env zsh
emulate -L zsh
setopt errexit nounset pipefail

ROOT="${0:A:h:h}"

fail() {
  print -ru2 -- "test failure: $1"
  exit 1
}

unalias -m '*' 2>/dev/null || true
source "$ROOT/shell/git-aliases.sh"

typeset -A selected_aliases
typeset name
for name in ${(k)aliases}; do
  selected_aliases[$name]="${aliases[$name]}"
done

(( ${+selected_aliases[gs]} == 0 )) || fail 'custom gs alias is still selected'
(( ${+selected_aliases[gpsup]} == 0 )) || fail 'gpsup should be excluded'
(( ${+selected_aliases[gsb]} == 1 )) || fail 'OMZ gsb alias is not selected'
(( ${+selected_aliases[glg]} == 1 )) || fail 'OMZ glg alias is not selected'
(( ${+selected_aliases[glgp]} == 1 )) || fail 'OMZ glgp alias is not selected'

unalias -m '*' 2>/dev/null || true
compdef() { :; }
source "$ROOT/vendor/zsh/oh-my-zsh-git/git.plugin.zsh"

for name in ${(k)selected_aliases}; do
  (( ${+aliases[$name]} == 1 )) || fail "$name is absent from the pinned OMZ plugin"
  [[ "${selected_aliases[$name]}" == "${aliases[$name]}" ]] ||
    fail "$name differs from the pinned OMZ plugin"
done

print 'Git aliases match the pinned Oh My Zsh plugin'
