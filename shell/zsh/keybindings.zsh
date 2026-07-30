# Keep line editing deterministic when EDITOR or VISUAL points at Vim/Neovim.
bindkey -e

# Edit the current command in VISUAL, matching the previous Oh My Zsh binding.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Search history for the text already entered at the prompt.
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Standard line movement; end-of-line also accepts autosuggestions.
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char

if [[ -n "${terminfo[khome]-}" ]]; then
  bindkey "${terminfo[khome]}" beginning-of-line
fi

if [[ -n "${terminfo[kend]-}" ]]; then
  bindkey "${terminfo[kend]}" end-of-line
fi

if [[ -n "${terminfo[kdch1]-}" ]]; then
  bindkey "${terminfo[kdch1]}" delete-char
fi
