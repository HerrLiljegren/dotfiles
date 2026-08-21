#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
TEST_HOME="$TEST_ROOT/home"
FAKE_BIN="$TEST_ROOT/bin"
HERDR_LOG="$TEST_ROOT/herdr.log"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  printf 'test failure: %s\n' "$*" >&2
  exit 1
}

mkdir -p -- "$TEST_HOME" "$FAKE_BIN"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf '\''%s\n'\'' "$*" >>"$HERDR_TEST_LOG"' \
  'if [[ "${HERDR_FAIL_SOURCE:-}" == "${3:-}" ]]; then exit 23; fi' \
  >"$FAKE_BIN/herdr"
chmod +x "$FAKE_BIN/herdr"

PATH="$FAKE_BIN:$PATH" \
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
HERDR_TEST_LOG="$HERDR_LOG" \
  "$ROOT/install.sh" --with all >/dev/null

expected_calls="$(printf '%s\n' \
  'plugin install smarzban/herdr-file-viewer --yes' \
  'plugin install lmilojevicc/herdr-splits.nvim --yes' \
  'plugin install third774/herdr-last-workspace --yes' \
  'plugin install devashish2203/herdr-worktrunk --yes' \
  'plugin install beyondlex/herdr-recent-navigator --yes' \
  'plugin install StructuPath/herdr-browser --yes' \
  'plugin install thanhdat77/herdr-navigator --yes')"
actual_calls="$(<"$HERDR_LOG")"

[[ "$actual_calls" == "$expected_calls" ]] || {
  printf 'expected Herdr calls:\n%s\n' "$expected_calls" >&2
  printf 'actual Herdr calls:\n%s\n' "$actual_calls" >&2
  fail '--with all did not install every Herdr plugin'
}

: >"$HERDR_LOG"
PATH="$FAKE_BIN:$PATH" \
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
HERDR_TEST_LOG="$HERDR_LOG" \
  "$ROOT/install.sh" --with none >/dev/null

[[ ! -s "$HERDR_LOG" ]] || fail '--with none invoked Herdr'

PATH="$FAKE_BIN:$PATH" \
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
HERDR_TEST_LOG="$HERDR_LOG" \
  "$ROOT/install.sh" >/dev/null

[[ ! -s "$HERDR_LOG" ]] || fail 'non-interactive install invoked optional setup'

PATH="$FAKE_BIN:$PATH" \
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
HERDR_TEST_LOG="$HERDR_LOG" \
  "$ROOT/install.sh" --with herdr-plugins >/dev/null

actual_calls="$(<"$HERDR_LOG")"
[[ "$actual_calls" == "$expected_calls" ]] || fail '--with herdr-plugins did not install every declared plugin'

: >"$HERDR_LOG"
printf '\n' | \
  env \
    PATH="$FAKE_BIN:$PATH" \
    HOME="$TEST_HOME" \
    XDG_CONFIG_HOME="$TEST_HOME/.config" \
    HERDR_TEST_LOG="$HERDR_LOG" \
    script -qefc "$ROOT/install.sh" /dev/null \
    >"$TEST_ROOT/interactive-dotfiles.log"

grep -Fq 'Choose what to install:' "$TEST_ROOT/interactive-dotfiles.log" || fail 'interactive install did not show the selection prompt'
grep -Fq '1. Dotfiles only (default)' "$TEST_ROOT/interactive-dotfiles.log" || fail 'interactive install did not show the dotfiles default'
grep -Fq '==> Dotfiles' "$TEST_ROOT/interactive-dotfiles.log" || fail 'interactive install omitted the dotfiles progress section'
grep -Fq '==> Complete' "$TEST_ROOT/interactive-dotfiles.log" || fail 'interactive install omitted the completion section'
[[ ! -s "$HERDR_LOG" ]] || fail 'interactive default invoked optional setup'

: >"$HERDR_LOG"
printf '2\n' | \
  env \
    PATH="$FAKE_BIN:$PATH" \
    HOME="$TEST_HOME" \
    XDG_CONFIG_HOME="$TEST_HOME/.config" \
    HERDR_TEST_LOG="$HERDR_LOG" \
    script -qefc "$ROOT/install.sh" /dev/null \
    >"$TEST_ROOT/interactive-all.log"

grep -Fq '==> Herdr plugins' "$TEST_ROOT/interactive-all.log" || fail 'interactive everything selection omitted the Herdr progress section'
actual_calls="$(<"$HERDR_LOG")"
[[ "$actual_calls" == "$expected_calls" ]] || fail 'interactive everything selection omitted optional setup'

HOME="$TEST_HOME" "$ROOT/install.sh" --help >"$TEST_ROOT/help.log"
grep -Fq 'usage: install.sh [--with NAME]...' "$TEST_ROOT/help.log" || fail 'installer help omitted usage'
grep -Fq 'herdr-plugins' "$TEST_ROOT/help.log" || fail 'installer help omitted Herdr plugins'
grep -Fq 'non-interactive' "$TEST_ROOT/help.log" || fail 'installer help omitted non-interactive behavior'

: >"$HERDR_LOG"
PATH="$FAKE_BIN:$PATH" \
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
HERDR_TEST_LOG="$HERDR_LOG" \
  "$ROOT/install.sh" --with herdr-plugins --with herdr-plugins >/dev/null

actual_calls="$(<"$HERDR_LOG")"
[[ "$actual_calls" == "$expected_calls" ]] || fail 'repeated optional setup was not normalized'

if HOME="$TEST_HOME" "$ROOT/install.sh" --with all --with herdr-plugins >"$TEST_ROOT/conflict.log" 2>&1; then
  fail '--with all was accepted alongside another setup'
fi
grep -Fq 'all cannot be combined' "$TEST_ROOT/conflict.log" || fail 'conflicting setup error was not actionable'

MISSING_HERDR_HOME="$TEST_ROOT/missing-herdr-home"
mkdir -p -- "$MISSING_HERDR_HOME"
if PATH='/usr/bin:/bin' \
  HOME="$MISSING_HERDR_HOME" \
  XDG_CONFIG_HOME="$MISSING_HERDR_HOME/.config" \
  "$ROOT/install.sh" --with herdr-plugins >"$TEST_ROOT/missing-herdr.log" 2>&1
then
  fail 'Herdr plugin setup succeeded without Herdr'
fi
grep -Fq 'herdr is required' "$TEST_ROOT/missing-herdr.log" || fail 'missing Herdr error was not actionable'
[[ ! -e "$MISSING_HERDR_HOME/.config/herdr/config.toml" ]] || fail 'installer changed dotfiles before optional setup preflight'

: >"$HERDR_LOG"
if PATH="$FAKE_BIN:$PATH" \
  HOME="$TEST_HOME" \
  XDG_CONFIG_HOME="$TEST_HOME/.config" \
  HERDR_TEST_LOG="$HERDR_LOG" \
  HERDR_FAIL_SOURCE='third774/herdr-last-workspace' \
  "$ROOT/install.sh" --with herdr-plugins >"$TEST_ROOT/herdr-failure.log" 2>&1
then
  fail 'installer ignored a Herdr plugin installation failure'
fi
if grep -Fq 'devashish2203/herdr-worktrunk' "$HERDR_LOG"; then
  fail 'installer continued after a Herdr plugin installation failure'
fi

printf 'installer option tests passed\n'
