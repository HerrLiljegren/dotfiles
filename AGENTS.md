# Repository guidance

## Scope

This repository contains public, portable development configuration for Linux,
WSL, and Linux-based devcontainers.

## Working agreements

- Keep configuration free of credentials, personal identity, employer names,
  private hosts, and absolute user home paths.
- Keep `install.sh` dependency-free beyond Bash and standard Linux utilities.
- Do not install applications or project runtimes from this repository.
- Preserve existing user configuration and Git credential helpers.
- Never set or unset `ZDOTDIR`; callers such as VS Code own it during startup.
- Run `bash tests/install.sh` after changing installation behavior or managed
  paths.
- Prefer explicit file mappings over recursive discovery or a profile system.

## Skillset ownership

- Keep only the public desired-state manifest in this repository. Materialized
  skill contents belong in the external catalog managed through `gh skill`.
- `skillset` owns only manifest-listed names and projects enabled catalog
  entries as symlinks into both `.agents/skills` and `.claude/skills`.
- Preserve differently named entries owned by other installers. Refuse a
  same-name foreign file, directory, or symlink before changing either harness
  directory.
- Keep GitHub discovery, installation, and updates delegated to `gh skill`; do
  not add alternate source backends or fallback behavior.
- Run `bash tests/skillset.sh` after changing manifest, catalog, ownership, or
  reconciliation behavior.
