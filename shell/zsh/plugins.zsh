# Pinned, vendored interaction plugins.

source "$DOTFILES_ROOT/vendor/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$DOTFILES_ROOT/vendor/zsh/fzf-tab/fzf-tab.plugin.zsh"

zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  'if [[ -d $realpath ]]; then
     eza -1 --color=always --icons $realpath
   else
     bat --color=always --style=numbers --line-range=:500 $realpath
   fi'
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'eza -1 --color=always --icons $realpath'
zstyle ':completion:*:*:*:*:processes' command \
  "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter|export|unset|expand):*' \
  fzf-preview 'print -r -- ${(P)word}'
zstyle ':fzf-tab:*' fzf-flags '--preview-window=right:75%'

# History substring search integrates with syntax highlighting and must load
# after it.
source "$DOTFILES_ROOT/vendor/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$DOTFILES_ROOT/vendor/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh"
