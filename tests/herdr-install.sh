#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  printf 'test failure: %s\n' "$*" >&2
  exit 1
}

fake_bin=$TEST_ROOT/bin
mkdir -p -- "$fake_bin"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf '\''{"running":%s}\n'\'' "${HERDR_TEST_RUNNING:-false}"' \
  >"$fake_bin/herdr"
chmod +x "$fake_bin/herdr"

install_home=$TEST_ROOT/install-home
mkdir -p -- "$install_home/.config/herdr/plugins/github/example"
ln -s "$ROOT/config/herdr/config.toml" "$install_home/.config/herdr/config.toml"
printf 'installed plugin\n' >"$install_home/.config/herdr/plugins/github/example/herdr-plugin.toml"
printf '[]\n' >"$install_home/.config/herdr/plugins.json"

PATH=/usr/bin:/bin \
HOME="$install_home" \
XDG_CONFIG_HOME="$install_home/.config" \
  "$ROOT/install.sh" --with none >/dev/null

[[ -d "$install_home/.config/herdr" && ! -L "$install_home/.config/herdr" ]] ||
  fail 'Herdr state directory was replaced with a symlink'
[[ -L "$install_home/.config/herdr/config.toml" ]] || fail 'Herdr config was not linked'
[[ -f "$install_home/.config/herdr/plugins/github/example/herdr-plugin.toml" ]] ||
  fail 'Herdr plugin state was not preserved'
[[ -f "$install_home/.config/herdr/plugins.json" ]] || fail 'Herdr plugin registry was not preserved'

HOME="$install_home" \
XDG_CONFIG_HOME="$install_home/.config" \
  "$ROOT/uninstall.sh" >/dev/null

[[ -d "$install_home/.config/herdr" && ! -L "$install_home/.config/herdr" ]] ||
  fail 'Herdr state directory was removed after uninstall'
[[ ! -L "$install_home/.config/herdr/config.toml" ]] || fail 'Herdr config symlink remained after uninstall'
[[ -f "$install_home/.config/herdr/plugins/github/example/herdr-plugin.toml" ]] ||
  fail 'Herdr plugin state was removed after uninstall'
[[ -f "$install_home/.config/herdr/plugins.json" ]] || fail 'Herdr plugin registry was removed after uninstall'

migration_home=$TEST_ROOT/migration-home
mkdir -p -- "$migration_home/.config/herdr.pre-dotfiles/plugins/github/example"
ln -s "$ROOT/config/herdr" "$migration_home/.config/herdr"
printf 'installed plugin\n' \
  >"$migration_home/.config/herdr.pre-dotfiles/plugins/github/example/herdr-plugin.toml"
printf '[]\n' >"$migration_home/.config/herdr.pre-dotfiles/plugins.json"

PATH="$fake_bin:/usr/bin:/bin" \
HOME="$migration_home" \
XDG_CONFIG_HOME="$migration_home/.config" \
  "$ROOT/install.sh" --with none >/dev/null

[[ -d "$migration_home/.config/herdr" && ! -L "$migration_home/.config/herdr" ]] ||
  fail 'legacy Herdr directory symlink was not migrated'
[[ ! -e "$migration_home/.config/herdr.pre-dotfiles" ]] || fail 'Herdr state backup was not restored'
[[ -L "$migration_home/.config/herdr/config.toml" ]] || fail 'migrated Herdr config was not linked'
[[ -f "$migration_home/.config/herdr/plugins/github/example/herdr-plugin.toml" ]] ||
  fail 'backed-up Herdr plugin state was not restored'
[[ -f "$migration_home/.config/herdr/plugins.json" ]] || fail 'backed-up Herdr plugin registry was not restored'

running_home=$TEST_ROOT/running-home
mkdir -p -- "$running_home/.config"
ln -s "$ROOT/config/herdr" "$running_home/.config/herdr"

if PATH="$fake_bin:/usr/bin:/bin" \
  HOME="$running_home" \
  XDG_CONFIG_HOME="$running_home/.config" \
  HERDR_TEST_RUNNING=true \
  "$ROOT/install.sh" --with none >"$TEST_ROOT/running.log" 2>&1; then
  fail 'installer migrated Herdr config while the server was running'
fi
grep -Fq 'stop the Herdr server' "$TEST_ROOT/running.log" ||
  fail 'running Herdr error was not actionable'
[[ -L "$running_home/.config/herdr" ]] || fail 'running Herdr config was changed'

printf 'Herdr install and migration tests passed\n'
