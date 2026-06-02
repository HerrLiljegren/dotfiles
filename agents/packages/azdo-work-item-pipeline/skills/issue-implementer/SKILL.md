---
name: issue-implementer
description: Implements a project issue through verified local changes after resolving ambiguity through tracker context, code exploration, and grilling when needed. Use when the user asks to fix, implement, pick up, work, or continue an issue by number/URL, or asks the agent to derive the issue from the current branch/worktree.
---

# Issue Implementer

Take an issue from tracker context to a verified implementation. Stop before landing, merging, or closing the work item unless the user explicitly routes to `issue-landing`.

This skill composes the local issue tracker workflow with codebase exploration and, when the issue is not clearly ready for AFK implementation, a `grill-with-docs` clarification loop.

## Quick Start

1. Resolve the issue from an explicit number/URL, the branch or worktree name, or the current conversation.
2. Read the full issue, comments, links, tags, assignee, state, and any parent/child work items.
3. Decide whether it is ready for AFK implementation.
4. If it is not ready, use `grill-with-docs` to resolve uncertainties before editing.
5. Implement the smallest coherent fix.
6. Verify with relevant tests/builds/checks.
7. Update the issue with what changed, what was verified, and any remaining risk.
8. Hand off landing, merging, reconciliation, and closure to `issue-landing`.

## Resolve the Issue

Prefer explicit references in the user request. Accept issue numbers, URLs, branch names, and worktree names.

Before implementation, read repo-local agent docs when present:

- `docs/agents/issue-tracker.md`
- `docs/agents/triage-labels.md`
- `docs/agents/work-item-pipeline.md`

If issue tracker or triage docs are missing, route to `setup-matt-pocock-skills`. If pipeline docs are missing for an Azure DevOps repo, route to `setup-work-item-pipeline`.

If no explicit issue is provided, derive it conservatively:

- Look for a work item number in the current branch or worktree path, such as `issue-5073-*`, `issue/5073-*`, or `#5073`.
- If exactly one plausible issue is found, use it.
- If none or multiple are found, ask one short question before proceeding.

Use the repository's configured issue tracker from `AGENTS.md` or `docs/agents/issue-tracker.md`. If that setup is missing, inspect the repo docs before falling back to generic assumptions.

## Readiness Check

Treat an issue as AFK-ready only when all of these are true:

- It has a clear desired behavior and acceptance criteria.
- Domain terms match the repo glossary and ADRs.
- The implementation boundary is narrow enough to complete without new product judgment.
- No unresolved comments or contradictory decisions remain.
- Required external access, manual QA, or design review is not blocking implementation.

If the issue has a `ready-for-agent` state/tag and an Agent Brief, still read the code and comments. Tags are signals, not proof.

If the issue is `ready-for-human`, `needs-info`, `needs-triage`, or materially ambiguous, do not guess. Use `grill-with-docs` unless the user explicitly instructs a narrower mechanical change.

## Grill Before Editing

Use `grill-with-docs` when there is uncertainty about terminology, scope, behavior, dependencies, user-visible copy, persistence shape, migrations, compatibility, or acceptance criteria.

During the grilling loop:

- Ask one question at a time and recommend an answer.
- Explore the code instead of asking when the answer can be discovered locally.
- Challenge terminology against `CONTEXT.md` and ADRs.
- Update `CONTEXT.md` or ADRs inline only when the grilling decision belongs there.
- Stop grilling when the issue is clear enough for AFK implementation.

After grilling, restate the implementation scope in 3-6 bullets before editing.

## Implementation Loop

Follow the repo's agent instructions first.

1. Inspect the relevant code paths, tests, and recent patterns.
2. Make a small plan if more than one file or layer is involved.
3. Edit narrowly, preserving existing architecture and vocabulary.
4. Add or update tests proportional to risk.
5. Run the most relevant verification commands.
6. Fix failures caused by the change.
7. Check `git status` and avoid disturbing unrelated user changes.

Prefer vertical behavior changes over horizontal cleanup. Do not widen shared abstractions unless the issue explicitly asks for it or the local pattern already requires it.

## Tracker Update

When implementation is complete, add a concise issue comment with:

- What changed.
- What was verified, including commands.
- Any checks not run and why.
- Any follow-up risk or manual QA still needed.

Do not close the issue from this skill. Closure belongs to `issue-landing`, after target-branch containment is proven.

If the issue cannot be implemented after three concrete attempts because required information is missing, update the issue with specific blockers and move it to the appropriate non-AFK state if the workflow supports that.

## Completion Response

End with:

- The issue number and branch/worktree used.
- The important files changed.
- Verification run.
- Any remaining blocker or follow-up.
- Whether the work is ready for `issue-landing`.
