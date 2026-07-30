dotfiles_history_cursor_fail() {
  print -ru2 -- "test failure: $1"
  exit 1
}

source "$DOTFILES_TEST_ROOT/shell/zsh.sh"

print -s -- "echo dotfilesneedle older"
print -s -- "dotfilesneedle newer"
print -s -- "echo unrelated latest"

dotfiles_capture_history_state() {
  typeset -g DOTFILES_CAPTURED_BUFFER=$BUFFER
  typeset -g DOTFILES_CAPTURED_CURSOR=$CURSOR
  typeset -g DOTFILES_CAPTURED_LENGTH=${#BUFFER}
  zle accept-line
}
zle -N dotfiles_capture_history_state
bindkey '^X' dotfiles_capture_history_state

zle-line-init() {
  zle -U $'\e[A\e[A\x18'
}
zle -N zle-line-init

BUFFER=dotfilesneedle
vared -h BUFFER

[[ "$DOTFILES_CAPTURED_BUFFER" == "echo dotfilesneedle older" ]] ||
  dotfiles_history_cursor_fail "repeated Up did not cycle substring matches"
[[ "$DOTFILES_CAPTURED_CURSOR" == "$DOTFILES_CAPTURED_LENGTH" ]] ||
  dotfiles_history_cursor_fail "history search did not leave the cursor at end-of-line"

print "Zsh history cursor contract passed"
