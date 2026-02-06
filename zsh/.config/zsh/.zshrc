# --- Environment Variables ---
export EDITOR='nvim'
export LANG=en_US.UTF-8

# Opt-out of telemetry for cleaner terminal output
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# --- Antidote Bootstrap ---
local antidote_dir=${ZDOTDIR:-~}/.antidote
if [[ ! -d $antidote_dir ]]; then
  git clone --depth=1 https://github.com/mattmc3/antidote.git $antidote_dir
fi
source $antidote_dir/antidote.zsh

# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load

# History Configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS  # Don't record duplicates
setopt HIST_REDUCE_BLANKS    # Remove wasted space
setopt SHARE_HISTORY         # Share history between sessions

##################
# Configurations #
##################
# --- History Substring Search Bindings ---
# Bind UP and DOWN arrow keys
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Bind standard vim keys (j/k) if you use vi-mode
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# --- Plugin/Module Loading ---

eval "$(zoxide init --cmd cd zsh)"
#eval "$(dotnet completions script zsh)"
eval "$(starship init zsh)"

# Source files from a sub-directory to keep this file clean
[[ -f ~/.config/zsh/aliases.zsh ]] && source ~/.config/zsh/aliases.zsh
[[ -f ~/.config/zsh/functions.zsh ]] && source ~/.config/zsh/functions.zsh

