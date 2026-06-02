---
name: commit-message-writer
description: Writes a Git commit message from staged changes, diffstat, branch context, recent commits, and known Azure DevOps work item IDs. Use when the user asks for a commit message, is committing changes, or needs Conventional Commit guidance with Azure Boards `Refs #1234` footers.
---

# Commit Message Writer

Write the exact commit message text for staged Git changes.

This skill is tool-agnostic. Worktrunk or another Git wrapper may call equivalent guidance, but the message contract is plain Git.

## Quick Start

1. Inspect staged changes with `git diff --staged` and `git diff --staged --stat`.
2. Inspect branch name and recent commit style.
3. Read repo-local `docs/agents/work-item-pipeline.md` when present for Azure DevOps footer conventions.
4. Identify clearly known Azure DevOps work item IDs from branch name, user guidance, or existing commit footer patterns.
5. Output only the commit message text.

## Output Contract

- Output only the text that should be passed to `git commit`.
- Do not include explanations, markdown fences, XML tags, quotes, labels, or analysis.
- Do not echo the diff or these instructions.
- If the change is unclear, produce a conservative valid message anyway.

## Format

- Start with a single-line Conventional Commit message.
- Keep the subject under 50 characters when practical.
- Use format: `<type>(optional-scope): <subject>`.
- Use lowercase conventional commit types.
- Use imperative mood: `add feature`, not `added feature`.
- Prefer one-line messages for small or atomic changes.
- Add a body only when the change is clearly multi-part.
- For a body, add one blank line and then 1-4 bullets.
- Each body bullet starts with `- ` and stays concise.
- Add a footer only when Azure DevOps work item IDs are clearly known.

## Azure DevOps Footer

Use Azure Boards auto-linking syntax:

```text
Refs #5034
```

For multiple clearly relevant work items:

```text
Refs #5034, #6120
```

Prefer IDs from the branch name, explicit user guidance, or existing commit footer patterns. Do not infer work item IDs from unrelated numbers in the diff.

Put the footer after a blank line, preserving any body bullets above it. Do not use Markdown links.

## Style

- Match recent commit style when it is coherent.
- Describe what changed, not only why it was done.
- Do not list changed files.
- Avoid vague subjects like `update`, `cleanup`, or `fix stuff`.
- Preserve clearly known Azure Boards work item IDs as a `Refs` footer, not as the Conventional Commit scope.
