# Portable development dotfiles

Public, credential-free configuration for Linux, WSL, and Linux-based
devcontainers. The repository does not install applications or project
runtimes. Explicit optional setup may install plugins through an existing tool.

## Ownership boundaries

- A Dev Container Feature installs CLI tools and their system dependencies.
- The devcontainer setup owns shared VS Code settings and extensions.
- This repository owns the complete, shared terminal development experience.
- A separate private workstation repository owns host packages, Ghostty,
  Windows Terminal, local VS Code preferences, identity, work details, and
  machine-specific setup.

## Managed configuration

- Bash and Zsh integration
- Shared Zsh history, fzf completion, autosuggestions, syntax highlighting,
  and alias reminders
- Git behavior, OMZ-compatible aliases, an alias guide, and global ignores
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

When standard input and output are attached to a terminal, the installer asks
whether to install dotfiles only or everything. Dotfiles only is the default.
Everything includes the latest Herdr plugins; the prompt explains that this
requires network access and may run third-party build commands.

Non-interactive installation remains configuration-only. Automation can select
optional setup explicitly:

```bash
./install.sh --with all
./install.sh --with herdr-plugins
./install.sh --with none
```

`--with` is repeatable for future optional setup. `all` and `none` cannot be
combined with another selection. Run `./install.sh --help` for the complete
interface.

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

### Git aliases

The shared Bash and Zsh aliases are a curated subset of the Oh My Zsh Git
plugin. Their definitions are verified against a pinned upstream snapshot.
Run `ghelp` for a compact overview, `ghelp <alias-or-category>` for usage
guidance, or `ghelp --all` for the complete guide.

### Vendored Zsh plugins

Runtime files for autosuggestions, history substring search, syntax
highlighting, fzf-tab, and alias reminders are pinned under `vendor/zsh`.
The pinned Oh My Zsh Git plugin is retained there as the alias reference.
Shell startup never clones or updates plugins. Upstream revisions and retained
licenses are documented in `vendor/zsh/README.md`.

### Herdr plugins

The Herdr configuration depends on the plugins declared in
`config/herdr/plugins.tsv`. Selecting `herdr-plugins` or `all` runs
`herdr plugin install <source> --yes` for every declaration. Each invocation
installs or refreshes the latest upstream version; Herdr owns the resulting
plugin checkouts and state.

The `herdr-splits.nvim` repository supplies two cooperating parts. Herdr owns
the `herdr-splits` plugin installed by the optional setup, while Lazy.nvim owns
the Neovim plugin declared under `config/nvim`.

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
bash -n install.sh install/optional/herdr-plugins.sh uninstall.sh doctor.sh
bash -n tests/install.sh tests/install-options.sh
bash tests/install-options.sh
bash tests/git-alias-guide.sh
bash tests/skillset.sh
zsh tests/git-aliases.zsh
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
