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
mkdir -p -- "$TEST_HOME/.config/yazi"
printf 'existing yazi config\n' >"$TEST_HOME/.config/yazi/yazi.toml"
printf 'model = "existing-model"\n' >"$TEST_HOME/.codex/config.toml"
ln -s ../dotfiles/ghostty/.config/ghostty "$TEST_HOME/.config/ghostty"

legacy_links=(
  'bat/config'
  'bat/themes/Catppuccin Mocha.tmTheme'
  'delta/config.gitconfig'
  'glow/glow.yml'
  'herdr/config.toml'
  'hunk/config.toml'
  'ov/config.yaml'
  'worktrunk/config.toml'
)

for legacy_link in "${legacy_links[@]}"; do
  mkdir -p -- "$(dirname -- "$TEST_HOME/.config/$legacy_link")"
  ln -s "$ROOT/config/$legacy_link" "$TEST_HOME/.config/$legacy_link"
done

mkdir -p -- "$TEST_HOME/.config/herdr/plugins/github/example"
printf 'installed plugin\n' >"$TEST_HOME/.config/herdr/plugins/github/example/herdr-plugin.toml"
printf '[]\n' >"$TEST_HOME/.config/herdr/plugins.json"
printf 'existing worktrunk state\n' >"$TEST_HOME/.config/worktrunk/state.yml"

before_status="$(git -C "$ROOT" status --porcelain=v1)"

HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$ROOT/install.sh" </dev/null

[[ -L "$TEST_HOME/.config/starship.toml" ]] || fail 'starship config was not linked'
[[ -f "$TEST_HOME/.config/starship.toml.pre-dotfiles" ]] || fail 'existing config was not backed up'
[[ ! -L "$TEST_HOME/.codex/config.toml" ]] || fail 'Codex config was replaced with a symlink'
grep -Fq 'existing-model' "$TEST_HOME/.codex/config.toml" || fail 'Codex config was modified'
[[ -L "$TEST_HOME/.codex/AGENTS.md" ]] || fail 'Codex guidance was not linked'
[[ -L "$TEST_HOME/.config/git/ignore" ]] || fail 'global Git ignore was not linked'
[[ -L "$TEST_HOME/.config/worktrunk" ]] || fail 'Worktrunk config was not linked'
[[ -f "$TEST_HOME/.config/worktrunk.pre-dotfiles/state.yml" ]] ||
  fail 'existing Worktrunk state was not backed up'
[[ ! -e "$TEST_HOME/.config/worktrunk.pre-dotfiles/config.toml" ]] ||
  fail 'legacy Worktrunk link was included in the backup'
[[ -L "$TEST_HOME/.config/yazi" ]] || fail 'Yazi config was not linked'
[[ -f "$TEST_HOME/.config/yazi.pre-dotfiles/yazi.toml" ]] || fail 'existing Yazi config was not backed up'
[[ -d "$TEST_HOME/.config/herdr" && ! -L "$TEST_HOME/.config/herdr" ]] ||
  fail 'Herdr state directory was replaced with a symlink'
[[ -L "$TEST_HOME/.config/herdr/config.toml" ]] || fail 'Herdr config was not linked'
[[ -f "$TEST_HOME/.config/herdr/plugins/github/example/herdr-plugin.toml" ]] ||
  fail 'Herdr plugin state was not preserved'
[[ -f "$TEST_HOME/.config/herdr/plugins.json" ]] || fail 'Herdr plugin registry was not preserved'
[[ -L "$TEST_HOME/.config/bat" ]] || fail 'Bat config was not linked'
[[ ! -e "$TEST_HOME/.config/bat.pre-dotfiles" ]] || fail 'legacy Bat directory was backed up'
[[ -L "$TEST_HOME/.config/btop" ]] || fail 'Btop config was not linked'
[[ -L "$TEST_HOME/.config/lazygit" ]] || fail 'Lazygit config was not linked'
[[ "$(readlink -- "$TEST_HOME/.config/ghostty")" == "$ROOT/config/ghostty" ]] ||
  fail 'legacy Ghostty config was not migrated'
