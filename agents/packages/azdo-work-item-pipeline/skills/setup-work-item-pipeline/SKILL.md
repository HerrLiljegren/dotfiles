---
name: setup-work-item-pipeline
description: Sets up repo-local docs for the Azure DevOps Issue/Bug work item pipeline, including target branch, push policy, tracker tags, pipeline evidence, and closure gates. Run before first use of work-item-pipeline, issue-implementer, or issue-landing in a repo, or when those skills lack repo-specific Azure DevOps workflow context.
disable-model-invocation: true
---

# Setup Work Item Pipeline

Scaffold the per-repo configuration that the Azure DevOps work item pipeline skills assume.

This setup extends Matt Pocock-style repo docs. If `docs/agents/issue-tracker.md` or `docs/agents/triage-labels.md` is missing, run `setup-matt-pocock-skills` first.

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

## Process

### 1. Explore

Look at the current repo before asking questions:

- `git remote -v`, `.git/config`, and current branch.
- `AGENTS.md` and `CLAUDE.md`; check for an existing `## Agent skills` block.
- `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`, and `docs/agents/domain.md`.
- `docs/agents/work-item-pipeline.md`; if present, update it instead of replacing it.
- Azure DevOps project/team/repository names from remotes, repo docs, work item links, or MCP context.
- Existing pipeline/build/release docs, YAML files, and references to `main`, staging, CI, or deployment.
- Existing tracker state/tag vocabulary.

Prefer repo evidence over assumptions. If Azure DevOps MCP tools are available, they may be used to confirm projects, work items, and pipeline runs.

If `docs/agents/issue-tracker.md` or `docs/agents/triage-labels.md` is missing, stop and route to `setup-matt-pocock-skills` before writing pipeline-specific docs.

### 2. Present findings and ask

Summarize what is present and missing. Then walk the user through the setup decisions one at a time. Do not ask all sections at once.

**Section A - Azure DevOps scope.**

> Explainer: These skills only implement and land Azure DevOps `Issue` and `Bug` work items. Planning-level items should route out before implementation.

Confirm:

- Azure DevOps organization/project/team.
- In-scope work item types: default `Issue`, `Bug`.
- Out-of-scope types: default `Feature`, `Epic`.

**Section B - Branch and push policy.**

> Explainer: Landing can happen locally, but pushing shared branches may trigger tests, staging builds, or deployment. The skills need to know where to stop.

Confirm:

- Default target branch, usually `main`.
- Remote target branch, usually `origin/main`.
- Push policy: default `always ask the human; never push automatically`.
- Whether local landing without push should create a `landed-not-closed` comment.

**Section C - Tracker states and tags.**

> Explainer: Azure DevOps states and tags vary by project. The skills need a local mapping so they do not invent invalid states.

Confirm semantic tags or mappings:

- `needs-info`
- `needs-product-decision`
- `needs-access`
- `ready-for-agent`
- `ready-for-human-verification`
- `landed-not-closed`
- `closed-with-evidence`

If the project cannot use tags, record that comments carry these semantic outcomes instead.

**Section D - Integration evidence.**

> Explainer: Closing should require shared evidence when pushing `main` triggers tests, staging builds, deployment, or similar gates.

Confirm:

- Which pipeline/build/staging checks matter for closure.
- Pipeline IDs/names if known.
- Whether Azure DevOps MCP pipeline evidence is sufficient for closure.
- Whether user-provided evidence is accepted when the agent cannot query the pipeline.

**Section E - Automatic closure.**

> Explainer: The landing skill can close `Issue` and `Bug` work items only after shared containment and required integration evidence are present.

Confirm:

- Whether automatic closure is allowed.
- Which human gates block closure: manual QA, device QA, TestFlight/App Store, customer confirmation, rollout monitoring, product acceptance, or release supervision.

### 3. Confirm and edit

Show the user a draft of:

- Any additions to the existing `## Agent skills` block in `AGENTS.md` or `CLAUDE.md`.
- `docs/agents/work-item-pipeline.md`.
- Any needed updates to `docs/agents/issue-tracker.md` or `docs/agents/triage-labels.md`.

Let the user adjust the draft before writing.

### 4. Write

Pick the file to edit:

- If `CLAUDE.md` exists, edit it.
- Else if `AGENTS.md` exists, edit it.
- If neither exists, ask the user which one to create.

If an `## Agent skills` block already exists, update it in place. Add a short `### Work item pipeline` subsection that points to `docs/agents/work-item-pipeline.md`.

Write `docs/agents/work-item-pipeline.md` using [work-item-pipeline.md](work-item-pipeline.md) as the seed template.

Do not duplicate the issue tracker, triage label, or domain docs created by `setup-matt-pocock-skills`; reference them and add only pipeline-specific configuration.

### 5. Done

Tell the user setup is complete and which skills will read the new docs: `work-item-pipeline`, `issue-implementer`, `issue-landing`, and `commit-message-writer`.
