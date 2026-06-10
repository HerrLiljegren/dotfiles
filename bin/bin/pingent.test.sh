#!/usr/bin/env bash
set -euo pipefail

PINGENT_BIN="/home/jesper/bin/pingent"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

FAKE_NOTIFY="$TEST_DIR/notify-send"
cat > "$FAKE_NOTIFY" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$PINGENT_TEST_NOTIFY_LOG"
EOF
chmod +x "$FAKE_NOTIFY"

run_pingent_json() {
  local name="$1"
  local payload="$2"
  local expected="$3"
  local logfile="$TEST_DIR/$name.log"
  local config_dir="$TEST_DIR/$name-config"

  mkdir -p "$config_dir"
  : > "$logfile"
  printf '%s' "$payload" | \
    PATH="$TEST_DIR:$PATH" \
    PINGENT_CONFIG_DIR="$config_dir" \
    PINGENT_TEST_NOTIFY_LOG="$logfile" \
    "$PINGENT_BIN"

  grep -F -- "$expected" "$logfile" >/dev/null
}

run_pingent_args() {
  local name="$1"
  local expected="$2"
  shift 2
  local logfile="$TEST_DIR/$name.log"
  local config_dir="$TEST_DIR/$name-config"

  mkdir -p "$config_dir"
  : > "$logfile"
  PATH="$TEST_DIR:$PATH" \
    PINGENT_CONFIG_DIR="$config_dir" \
    PINGENT_TEST_NOTIFY_LOG="$logfile" \
    "$PINGENT_BIN" "$@"

  grep -F -- "$expected" "$logfile" >/dev/null
}

run_pingent_json_with_env() {
  local name="$1"
  local payload="$2"
  local config_dir="$3"
  local logfile="$TEST_DIR/$name.log"

  : > "$logfile"
  printf '%s' "$payload" | \
    PATH="$TEST_DIR:$PATH" \
    PINGENT_CONFIG_DIR="$config_dir" \
    PINGENT_TEST_NOTIFY_LOG="$logfile" \
    "$PINGENT_BIN"
}

assert_pingent_json_silent() {
  local name="$1"
  local payload="$2"
  local config_dir="$3"
  local logfile="$TEST_DIR/$name.log"

  : > "$logfile"
  printf '%s' "$payload" | \
    PATH="$TEST_DIR:$PATH" \
    PINGENT_CONFIG_DIR="$config_dir" \
    PINGENT_TEST_NOTIFY_LOG="$logfile" \
    "$PINGENT_BIN"

  if [ -s "$logfile" ]; then
    echo "expected $name notification to be suppressed" >&2
    exit 1
  fi
}

assert_pingent_args_silent() {
  local name="$1"
  local config_dir="$2"
  shift 2
  local logfile="$TEST_DIR/$name.log"

  : > "$logfile"
  PATH="$TEST_DIR:$PATH" \
    PINGENT_CONFIG_DIR="$config_dir" \
    PINGENT_TEST_NOTIFY_LOG="$logfile" \
    "$PINGENT_BIN" "$@"

  if [ -s "$logfile" ]; then
    echo "expected $name notification to be suppressed" >&2
    exit 1
  fi
}

run_pingent_json codex_attention \
  '{"hook_event_name":"PermissionRequest","cwd":"/tmp/demo","tool_input":{"command":"git push"}}' \
  '-u normal -t 8000 -e -r 271828 Pingent: codex codex needs your input in demo'

DEFAULT_CONFIG_DIR="$TEST_DIR/default-config"
mkdir -p "$DEFAULT_CONFIG_DIR"

assert_pingent_json_silent codex_complete_default \
  '{"hook_event_name":"Stop","cwd":"/tmp/demo"}' \
  "$DEFAULT_CONFIG_DIR"

assert_pingent_args_silent args_complete_default \
  "$DEFAULT_CONFIG_DIR" \
  copilot complete 'copilot finished in repo'

CONFIG_DIR="$TEST_DIR/config"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/config.json" <<'EOF'
{
  "enabledEvents": ["attention", "complete", "error"],
  "minCompleteSeconds": 10,
  "dedupeSeconds": 60,
  "messages": {
    "attention": "{source}: action needed in {projectName}",
    "complete": "{source}: done in {projectName}",
    "error": "{source}: failed in {projectName}"
  }
}
EOF

assert_pingent_json_silent opencode_error_default \
  '{"source":"opencode","event":"session.error","projectName":"demo"}' \
  "$DEFAULT_CONFIG_DIR"

assert_pingent_json_silent short_complete \
  '{"source":"opencode","event":"session.idle","projectName":"demo","durationSeconds":2}' \
  "$CONFIG_DIR"

run_pingent_json_with_env dedupe_first '{"source":"opencode","event":"permission.asked","projectName":"demo","key":"demo-key"}' "$CONFIG_DIR"
run_pingent_json_with_env dedupe_second '{"source":"opencode","event":"permission.asked","projectName":"demo","key":"demo-key"}' "$CONFIG_DIR"
if [ -s "$TEST_DIR/dedupe_second.log" ]; then
  echo 'expected second duplicate alert to be suppressed' >&2
  exit 1
fi

run_pingent_json_with_env config_message '{"source":"opencode","event":"session.error","projectName":"demo"}' "$CONFIG_DIR"
grep -F -- '-u normal -t 8000 -e -r 271828 Pingent: opencode opencode: failed in demo' "$TEST_DIR/config_message.log" >/dev/null

grep -F 'permission.asked' /home/jesper/.config/opencode/plugins/pingent.ts >/dev/null
grep -F 'question' /home/jesper/.config/opencode/plugins/pingent.ts >/dev/null

grep -F 'hooks = true' /home/jesper/.codex/config.toml >/dev/null
grep -F 'PermissionRequest' /home/jesper/.codex/hooks.json >/dev/null
grep -F 'Stop' /home/jesper/.codex/hooks.json >/dev/null
grep -F '/home/jesper/bin/pingent' /home/jesper/.codex/hooks.json >/dev/null

grep -F 'sessionEnd' /home/jesper/.config/pingent/copilot-hooks/copilot-pingent.json >/dev/null
grep -F 'preToolUse' /home/jesper/.config/pingent/copilot-hooks/copilot-pingent.json >/dev/null
grep -F '/home/jesper/bin/pingent' /home/jesper/.config/pingent/copilot-hooks/pingent-hook.sh >/dev/null

grep -F '.github/hooks/' /home/jesper/.config/pingent/README.md >/dev/null
grep -F '~/.codex/hooks.json' /home/jesper/.config/pingent/README.md >/dev/null
grep -F '~/.config/opencode/plugins/pingent.ts' /home/jesper/.config/pingent/README.md >/dev/null
grep -F 'notify-send "Test" "Hello"' /home/jesper/.config/pingent/README.md >/dev/null

grep -F 'PINGENT_DEBUG_LOG' /home/jesper/bin/pingent >/dev/null
grep -F 'enabledEvents' /home/jesper/bin/pingent.test.sh >/dev/null

echo 'PASS: pingent normalization smoke tests'
