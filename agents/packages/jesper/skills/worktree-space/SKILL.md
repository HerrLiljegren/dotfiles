---
name: worktree-space
description: Create managed Worktrunk worktrees and matching herdr worktree spaces. Use when the user asks to create a new worktree, branch, or herdr space from an issue number, ticket, work item, or plain goal, especially when Worktrunk (`wt`) and herdr should stay in sync.
---

# Worktree Space

Create one Worktrunk-managed Git worktree and one matching herdr space.

## Workflow

1. Resolve the parent repo.
   - Use the current directory if it is inside a Git repo.
   - If the current directory is a linked worktree, resolve the parent checkout with `git rev-parse --show-toplevel --git-common-dir`; use the non-linked repo parent when invoking herdr.
   - If more than one plausible repo exists, ask one short question before creating anything.
   - Completion criterion: know the parent repo cwd and whether the current checkout is already a linked worktree.

2. Derive the branch name.
   - If the input is an issue number, find the issue title from available local context first, then the issue tracker if configured. Use `issue/###-<slug>`.
   - If only a goal is given, derive a short scoped branch name from the goal, usually `feature/<slug>` unless the repo convention clearly prefers another prefix.
   - Make slugs lowercase ASCII, dash-separated, and specific enough to distinguish the work.
   - Prefer existing repo naming conventions over these defaults when they are obvious from nearby worktrees or branches.
   - Completion criterion: branch name is explicit and includes the issue number when present.

3. Show the planned commands before mutation when the user has not already said to proceed.
   - Include `wt new <branch>` and the expected herdr open command.
   - Use `wt new`, not raw `git worktree`, unless Worktrunk is unavailable or the user explicitly asks for Git-native commands.
   - Completion criterion: either the user approved, or the user already gave a direct create instruction.

4. Create the worktree.
   - Run `wt new <branch>` from the parent repo checkout.
   - Do not attach to or switch tmux sessions.
   - Do not use `wt switch` unless the user explicitly wants the current shell moved.
   - Completion criterion: `wt new` succeeds or reports the worktree already exists.

5. Resolve the checkout path.
   - Prefer `wt list` if available.
   - Otherwise use `git worktree list --porcelain` from the parent repo.
   - Completion criterion: have the absolute checkout path for the branch.

6. Open/register the herdr space.
   - If running inside herdr (`HERDR_ENV=1`), use:

     ```bash
     herdr worktree open --cwd <parent-repo-cwd> --path <checkout-path> --label "<label>" --no-focus
     ```

   - Use `herdr worktree open`, not `herdr workspace create`, so herdr records linked-worktree membership under the correct parent.
   - If not running inside herdr, report the exact command for the user to run instead of trying to control herdr externally.
   - Completion criterion: `herdr workspace list` shows the new space with `worktree.is_linked_worktree: true` and the correct `repo_root`.

7. Report the result.
   - Include branch, checkout path, herdr label, and whether herdr said `already_open`.
   - Mention any skipped step, especially if herdr was not available.

## Label Rules

- For issue branches, use `#<number> <short title slug words>` as the herdr label.
- For non-issue branches, use the branch slug words without the prefix, e.g. `support rail polish`.
- Do not repeat the parent repo name in linked-worktree labels; herdr groups worktree children under the parent.

## Issue Title Sources

Use the cheapest reliable source available:

- Repo-local issue manifests, prompt files, or docs.
- Existing branch/worktree names that include the same issue number.
- Configured issue tracker CLIs or MCP tools.

If no title is available, ask for the title or derive a conservative slug from the user's stated goal.
