#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_kitty_arch() {
    info "Installing Kitty for Arch Linux..."

    if ! command_exists kitty; then
        info "Installing Kitty terminal via pacman..."
        sudo pacman -Sy --needed --noconfirm kitty
    else
        info "Kitty already installed"
    fi
}

setup_kitty_config() {
    info "Setting up Kitty configuration..."

    # Create kitty config directory if it doesn't exist
    mkdir -p "$HOME/.config/kitty"

    # Create symlinks for kitty configs
    create_symlink "$SCRIPT_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    create_symlink "$SCRIPT_DIR/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"
    create_symlink "$SCRIPT_DIR/ssh.conf" "$HOME/.config/kitty/ssh.conf"

    info "Kitty configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_kitty_arch
    fi
    setup_kitty_config
}

main "$@"
