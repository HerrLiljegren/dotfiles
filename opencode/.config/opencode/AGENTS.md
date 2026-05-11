# Global Agent Preferences

## Worktrees

Use Worktrunk via the `wt` command for git worktree creation and switching. Do not treat `wt` as a directory name.

Default workflow:

- Create worktrees with `wt switch --create <branch>`.
- Use the configured Worktrunk `worktree-path` from `~/.config/worktrunk/config.toml`.
- Prefer `--format json` and `--no-cd` when automation needs the created worktree path.

Exceptions:

- Do not use worktrees for configuration repositories or symlinked/stow-managed config.
- Never create or use worktrees anywhere under `~/dotfiles`.
- When working on configuration, use the primary checkout unless the user explicitly asks for a worktree.
