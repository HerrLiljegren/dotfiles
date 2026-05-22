# .NET project helpers.

dprun() {
  emulate -L zsh

  # Pick a launchSettings.json profile from the current tree and run it with
  # dotnet. Use `dprun --watch [root]` or `dprun -w [root]` for dotnet watch.
  local mode="run"
  [[ "$1" == "--watch" || "$1" == "-w" ]] && { mode="watch"; shift; }

  local root="${1:-.}"
  local tmp selected project profile
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' RETURN

  while IFS= read -r -d '' launch_file; do
    local project_dir project_file
    project_dir="${launch_file%/Properties/launchSettings.json}"
    project_file=("${project_dir}"/*.csproj(N))

    [[ ${#project_file} -eq 0 ]] && continue

    jq -r --arg p "${project_file[1]}" --arg l "$launch_file" \
      '.profiles | keys[] | "\($p)\t\(. )\t\($l)"' "$launch_file" >> "$tmp"
  done < <(find "$root" -type f -name launchSettings.json -print0)

  if [[ ! -s "$tmp" ]]; then
    print "No launch profiles found under: $root" >&2
    return 1
  fi

  if (( $+commands[fzf] )); then
    selected="$(fzf --prompt='launch profile> ' --delimiter=$'\t' --with-nth=1,2 < "$tmp")" || return 0
    [[ -z "$selected" ]] && return 0
    project="${selected%%$'\t'*}"
    profile="${selected#*$'\t'}"; profile="${profile%%$'\t'*}"
  else
    local -a rows
    local i=1 choice
    print "Pick profile:"
    while IFS=$'\t' read -r project profile launch_file; do
      rows+=("$project\t$profile\t$launch_file")
      printf "  %2d) %s (%s)\n" "$i" "$profile" "$(basename "$project" .csproj)"
      i=$((i+1))
    done < "$tmp"
    vared -p "Select [1-${#rows[@]}]: " choice
    if ! [[ "$choice" == <-> ]] || (( choice < 1 || choice > ${#rows[@]} )); then
      return 0
    fi

    selected="${rows[$choice]}"
    IFS=$'\t' read -r project profile _ <<< "$selected"
  fi

  if [[ "$mode" == "watch" ]]; then
    dotnet watch run --project "$project" --launch-profile "$profile"
  else
    dotnet run --project "$project" --launch-profile "$profile"
  fi
}
