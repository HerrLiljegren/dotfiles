# Tool integrations supplied by the workstation or Workbench Feature.

setopt auto_cd interactive_comments
alias reload='exec zsh'
alias -g C='| wl-copy'

y() {
  local cwd_file cwd yazi_status

  cwd_file="$(mktemp -t yazi-cwd.XXXXXX)" || return
  command yazi "$@" --cwd-file="$cwd_file"
  yazi_status=$?
  cwd="$(<"$cwd_file")"
  command rm -f -- "$cwd_file"

  ((yazi_status == 0)) || return "$yazi_status"
  [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
}

eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
eval "$(wt config shell init zsh)"
