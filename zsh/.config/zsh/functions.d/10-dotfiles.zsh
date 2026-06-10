# Dotfiles maintenance helpers.

updot() {
  emulate -L zsh

  # Commit and push dotfiles, including the nested Neovim config when it has
  # changes. If no message is supplied, Codex Spark splits the work into
  # atomic conventional commits before this wrapper pushes.
  local msg="$*"
  local codex_model="gpt-5.3-codex-spark"
  local codex_prompt="Split current changes into atomic git commits.

Inspect staged, unstaged, and untracked changes. Stage coherent subsets and create multiple atomic commits using Conventional Commit subjects. Prefer multiple small commits over one mixed commit. Keep related tests, config, and docs with the change they belong to. Commit all current changes unless blocked, and preserve user changes exactly.

Do not push, pull, fetch, rebase, merge, reset, amend, or discard changes. The wrapper pushes after verification.

Final response: concise. List created commit hashes and subjects, or explain why none were created."

  _updot_print_codex_summary() {
    local summary_file="$1"

    if [[ -s "$summary_file" ]]; then
      sed '/^[[:space:]]*$/d' "$summary_file"
    fi
  }

  _updot_print_log_excerpt() {
    local log_file="$1"

    if [[ -s "$log_file" ]]; then
      echo "Codex output:"
      sed '/^[[:space:]]*$/d' "$log_file" | tail -n 20
    fi
  }

  _updot_push() {
    local repo_name="$1"
    local branch="$2"
    local push_log

    push_log=$(mktemp "${TMPDIR:-/tmp}/updot-push.XXXXXX.log") || return 1

    if git push --quiet origin "$branch" >| "$push_log" 2>&1; then
      rm -f "$push_log"
      return 0
    fi

    echo "$repo_name push failed."
    sed '/^[[:space:]]*$/d' "$push_log"
    echo "Full push log: $push_log"
    return 1
  }

  _updot_manual_commit_and_push() {
    local repo_name="$1"
    local branch="$2"
    local commit_msg="$3"

    git add . || return 1
    if ! git diff --cached --quiet; then
      git commit -m "$commit_msg" || return 1
      _updot_push "$repo_name" "$branch" || return 1
      echo "$repo_name pushed: $commit_msg"
    else
      echo "Nothing to commit in $repo_name."
    fi
  }

  _updot_codex_commit_and_push() {
    local repo_name="$1"
    local branch="$2"
    local before_head
    local after_head
    local repo_root
    local git_dir
    local git_common_dir
    local git_index
    local git_index_dir
    local codex_log
    local codex_summary
    local codex_status
    local -a git_metadata_flags

    if [[ -z $(git status --porcelain) ]]; then
      echo "Nothing to commit in $repo_name."
      return
    fi

    repo_root=$(git rev-parse --show-toplevel) || return 1
    git_dir=$(git rev-parse --absolute-git-dir) || return 1
    git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || git rev-parse --absolute-git-dir) || return 1
    git_index=$(git rev-parse --path-format=absolute --git-path index 2>/dev/null || git rev-parse --git-path index) || return 1
    git_index_dir="${git_index:h}"

    if [[ ! -w "$git_index_dir" ]]; then
      echo "$repo_name Git metadata is not writable; cannot create commits."
      echo "Index directory: $git_index_dir"
      return 1
    fi

    codex_log=$(mktemp "${TMPDIR:-/tmp}/updot-codex.XXXXXX.log") || return 1
    codex_summary=$(mktemp "${TMPDIR:-/tmp}/updot-codex.XXXXXX.summary") || return 1
    git_metadata_flags=(--add-dir "$git_dir")
    if [[ "$git_common_dir" != "$git_dir" ]]; then
      git_metadata_flags+=(--add-dir "$git_common_dir")
    fi

    before_head=$(git rev-parse HEAD) || return 1
    echo "Creating atomic $repo_name commits via Codex Spark..."
    codex exec \
      -m "$codex_model" \
      -s workspace-write \
      -C "$repo_root" \
      "${git_metadata_flags[@]}" \
      --color never \
      --ephemeral \
      --output-last-message "$codex_summary" \
      "$codex_prompt" >| "$codex_log" 2>&1
    codex_status=$?

    if (( codex_status != 0 )); then
      echo "$repo_name Codex commit step failed; not pushing."
      _updot_print_codex_summary "$codex_summary"
      _updot_print_log_excerpt "$codex_log"
      echo "Full Codex log: $codex_log"
      return "$codex_status"
    fi

    if [[ -n $(git status --porcelain) ]]; then
      echo "$repo_name still has uncommitted changes; refusing to push."
      _updot_print_codex_summary "$codex_summary"
      git status --short
      echo "Full Codex log: $codex_log"
      return 1
    fi

    after_head=$(git rev-parse HEAD) || return 1
    if [[ "$before_head" == "$after_head" ]]; then
      echo "No new $repo_name commits created; nothing to push."
      _updot_print_codex_summary "$codex_summary"
      echo "Full Codex log: $codex_log"
      return
    fi

    _updot_print_codex_summary "$codex_summary"
    git log --oneline "${before_head}..${after_head}"
    _updot_push "$repo_name" "$branch" || return 1
    echo "$repo_name pushed."
  }

  if [[ -d "nvim/.config/nvim" ]]; then
    echo "Checking Nvim submodule..."
    (
      cd nvim/.config/nvim || return
      if [[ -n $(git status -s) ]]; then
        if [[ -n "$msg" ]]; then
          _updot_manual_commit_and_push "Nvim fork" "master" "$msg"
        else
          _updot_codex_commit_and_push "Nvim fork" "master"
        fi
      fi
    )
  fi

  echo "Updating parent dotfiles..."
  if [[ -n "$msg" ]]; then
    _updot_manual_commit_and_push "parent dotfiles" "main" "$msg"
  else
    _updot_codex_commit_and_push "parent dotfiles" "main"
  fi
}
