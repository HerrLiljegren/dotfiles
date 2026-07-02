# Neovim

This is the dotfiles-managed Neovim config.

It uses [LazyVim](https://www.lazyvim.org/) as the base distribution and tracks
local customizations directly in this repository. The previous Kickstart config
was removed as a submodule; recover it from git history if needed.

## Layout

- `lua/config/options.lua`: local options
- `lua/config/keymaps.lua`: local keymaps
- `lua/config/autocmds.lua`: local autocmds
- `lua/config/lazy.lua`: LazyVim bootstrap and enabled extras
- `lua/plugins/*.lua`: local plugin additions and overrides
- `lazy-lock.json`: pinned plugin versions
- `lazyvim.json`: LazyVim metadata

## Enabled Extras

- `lazyvim.plugins.extras.lang.dotnet`

## Install

The `nvim` package is deployed with GNU Stow from the dotfiles root:

```sh
stow nvim
```
