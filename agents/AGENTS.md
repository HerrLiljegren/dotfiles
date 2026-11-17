# Shared agent working agreements

- Preserve the requested behavior and verification standard. Use supported alternatives when they
  preserve both. Report meaningful limitations; never hide failures or silently weaken correctness,
  security, or evidence.
- Lead with the outcome and keep explanations proportionate to the task.
- Preserve unrelated user changes and call out overlapping edits.
- Comment non-obvious decisions, constraints, and failure modes that the code cannot make clear. For
  public .NET APIs, use XML documentation when it adds contract or behavioral context; omit comments
  that only restate the code.
- Never print, commit, or copy credentials, authentication state, or session history.
- Reuse authorization already given for the same action and scope. Ask before destructive or
  external changes that need new authority.
- Explicit user instructions take precedence over skill guidelines. When a rule blocks progress,
  cite its file and wording and the missing decision.
- Report the outcome, verification evidence, and remaining gates; distinguish local results from
  pending CI or human verification.

## Publication scope

Keep advisory plans, scratch artifacts and agent accounting local unless publication is part of the
requested deliverable. Before publishing, compare both the staged changes and the final changed-file
list with the agreed scope.

## Verification

- Choose the smallest checks that cover changed behavior and likely regression risks. Reuse existing
  coverage; add tests when a behavior or regression needs it. Documentation-only changes need
  relevant static checks.
- Follow repository-required verification. Before expanding beyond affected checks, name the
  concrete risk or explicit requirement that justifies it.
- Reuse passing results while relevant code, dependencies, configuration, and environment remain
  unchanged. Once required checks pass, stop testing; repeat or broaden checks only for relevant
  changes, failures, or concrete unresolved concerns.
- Avoid duplicate builds when the selected checks already build all required targets in the required
  configuration. Report scope, results, and log paths concisely instead of repeatedly streaming full
  output.

## Task-specific defaults

- Before creating or amending a commit, read `~/.agents/commit-style.md`. Use lowercase Conventional
  Commit subjects unless the repository overrides it.
- When creating a new .NET solution, read `~/.agents/dotnet-defaults.md`.
- After writing or editing Markdown, run `fmt-md <file>...` unless your harness already does. It
  applies the repository's Prettier config, or the home default when the repository has none. Don't
  reformat files you didn't change.
- Edit files with the harness's edit or patch tool. When a script replaces text instead, make it
  fail unless each pattern matched the expected number of times.
- Run shell commands in bash. In Codex, pass `shell: "/bin/bash"` to every `exec_command` call; the
  login shell is zsh. If a command still runs in zsh, quote globs (`--include='*.cs'`) and never
  start an unquoted word with `=` (`echo ====` fails).
- Wait for long commands (builds, tests, app start) in as few turns as possible. In Codex, use
  `yield_time_ms` of at least 30000 for them and when polling with `write_stdin`. In Claude, run
  them in the background and wait for the completion notice; never loop on `sleep`. Don't poll
  delegates: they report back when done.
- Keep git backups as `refs/backup/<name>` (`git update-ref`). This git config sets
  `fetch.pruneTags` and `rebase.updateRefs`, so a fetch can delete backup tags and a rebase can move
  backup branches.

## Branches

When the repository has no branch convention of its own, name new branches
`<prefix>/<kebab-case-slug>`: lowercase ASCII, one prefix level. Use `issue/<key>-<slug>` whenever
an issue exists (`issue/dev-42-log-noise`); otherwise pick the prefix matching the commit type:
`feature/`, `fix/`, `hotfix/` (urgent production fix), `refactor/`, `perf/`, `test/`, `docs/`,
`chore/` (build, CI, dependencies, tooling), or `spike/` (throwaway, never merged).

## Worktrees

Prefer Worktrunk (`wt`) over raw `git worktree` for user-facing worktree creation, switching,
listing, and removal.

- Use `wt switch <branch>` when the task explicitly needs to move the current shell to an existing
  worktree.
- Use `wt list` to inspect managed worktrees.
- Prefer `--format json` and `--no-cd` when automation needs the created worktree path.
- Do not create worktrees for configuration repositories or symlink-managed configuration unless the
  user explicitly asks.
- Use raw `git worktree` only when Worktrunk is unavailable, when the repository is not meant to use
  Worktrunk, or when the user explicitly asks for Git-native worktree commands.

## Repository guidance

Read the repository root and applicable nested `AGENTS.md` files before working. Harnesses that load
them automatically do not need to load them a second time.

## User skills

- Install requested user skills once at `~/.agents/skills/<name>/`, including their supporting
  files. An explicit project scope uses the repository's skill layout instead.
- When a skill has an existing source checkout, keep that source authoritative and symlink its
  complete skill directory into `~/.agents/skills/`. Edit the source through the link.
- Codex and Pi discover `~/.agents/skills/` directly. Expose each shared skill to Claude with
  `~/.claude/skills/<name>` pointing to `~/.agents/skills/<name>`. Keep `~/.pi/agent/skills` and
  `~/.gemini/config/skills` pointing to `~/.agents/skills` for Pi and Antigravity compatibility.
  Preserve harness-managed system, plugin, and synced skills separately.
- Before replacing an existing installation, compare complete packages and preserve differing
  content for reconciliation. Finish with one authoritative package and working discovery paths;
  verify new links resolve to the same files.
- For cross-harness skills, use portable `SKILL.md` frontmatter and relative resource paths. Check
  required commands, tools, connectors, and invocation controls in each target harness. Use
  supported equivalents that preserve the contract; report unavailable capabilities instead of
  claiming full compatibility from file discovery alone. Keep private data and generated state
  outside packages.
- After installing or updating, validate metadata and bundled resources, then report filesystem
  checks separately from live harness discovery and execution. Reload or restart sessions as needed.

## Host-local guidance

If `~/.agents/local.md` exists, read it and follow its routing rules. Read linked guidance only when
its stated condition applies. Host-local instructions supplement this public baseline with private
workspace routing and conventions.
