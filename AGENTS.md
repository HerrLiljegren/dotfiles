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
