# Tool integrations supplied by the workstation or Workbench Feature.

setopt auto_cd interactive_comments
alias reload='exec zsh'
alias -g C='| wl-copy'

eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
eval "$(wt config shell init zsh)"
