#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

pkg_installed() {
    pacman -Qi "$1" >/dev/null 2>&1
}

install_i3_arch() {
    info "Installing i3 window manager packages for Arch Linux..."

    local packages=(
        i3-wm
        i3status
        i3lock
        dmenu
        brightnessctl
        flameshot
        libpulse
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-utils
        dex
    )

    for pkg in "${packages[@]}"; do
        if ! pkg_installed "$pkg"; then
            info "Installing $pkg via pacman..."
            sudo pacman -S --needed --noconfirm "$pkg"
        else
            info "$pkg already installed"
        fi
    done

    info "i3 packages installed successfully!"
}

setup_i3_config() {
    info "Setting up i3 configuration..."

    mkdir -p "$HOME/.config/i3"
    create_symlink "$SCRIPT_DIR/config" "$HOME/.config/i3/config"

    mkdir -p "$HOME/.config/i3status"
    create_symlink "$SCRIPT_DIR/i3status.conf" "$HOME/.config/i3status/config"

    mkdir -p "$HOME/.config/flameshot"
    create_symlink "$SCRIPT_DIR/flameshot.ini" "$HOME/.config/flameshot/flameshot.ini"

    mkdir -p "$HOME/.config/xdg-desktop-portal"
    create_symlink "$SCRIPT_DIR/portals.conf" "$HOME/.config/xdg-desktop-portal/portals.conf"

    info "i3 configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_i3_arch
    fi
    setup_i3_config
}

main "$@"
