# shellcheck shell=zsh
# cliq: natural-language shell commands via pi + deepseek-v4-flash.
#
# Default mode inserts the suggested command into the edit buffer for review;
# nothing runs. `cliq -x` / `cliq --run` evaluates the command only after a
# verdict-gated confirmation. The verdict never trusts the model: a static
# pattern gate (Layer 1) classifies the suggestion as ok/caution/danger, and
# execution friction scales with the verdict (Layer 2). Executed suggestions
# are audited because eval'ed commands never reach zsh history (Layer 3).

# Global hardening, part of the same safety model: `rm *`-style commands wait
# for confirmation instead of running silently.
setopt rm_star_wait
setopt rm_star_silent

# Classify a shell command by static patterns. Returns one of:
#   ok       safe enough to run after a plain yes/no
#   caution  destructive or system-mutating; requires typed confirmation
#   danger   root-targeting or obviously harmful; refused without --force

# True when an rm command in the request targets an absolute path such as
# /etc or a standalone / argument. Token-aware so paths in other commands
# (cd / && rm -rf *) and trailing-slash arguments (rm -rf dist/ node_modules/)
# do not trip the root rule.
_cliq_rm_targets_root() {
  local req="$1"
  local seg='' token='' cmd=''
  local -a tokens=()
  local i=0 j=0
  for seg in "${(@s[;])req}"; do
    tokens=("${(@z)seg}")
    for ((i = 1; i <= $#tokens; i++)); do
      [[ "${tokens[i]}" == rm ]] || continue
      for ((j = i + 1; j <= $#tokens; j++)); do
        [[ "${tokens[j]}" == /* ]] && return 0
      done
    done
  done
  return 1
}

_cliq_verdict() {
  local command="$*"
  local danger='sudo[[:space:]]+rm|(^|[;&|[:space:]])mkfs|dd[[:space:]]+[^|;]*of=/dev/|:\(\)\{|(^|[;&|[:space:]])>[[:space:]]*/dev/sd|(^|[;&|[:space:]])chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/|(curl|wget)[[:space:]]+[^|;]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh'
  local caution='(^|[;&|[:space:]])sudo[[:space:]]|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+push[[:space:]]+[^|;]*(--force|-f([^[:alnum:]]|$))|(^|[;&|[:space:]])rm[[:space:]]+(-[a-z]*r[a-z]*[[:space:]]+|-f)|kill[[:space:]]+-9|(^|[;&|[:space:]])(pkill|killall|shutdown|reboot|poweroff|halt)|find[[:space:]]+[^|;]*-delete|(^|[;&|[:space:]])docker[[:space:]]+rmi[[:space:]]+-f|>[[:space:]]*/etc/|(chmod|chown)[[:space:]]+-R|pip[[:space:]]+install|npm[[:space:]]+install[[:space:]]+-g|cargo[[:space:]]+install'

  _cliq_rm_targets_root "$command" && { print -r -- danger; return }
  [[ "$command" =~ $danger ]] && { print -r -- danger; return }
  [[ "$command" =~ $caution ]] && { print -r -- caution; return }
  print -r -- ok
}

# Reduce a model reply to a single clean command line: strip markdown
# fences, surrounding whitespace, and anything past the first newline.
_cliq_scrub() {
  local fence='```'
  local reply="$*"
  reply="${reply#"${reply%%[![:space:]]*}"}" # trim leading whitespace
  reply="${reply//$'\r'/}"                   # drop carriage returns
  [[ "$reply" == "$fence"* ]] && reply="${reply#*$'\n'}"
  reply="${reply%%$'\n'*}"                   # keep only the first line
  reply="${reply#"${reply%%[![:space:]]*}"}" # trim leading whitespace again
  reply="${reply%"${reply##*[![:space:]]}"}" # trim trailing whitespace
  reply="${reply%"$fence"}"                  # drop a trailing fence, if any
  print -r -- "$reply"
}

# Record an executed suggestion: timestamp, cwd, verdict, and the command.
_cliq_audit() {
  local log="${CLIQ_LOG:-${XDG_DATA_HOME:-$HOME/.local/share}/cliq/log}"
  local cmd="$1"
  local verdict="$2"
  mkdir -p -- "${log:h}" 2>/dev/null || return 0
  printf '%s\t%s\t%s\t%s\n' "$(date +%FT%T%z)" "$PWD" "$verdict" "$cmd" >>"$log"
  print -ru2 -- "cliq: executed [$verdict]; logged to $log"
}

# Usage: cliq [-x|--run] [--force] <natural-language request>
cliq() {
  local run=0
  local force=0
  local -a request=()
  local arg='' question='' reply='' cmd='' verdict='' confirm=''
  local model='' system_prompt=''

  for arg in "$@"; do
    case "$arg" in
      -x | --run) run=1 ;;
      --force) force=1 ;;
      -*) print -ru2 -- "cliq: unknown option: $arg"; return 2 ;;
      *) request+=("$arg") ;;
    esac
  done
  (( $#request )) || {
    print -ru2 -- 'usage: cliq [-x|--run] [--force] <natural-language request>'
    return 2
  }

  question="${(j: :)request}"
  model="${CLIQ_MODEL:-opencode-go/deepseek-v4-flash}"
  system_prompt='You are an expert Zsh user on Linux. Reply with ONLY a single-line shell command that fulfills the request. Output no explanation, no markdown fences, no commentary, and no leading prompt marker.'

  # Layer 0: the model can only print text. -nt disables tools, -nc skips
  # AGENTS.md context, and --no-session keeps the run ephemeral.
  reply="$(command pi -p --model "$model" -nt -nc --no-session --system-prompt "$system_prompt" "$question")" || {
    print -ru2 -- 'cliq: pi failed; is pi installed and the provider configured?'
    return 1
  }
  cmd="$(_cliq_scrub "$reply")"
  [[ -n "$cmd" ]] || {
    print -ru2 -- 'cliq: empty suggestion from the model'
    return 1
  }

  verdict="$(_cliq_verdict "$cmd")"

  # Default mode: put the command in the edit buffer for review. In a
  # non-interactive shell, print it to stdout so it can be piped on purpose.
  if (( ! run )); then
    if [[ -o interactive ]]; then
      print -ru2 -- "cliq [$verdict] inserted into the buffer for review:"
      print -rz -- "$cmd"
    else
      print -r -- "$cmd"
    fi
    return 0
  fi

  case "$verdict" in
    danger)
      if (( ! force )); then
        print -ru2 -- "cliq: refusing to run: $cmd"
        print -ru2 -- 'cliq: verdict is danger. Rerun with --force if you really mean it.'
        return 3
      fi
      ;&
    caution)
      # Typed confirmation defeats the muscle memory that defeats y/N prompts.
      print -ru2 -- "cliq [$verdict]: type the first ${CLIQ_CONFIRM_CHARS:-4} characters of the command to run it."
      print -ru2 -- "$cmd"
      IFS= read -r confirm
      [[ "$confirm" == "${cmd:0:${CLIQ_CONFIRM_CHARS:-4}}" ]] || {
        print -ru2 -- 'cliq: confirmation mismatch; nothing ran.'
        return 3
      }
      ;;
    ok)
      print -ru2 -- "cliq [$verdict]: run this command? (y/N)"
      print -ru2 -- "$cmd"
      IFS= read -r confirm
      [[ "$confirm" == [yY] || "$confirm" == [yY][eE][sS] ]] || {
        print -ru2 -- 'cliq: cancelled.'
        return 0
      }
      ;;
  esac

  _cliq_audit "$cmd" "$verdict"
  eval "$cmd"
}