#Requires AutoHotkey v2.0
#SingleInstance Force

; Ctrl+Alt+V: push the clipboard image or file to SSH_CLIP_HOST and put its remote path on the clipboard.
; ssh-clip.ps1 must sit next to this script.
^!v:: {
    exitCode := RunWait('powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' A_ScriptDir '\ssh-clip.ps1"', , "Hide")
    messages := Map(
        0, "Pushed to Linux: path is on the clipboard",
        1, "Nothing to push on the clipboard",
        2, "Upload failed: check SSH and Tailscale",
        3, "SSH_CLIP_HOST is not set"
    )
    ToolTip(messages.Get(exitCode, "ssh-clip failed (exit " exitCode ")"))
    SetTimer(() => ToolTip(), -2000)
}
