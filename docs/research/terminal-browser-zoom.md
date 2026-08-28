# terminal-browser zoom keys

## Finding

The upstream `zenbu-labs/terminal-browser` README does not define a separate
browser zoom shortcut. Its Linux shortcut table says that zoom in, zoom out,
and reset use “your terminal's zoom keybind”. Therefore, in Ghostty,
terminal-browser zoom follows Ghostty's font-size bindings rather than an
Electron/Chromium browser shortcut.

The same README documents `--no-shortcuts` as an option that disables browser
shortcuts, but that does not change the terminal zoom binding itself.

## Local implication

The repository's Ghostty configuration currently binds font zoom to:

```ini
keybind = ctrl+shift+equal=increase_font_size:1
keybind = ctrl+shift+plus=increase_font_size:1
keybind = ctrl+shift+minus=decrease_font_size:1
keybind = ctrl+shift+zero=reset_font_size
```

Thus the expected zoom controls are `Ctrl+Shift+=`/`Ctrl+Shift++`,
`Ctrl+Shift+-`, and `Ctrl+Shift+0`, provided the running Ghostty instance has
loaded this configuration. Plain `Ctrl+=` is not the configured zoom key.

## Sources

- [terminal-browser README](https://github.com/zenbu-labs/terminal-browser#shortcuts)
- [Ghostty keybinding documentation](https://ghostty.org/docs/config/keybind)
- [Ghostty keybinding action reference](https://ghostty.org/docs/config/keybind/reference)
