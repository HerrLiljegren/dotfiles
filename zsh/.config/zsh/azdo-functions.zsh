# Azure DevOps shell helpers.
#
# These functions wrap the Azure DevOps Azure CLI extension with short,
# memorable commands for the operations that are useful from inside a repo.
#
# Requirements:
#   - Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli
#   - Azure DevOps extension: az extension add --name azure-devops
#   - Defaults configured with either:
#       azdo-defaults https://dev.azure.com/my-org "My Project"
#     or:
#       az devops configure --defaults organization=https://dev.azure.com/my-org project="My Project"
#
# Completion:
#   - .zshrc already adds ~/.config/zsh/completions to fpath and runs compinit.
#   - completions/_azdo_functions provides completions for these helpers.
#   - After editing completion files, run: rm ~/.zcompdump* && reload

__azdo_usage() {
  cat <<'EOF'
Azure DevOps helpers

Setup:
  azdo-defaults <organization-url> <project>
      Store Azure DevOps CLI defaults for this shell/user.

Inspection:
  azdo-status
      Show current Azure DevOps defaults and signed-in account.

Pull requests:
  azpr [active|mine|reviewing|completed|abandoned|all] [top]
      List pull requests in a compact table.

  azpr-open <id|current>
      Open a pull request in the browser. "current" resolves from the current
      git branch by looking for an active source-branch PR.

  azpr-checkout <id>
      Fetch and checkout a pull request branch using the Azure DevOps CLI.

Pipeline runs:
  azruns [all|running|queued|completed|failed|succeeded|partial|canceled] [branch|.] [top]
      List recent pipeline runs. Use "." for the current git branch.

  azrun-open <run-id>
      Open a pipeline run in the browser.

  azpipe-run <pipeline-id-or-name> [branch|.]
      Queue a pipeline run. Use "." for the current git branch.

Patterns:
  - Keep helpers thin: preserve Azure CLI flags where possible.
  - Prefer table output for scanning and JSON only for machine extraction.
  - Use "current" or "." for repo-context shortcuts instead of many bespoke flags.
  - Add completion in completions/_azdo_functions; keep function files source-only.
EOF
}

azdo-help() {
  emulate -L zsh
  __azdo_usage
}

__azdo_require_az() {
  if ! (( $+commands[az] )); then
    print -u2 "az is not installed or not on PATH."
    return 127
  fi
}

__azdo_current_branch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null
}

__azdo_branch_arg() {
  local branch="${1:-main}"
  if [[ "$branch" == "." || "$branch" == "current" ]]; then
    branch="$(__azdo_current_branch)"
  fi
  [[ -n "$branch" ]] && print -r -- "$branch"
}

__azdo_open_url() {
  local url="$1"
  if [[ -z "$url" || "$url" == "null" ]]; then
    print -u2 "No URL found."
    return 1
  fi

  if (( $+commands[xdg-open] )); then
    xdg-open "$url" >/dev/null 2>&1 &
  elif (( $+commands[open] )); then
    open "$url"
  else
    print -r -- "$url"
  fi
}

azdo-defaults() {
  emulate -L zsh
  __azdo_require_az || return

  if [[ "$1" == "-h" || "$1" == "--help" || $# -lt 2 ]]; then
    cat <<'EOF'
Usage: azdo-defaults <organization-url> <project>

Examples:
  azdo-defaults https://dev.azure.com/my-org "My Project"
  azdo-defaults https://my-org.visualstudio.com "My Project"
EOF
    return $(( $# < 2 ? 1 : 0 ))
  fi

  az devops configure --defaults organization="$1" project="$2"
}

azdo-status() {
  emulate -L zsh
  __azdo_require_az || return

  print "Azure DevOps defaults:"
  az devops configure --list
  print
  print "Azure account:"
  az account show --query '{Name:name, User:user.name, Tenant:tenantDisplayName}' -o table
}

azpr() {
  emulate -L zsh
  __azdo_require_az || return

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
Usage: azpr [active|mine|reviewing|completed|abandoned|all] [top]

Lists pull requests in the configured Azure DevOps project.
EOF
    return
  fi

  local filter="${1:-active}"
  local top="${2:-20}"
  local -a args
  args=(--top "$top")

  case "$filter" in
    active|open)
      args+=(--status active)
      ;;
    mine|created|created-by-me)
      args+=(--status active --creator "@me")
      ;;
    reviewing|reviewer)
      args+=(--status active --reviewer "@me")
      ;;
    completed|done)
      args+=(--status completed)
      ;;
    abandoned|closed)
      args+=(--status abandoned)
      ;;
    all)
      args+=(--status all)
      ;;
    *)
      print -u2 "Usage: azpr [active|mine|reviewing|completed|abandoned|all] [top]"
      return 1
      ;;
  esac

  az repos pr list "${args[@]}" \
    --query '[].{
      Id:pullRequestId,
      Title:title,
      Status:status,
      Author:createdBy.displayName,
      Source:sourceRefName,
      Target:targetRefName
    }' \
    -o table
}

