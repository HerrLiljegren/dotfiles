# Push the clipboard image or file to the host in SSH_CLIP_HOST and put its remote path on the clipboard.
# Exit codes: 0 pushed, 1 nothing usable on the clipboard, 2 upload failed, 3 SSH_CLIP_HOST not set.
# Run with Windows PowerShell 5.1; Get-Clipboard -Format Image is not in pwsh 7.
Add-Type -AssemblyName System.Drawing

$sshHost = $env:SSH_CLIP_HOST
if (-not $sshHost) { exit 3 }

$files = Get-Clipboard -Format FileDropList
if ($files -and (Test-Path $files[0] -PathType Leaf)) {
  $src = $files[0]
  $ext = [IO.Path]::GetExtension($src) -replace '[^A-Za-z0-9.]', ''
} else {
  $img = Get-Clipboard -Format Image
  if (-not $img) { exit 1 }
  $src = Join-Path $env:TEMP 'ssh-clip.png'
  $img.Save($src, [System.Drawing.Imaging.ImageFormat]::Png)
  $ext = '.png'
}

# Feed ssh from the file, not a pipe: PS 5.1 pipes mangle binary data.
# The remote side saves the upload and prints its path. Keep double quotes out of $remoteCmd.
$remoteCmd = "set -e; mkdir -p `$HOME/.cache/pasted; p=`$HOME/.cache/pasted/clip-`$(date +%Y%m%d-%H%M%S)$ext; cat > `$p; echo `$p"
$remote = (cmd.exe /c "ssh -o BatchMode=yes $sshHost ""$remoteCmd"" < ""$src""" | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or -not $remote) { exit 2 }

Set-Clipboard -Value $remote
