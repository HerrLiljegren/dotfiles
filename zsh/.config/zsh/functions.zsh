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
