# Shared agent working agreements

- Preserve the requested behavior and verification standard. Use supported
  alternatives when they preserve both. Report meaningful limitations; never
  hide failures or silently weaken correctness, security, or evidence.
- Lead with the outcome and keep explanations proportionate to the task.
- Preserve unrelated user changes and call out overlapping edits.
- Comment non-obvious decisions, constraints, and failure modes that the code
  cannot make clear. For public .NET APIs, use XML documentation when it adds
  contract or behavioral context; omit comments that only restate the code.
- Never print, commit, or copy credentials, authentication state, or session
  history.
- Reuse authorization already given for the same action and scope. Ask before
  destructive or external changes that need new authority.
- Explicit user instructions take precedence over skill guidelines. When a
  rule blocks progress, cite its file and wording and the missing decision.
- Report the outcome, verification evidence, and remaining gates; distinguish
  local results from pending CI or human verification.

## Publication scope

Keep advisory plans, scratch artifacts and agent accounting local unless
publication is part of the requested deliverable. Before publishing, compare
both the staged changes and the final changed-file list with the agreed scope.

## Verification

- Choose the smallest checks that cover changed behavior and likely regression
  risks. Reuse existing coverage; add tests when a behavior or regression needs
  it. Documentation-only changes need relevant static checks.
- Follow repository-required verification. Before expanding beyond affected
  checks, name the concrete risk or explicit requirement that justifies it.
- Reuse passing results while relevant code, dependencies, configuration, and
  environment remain unchanged. Once required checks pass, stop testing;
  repeat or broaden checks only for relevant changes, failures, or concrete
  unresolved concerns.
- Avoid duplicate builds when the selected checks already build all required
  targets in the required configuration. Report scope, results, and log paths
  concisely instead of repeatedly streaming full output.

## Task-specific defaults

- Before creating or amending a commit, read `~/.agents/commit-style.md`.
  Use lowercase Conventional Commit subjects unless the repository overrides it.
- When creating a new .NET solution, read `~/.agents/dotnet-defaults.md`.

## Worktrees

Prefer Worktrunk (`wt`) over raw `git worktree` for user-facing worktree
creation, switching, listing, and removal.

- For work tied to a numbered issue, when the repository has no stronger
  convention, name the branch `issue/<number>-<kebab-case-slug>`.
- Use `wt switch <branch>` when the task explicitly needs to move the current
  shell to an existing worktree.
- Use `wt list` to inspect managed worktrees.
- Prefer `--format json` and `--no-cd` when automation needs the created
  worktree path.
- Do not create worktrees for configuration repositories or symlink-managed
  configuration unless the user explicitly asks.
- Use raw `git worktree` only when Worktrunk is unavailable, when the
  repository is not meant to use Worktrunk, or when the user explicitly asks
  for Git-native worktree commands.

## Repository guidance

Read the repository root and applicable nested `AGENTS.md` files before
working. Harnesses that load them automatically do not need to load them a
second time.

## Host-local guidance

If `~/.agents/local.md` exists, read it and follow its routing rules. Read
linked guidance only when its stated condition applies. Host-local
instructions supplement this public baseline with private workspace routing
and conventions.
