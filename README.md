## 🛠️ Installation

### 1. Clone the repository

```bash
git clone --recursive git@github.com:HerrLiljegren/dotfiles.git ~/dotfiles
cd ~/dotfiles

```

### 2. Configure ZDOTDIR

Zsh needs to know your config has moved. Add this to your `~/.zshenv` (create it if it doesn't exist):

```bash
export ZDOTDIR="$HOME/.config/zsh"

```

### 3. Deploy with GNU Stow

Instead of manual symlinking, use **Stow** to map your configuration packages to `~/.config`. Run this from your `~/dotfiles` directory:

```bash
# Mirrors zsh, nvim, and starship into your ~/.config
stow zsh nvim starship

# Scripts and small utilities into ~/.local/bin
stow scripts

```

### 4. Bootstrap

Simply restart your shell or run `zsh`. The **Antidote** bootstrap logic in your `.zshrc` will automatically clone the plugin manager and initialize your environment.

---

## ⌨️ Usage

### AI-Augmented Workflow: `updot`

Automate the "Double Commit" (Nvim submodule + Parent repo) with AI-generated messages.

* **`updot`**: No arguments? OpenCode (Gemini 3 Flash) analyzes your `git diff` and writes your commit messages for you.
* **`updot "msg"`**: Overrides the AI with your own manual commit message.

### Configuration Search: `dots`

The ultimate "find and edit" command.

* **`dots`**: Triggers a fuzzy search (via `fzf` and `fd`) with a live `bat` preview of your configs. Pressing `Enter` opens the file in your Nvim/Kickstart setup.

### Screenshots (Greenshot-style on Hyprland)

The `shot` script emulates Greenshot muscle-memory on Hyprland (region/window/full/last) and shows a destination chooser for copy/save/annotate/open.

---

## 🧰 Tech Stack

| Component | Tool |
| --- | --- |
| **OS** | Arch Linux (WSL) |
| **Shell** | Zsh + Antidote |
| **Symlink Mgr** | GNU Stow |
| **Editor** | Neovim (Kickstart Submodule) |
| **AI CLI** | OpenCode (google/gemini-3-flash-preview) |
| **Navigation** | Zoxide + fzf-tab |

## Paru

| Command | What it actually does |
| ------- | --------------------- |
| paru | Just typing the name with no flags runs a full system update (including AUR). |
| paru -Sua | Updates only your AUR packages (skips the main system sync). |
| paru -Sc | The Janitor: Cleans out uninstalled cached files. Keeps your SSD lean. |
| paru -Rns | The Clean Uninstall: Removes the app and its dependencies and its config files. |
| - | - |
| paru -Si <package> | View the "Stats" before installing (license, size, dependencies). |
| paru -Ql <package> | "Where did the files go?" Shows every file the package installed. |
| paru -G <package> | "Get" the build files. Downloads the PKGBUILD so you can inspect how it’s built. |
