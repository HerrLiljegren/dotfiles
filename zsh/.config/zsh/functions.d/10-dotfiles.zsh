# Dotfiles maintenance helpers.

updot() {
  emulate -L zsh

  # Commit and push dotfiles, including the nested Neovim config when it has
  # changes. If no message is supplied, Codex Spark splits the work into
  # atomic conventional commits before this wrapper pushes.
  local msg="$1"
  local codex_model="gpt-5.3-codex-spark"
  local codex_prompt="Split current changes into atomic git commits.

Inspect staged, unstaged, and untracked changes. Stage coherent subsets and create multiple atomic commits using Conventional Commit subjects. Prefer multiple small commits over one mixed commit. Keep related tests, config, and docs with the change they belong to. Commit all current changes unless blocked, and preserve user changes exactly.

Do not push, pull, fetch, rebase, merge, reset, amend, or discard changes. The wrapper pushes after verification.

Final response: list created commit hashes and subjects, or explain why none were created."

  _updot_manual_commit_and_push() {
    local repo_name="$1"
    local branch="$2"
    local commit_msg="$3"

    git add .
    if ! git diff --cached --quiet; then
      git commit -m "$commit_msg"
      git push origin "$branch"
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

    if [[ -z $(git status --porcelain) ]]; then
      echo "Nothing to commit in $repo_name."
      return
    fi

    before_head=$(git rev-parse HEAD)
    echo "Creating atomic $repo_name commits via Codex Spark..."
    codex exec -m "$codex_model" "$codex_prompt"

    if [[ -n $(git status --porcelain) ]]; then
      echo "$repo_name still has uncommitted changes; refusing to push."
      git status --short
      return 1
    fi

    after_head=$(git rev-parse HEAD)
    if [[ "$before_head" == "$after_head" ]]; then
      echo "No new $repo_name commits created; nothing to push."
      return
    fi

    git push origin "$branch"
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
