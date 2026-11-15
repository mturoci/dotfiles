#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_nvim_macos() {
    info "Installing neovim for macOS via asdf..."

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

install_delta_macos() {
    info "Installing delta for macOS..."

    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    if ! command_exists delta; then
        info "Installing delta via Homebrew..."
        brew install git-delta
    else
        info "delta already installed"
    fi
}

install_ripgrep_macos() {
    info "Installing ripgrep for macOS..."

    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    if ! command_exists rg; then
        info "Installing ripgrep via Homebrew..."
        brew install ripgrep
    else
        info "ripgrep already installed"
    fi
}

setup_nvim_config() {
    info "Setting up neovim configuration..."

    mkdir -p "$HOME/.config"
    create_symlink "$SCRIPT_DIR" "$HOME/.config/nvim"

    info "Neovim configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_nvim_macos
        install_delta_macos
        install_ripgrep_macos
    fi
    setup_nvim_config
}

main "$@"
