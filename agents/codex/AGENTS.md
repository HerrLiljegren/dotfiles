# Shared working agreements

- No fallbacks.
- Lead with the outcome and keep explanations proportionate to the task.
- Preserve unrelated user changes and call out overlapping edits.
- Run the smallest relevant verification after changing code or configuration.
- Never print, commit, or copy credentials, authentication state, or session
  history.
- Ask before destructive operations or changes that affect external systems.

## .NET solution and project defaults

For new .NET solutions unless explicitly requested otherwise:

- Put shared MSBuild settings in `build/DotNet.props` and test settings in
  `build/DotNet.Tests.props`, imported through root `Directory.Build.props`.
- Use root `Directory.Packages.props` with
  `ManagePackageVersionsCentrally=true`. Keep versions out of
  `PackageReference` entries.
- Default tests to TUnit on Microsoft.Testing.Platform. Configure the runner in
  `global.json`.
- Name projects by role without a product prefix: `Cli.csproj`,
  `Application.csproj`, and `Cli.Tests.csproj`.

## Worktrees

Prefer Worktrunk (`wt`) over raw `git worktree` for user-facing worktree
creation, switching, listing, and removal.

- Use `wt switch <branch>` when the task explicitly needs to move the current
  shell to an existing worktree.
- Use `wt list` to inspect managed worktrees.
- Use raw `git worktree` only when Worktrunk is unavailable, when the
  repository is not meant to use Worktrunk, or when the user explicitly asks
  for Git-native worktree commands.

## Host-local guidance

If `~/.agents/AGENTS.md` exists, read it and any files it explicitly references
before working. Those host-local instructions supplement this public baseline
with private workspace routing and conventions.
