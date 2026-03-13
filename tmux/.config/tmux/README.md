# tmux status bar notes

This config uses a small Catppuccin Mocha theme and Nerd Font glyphs to make
the session name and windows look like pills.

## The main ideas

- `set -g ...` changes a tmux option globally.
- `@name` stores a user option. Here it is used for color names.
- `#{@name}` inserts that stored value later.
- `#[]` is tmux style syntax inside status text.
- `#S` is the current session name.
- `#I` is the window number.
- `#W` is the window name.
- `#{pane_current_path}` is the current pane's path.
- `#{?client_prefix,yes,no}` is a small if/else expression.

## Small example

This line stores a color:

```tmux
set -g @ctp_blue '#89b4fa'
```

This line uses it:

```tmux
set -g status-style "bg=#{@ctp_mantle},fg=#{@ctp_text}"
```

So you can read that as: background = mantle, foreground = text.

## How the pills work

The bar uses Nerd Font / Powerline glyphs:

- `` left rounded edge
- `` right rounded edge

The middle text gets a background color, and the two edge glyphs are colored to
blend into the bar around it. That creates the pill effect.

## Status bar lines in this config

- `status-position top` puts the bar at the top.
- `status-style` sets the overall bar colors.
- `status-left` draws the session pill.
- `window-status-format` draws inactive window pills.
- `window-status-current-format` draws the active window pill.
- `status-right` draws the right side pills.
- `status-right-length` gives the right side enough room.
- `window-status-separator ""` removes tmux's default spacing between windows.

## Current right side

The right side currently shows three kinds of information:

- prefix state: `#{?client_prefix,...}` only shows the `PREFIX` pill while the prefix is active
- current path: `#{pane_current_path}` shows the path of the active pane
- time: `%H:%M` shows the current time

This config also uses:

```tmux
#{=/40/...:pane_current_path}
```

That means: if the path is longer than 40 characters, trim it and add `...`.

If you want the full path, use:

```tmux
#{pane_current_path}
```

If you want only the current directory name, use:

```tmux
#{b:pane_current_path}
```

## Easiest things to tweak

Change only these first:

- `@ctp_blue` to change the session pill color
- `@ctp_pink` to change the active window color
- `window-status-format` to show only `#W` instead of `#I:#W`
- `window-status-current-format` to make the active window text bolder or simpler

Example: show only window names:

```tmux
set -g window-status-format "#[fg=#{@ctp_surface1},bg=#{@ctp_mantle}]#[fg=#{@ctp_subtext1},bg=#{@ctp_surface1}] #W #[fg=#{@ctp_surface1},bg=#{@ctp_mantle}] "
set -g window-status-current-format "#[fg=#{@ctp_pink},bg=#{@ctp_mantle}]#[fg=#{@ctp_crust},bg=#{@ctp_pink},bold] #W #[fg=#{@ctp_pink},bg=#{@ctp_mantle}] "
```

## Reloading

Inside tmux:

```tmux
prefix + R
```

In this config, the prefix is `Ctrl-Space`.

From the shell:

```sh
tmux source-file ~/.config/tmux/tmux.conf
```

## One tmux gotcha

If you comment out a style line, tmux may keep the old value in memory until you
set a new value or restart the tmux server.

If a theme change seems stuck, restart tmux completely:

```sh
tmux kill-server
```
