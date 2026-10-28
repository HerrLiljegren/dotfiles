# SSH clipboard push

Sends the Windows clipboard to a Linux host over SSH, so a remote program such
as Claude Code can read it with its own paste key. The clipboard image or file
is saved on the host under `~/.cache/pasted/`, and the Windows clipboard is
replaced with the remote path.

## Requirements

- Windows PowerShell 5.1 (`powershell.exe`)
- [AutoHotkey v2](https://www.autohotkey.com/) for the hotkey
- Key-based SSH to the host, working without a password prompt
  (`ssh -o BatchMode=yes <host> true` must succeed)

## Setup

Set the host once, as a user environment variable. Use an alias from
`~/.ssh/config` or `user@host`:

```powershell
[Environment]::SetEnvironmentVariable('SSH_CLIP_HOST', 'user@host', 'User')
```

Then start `ssh-clip.ahk`, and place a shortcut to it in
`shell:startup` to run at login. Restart AutoHotkey after changing the variable,
since running processes keep the environment they started with.

## Use

Copy an image or a file, then press **Ctrl+Alt+V**. A tooltip reports the result.
Paste the path into the remote program, or press its paste key if it reads the
remote clipboard.

## Exit codes

`ssh-clip.ps1` can also run directly:

| Code | Meaning                                  |
| ---- | ---------------------------------------- |
| 0    | Pushed; remote path is on the clipboard  |
| 1    | Clipboard has no image or file           |
| 2    | Upload failed                            |
| 3    | `SSH_CLIP_HOST` is not set               |
