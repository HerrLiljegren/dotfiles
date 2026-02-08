#!/bin/bash

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ ! -d "$TPM_DIR" ]; then
    log_info "Tmux Plugin Manager not found. Forging..."

    # Use git quietly
    git clone -q https://github.com/tmux-plugins/tpm "$TPM_DIR"

    log_info "Bootstrapping Tmux plugins (Background)..."
    # detatched session to avoid terminal flickering
    tmux new-session -d -s tpm_init "sleep 1; $TPM_DIR/bin/install_plugins; tmux kill-session" &>/dev/null

    log_success "TPM forged and plugins initialized."
else
    # We use a dimmer log here because it's a "skipped" state
    log_success "TPM is already present."
fi
