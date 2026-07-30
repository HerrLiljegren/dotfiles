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
mkdir -p -- "$TEST_HOME/.codex"
printf '# existing bash config\n' >"$TEST_HOME/.bashrc"
printf '# existing zsh config\n' >"$TEST_HOME/.zshrc"
printf '# existing zsh environment; must preserve caller-owned ZDOTDIR\n' >"$TEST_HOME/.zshenv"
printf '[credential]\n    helper = existing-helper\n' >"$TEST_HOME/.gitconfig"
printf 'existing starship config\n' >"$TEST_HOME/.config/starship.toml"
printf 'model = "existing-model"\n' >"$TEST_HOME/.codex/config.toml"

before_status="$(git -C "$ROOT" status --porcelain=v1)"

HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$ROOT/install.sh"

[[ -L "$TEST_HOME/.config/starship.toml" ]] || fail 'starship config was not linked'
[[ -f "$TEST_HOME/.config/starship.toml.pre-dotfiles" ]] || fail 'existing config was not backed up'
[[ ! -L "$TEST_HOME/.codex/config.toml" ]] || fail 'Codex config was replaced with a symlink'
grep -Fq 'existing-model' "$TEST_HOME/.codex/config.toml" || fail 'Codex config was modified'
[[ -L "$TEST_HOME/.codex/AGENTS.md" ]] || fail 'Codex guidance was not linked'
[[ -L "$TEST_HOME/.config/git/ignore" ]] || fail 'global Git ignore was not linked'
[[ -L "$TEST_HOME/.config/worktrunk/config.toml" ]] || fail 'Worktrunk config was not linked'
[[ -L "$TEST_HOME/.config/herdr/config.toml" ]] || fail 'Herdr config was not linked'
[[ -L "$TEST_HOME/.config/hunk/config.toml" ]] || fail 'Hunk config was not linked'
[[ "$(grep -Fc '# >>> dotfiles:bash >>>' "$TEST_HOME/.bashrc")" == 1 ]] || fail 'bash block count is not one'
[[ "$(grep -Fc '# >>> dotfiles:zsh >>>' "$TEST_HOME/.zshrc")" == 1 ]] || fail 'zsh block count is not one'
[[ "$(grep -Fc '# >>> dotfiles:git >>>' "$TEST_HOME/.gitconfig")" == 1 ]] || fail 'git block count is not one'
grep -Fq 'helper = existing-helper' "$TEST_HOME/.gitconfig" || fail 'Git credential helper was replaced'

mkdir -p -- "$TEST_HOME/.aspnet/dev-certs/trust"

env -u SSL_CERT_DIR \
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
TERM=xterm-256color \
  zsh -lic '
    [[ "$SSL_CERT_DIR" == "$HOME/.aspnet/dev-certs/trust:/etc/ssl/certs" ]]
  ' || fail 'fresh Zsh login did not discover the .NET development certificate trust directory'

SSL_CERT_DIR="/custom/certs:/etc/ssl/certs" \
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
TERM=xterm-256color \
  zsh -lic '
    [[ "$SSL_CERT_DIR" == "$HOME/.aspnet/dev-certs/trust:/custom/certs:/etc/ssl/certs" ]]
  ' || fail 'fresh Zsh login replaced existing certificate directories'

mkdir -p -- "$TEST_HOME/.config/dotfiles"
printf 'export DOTFILES_PERSONAL_ZSH_LOADED=1\n' >"$TEST_HOME/.config/dotfiles/personal.zsh"

env -u ZDOTDIR \
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
TERM=xterm-256color \
DOTFILES_CONTRACT_ASSERT="$ROOT/tests/zsh-contract.zsh" \
  zsh -ic 'source "$DOTFILES_CONTRACT_ASSERT"'

history_cursor_log="$TEST_ROOT/zsh-history-cursor.log"
if ! env -u ZDOTDIR \
  HOME="$TEST_HOME" \
  XDG_CONFIG_HOME="$TEST_HOME/.config" \
  TERM=xterm-256color \
  DOTFILES_TEST_ROOT="$ROOT" \
    script -qefc \
      'zsh -dfi "$DOTFILES_TEST_ROOT/tests/zsh-history-cursor.zsh"' \
      /dev/null >"$history_cursor_log"
then
  cat "$history_cursor_log" >&2
  fail 'Zsh history cursor contract failed'
fi

HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
TERM=xterm-256color \
USER_ZDOTDIR="$TEST_HOME" \
ZDOTDIR="$ROOT/tests/fixtures/vscode-zdotdir" \
VSCODE_INJECTION=1 \
DOTFILES_CONTRACT_ASSERT="$ROOT/tests/zsh-contract.zsh" \
  zsh -ic exit

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
