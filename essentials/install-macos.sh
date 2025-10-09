#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_essentials_macos() {
    info "Installing essential tools for macOS..."

    # Check if Homebrew is installed
    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    # Install gzip (GNU version with better features than macOS default)
    if ! brew list gzip &>/dev/null; then
        info "Installing gzip via Homebrew..."
        brew install gzip
    else
        info "gzip already installed"
    fi

    # Install GNU tar (gtar - GNU version with more features than BSD tar)
    if ! brew list gnu-tar &>/dev/null; then
        info "Installing gnu-tar via Homebrew..."
        brew install gnu-tar
    else
        info "gnu-tar already installed"
    fi

    # Install make (GNU make - may already be present via Xcode Command Line Tools)
    if ! brew list make &>/dev/null; then
        info "Installing make via Homebrew..."
        brew install make
    else
        info "make already installed"
    fi

    info "Essential tools installed successfully!"
    info "Note: GNU tar is available as 'gtar' command"
    info "Note: GNU gzip is available in PATH with priority over system version"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_essentials_macos
    fi
}

main "$@"
