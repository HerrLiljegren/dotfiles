# Git aliases selected from the pinned Oh My Zsh Git plugin.
# Keep definitions identical to vendor/zsh/oh-my-zsh-git/git.plugin.zsh.

# Basics and staging.
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gsb='git status --short --branch'
alias gss='git status --short'
alias gst='git status'
alias gd='git diff'
alias gds='git diff --staged'

# Branches and history.
alias gb='git branch'
alias gba='git branch --all'
alias gsw='git switch'
alias gswc='git switch --create'
alias gsh='git show'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glg='git log --stat'
alias glgp='git log --stat --patch'

# Commits and history editing.
alias gc='git commit --verbose'
alias gcmsg='git commit --message'
alias gcfu='git commit --fixup'
alias grb='git rebase'
alias grbi='git rebase --interactive'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grst='git restore --staged'

# Remotes and synchronization.
alias gf='git fetch'
alias gfa='git fetch --all --tags --prune --jobs=10'
alias gpr='git pull --rebase'
alias gp='git push'

# Stashes and cherry-picks.
alias gsta='git stash push'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gsts='git stash show --patch'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
