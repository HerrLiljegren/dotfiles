# Session picker helpers.

function sesh-sessions() {
  # zle widget bound in .zshrc. Opens a compact fzf picker for sesh sessions and
  # connects to the selected session. Escape cancels without changing state.
  unsetopt xtrace verbose
  emulate -L zsh -o no_xtrace -o no_verbose -o typeset_silent

  {
    exec </dev/tty
    exec <&1

    local selected session project worktree row header sep
    local name_width=15 worktree_width=8
    local -a rows

    sep=$'\x1f'

    while IFS= read -r session; do
      [[ -z "$session" ]] && continue

      if [[ "$session" == *" "* ]]; then
        project="${session%% *}"
        worktree="${session#* }"
      else
        project="$session"
        worktree=""
      fi

      (( ${#project} > name_width )) && name_width=${#project}
      (( ${#worktree} > worktree_width )) && worktree_width=${#worktree}
      rows+=("${project}${sep}${worktree}${sep}${session}")
    done < <(sesh list -t -c)

    if (( ${#rows[@]} == 0 )); then
      zle reset-prompt >/dev/null 2>&1 || true
      return
    fi

    header=$(printf "%-${name_width}s  %-${worktree_width}s" "project/session" "worktree")
    selected=$(
      for row in "${rows[@]}"; do
        IFS="$sep" read -r project worktree session <<< "$row"
        printf "%-${name_width}s  %-${worktree_width}s%s%s\n" "$project" "$worktree" "$sep" "$session"
      done | fzf \
        --height=40% \
        --reverse \
        --border-label ' sesh ' \
        --border \
        --prompt 'session> ' \
        --header="$header" \
        --delimiter="$sep" \
        --nth=1 \
        --with-nth=1
    )
    zle reset-prompt >/dev/null 2>&1 || true
    [[ -z "$selected" ]] && return
    session="${selected##*${sep}}"
    sesh connect "$session"
  }
}
