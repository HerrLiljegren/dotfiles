# Portable development dotfiles

Shared, credential-free configuration for Linux, WSL, and Linux-based dev
containers. Host packages, graphical desktop settings, identity, and other
machine-specific setup remain outside this repository.

## Managed configuration

- Bash and Zsh, including history, completion, aliases, and vendored plugins
- Git behavior, aliases, global ignores, and Delta
- Bat, Btop, Ghostty, Glow, Hunk, Lazygit, Neovim, Ov, Starship, Worktrunk, and Yazi
- Herdr and its optional plugins
- Global Codex working agreements

The repository configures existing applications. Only explicit optional setup
may download plugins.

## Install

Clone to a stable path because installed files are symlinks:

```bash
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}" \
  && git clone https://github.com/HerrLiljegren/dotfiles.git "${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles" \
  && "${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/install.sh"
```

The installer is idempotent. It preserves existing shell and Git files through
managed blocks, and moves conflicting destinations to `.pre-dotfiles` backups.
Installation stops rather than overwrite an existing backup.

Interactive runs offer configuration-only installation or all optional setup.
Automation can choose explicitly:

```bash
./install.sh --with all
./install.sh --with herdr-plugins
./install.sh --with none
```

Run `./install.sh --help` for the current options.

## Local shell configuration

Optional Bash/Zsh exports may be added to:

```text
~/.config/dotfiles/local.sh
```

Zsh-only configuration may be added to:

```text
~/.config/dotfiles/personal.zsh
```

Keep `ZDOTDIR` unchanged in these files; VS Code temporarily sets it while
injecting shell integration.

## Shell tools

`ghelp` documents the shared Git aliases. Use `ghelp <alias-or-category>` or
`ghelp --all` for more detail.

`cliq` asks pi for a shell command and inserts it for review. `cliq --run`
executes suggestions that pass its static safety gate; `--force` is required
for commands classified as dangerous. Executed suggestions are logged under
`~/.local/share/cliq/log`.

Herdr plugins are installed only when selecting `herdr-plugins` or `all`.
Their sources are declared in `config/herdr/plugins.tsv`.

## Dev containers

A dev-container setup should install required binaries, clone this repository
at a pinned commit, and run `install.sh` as the non-root user. The consumer owns
the selected revision; the installer never updates its checkout.

## Verify

```bash
bash -n install.sh install/optional/herdr-plugins.sh uninstall.sh doctor.sh
bash -n tests/install.sh tests/install-options.sh
bash tests/herdr-install.sh
bash tests/install-options.sh
bash tests/git-alias-guide.sh
bash tests/skillset.sh
zsh tests/git-aliases.zsh
zsh tests/cliq.zsh
bash tests/install.sh
./doctor.sh
```

## Uninstall

```bash
./uninstall.sh
```

Uninstall removes managed links and blocks and restores `.pre-dotfiles`
backups. Applications, caches, and the checkout remain untouched.

## Security

Keep credentials, authentication state, SSH material, private hosts, employer
details, session history, generated conversations, and machine identifiers out
of the repository. Use the host or an external secret manager for
authentication.
