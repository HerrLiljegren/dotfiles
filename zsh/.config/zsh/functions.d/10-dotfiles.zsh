# Dotfiles maintenance helpers.

updot() {
  emulate -L zsh

  # Commit and push dotfiles, including the nested Neovim config when it has
  # changes. If no message is supplied, OpenCode generates a conventional
  # commit message from the staged diff.
  local msg="$1"
  local prompt="Generate a concise, one-line git commit message based on the following diff. Use conventional commits (e.g., feat:, fix:, chore:). Output ONLY the message text."
  local model="openai/gpt-5.4"
  local variant="low"

  if [[ -d "nvim/.config/nvim" ]]; then
    echo "Checking Nvim submodule..."
    (
      cd nvim/.config/nvim || return
      if [[ -n $(git status -s) ]]; then
        git add .
        local nvim_msg="$msg"
        if [[ -z "$nvim_msg" ]]; then
          echo "Generating Nvim commit message via OpenCode..."
          nvim_msg=$(git diff --cached | opencode run "$prompt" --model "$model" --variant "$variant")
        fi
        git commit -m "$nvim_msg"
        git push origin master
        echo "Nvim fork updated: $nvim_msg"
      fi
    )
  fi

  echo "Updating parent dotfiles..."
  git add .
  if ! git diff --cached --quiet; then
    if [[ -z "$msg" ]]; then
      echo "Generating Dotfiles commit message via OpenCode..."
      msg=$(git diff --cached | opencode run "$prompt" --model "$model" --variant "$variant")
    fi
    git commit -m "$msg"
    git push origin main
    echo "Dotfiles pushed: $msg"
  else
    echo "Nothing to commit in parent."
  fi
}
