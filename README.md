# Portable development dotfiles

Public, credential-free configuration for Linux, WSL, and Linux-based
devcontainers. The repository configures tools but never installs them.

## Ownership boundaries

- A Dev Container Feature installs CLI tools and their system dependencies.
- The devcontainer setup owns shared VS Code settings and extensions.
- This repository owns the complete, shared terminal development experience.
- A separate private workstation repository owns host packages, Ghostty,
  Windows Terminal, local VS Code preferences, identity, work details, and
  machine-specific setup.

## Managed configuration

- Bash and Zsh integration
- Shared Zsh history, fzf completion, autosuggestions, and syntax highlighting
- Git behavior and global ignore patterns
- Bat, Delta, Glow, Hunk, Starship, and Neovim
- Worktrunk and Herdr
- Global Codex working agreements

No profile system is used. The public configuration is the shared team
configuration.

## Installation

Clone the repository to a stable location because managed files are symlinks:

```bash
git clone <repository-url> "${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
"${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/install.sh"
```

`install.sh` resolves its own location, supports any non-root `$HOME`, and can
be run repeatedly. Existing unmanaged destinations are moved once to a sibling
with the `.pre-dotfiles` suffix. If that backup already exists, installation
stops rather than overwriting either file.

The installer preserves existing `.bashrc`, `.zshrc`, `.gitconfig`, and Git
credential helpers. It adds clearly marked source/include blocks instead of
replacing those files.

### Personal configuration

The public shell is fully usable without a personal layer. A private
workstation repository may add portable Bash/Zsh exports in:

```text
~/.config/dotfiles/local.sh
```

Zsh-only options, functions, or bindings belong in:

```text
~/.config/dotfiles/personal.zsh
```

Both files are optional and remain outside this repository. Do not set or
unset `ZDOTDIR` in `.zshenv` or either personal file. VS Code temporarily owns
that variable while injecting its shell integration.

### Vendored Zsh plugins

Runtime files for autosuggestions, history substring search, syntax
highlighting, and fzf-tab are pinned under `vendor/zsh`. Shell startup never
clones or updates plugins. Upstream revisions and retained licenses are
documented in `vendor/zsh/README.md`.

## Devcontainer integration

The devcontainer setup should:

1. Install required binaries through the separate Dev Container Feature.
2. Clone this repository at a pinned commit into a stable path under the
   container user's home directory.
3. Run `install.sh` as the non-root remote user.

The dotfiles installer does not install packages or project runtimes and does
not update its own Git checkout.

## Updating

The consumer controls the selected Git revision. Update the pinned commit,
check out that revision in the stable clone, and run `install.sh` again. Your
private workstation setup may track `main` if you prefer faster personal
updates.

## Verification

```bash
bash -n install.sh uninstall.sh doctor.sh tests/install.sh
bash tests/install.sh
./doctor.sh
```

The test installs twice into a temporary home, verifies ordinary and VS
Code-injected Zsh startup, confirms the second install makes no changes,
preserves an existing Git credential helper, and exercises uninstall and
backup restoration.

## Uninstalling

```bash
./uninstall.sh
```

Uninstall removes only symlinks that still point into this checkout, restores
`.pre-dotfiles` backups, and removes the managed shell and Git blocks. It does
not remove applications, caches, or the repository checkout.

## Security

Never commit credentials, authentication state, SSH material, private hosts,
employer details, session history, generated conversations, or machine
identifiers. Authentication remains the responsibility of the host,
devcontainer, or an external secret manager.
