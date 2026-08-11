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
fzf_default_opts='--height=40% --layout=reverse --border'
fzf_default_opts="$fzf_default_opts --color=fg:#cdd6f4,bg:-1,hl:#f9e2af"
fzf_default_opts="$fzf_default_opts --color=fg+:#cdd6f4,bg+:#313244,hl+:#f9e2af"
fzf_default_opts="$fzf_default_opts --color=info:#a6adc8,prompt:#cba6f7,pointer:#89b4fa"
fzf_default_opts="$fzf_default_opts --color=marker:#a6e3a1,spinner:#f5e0dc,header:#a6adc8"
fzf_default_opts="$fzf_default_opts --color=border:#45475a,label:#89b4fa"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-$fzf_default_opts}"
unset fzf_default_opts

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

# Curated Git aliases shared by Bash and Zsh.
. "$DOTFILES_SHELL_DIR/git-aliases.sh"
alias ghelp='git-aliases' # Open the Git alias guide.

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