[[ -L "$TEST_HOME/.config/hunk" ]] || fail 'Hunk config was not linked'
[[ -d "$TEST_HOME/.local/bin" && ! -L "$TEST_HOME/.local/bin" ]] || fail '.local/bin was not created as a real directory'
[[ -L "$TEST_HOME/.local/bin/git-aliases" ]] || fail 'Git alias guide was not linked'
[[ -L "$TEST_HOME/.local/bin/skillset" ]] || fail 'skillset was not linked'
[[ -L "$TEST_HOME/.local/bin/ssh-to" ]] || fail 'ssh-to was not linked'
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

zsh "$ROOT/tests/cliq.zsh" \
  || fail 'cliq safety gate tests failed'

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
  "$ROOT/install.sh" </dev/null

diff -ruN -- "$FIRST_INSTALL" "$TEST_HOME" || fail 'second install changed the target home'

after_status="$(git -C "$ROOT" status --porcelain=v1)"
[[ "$before_status" == "$after_status" ]] || fail 'installer modified its source repository'

HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/.config" \
  "$ROOT/uninstall.sh"

[[ ! -L "$TEST_HOME/.config/starship.toml" ]] || fail 'starship symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.config/ghostty" ]] || fail 'Ghostty symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.config/yazi" ]] || fail 'Yazi symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.config/btop" ]] || fail 'Btop symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.config/lazygit" ]] || fail 'Lazygit symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.config/bat" ]] || fail 'Bat symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.config/delta" ]] || fail 'Delta symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.config/glow" ]] || fail 'Glow symlink remained after uninstall'
[[ -d "$TEST_HOME/.config/herdr" && ! -L "$TEST_HOME/.config/herdr" ]] ||
  fail 'Herdr state directory was removed after uninstall'
[[ ! -L "$TEST_HOME/.config/herdr/config.toml" ]] || fail 'Herdr config symlink remained after uninstall'
[[ -f "$TEST_HOME/.config/herdr/plugins/github/example/herdr-plugin.toml" ]] ||
  fail 'Herdr plugin state was removed after uninstall'
[[ -f "$TEST_HOME/.config/herdr/plugins.json" ]] || fail 'Herdr plugin registry was removed after uninstall'
[[ ! -L "$TEST_HOME/.config/hunk" ]] || fail 'Hunk symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.config/ov" ]] || fail 'Ov symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.config/worktrunk" ]] || fail 'Worktrunk symlink remained after uninstall'
[[ -f "$TEST_HOME/.config/worktrunk/state.yml" ]] || fail 'Worktrunk state was not restored'
[[ ! -e "$TEST_HOME/.config/worktrunk/config.toml" ]] ||
  fail 'legacy Worktrunk link was restored after uninstall'
[[ ! -e "$TEST_HOME/.config/bat" ]] || fail 'legacy Bat directory was restored after uninstall'
grep -Fq 'existing yazi config' "$TEST_HOME/.config/yazi/yazi.toml" || fail 'Yazi backup was not restored'
grep -Fq 'existing starship config' "$TEST_HOME/.config/starship.toml" || fail 'starship backup was not restored'
[[ ! -L "$TEST_HOME/.local/bin/git-aliases" ]] || fail 'Git alias guide symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.local/bin/skillset" ]] || fail 'skillset symlink remained after uninstall'
[[ ! -L "$TEST_HOME/.local/bin/ssh-to" ]] || fail 'ssh-to symlink remained after uninstall'
grep -Fq 'helper = existing-helper' "$TEST_HOME/.gitconfig" || fail 'Git credential helper was lost during uninstall'
if grep -Fq '# >>> dotfiles:' "$TEST_HOME/.bashrc" "$TEST_HOME/.zshrc" "$TEST_HOME/.gitconfig"; then
  fail 'managed block remained after uninstall'
fi

printf 'install, idempotency, and uninstall tests passed\n'
