#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

mkdir -p -- "$TEST_ROOT/bin"
cat >"$TEST_ROOT/config" <<'EOF'
Host proxmox build-host
Host *.internal
Host build-host
Host Alpha
EOF
cat >"$TEST_ROOT/bin/fzf" <<'EOF'
#!/usr/bin/env bash
tee "$SSH_FZF_INPUT_LOG" | awk -F '\t' '$1 == "proxmox" { print; exit }'
EOF
cat >"$TEST_ROOT/bin/ssh" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == -G ]]; then
  host="${!#}"
  user=tester
  [[ "$host" != build-host ]] || user=long-service-user
  printf 'hostname %s.example.test\nuser %s\nport 2222\nidentityfile %s/.ssh/id_test\n' "$host" "$user" "$HOME"
  exit
fi
printf '%s\n' "$*" >"$SSH_FZF_TEST_LOG"
EOF
chmod +x "$TEST_ROOT/bin/fzf" "$TEST_ROOT/bin/ssh"

PATH="$TEST_ROOT/bin:$PATH" \
SSH_FZF_CONFIG="$TEST_ROOT/config" \
SSH_FZF_INPUT_LOG="$TEST_ROOT/fzf-input.log" \
SSH_FZF_TEST_LOG="$TEST_ROOT/ssh.log" \
  "$ROOT/bin/ssh-to"

[[ "$(cat "$TEST_ROOT/ssh.log")" == proxmox ]]
[[ "$(cut -f1 "$TEST_ROOT/fzf-input.log" | tail -n +2)" == $'Alpha\nbuild-host\nproxmox' ]]
grep -Fq $'\033[38;2;203;166;247m󰒋' "$TEST_ROOT/fzf-input.log"
grep -Fq 'proxmox.example.test:2222' "$TEST_ROOT/fzf-input.log"
grep -Fq '~/.ssh/id_test' "$TEST_ROOT/fzf-input.log"
identity_columns="$(cut -f2- "$TEST_ROOT/fzf-input.log" | sed -E $'s/\\x1B\\[[0-9;]*m//g' | awk '{ print index($0, "󰌆") }' | sort -u)"
[[ "$(wc -l <<<"$identity_columns")" == 1 ]]
printf 'ssh-to test passed\n'
