#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_nvim() {
    info "Installing neovim for Arch Linux..."

    if command_exists nvim; then
        info "neovim already installed"
        return
    fi

    info "Installing neovim via pacman..."
    sudo pacman -Sy --needed --noconfirm neovim
}

install_delta() {
    info "Installing delta for Arch Linux..."

    if command_exists delta; then
        info "delta already installed"
        return
    fi

    info "Installing git-delta via pacman..."
    sudo pacman -S --needed --noconfirm git-delta
}

install_ripgrep() {
    info "Installing ripgrep for Arch Linux..."

    if command_exists rg; then
        info "ripgrep already installed"
        return
    fi

    info "Installing ripgrep via pacman..."
    sudo pacman -S --needed --noconfirm ripgrep
}

setup_nvim_config() {
    info "Setting up neovim configuration..."

    mkdir -p "$HOME/.config"
    create_symlink "$SCRIPT_DIR" "$HOME/.config/nvim"

    info "Neovim configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_nvim
        install_delta
        install_ripgrep
    fi
    setup_nvim_config
}

main "$@"
