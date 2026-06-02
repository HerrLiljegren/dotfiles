# Issue Landing Reference

## Local Landing Comment

Use this when work is landed locally but not pushed to the shared target branch:

```text
Landed locally, not closed.

Target branch: main
Local landed commit: <sha>
Containment: local main contains <sha>
Post-rebase verification: <command> <result>
Remote push/staging: pending human-supervised push
Status: landed-not-closed
```

## Final Reconciliation Evidence

Before final closure, fetch and prove the remote-tracking target branch contains the landed commit:

```text
git fetch origin main
git merge-base --is-ancestor <sha> origin/main
```

The final Azure DevOps comment should include:

- Remote target branch name, usually `origin/main`.
- Landed commit SHA on the shared target branch.
- Work item ID.
- Containment evidence.
- Post-rebase verification commands and results.
- Shared check or staging-build evidence when available or provided by the user.

## Closure Rules

Close automatically only when:

- The work item is an `Issue` or `Bug`.
- The shared target branch contains the landed commit.
- Post-rebase verification passed.
- Required shared integration checks, tests, or staging builds passed.
- There is no unresolved child item.
- No manual QA, release, rollout, product acceptance, or pending human confirmation gate remains.

Do not close when any of these are pending:

- manual QA
- device QA
- TestFlight or App Store review
- customer confirmation
- rollout monitoring
- product acceptance
- release supervision

If closure is blocked, add the evidence comment and apply a semantic tag when available, such as `ready-for-human-verification` or `landed-not-closed`.

If shared integration evidence is required, prefer Azure DevOps MCP pipeline tools when available. Use repo docs, work item links, commit/build associations, or user-provided pipeline IDs to identify the relevant run, then query run or build status before closure.

If shared integration evidence is required but unavailable, do not close. Accept user-provided evidence when the agent cannot query the pipeline or staging system directly.
