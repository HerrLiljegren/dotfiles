# Personal agent-skill management

Date: 2026-08-10

## Recommendation

Keep the useful part of `agentctl`, but make it much smaller.

- Use the first-party `gh skill` commands as the GitHub acquisition and update
  engine.
- Keep a small, declarative `agentctl` as the owner of the curated catalog,
  enabled set, profiles, and cross-harness links.
- Keep `~/.agents/skills` as the active shared surface for Codex, OpenCode, Pi,
  and GitHub Copilot CLI.
- Project the same active set into `~/.claude/skills` with per-skill symlinks
  for Claude Code.
- Use Codex or Claude plugins only when a capability actually needs that
  harness's plugin features; do not make either plugin system the source of
  truth for portable skills.

No current off-the-shelf tool satisfies all three requirements at once:
GitHub-backed install/update, a reproducible personal catalog, and one
cross-harness enabled set.

## Why `gh skill` should be the backend

The installed GitHub CLI is 2.97.0 and includes `gh skill`. The command is
still in public preview, but it already provides the missing commodity work:
search, preview, install, list, update, source tracking, and optional version
pinning. Its official host list includes all five relevant targets:
`github-copilot`, `claude-code`, `codex`, `opencode`, and `pi`.
[GitHub CLI overview](https://cli.github.com/manual/gh_skill)
[Install reference](https://cli.github.com/manual/gh_skill_install)

The useful lifecycle is:

```sh
gh skill search <query>
gh skill preview <owner/repo> <skill>
gh skill install <owner/repo> <skill> --dir <catalog-directory>
gh skill update --dir <catalog-directory> --dry-run
gh skill update --dir <catalog-directory> --all
```

`gh skill install` injects source metadata, resolves an unpinned skill from the
latest tag or default-branch HEAD, and supports tag/SHA pins. `gh skill update`
compares the stored tree SHA with GitHub and updates in place. A former
namespaced-`--dir` relocation bug was fixed by staging and atomically swapping
content in place; that fix landed before the locally installed 2.97.0.
[Update reference](https://cli.github.com/manual/gh_skill_update)
[in-place update fix](https://github.com/cli/cli/pull/13449)

Important limits remain:

- GitHub repositories and local directories are the supported sources.
- There is no remove/disable command, declarative manifest, profile, or
  scheduler.
- `--agent` installs for one host at a time; using a catalog plus a shared
  projection avoids maintaining five copies.

Those limits are exactly where a thin local layer is justified.

## Why not use `npx skills` as the source of truth

Vercel Labs' CLI is the strongest general cross-harness alternative. It
supports GitHub, GitLab, arbitrary Git URLs, archives, and local paths; it can
target multiple agents; and it provides `add`, `list`, `find`, `remove`, and
`update`. Its compatibility table includes all five relevant harnesses, and
its recommended installation mode uses one canonical copy plus agent-specific
symlinks.
[Vercel Labs skills CLI](https://github.com/vercel-labs/skills/blob/main/README.md)

It is not a sufficient declarative manager, however. Its lock file is an
update registry, not an install manifest: the open `skills sync` request
documents that `update` does not restore a missing skill whose recorded hash
already matches upstream. `remove` is therefore closer to uninstall than a
reversible disable operation.
[declarative sync gap](https://github.com/vercel-labs/skills/issues/283)

It remains a good one-off installer for non-GitHub sources. Making it the
primary manager would still require a custom manifest/profile layer, while
adding Node/npx to a workflow already covered by the installed GitHub CLI.

## Native systems do not provide one shared lifecycle

| Surface | Install/update | Enable/disable | Cross-harness fit |
| --- | --- | --- | --- |
| Codex skills | `$skill-installer` installs local/GitHub skills; standalone skills have no general update command | `[[skills.config]]` can disable by path | Reads `~/.agents/skills` and follows symlinked skill directories |
| Codex plugins | Git marketplaces can be upgraded and plugins installed/removed | Codex-specific plugin state | Good for Codex/ChatGPT bundles, not the other harnesses |
| Claude plugins | Marketplace add/install/update, per-marketplace auto-update | Native enable/disable/uninstall | Excellent Claude lifecycle, Claude-only |
| OpenCode | Discovers local shared skills | Per-skill `allow`, `ask`, or `deny` | Reads `~/.agents/skills` |
| Pi | Has its own Git/npm package install and update system | Harness-specific skill controls | Reads `~/.agents/skills` |
| Copilot CLI | `gh skill` and `copilot skill` operations | Interactive per-skill toggle | Reads `~/.agents/skills` |

OpenAI explicitly designates `$HOME/.agents/skills` for a user's curated
skills, supports symlinked skill folders, and warns that very large installed
sets can exceed the initial skill-list budget. It recommends plugins for
distribution and bundling, not as a universal personal package manager.
[OpenAI skill documentation](https://learn.chatgpt.com/docs/build-skills)
[OpenAI plugin documentation](https://learn.chatgpt.com/docs/build-plugins)

OpenCode, Pi, and GitHub Copilot CLI also document `~/.agents/skills` as a
global discovery location. Claude Code instead uses `~/.claude/skills`, but
supports directory symlinks, so it only needs a compatibility projection.
[OpenCode skills](https://opencode.ai/docs/skills/)
[Pi skills](https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/skills.md)
[Copilot CLI skills](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
[Claude Code skills](https://code.claude.com/docs/en/skills)

Harness-native disable switches should remain exceptional overrides. If the
desired enabled set is split among Codex TOML, OpenCode permissions, Claude
settings, and Copilot toggles, the original configuration-drift problem
returns.

## Proposed ownership model

```text
dotfiles/agents/
  skills.toml                 # packages, source/path/ref, enabled/profile state
  packages/<package>/skills/  # physical personal and imported skills
  profiles/*.toml             # named active sets, if profiles remain useful
  bin/agentctl                # projection and gh-skill orchestration only

~/.agents/skills/<skill>      -> physical catalog skill (active set)
~/.claude/skills/<skill>      -> same physical catalog skill (active set)
```

The successor should expose only:

```text
agentctl add <owner/repo> [skill]
agentctl list
agentctl enable <skill>
agentctl disable <skill>
agentctl apply <profile>
agentctl check
agentctl update [skill|--all]
```

Responsibilities should be strict:

- `gh skill` owns discovery, download, provenance metadata, comparison, and
  content updates.
- the manifest owns what exists, where it came from, and desired enabled state
- `agentctl` owns only safe symlink reconciliation and invoking `gh skill`
- harness-native plugins and skill directories are not silently imported into
  the shared catalog
- personal forks live under a personal package and are not overwritten from
  upstream

This preserves the legacy system's good contract while deleting its custom
GitHub URL parsing, downloading, tree traversal, update comparison, and
interactive package-management machinery.

## Update policy decision

Neither `gh skill` nor `npx skills` contains a scheduler. A timer can call the
manager, but silently applying every upstream change should be an explicit
trust decision: skills can include scripts, and GitHub warns that pre-approved
shell access in an untrusted skill can execute arbitrary commands.
[GitHub skill safety guidance](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills#enabling-a-skill-to-run-a-script)

Recommended default:

1. run a scheduled `agentctl check` backed by `gh skill update --dry-run`
2. notify when active skills have updates
3. apply with `agentctl update --all` after review
4. allow explicit per-package `auto_update = true` only for trusted upstreams

The remaining material choice before implementation is whether trusted
packages should auto-apply, or whether every upstream update should remain a
reviewed dotfiles change.
