# Agent Skills Dotfiles

This directory is the source of truth for local agent skills.

## Layout

- Skill packages live under `packages/<package>/skills/<skill>/`.
- Enabled skills are symlinks in `~/.agents/skills`.
- Profiles in `profiles/*.toml` describe durable enabled sets.
- `bin/agentctl` is the command surface for listing, enabling, disabling, applying profiles, and managing GitHub-backed packages.

## GitHub-Backed Packages

GitHub-backed packages are update-owned snapshots. Do not make persistent local edits inside imported packages. If an upstream skill needs local behavior changes, copy it into `packages/jesper/skills/<skill>` or another local package and enable that fork instead.

`package.toml` records the GitHub URL, branch, skill root, and last imported commit. `package-lock.toml` records hashes for imported skill files so updates can detect local modifications before overwriting. It also records generated per-skill source metadata such as upstream source path, group/category, and whether the skill came from a `deprecated` path.

## Command Contract

- `agentctl import-github <https://github.com/owner/repo>` previews an import and writes nothing.
- `agentctl import-github <https://github.com/owner/repo> --apply` creates the derived package, copies discovered skill directories, and writes package metadata.
- `agentctl update <package>` previews changes for one GitHub-backed package.
- `agentctl update <package> --apply` applies a clean update.
- `agentctl update --all [--apply]` checks all GitHub-backed packages.
- `agentctl list` shows known skills and live symlink state.
- `agentctl enable <package>/<skill>` changes the live symlink only.
- `agentctl disable <skill>` changes the live symlink only.
- `agentctl apply [profile]` reconciles live symlinks to a profile.

Imports and updates never auto-enable skills and never rewrite profiles. New skills stay disabled until the profile or live symlink is changed explicitly.

## Verification

When changing this system, verify `agentctl` from outside this directory as well as from inside it. Prefer preview commands before `--apply`, especially for GitHub-backed packages.
