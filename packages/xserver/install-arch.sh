#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

pkg_installed() {
    pacman -Qi "$1" >/dev/null 2>&1
}

install_xserver_arch() {
    info "Installing X server packages for Arch Linux..."

    local packages=(
        xorg-server
        xorg-xinit
        xorg-xrdb
        xorg-xrandr
        xorg-xdpyinfo
        xclip
        xsel
    )

    for pkg in "${packages[@]}"; do
        if ! pkg_installed "$pkg"; then
            info "Installing $pkg via pacman..."
            sudo pacman -S --needed --noconfirm "$pkg"
        else
            info "$pkg already installed"
        fi
    done

    info "X server packages installed successfully!"
}

setup_xserver_config() {
    info "Setting up X server configuration..."

    create_symlink "$SCRIPT_DIR/.xinitrc" "$HOME/.xinitrc"
    create_symlink "$SCRIPT_DIR/.Xresources" "$HOME/.Xresources"

    if [ -f "$SCRIPT_DIR/00-keyboard.conf" ]; then
        if [ ! -f /etc/X11/xorg.conf.d/00-keyboard.conf ] || ! cmp -s "$SCRIPT_DIR/00-keyboard.conf" /etc/X11/xorg.conf.d/00-keyboard.conf; then
            info "Installing X11 keyboard configuration (caps:escape)..."
            sudo mkdir -p /etc/X11/xorg.conf.d
            sudo cp "$SCRIPT_DIR/00-keyboard.conf" /etc/X11/xorg.conf.d/00-keyboard.conf
        else
            info "X11 keyboard configuration already up to date"
        fi
    fi

    info "X server configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_xserver_arch
    fi
    setup_xserver_config
}

main "$@"
