# Shared interactive shell configuration for Bash and Zsh.

for bin_dir in "$HOME/.local/bin" "$HOME/.devcontainers/bin" "$HOME/.cargo/bin"; do
  case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *) PATH="$bin_dir:$PATH" ;;
  esac
done
unset bin_dir
export PATH

if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  export VISUAL=nvim
elif command -v vim >/dev/null 2>&1; then
  export EDITOR=vim
  export VISUAL=vim
fi

export PAGER="${PAGER:-less}"
export LESS="${LESS:--FRX}"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height=40% --layout=reverse --border}"

# Let OpenSSL-based tools discover the per-user .NET development certificate.
dotnet_trust_dir="$HOME/.aspnet/dev-certs/trust"
if [ -d "$dotnet_trust_dir" ]; then
  SSL_CERT_DIR="${SSL_CERT_DIR:-/etc/ssl/certs}"
  case ":$SSL_CERT_DIR:" in
    *":$dotnet_trust_dir:"*) ;;
    *) SSL_CERT_DIR="$dotnet_trust_dir:$SSL_CERT_DIR" ;;
  esac
  export SSL_CERT_DIR
fi
unset dotnet_trust_dir

# Directory navigation and listing.
alias ..='cd ..'             # Move up one directory.
alias ...='cd ../..'         # Move up two directories.
alias ....='cd ../../..'     # Move up three directories.
alias ll='ls -alF'           # List all files with details and type indicators.
alias la='ls -lAFh'          # List almost all files with human-readable sizes.

if command -v eza >/dev/null 2>&1; then
  alias l='eza -lh --icons --git --group-directories-first'    # Detailed list.
  alias la='eza -lah --icons --git --group-directories-first'  # Include hidden files.
  alias ll='eza -lah --icons --git --group-directories-first'  # Detailed list with hidden files.
  alias lt='eza --tree --level=4 --git-ignore --icons'         # Four-level tree, respecting Git ignores.
  alias lta='eza --tree --level=4 --all --icons --group-directories-first' # Tree including hidden files.
fi

# Git basics and staging.
alias g='git'                          # Run Git.
alias ga='git add'                     # Stage paths.
alias gaa='git add --all'              # Stage all changes.
alias gapa='git add --patch'           # Interactively stage parts of changes.
alias gs='git status --short --branch' # Show compact status and branch information.
alias gss='git status --short'         # Show compact status.
alias gst='git status'                 # Show full status.
alias gd='git diff'                    # Show unstaged changes.
alias gds='git diff --staged'          # Show staged changes.

# Git branches and history.
alias gb='git branch'                                  # List or manage local branches.
alias gba='git branch --all'                           # List local and remote branches.
alias gsw='git switch'                                 # Switch branches.
alias gswc='git switch --create'                       # Create and switch to a branch.
alias gsh='git show'                                   # Show a commit or object.
alias glo='git log --oneline --decorate'               # Show compact history.
alias glog='git log --oneline --decorate --graph'      # Show compact graph history.
alias gloga='git log --oneline --decorate --graph --all' # Show graph history for all refs.

# Git commits and history editing.
alias gc='git commit --verbose'          # Commit with the staged diff in the editor.
alias gcmsg='git commit --message'       # Commit with a message argument.
alias gcfu='git commit --fixup'          # Create a fixup commit for autosquash.
alias grb='git rebase'                   # Rebase onto another branch or commit.
alias grbi='git rebase --interactive'    # Edit commits during a rebase.
alias grba='git rebase --abort'          # Abort the current rebase.
alias grbc='git rebase --continue'       # Continue after resolving rebase conflicts.
alias grst='git restore --staged'        # Unstage paths without discarding their changes.

# Git remotes and synchronization.
alias gf='git fetch'                         # Fetch from the default remote.
alias gfa='git fetch --all --tags --prune'  # Refresh all remotes, tags, and stale refs.
alias gpr='git pull --rebase'                # Pull and rebase local commits.
alias gp='git push'                          # Push to the configured upstream.
alias gpsup='git push --set-upstream origin HEAD' # Push the current branch and set upstream.

# Git stashes and cherry-picks.
alias gsta='git stash push'              # Stash tracked changes.
alias gstp='git stash pop'               # Apply and remove the latest stash.
alias gstl='git stash list'              # List stashes.
alias gsts='git stash show --patch'      # Show the latest stash as a patch.
alias gcp='git cherry-pick'              # Apply an existing commit.
alias gcpa='git cherry-pick --abort'     # Abort the current cherry-pick.
alias gcpc='git cherry-pick --continue'  # Continue after resolving cherry-pick conflicts.

# General command-line shortcuts.
alias c='clear'       # Clear the terminal.
alias h='history'     # Show command history.
alias md='mkdir -p'  # Create directories, including missing parents.
alias dfh='df -h'    # Show filesystem usage with human-readable sizes.
alias duh='du -sh'   # Show the total size of a path.

take() {
  # Create a directory and enter it.
  [ "$#" -eq 1 ] || {
    printf 'usage: take <directory>\n' >&2
    return 2
  }
  mkdir -p -- "$1" && cd -- "$1"
}

path() {
  # Print PATH with one directory per line.
  printf '%s\n' "$PATH" | tr ':' '\n'
}

if command -v ss >/dev/null 2>&1; then
  alias ports='ss -lntup' # Show listening TCP and UDP ports.
fi

if command -v lazygit >/dev/null 2>&1; then
  alias lg='lazygit' # Open Lazygit.
fi

if command -v opencode >/dev/null 2>&1; then
  alias oc='opencode' # Open OpenCode.
fi

if command -v btop >/dev/null 2>&1; then
  alias top='btop' # Use the enhanced process monitor.
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat' # Show files with syntax highlighting and paging.
fi

DOTFILES_LOCAL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local.sh"
if [ -r "$DOTFILES_LOCAL_CONFIG" ]; then
  . "$DOTFILES_LOCAL_CONFIG"
fi
unset DOTFILES_LOCAL_CONFIG
