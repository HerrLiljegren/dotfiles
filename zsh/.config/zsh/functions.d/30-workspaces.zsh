# Workspace picker helpers.

function __ws_pick_and_open() {
  unsetopt xtrace verbose
  emulate -L zsh -o no_xtrace -o no_verbose -o typeset_silent

  # Search ~/dev, or an optional path passed as the first argument, for VS Code
  # workspace files. The picker shows project and worktree. Selecting an entry
  # opens its hidden .code-workspace path in a new VS Code window.
  local dev_root="${1:-$HOME/dev}"
  local selected workspace project worktree workspace_dir rel row header
  local project_width=7 worktree_width=8
  local -a rows

  if [[ ! -d "$dev_root" ]]; then
    print "No dev folder found: $dev_root" >&2
    return 1
  fi

  while IFS= read -r -d '' workspace; do
    workspace_dir="${workspace:h}"
    rel="${workspace#$dev_root/}"

    if [[ "$rel" == worktrees/*/*/* ]]; then
      project="${rel#worktrees/}"
      project="${project%%/*}"
      worktree="${rel#worktrees/$project/}"
      worktree="${worktree%%/*}"
    elif [[ "$rel" == */.worktrees/*/* ]]; then
      project="${rel%%/.worktrees/*}"
      project="${project:t}"
      worktree="${rel#*/.worktrees/}"
      worktree="${worktree%%/*}"
    else
      project="${workspace_dir:t}"
      worktree="main"
    fi

    (( ${#project} > project_width )) && project_width=${#project}
    (( ${#worktree} > worktree_width )) && worktree_width=${#worktree}
    rows+=("${project}"$'\t'"${worktree}"$'\t'"${workspace}")
  done < <(find "$dev_root" -type f -name '*.code-workspace' -print0 2>/dev/null)

  if (( ${#rows[@]} == 0 )); then
    print "No VS Code workspaces found under: $dev_root" >&2
    return 1
  fi

  if (( $+commands[fzf] )); then
    header=$(printf "%-${project_width}s  %-${worktree_width}s" "project" "worktree")
    selected=$(
      for row in "${rows[@]}"; do
        IFS=$'\t' read -r project worktree workspace <<< "$row"
        printf "%-${project_width}s  %-${worktree_width}s\t%s\n" "$project" "$worktree" "$workspace"
      done | fzf \
      --height=40% \
      --reverse \
      --border \
      --border-label=' workspaces ' \
      --prompt='workspace> ' \
      --header="$header" \
      --delimiter=$'\t' \
      --nth=1 \
      --with-nth=1
    ) || return 0
    [[ -z "$selected" ]] && return 0
    workspace="${selected##*$'\t'}"
  else
    local i=1 choice
    print "Pick workspace:"
    for row in "${rows[@]}"; do
      IFS=$'\t' read -r project worktree workspace <<< "$row"
      printf "  %2d) %-${project_width}s  %-${worktree_width}s\n" "$i" "$project" "$worktree"
      i=$((i+1))
    done
    vared -p "Select [1-${#rows[@]}]: " choice
    if ! [[ "$choice" == <-> ]] || (( choice < 1 || choice > ${#rows[@]} )); then
      return 0
    fi
    workspace="${rows[$choice]##*$'\t'}"
  fi

  if ! (( $+commands[code] )); then
    print "VS Code CLI not found: code" >&2
    return 1
  fi

  code -n "$workspace" >/dev/null 2>&1 &!
}

function ws() {
  # Plain command form: run `ws` from the prompt.
  unsetopt xtrace verbose
  __ws_pick_and_open "$@"
}

function ws-widget() {
  # ZLE widget form, matching the Alt+s sesh picker. Taking input from /dev/tty
  # lets fzf own the terminal cleanly even while the line editor is active.
  unsetopt xtrace verbose
  {
    exec </dev/tty
    exec <&1
    __ws_pick_and_open "$@"
    zle reset-prompt >/dev/null 2>&1 || true
  }
}
