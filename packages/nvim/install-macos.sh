#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_nvim_macos() {
    info "Installing neovim for macOS..."

    # Check if Homebrew is installed
    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    # Install neovim via Homebrew
    if ! command_exists nvim; then
        info "Installing neovim via Homebrew..."
        brew install neovim@0.9.4
    else
        info "neovim already installed"
    fi
}

install_delta_macos() {
    info "Installing delta for macOS..."

    # Check if Homebrew is installed
    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    # Install delta via Homebrew
    if ! command_exists delta; then
        info "Installing delta via Homebrew..."
        brew install git-delta
    else
        info "delta already installed"
    fi
}

setup_nvim_config() {
    info "Setting up neovim configuration..."

    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"

    # Create symlink for nvim config directory
    create_symlink "$SCRIPT_DIR" "$HOME/.config/nvim"

    info "Neovim configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_nvim_macos
        install_delta_macos
    fi
    setup_nvim_config
}

main "$@"
