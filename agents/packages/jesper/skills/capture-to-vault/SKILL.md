---
name: capture-to-vault
description: Capture an in-the-moment thought, follow-up, decision, or later-task into the user's Work Obsidian vault without derailing the current agent session. Use when the user asks to capture, remember, note, park, save for later, or add something to the Work vault while another task is in progress.
argument-hint: "What should be captured?"
---

# Capture To Vault

Capture one concise note to the Work vault inbox, then return to the current task.

## Target

- Vault: `/home/jesper/Documents/Work`
- Inbox note: `/home/jesper/Documents/Work/00 Inbox/Idea Inbox.md`
- Section: `## Unprocessed`

## Workflow

1. Turn the user's capture request into one clear bullet.
2. Preserve concrete nouns, repo names, issue numbers, file paths, URLs, and stated intent.
3. Add enough context for future-Jesper to understand why it mattered.
4. Append the bullet under `## Unprocessed`.
5. Reply with one short confirmation and continue the previous task if there was one.

## Format

Use this shape:

```md
- YYYY-MM-DD: [capture]
```

If the note came from active work, include a compact context prefix:

```md
- YYYY-MM-DD: During [repo/task/issue], [capture].
```

## Rules

- Do not ask follow-up questions unless the capture is unintelligible.
- Do not expand the capture into a plan, PRD, issue, or implementation unless explicitly asked.
- Do not mark it as a commitment. It is inbox material.
- Do not edit, reorganize, or process older inbox items.
- Redact secrets and credentials; capture that a secret-related follow-up exists without storing the secret.
- Keep the confirmation short: `Captured to Work vault: [short label].`
