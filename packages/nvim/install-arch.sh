#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_nvim() {
    info "Installing neovim for Arch Linux via asdf..."

    # Add ~/.local/bin to PATH if not already there (for current session)
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Ensure asdf is available
    if ! command_exists asdf; then
        error "asdf not found. Please install asdf first."
        exit 1
    fi

    # Add neovim plugin if not already added
    if ! asdf plugin list | grep -q neovim; then
        info "Adding neovim plugin..."
        asdf plugin add neovim
    fi

    # Check if neovim is already installed
    if command_exists nvim; then
        info "neovim already installed"
        return
    fi

    # Install neovim 0.11.4
    info "Installing neovim 0.11.4 via asdf..."
    asdf install neovim 0.11.4
    asdf set --home neovim 0.11.4
    info "neovim 0.11.4 installed and set as global"
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
