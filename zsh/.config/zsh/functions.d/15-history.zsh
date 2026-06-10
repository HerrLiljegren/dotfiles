# History picker helpers.

function history-fuzzy-search() {
  # ZLE widget bound in .zshrc. Opens a compact fzf picker for shell history and
  # places the selected command on the current prompt.
  unsetopt xtrace verbose
  emulate -L zsh -o no_xtrace -o no_verbose -o typeset_silent

  if ! (( $+commands[fzf] )); then
    zle history-incremental-search-backward
    return
  fi

  {
    exec </dev/tty
    exec <&1

    local line command selected
    local -A seen
    local -a commands

    function __history_fuzzy_add_command() {
      local item="$1"
      item="${item//$'\n'/ ; }"
      item="${item//$'\t'/ }"
      item="${item#"${item%%[![:space:]]*}"}"
      item="${item%"${item##*[![:space:]]}"}"

      [[ -z "$item" || -n "${seen[$item]}" ]] && return
      seen[$item]=1
      commands+=("$item")
    }

    while IFS= read -r line; do
      if [[ "$line" =~ '^[[:space:]]*[0-9]+\*?[[:space:]]+(.*)$' ]]; then
        __history_fuzzy_add_command "$command"
        command="${match[1]}"
      else
        command+=$'\n'"$line"
      fi
    done < <(fc -rl 1)
    __history_fuzzy_add_command "$command"

    selected=$(
      print -rl -- "${commands[@]}" | fzf \
        --height=40% \
        --reverse \
        --border \
        --border-label=' history ' \
        --prompt='history> ' \
        --query="$BUFFER" \
        --tiebreak=index \
        --bind='ctrl-r:toggle-sort' \
        --bind='ctrl-y:accept' \
        --preview='print -r -- {}' \
        --preview-window='down:3:wrap'
    )

    zle reset-prompt >/dev/null 2>&1 || true
    [[ -z "$selected" ]] && return

    BUFFER="$selected"
    CURSOR=${#BUFFER}
    zle redisplay
  }
}
