#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_essentials_ubuntu() {
    info "Installing essential tools for Ubuntu..."

    # Check if gzip is installed
    if ! command_exists gzip; then
        info "Installing gzip via apt..."
        apt-get install -y gzip
    else
        info "gzip already installed"
    fi

    # Check if tar is installed
    if ! command_exists tar; then
        info "Installing tar via apt..."
        apt-get install -y tar
    else
        info "tar already installed"
    fi

    # Check if make is installed
    if ! command_exists make; then
        info "Installing make via apt..."
        apt-get install -y make
    else
        info "make already installed"
    fi

    info "Essential tools installed successfully!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_essentials_ubuntu
    fi
}

main "$@"
