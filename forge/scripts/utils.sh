#!/bin/bash
# scripts/utils.sh

# scripts/utils.sh additions

# Colors
export CLR_RESET="\e[0m"
export CLR_BLU="\e[34m"
export CLR_GRN="\e[32m"
export CLR_YLW="\e[33m"
export CLR_RED="\e[31m"

log_info() { echo -e "${CLR_BLU}INFO  ${CLR_RESET} $1"; }
log_success() { echo -e "${CLR_GRN}OK    ${CLR_RESET} $1"; }
log_warn() { echo -e "${CLR_YLW}WARN  ${CLR_RESET} $1"; }
log_error() { echo -e "${CLR_RED}ERROR ${CLR_RESET} $1"; }

is_installed() {
    pacman -Qi "$1" &> /dev/null
}

is_group_installed() {
    pacman -Qg "$1" &> /dev/null
}

install_packages() {
    local to_install=()
    for pkg in "$@"; do
        if ! is_installed "$pkg" && ! is_group_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -ne 0 ]; then
        paru -S --noconfirm "${to_install[@]}"
    fi

    FORGE_INSTALLED_PACKAGES=("${to_install[@]}")
}

enable_user_services() {
    for service in "$@"; do
        if ! systemctl --user is-enabled "$service" &> /dev/null; then
            systemctl --user enable --now "$service"
        fi
    done
}
