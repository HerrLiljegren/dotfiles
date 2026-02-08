#!/bin/bash
# Forge: System Orchestrator
# A Typecraft-inspired automation engine

set -e

# Establish paths relative to the script location
FORGE_ROOT=$(dirname "$(readlink -f "$0")")
source "$FORGE_ROOT/scripts/utils.sh"

print_logo() {
    clear
    # Color: Red (31) for that "Hot Steel" look
    echo -e "\e[31m"
    cat << "EOF"
  ███████╗ ██████╗ ██████╗  ██████╗ ███████╗
  ██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝
  █████╗  ██║   ██║██████╔╝██║  ███╗█████╗  
  ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝  
  ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗
  ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
EOF
    echo -e "\e[0m"
    echo -e "  ${CLR_DIM}System Orchestration | Inspired by Typecraft${CLR_RESET}\n"
}

# --- 1. Initialization ---
print_logo
log_info "Synchronizing System Repos..."
system_updates_raw="$(sudo pacman -Syu --noconfirm | grep -E "upgrading|installing|removing" | tee /dev/stderr || true)"
if [ -z "$system_updates_raw" ]; then
    log_success "System is already up to date."
fi

# Bootstrap Paru
if ! command -v paru &> /dev/null; then
    echo "⚒️  Paru not found. Forging AUR helper..."
    sudo pacman -S --needed git base-devel --noconfirm
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
fi

log_info "Synchronizing AUR Repos..."
aur_updates_raw="$(paru -Sua --noconfirm | grep -E "upgrading|installing" | tee /dev/stderr || true)"
if [ -z "$aur_updates_raw" ]; then
    log_success "AUR is already up to date."
fi

# --- 2. Installation ---
source "$FORGE_ROOT/packages.conf"

log_info "Forging Package Sets..."
install_packages "${SYSTEM_UTILS[@]}" "${DEV_TOOLS[@]}" "${DESKTOP[@]}" "${MEDIA[@]}" "${FONTS[@]}"
log_success "All packages present."

# --- 3. Services ---
echo "⚙️  Enabling System Services..."
for svc in "${SERVICES[@]}"; do
    sudo systemctl enable --now "$svc"
done

echo "👤 Enabling User Services..."
enable_user_services "${USER_SERVICES[@]}"

# --- 4. Logic Modules ---
source "$FORGE_ROOT/scripts/tpm.sh"

# --- 5. Finalize ---
if gdbus introspect --session --dest dev.benz.walker --object-path /dev/benz/walker &>/dev/null; then
    log_info "Walker service active."
else
    log_info "Pre-warming Walker..."
    walker --gapplication-service &
fi

log_success "Forge Complete."
echo -e "\n${CLR_DIM}------------------------------------------${CLR_RESET}"

installed_summary=""
if [ ${#FORGE_INSTALLED_PACKAGES[@]} -gt 0 ]; then
    installed_summary="$(printf '%s\n' "${FORGE_INSTALLED_PACKAGES[@]}")"
fi

format_summary_block() {
    local label="$1"
    local content="$2"
    local count

    if [ -n "$content" ]; then
        count="$(printf '%s\n' "$content" | wc -l | tr -d ' ')"
    else
        count=0
    fi

    printf '  %b%s%b (%s)\n' "$CLR_DIM" "$label" "$CLR_RESET" "$count"
    if [ -n "$content" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && printf '    %b•%b %s\n' "$CLR_DIM" "$CLR_RESET" "$line"
        done <<< "$content"
    else
        printf '    %b•%b none\n' "$CLR_DIM" "$CLR_RESET"
    fi
}

cat << EOF
  Forge Details:
  - Repository: $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)
  - Packages:   $(echo "${SYSTEM_UTILS[@]} ${DEV_TOOLS[@]}" | wc -w) tracked
  - Services:   ${#SERVICES[@]} system / ${#USER_SERVICES[@]} user
EOF

format_summary_block "System updates" "$system_updates_raw"
format_summary_block "AUR updates" "$aur_updates_raw"
format_summary_block "Installed by Forge" "$installed_summary"
