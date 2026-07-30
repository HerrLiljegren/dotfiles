#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
TEST_HOME="$TEST_ROOT/home"
TEST_CONFIG="$TEST_HOME/.config"
FIRST_INSTALL="$TEST_ROOT/first-install"
GUIDANCE="$ROOT/agents/AGENTS.md"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  printf 'test failure: %s\n' "$*" >&2
  exit 1
}

assert_link() {
  local destination=$1

  [[ -L "$destination" ]] || fail "$destination was not linked"
  [[ "$(readlink -- "$destination")" == "$GUIDANCE" ]] ||
    fail "$destination points to the wrong source"
}

mkdir -p \
  "$TEST_HOME/.agents" \
  "$TEST_HOME/.codex" \
  "$TEST_CONFIG/opencode"
printf 'existing host guidance\n' >"$TEST_HOME/.agents/AGENTS.md"
printf 'existing OpenCode guidance\n' >"$TEST_CONFIG/opencode/AGENTS.md"
ln -s \
  "$ROOT/agents/codex/AGENTS.md" \
  "$TEST_HOME/.codex/AGENTS.md"

HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_CONFIG" \
  "$ROOT/install.sh" >/dev/null

assert_link "$TEST_HOME/.agents/AGENTS.md"
assert_link "$TEST_HOME/.codex/AGENTS.md"
assert_link "$TEST_HOME/.claude/CLAUDE.md"
assert_link "$TEST_HOME/.pi/agent/AGENTS.md"
assert_link "$TEST_CONFIG/opencode/AGENTS.md"
assert_link "$TEST_HOME/.copilot/copilot-instructions.md"

grep -Fq 'existing host guidance' \
  "$TEST_HOME/.agents/AGENTS.md.pre-dotfiles" ||
  fail 'existing neutral guidance was not backed up'
grep -Fq 'existing OpenCode guidance' \
  "$TEST_CONFIG/opencode/AGENTS.md.pre-dotfiles" ||
  fail 'existing OpenCode guidance was not backed up'
[[ ! -e "$TEST_HOME/.codex/AGENTS.md.pre-dotfiles" ]] ||
  fail 'legacy managed Codex guidance was unnecessarily backed up'

mkdir -p -- "$FIRST_INSTALL"
cp -a -- "$TEST_HOME/." "$FIRST_INSTALL/"

HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_CONFIG" \
  "$ROOT/install.sh" >/dev/null

diff -ruN -- "$FIRST_INSTALL" "$TEST_HOME" ||
  fail 'second install changed the target home'

HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_CONFIG" \
  "$ROOT/uninstall.sh" >/dev/null

grep -Fq 'existing host guidance' "$TEST_HOME/.agents/AGENTS.md" ||
  fail 'neutral guidance backup was not restored'
grep -Fq 'existing OpenCode guidance' "$TEST_CONFIG/opencode/AGENTS.md" ||
  fail 'OpenCode guidance backup was not restored'
[[ ! -e "$TEST_HOME/.codex/AGENTS.md" ]] ||
  fail 'managed Codex guidance remained after uninstall'
[[ ! -e "$TEST_HOME/.claude/CLAUDE.md" ]] ||
  fail 'managed Claude guidance remained after uninstall'
[[ ! -e "$TEST_HOME/.pi/agent/AGENTS.md" ]] ||
  fail 'managed Pi guidance remained after uninstall'
[[ ! -e "$TEST_HOME/.copilot/copilot-instructions.md" ]] ||
  fail 'managed Copilot guidance remained after uninstall'

printf 'agent guidance link tests passed\n'
