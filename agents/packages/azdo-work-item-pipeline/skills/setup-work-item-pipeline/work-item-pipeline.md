# Work Item Pipeline

This repo uses the Azure DevOps work item pipeline skills for `Issue` and `Bug` work items.

## Scope

- In scope: `Issue`, `Bug`
- Out of scope for direct implementation: `Feature`, `Epic`
- Out-of-scope items route to planning or slicing before implementation.

## Azure DevOps

- Project: `<project>`
- Team: `<team>`
- Repository: `<repository>`

See `docs/agents/issue-tracker.md` for general tracker access rules.

## Branches

- Local target branch: `main`
- Remote target branch: `origin/main`

## Push Policy

Agents must not push automatically.

Pushing the shared target branch requires human approval and supervision.

If work is landed locally but not pushed, the agent should comment with local evidence and use the semantic outcome `landed-not-closed`.

## Tracker Outcomes

Use tags when available. If tags are not available, record the same semantic outcome in an Azure DevOps comment.

- `needs-info`
- `needs-product-decision`
- `needs-access`
- `ready-for-agent`
- `ready-for-human-verification`
- `landed-not-closed`
- `closed-with-evidence`

## Integration Evidence

Closure requires shared target-branch containment and required integration evidence.

Relevant checks:

- `<pipeline or staging check>`

Azure DevOps MCP pipeline evidence is acceptable when it identifies the relevant run and shows success. User-provided evidence is acceptable when the agent cannot query the pipeline or staging system directly.

## Closure

Automatic closure is allowed only for `Issue` and `Bug` work items when:

- The shared target branch contains the landed commit.
- Required integration checks passed.
- No manual QA, release, rollout, product acceptance, or pending human confirmation gate remains.

Do not close when any of these are pending:

- manual QA
- device QA
- TestFlight or App Store review
- customer confirmation
- rollout monitoring
- product acceptance
- release supervision
