# Agent Skills

This directory is the source of truth for local agent skills.

Skills are grouped by package/provenance under `packages/*/skills/*`.
Harness enablement is intentionally filesystem-based:

- enabled: `~/.agents/skills/<name>` symlinks to a skill directory here
- disabled: no symlink in `~/.agents/skills`

The goal is that Codex, OpenCode, Copilot, Gemini CLI, and similar harnesses
all see the same enabled set by reading `~/.agents/skills`.

## Packages

- `anthropics-skills`: imported third-party skills from Anthropic examples.
- `vercel-labs-skills`: imported third-party skills from Vercel Labs.
- `mattpocock-skills`: imported third-party skills from Matt Pocock.
- `azdo-work-item-pipeline`: Jesper's Azure DevOps work item pipeline package.
- `jesper`: local personal skills.

## Forking Rule

When an upstream skill needs persistent local behavior changes, copy it into
`packages/jesper/skills/<name>` or a new local package and repoint the symlink.
Keep the original package copy intact so upstream provenance remains clear.
