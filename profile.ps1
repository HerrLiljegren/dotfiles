$env:LC_ALL='C.UTF-8'
#Import-WslCommand "awk", "emacs", "grep", "head", "less", "ls", "man", "sed", "seq", "ssh", "tail", "vim", "vi", "htop", "find"
Import-Module posh-git
$GitPromptSettings.DefaultPromptSuffix = '`n$(''>'' * ($nestedPromptLevel + 1)) '
