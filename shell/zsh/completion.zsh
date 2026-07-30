# Native completion plus fzf-backed history, files, and directories.

autoload -Uz compinit
mkdir -p -- "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height=40% --layout=reverse --border}"
export FZF_CTRL_R_OPTS="--border-label=' history ' --tiebreak=index"
export FZF_COMPLETION_TRIGGER='**'
export FZF_COMPLETION_PATH_OPTS='--preview="bat --color=always --style=numbers --line-range=:500 {}" --preview-window=right:75%'
export FZF_COMPLETION_DIR_OPTS='--preview="eza -1 --color=always --icons {}" --preview-window=right:75%'

_fzf_compgen_path() {
  fd --hidden --follow --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude .git . "$1"
}

source <(fzf --zsh)
