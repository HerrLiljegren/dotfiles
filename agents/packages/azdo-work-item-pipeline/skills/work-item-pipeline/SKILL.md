---
name: work-item-pipeline
description: Routes Azure DevOps Issue and Bug work through triage, clarification, implementation, commit-message writing, landing, and reconciliation skills. Use when the user asks to start, continue, finish, land, close, or manage an Azure DevOps work item lifecycle.
---

# Work Item Pipeline

Route Azure DevOps `Issue` and `Bug` work to the right stage skill.

This is a thin conductor. Do not duplicate stage logic here; invoke the matching dependency or package skill.

## Quick Start

1. Identify the work item ID, type, repository, branch/worktree, and user intent.
2. If repo-local agent docs are missing, run setup first.
3. Route planning or readiness questions to `triage`.
4. Route ambiguity to `grill-with-docs` with current stage context.
5. Route implementation to `issue-implementer`.
6. Route commit-message requests to `commit-message-writer`.
7. Route landing, merge, close, or finish requests to `issue-landing`.

## Setup Prerequisite

Before using the pipeline in a repo, check for `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`, and `docs/agents/work-item-pipeline.md`.

If the Matt Pocock-style core docs are missing, run `setup-matt-pocock-skills` first. Then run `setup-work-item-pipeline` to add Azure DevOps target branch, push policy, pipeline evidence, and closure gate configuration.

## Scope

Version 1 supports Azure DevOps Boards `Issue` and `Bug` work items.

If the item is a `Feature`, `Epic`, or planning-level work item, stop before implementation and route to `to-issues` or a planning workflow.

## Routing

Use `triage` when:

- The user asks to assess, prepare, classify, or make a work item ready.
- The item state, tags, comments, acceptance criteria, or ownership are unclear.

Use `to-issues` when:

- The work item is too broad for one implementation pass.
- The item is a `Feature`, `Epic`, or parent-level planning artifact.

Use `grill-with-docs` when:

- Domain language, acceptance criteria, scope, persistence, compatibility, or user-visible behavior is ambiguous.
- A rebase conflict changes implementation assumptions.
- The answer requires a user decision rather than code exploration.

Use `issue-implementer` when:

- The user asks to fix, implement, pick up, or continue an Azure DevOps `Issue` or `Bug`.
- The work item is ready enough for autonomous implementation.

Use `commit-message-writer` when:

- The user asks for a commit message.
- A commit stage needs a message from staged changes.

Use `issue-landing` when:

- Implementation is complete and the user asks to land, merge, finish, reconcile, or close.
- The branch needs commit, squash, rebase, verification, landing, or Azure DevOps reconciliation.

## Invariants

- Do not close a work item until the target branch contains the work.
- Prefer Git evidence over tool success messages.
- Treat Worktrunk as a local tool adapter, not a pipeline requirement.
- Do not guess implementation scope when a Grilling Session or triage stop is needed.