__azdo_current_pr_id() {
  local branch="$(__azdo_current_branch)"
  if [[ -z "$branch" ]]; then
    return 1
  fi

  az repos pr list \
    --status active \
    --source-branch "$branch" \
    --query '[0].pullRequestId' \
    -o tsv
}

azpr-open() {
  emulate -L zsh
  __azdo_require_az || return

  if [[ "$1" == "-h" || "$1" == "--help" || $# -lt 1 ]]; then
    cat <<'EOF'
Usage: azpr-open <id|current>

Opens a pull request in the browser. "current" resolves the active PR for the
current git branch.
EOF
    return $(( $# < 1 ? 1 : 0 ))
  fi

  local id="$1"
  if [[ "$id" == "current" || "$id" == "." ]]; then
    id="$(__azdo_current_pr_id)"
  fi

  if [[ -z "$id" || "$id" == "null" ]]; then
    print -u2 "Could not resolve pull request id."
    return 1
  fi

  local url
  url="$(az repos pr show --id "$id" --query url -o tsv)"
  __azdo_open_url "$url"
}

azpr-checkout() {
  emulate -L zsh
  __azdo_require_az || return

  if [[ "$1" == "-h" || "$1" == "--help" || $# -lt 1 ]]; then
    cat <<'EOF'
Usage: azpr-checkout <id>

Fetches and checks out the pull request branch using Azure DevOps CLI.
EOF
    return $(( $# < 1 ? 1 : 0 ))
  fi

  az repos pr checkout --id "$1"
}

azruns() {
  emulate -L zsh
  __azdo_require_az || return

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
Usage: azruns [all|running|queued|completed|failed|succeeded|partial|canceled] [branch|.] [top]

Examples:
  azruns failed main 20
  azruns running . 10
EOF
    return
  fi

  local filter="${1:-all}"
  local branch
  branch="$(__azdo_branch_arg "${2:-main}")"
  local top="${3:-10}"
  local -a args

  args=(--branch "$branch" --top "$top" --query-order QueueTimeDesc)

  case "$filter" in
    all)
      ;;
    running|progress|inprogress)
      args+=(--status inProgress)
      ;;
    queued|notstarted)
      args+=(--status notStarted)
      ;;
    completed|done)
      args+=(--status completed)
      ;;
    failed|fail)
      args+=(--status completed --result failed)
      ;;
    succeeded|success|succeed)
      args+=(--status completed --result succeeded)
      ;;
    partial|partially)
      args+=(--status completed --result partiallySucceeded)
      ;;
    canceled|cancelled)
      args+=(--status completed --result canceled)
      ;;
    *)
      print -u2 "Usage: azruns [all|running|queued|completed|failed|succeeded|partial|canceled] [branch|.] [top]"
      return 1
      ;;
  esac

  az pipelines runs list "${args[@]}" \
    --query '[].{
      Id:id,
      Pipeline:definition.name,
      Status:status,
      Result:result,
      Branch:sourceBranch,
      Queued:queueTime,
      Finished:finishTime
    }' \
    -o table
}

azrun-open() {
  emulate -L zsh
  __azdo_require_az || return

  if [[ "$1" == "-h" || "$1" == "--help" || $# -lt 1 ]]; then
    cat <<'EOF'
Usage: azrun-open <run-id>

Opens a pipeline run in the browser.
EOF
    return $(( $# < 1 ? 1 : 0 ))
  fi

  local url
  url="$(az pipelines runs show --id "$1" --query url -o tsv)"
  __azdo_open_url "$url"
}

azpipe-run() {
  emulate -L zsh
  __azdo_require_az || return

  if [[ "$1" == "-h" || "$1" == "--help" || $# -lt 1 ]]; then
    cat <<'EOF'
Usage: azpipe-run <pipeline-id-or-name> [branch|.]

Queues a pipeline run. Numeric values are passed as --id; other values are
passed as --name. Branch defaults to the current git branch, then main.
EOF
    return $(( $# < 1 ? 1 : 0 ))
  fi

  local pipeline="$1"
  local branch
  branch="$(__azdo_branch_arg "${2:-.}")"
  [[ -z "$branch" ]] && branch="main"

  if [[ "$pipeline" == <-> ]]; then
    az pipelines run --id "$pipeline" --branch "$branch" -o table
  else
    az pipelines run --name "$pipeline" --branch "$branch" -o table
  fi
}

compdef _azdo_functions azdo-help azdo-defaults azdo-status azpr azpr-open azpr-checkout azruns azrun-open azpipe-run 2>/dev/null || true
