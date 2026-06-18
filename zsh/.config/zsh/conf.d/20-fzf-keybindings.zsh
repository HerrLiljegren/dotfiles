# fzf path completion.
#
# Test 2: keep normal Tab behavior, and use **<Tab> for recursive path search.

if (( $+commands[fzf] && $+commands[fd] )); then
  export FZF_COMPLETION_TRIGGER='**'
  export FZF_COMPLETION_PATH_OPTS='--preview="bat --color=always --style=numbers --line-range=:500 {}" --preview-window=right:75%'
  export FZF_COMPLETION_DIR_OPTS='--preview="eza -1 --color=always --icons {}" --preview-window=right:75%'

  _fzf_compgen_path() {
    fd --hidden --follow --exclude .git . "$1"
  }

  _fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude .git . "$1"
  }

  source /usr/share/fzf/completion.zsh
fi
