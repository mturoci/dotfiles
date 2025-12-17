#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_aerospace_macos() {
    info "Installing AeroSpace for macOS..."

    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    if brew list --cask nikitabobko/tap/aerospace &>/dev/null; then
        info "AeroSpace already installed"
    else
        info "Installing AeroSpace via Homebrew..."
        brew install --cask nikitabobko/tap/aerospace
    fi
}

setup_aerospace_config() {
    info "Setting up AeroSpace configuration..."

    mkdir -p "$HOME/.config/aerospace"

    create_symlink "$SCRIPT_DIR/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"

    info "AeroSpace configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_aerospace_macos
    fi
    setup_aerospace_config
}

main "$@"
