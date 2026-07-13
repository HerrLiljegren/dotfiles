#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
TEST_HOME="$TEST_ROOT/home"
FIRST_INSTALL="$TEST_ROOT/first-install"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  printf 'test failure: %s\n' "$*" >&2
  exit 1
}

mkdir -p -- "$TEST_HOME/.config"
printf '# existing bash config\n' >"$TEST_HOME/.bashrc"
printf '# existing zsh config\n' >"$TEST_HOME/.zshrc"
printf '[credential]\n    helper = existing-helper\n' >"$TEST_HOME/.gitconfig"
printf 'existing starship config\n' >"$TEST_HOME/.config/starship.toml"

before_status="$(git -C "$ROOT" status --porcelain=v1)"

HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$ROOT/install.sh"

[[ -L "$TEST_HOME/.config/starship.toml" ]] || fail 'starship config was not linked'
[[ -f "$TEST_HOME/.config/starship.toml.pre-dotfiles" ]] || fail 'existing config was not backed up'
[[ -L "$TEST_HOME/.codex/config.toml" ]] || fail 'Codex config was not linked'
[[ -L "$TEST_HOME/.config/git/ignore" ]] || fail 'global Git ignore was not linked'
[[ -L "$TEST_HOME/.config/worktrunk/config.toml" ]] || fail 'Worktrunk config was not linked'
[[ -L "$TEST_HOME/.config/herdr/config.toml" ]] || fail 'Herdr config was not linked'
[[ "$(grep -Fc '# >>> dotfiles:bash >>>' "$TEST_HOME/.bashrc")" == 1 ]] || fail 'bash block count is not one'
[[ "$(grep -Fc '# >>> dotfiles:zsh >>>' "$TEST_HOME/.zshrc")" == 1 ]] || fail 'zsh block count is not one'
[[ "$(grep -Fc '# >>> dotfiles:git >>>' "$TEST_HOME/.gitconfig")" == 1 ]] || fail 'git block count is not one'
grep -Fq 'helper = existing-helper' "$TEST_HOME/.gitconfig" || fail 'Git credential helper was replaced'

mkdir -p -- "$FIRST_INSTALL"
cp -a -- "$TEST_HOME/." "$FIRST_INSTALL/"

HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$ROOT/install.sh"

diff -ruN -- "$FIRST_INSTALL" "$TEST_HOME" || fail 'second install changed the target home'

after_status="$(git -C "$ROOT" status --porcelain=v1)"
[[ "$before_status" == "$after_status" ]] || fail 'installer modified its source repository'

HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$ROOT/uninstall.sh"

[[ ! -L "$TEST_HOME/.config/starship.toml" ]] || fail 'starship symlink remained after uninstall'
grep -Fq 'existing starship config' "$TEST_HOME/.config/starship.toml" || fail 'starship backup was not restored'
grep -Fq 'helper = existing-helper' "$TEST_HOME/.gitconfig" || fail 'Git credential helper was lost during uninstall'
if grep -Fq '# >>> dotfiles:' "$TEST_HOME/.bashrc" "$TEST_HOME/.zshrc" "$TEST_HOME/.gitconfig"; then
  fail 'managed block remained after uninstall'
fi

printf 'install, idempotency, and uninstall tests passed\n'

