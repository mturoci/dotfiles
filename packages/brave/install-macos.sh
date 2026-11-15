#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_brave_macos() {
    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    if brew list --cask brave-browser &>/dev/null || [ -d "/Applications/Brave Browser.app" ]; then
        info "Brave already installed"
    else
        info "Installing Brave via Homebrew..."
        brew install --cask brave-browser
    fi
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_brave_macos
    fi
}

main "$@"
