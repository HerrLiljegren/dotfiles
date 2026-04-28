# Global Agent Preferences

## Worktrees

Use Worktrunk via the `wt` command for git worktree creation and switching. Do not treat `wt` as a directory name.

Default workflow:

- Create worktrees with `wt switch --create <branch>`.
- Use the configured Worktrunk `worktree-path` from `~/.config/worktrunk/config.toml`.
- Prefer `--format json` and `--no-cd` when automation needs the created worktree path.
