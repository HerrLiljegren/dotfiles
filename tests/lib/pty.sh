# shellcheck shell=bash

# Run a command under a pseudo-terminal with util-linux or BSD (macOS) script.
run_in_pty() {
  local command=''

  if script --version >/dev/null 2>&1; then
    printf -v command '%q ' "$@"
    script -qefc "$command" /dev/null
  else
    # BSD script sends EOF ahead of queued input once stdin closes, so hold
    # the pipe open while the command reads.
    { cat; sleep 1; } | script -qe /dev/null "$@"
  fi
}
