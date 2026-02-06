# --- fzf-tab Configuration ---

# 1. Disable the default static completion description (fzf-tab takes over)
zstyle ':completion:*:descriptions' format '[%d]'

# 2. Basic file preview:
#    When tabbing files, show the content using 'bat' (with color)
#    If it's a directory, show contents using 'eza'
zstyle ':fzf-tab:complete:*:*' fzf-preview 'less ${(Q)realpath}'
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  'if [[ -d $realpath ]]; then 
     eza -1 --color=always --icons $realpath 
   else 
     bat --color=always --style=numbers --line-range=:500 $realpath 
   fi'

# 3. 'cd' preview:
#    When typing 'cd <tab>', show the contents of that directory
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'

# 4. Process kill preview:
#    When typing 'kill <tab>', show the full process command line arguments
#    (ps -ef usually truncates output, this shows more context)
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'

# 5. Environment variable preview:
#    When typing 'export <tab>' or 'print $<tab>', show the variable's value
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
	fzf-preview 'echo ${(P)word}'

# Force the preview window to take 75% of the space
zstyle ':fzf-tab:*' fzf-flags '--preview-window=right:75%'

updot() {
  local msg="$1"
  local prompt="Generate a concise, one-line git commit message based on the following diff. Use conventional commits (e.g., feat:, fix:, chore:). Output ONLY the message text."

  # 1. Handle Nvim Submodule
  if [[ -d "nvim/.config/nvim/.git" ]]; then
    echo "Checking Nvim submodule..."
    (
      cd nvim/.config/nvim
      if [[ -n $(git status -s) ]]; then
        git add .
        local nvim_msg="$msg"
        if [[ -z "$nvim_msg" ]]; then
          echo "🤖 Generating Nvim commit message via OpenCode..."
          nvim_msg=$(git diff --cached | opencode run "$prompt" --model google/gemini-3-flash-preview)
        fi
        git commit -m "$nvim_msg"
        git push origin master
        echo "✅ Nvim fork updated: $nvim_msg"
      fi
    )
  fi

  # 2. Handle Parent Dotfiles
  echo "Updating parent dotfiles..."
  git add .
  if ! git diff --cached --quiet; then
    if [[ -z "$msg" ]]; then
      echo "🤖 Generating Dotfiles commit message via OpenCode..."
      msg=$(git diff --cached | opencode run "$prompt" --model google/gemini-3-flash-preview)
    fi
    git commit -m "$msg"
    git push origin main
    echo "✅ Dotfiles pushed: $msg"
  else
    echo "--- Nothing to commit in parent."
  fi
}
