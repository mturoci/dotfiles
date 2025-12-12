#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_nvim_macos() {
    info "Installing neovim for macOS..."

    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    if ! command_exists nvim; then
        info "Installing neovim via Homebrew..."
        brew install neovim
    else
        info "neovim already installed"
    fi
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
