#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_brave_arch() {
    if command_exists brave; then
        info "Brave already installed"
        return
    fi

    info "Installing Brave from AUR (brave-bin)..."
    if command_exists yay; then
        yay -S --needed --noconfirm brave-bin
    elif command_exists paru; then
        paru -S --needed --noconfirm brave-bin
    else
        sudo pacman -Sy --needed --noconfirm base-devel git
        local build_dir
        build_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/brave-bin.git "$build_dir"
        (cd "$build_dir" && makepkg -si --noconfirm)
        rm -rf "$build_dir"
    fi
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_brave_arch
    fi
}

main "$@"
