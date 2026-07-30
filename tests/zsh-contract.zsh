dotfiles_contract_fail() {
  print -ru2 -- "test failure: $1"
  exit 1
}

[[ "$HISTFILE" == "$HOME/.zsh_history" ]] ||
  dotfiles_contract_fail "Zsh history is not stored under HOME"
(( $+functions[prompt_starship_precmd] )) ||
  dotfiles_contract_fail "Starship was not initialized"
bindkey "^R" | grep -Fq "fzf-history-widget" ||
  dotfiles_contract_fail "Ctrl-R does not open fzf history"
bindkey "^[[A" | grep -Fq "history-substring-search-up" ||
  dotfiles_contract_fail "Up does not search history substrings"
bindkey "^[[B" | grep -Fq "history-substring-search-down" ||
  dotfiles_contract_fail "Down does not search history substrings"
[[ "$(bindkey -lL main)" == "bindkey -A emacs main" ]] ||
  dotfiles_contract_fail "the active ZLE keymap is not Emacs-style"
bindkey "^E" | grep -Fq "end-of-line" ||
  dotfiles_contract_fail "Ctrl-E does not move to the end and accept suggestions"
bindkey "^X^E" | grep -Fq "edit-command-line" ||
  dotfiles_contract_fail "Ctrl-X Ctrl-E does not edit the command in VISUAL"
bindkey "^[[H" | grep -Fq "beginning-of-line" ||
  dotfiles_contract_fail "Home does not move to the beginning of the line"
bindkey "^[[F" | grep -Fq "end-of-line" ||
  dotfiles_contract_fail "End does not move to the end of the line"
bindkey "^[[3~" | grep -Fq "delete-char" ||
  dotfiles_contract_fail "Delete does not remove the character under the cursor"
(( $+functions[_zsh_autosuggest_start] )) ||
  dotfiles_contract_fail "Zsh autosuggestions were not loaded"
(( $+functions[_zsh_highlight] )) ||
  dotfiles_contract_fail "Zsh syntax highlighting was not loaded"
(( $+functions[history-substring-search-up] )) ||
  dotfiles_contract_fail "Zsh history substring search was not loaded"
whence -w -- -ftb-complete | grep -Fq "function" ||
  dotfiles_contract_fail "fzf-tab was not loaded"
[[ "$DOTFILES_PERSONAL_ZSH_LOADED" == 1 ]] ||
  dotfiles_contract_fail "personal.zsh was not loaded"

print "Zsh shell contract passed"
