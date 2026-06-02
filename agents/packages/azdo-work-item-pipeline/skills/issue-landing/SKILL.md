---
name: issue-landing
description: Lands an implemented Azure DevOps Issue or Bug using a Git-first commit, squash, rebase, verify, merge, and tracker reconciliation workflow. Use when implementation is complete and the user asks to land, merge, reconcile, close, finish, or continue after implementation for an Azure DevOps work item.
---

# Issue Landing

Take an implemented Azure DevOps `Issue` or `Bug` from local changes or branch commits to target-branch containment and tracker reconciliation.

This skill is Git-first. Worktrunk may be used as a local adapter only when it satisfies the same stage contract.

## Quick Start

1. Resolve the work item ID, source branch, target branch, and repository.
2. Read the work item state, latest comments, child links, and any QA or release gates.
3. Inspect Git status and protect unrelated user changes.
4. Commit relevant uncommitted implementation changes if needed.
5. Squash the issue branch into one landing candidate commit.
6. Rebase the candidate onto the target branch.
7. Resolve conflicts and verify after the rebase.
8. Land onto the target branch.
9. Prove target-branch containment with Git.
10. Add Azure DevOps reconciliation evidence and close only when allowed.

Never push to a remote automatically. Always ask the human before pushing.

For comment templates and closure details, see [REFERENCE.md](REFERENCE.md).

## Preconditions

Proceed only for Azure DevOps `Issue` and `Bug` work items. If the item is a `Feature`, `Epic`, or planning-level item, stop and route to planning or slicing.

Before landing, read repo-local agent docs when present:

- `docs/agents/issue-tracker.md`
- `docs/agents/triage-labels.md`
- `docs/agents/work-item-pipeline.md`

If issue tracker or triage docs are missing, route to `setup-matt-pocock-skills`. If pipeline docs are missing, route to `setup-work-item-pipeline` before landing or closing.

Before changing Git history, establish the work item ID/type, source branch, target branch, relatedness of uncommitted changes, and whether any manual QA, release, rollout, product acceptance, or unresolved child dependency blocks closure. Do not stage unrelated user changes.

## Commit

If relevant implementation changes are uncommitted, create a commit before squash/rebase.

Baseline Git path: inspect status/diff, stage only relevant paths, generate or ask for a commit message, then run `git commit`.

Worktrunk adapter path: `wt step commit` is acceptable when it satisfies the same contract.

If a suitable implementation commit already exists, skip this stage.

## Squash

Normalize the issue branch to one landing candidate commit before rebasing onto the target branch.

Use non-interactive Git where possible. Before rewriting local history, create a safety ref or confirm an equivalent recovery point exists.

The landing candidate should contain the final issue behavior, not intermediate implementation steps. Preserve clearly known Azure DevOps work item IDs in the commit message footer, such as `Refs #5034`.

## Rebase

Rebase the landing candidate onto the target branch.

If conflicts occur:

- Inspect nearby code, resolve narrowly, continue the rebase, and run focused verification.

If a conflict changes domain assumptions, acceptance criteria, or implementation scope, invoke `grill-with-docs` with stage-specific context that the rebase conflict changed the implementation assumptions.

If conflicts require product judgment, update the work item with the blocker and do not land.

## Verify After Rebase

Run the smallest trustworthy verification after the rebase. Prefer focused tests first, then broader checks when the changed surface or repo instructions require them.

Record exact commands and results for reconciliation.

## Land

Land only after post-rebase verification passes or the user explicitly accepts a documented verification gap.

Baseline Git path: switch to the target branch, merge the verified landing candidate, and capture the landed commit SHA.

Worktrunk adapter path:

`wt merge --no-remove` is acceptable when it preserves the current worktree/session long enough for reconciliation. Still verify target-branch containment with Git after the tool completes.

Remote push is not part of this automatic landing workflow. If remote publication is needed, ask the human before pushing.

## Reconcile Azure DevOps

Reconciliation must use Git evidence, not only a tool success message.

Fetch the remote target branch before final shared containment checks. This is allowed as read-only state refresh. Do not push without explicit human approval.

If work is landed locally but not pushed, do not close. Add a non-final local landing comment and apply `landed-not-closed` when available.

Close automatically only when:

- The work item is an `Issue` or `Bug`.
- The shared target branch contains the landed commit.
- Post-rebase verification passed.
- Required shared integration checks, tests, or staging builds passed.
- No human gate remains.

Use [REFERENCE.md](REFERENCE.md) for exact evidence fields, local landing comment format, Azure DevOps MCP pipeline evidence guidance, and blocked-closure behavior.
