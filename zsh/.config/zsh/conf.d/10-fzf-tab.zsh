# fzf-tab completion UI.
#
# Adds previews to completion menus:
#   - files/directories show bat/eza previews
#   - cd shows directory contents
#   - kill/ps show process command lines
#   - variables show their current value

zstyle ':completion:*:descriptions' format '[%d]'

zstyle ':fzf-tab:complete:*:*' fzf-preview \
  'if [[ -d $realpath ]]; then
     eza -1 --color=always --icons $realpath
   else
     bat --color=always --style=numbers --line-range=:500 $realpath
   fi'

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'

zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'

zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
  fzf-preview 'echo ${(P)word}'

zstyle ':fzf-tab:*' fzf-flags '--preview-window=right:75%'
