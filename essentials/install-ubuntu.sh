#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_essentials_ubuntu() {
    info "Installing essential tools for Ubuntu..."

    # Install build-essential package (includes gcc, g++, make, and other build tools)
    if ! dpkg -l | grep -q "^ii  build-essential"; then
        info "Installing build-essential via apt..."
        sudo apt-get update
        sudo apt-get install -y build-essential
    else
        info "build-essential already installed"
    fi

    # Check if gzip is installed
    if ! command_exists gzip; then
        info "Installing gzip via apt..."
        sudo apt-get install -y gzip
    else
        info "gzip already installed"
    fi

    # Check if tar is installed
    if ! command_exists tar; then
        info "Installing tar via apt..."
        sudo apt-get install -y tar
    else
        info "tar already installed"
    fi

    info "Essential tools installed successfully!"
}

setup_git_config() {
    info "Setting up git configuration..."

    # Set git user name
    if ! git config --global user.name &>/dev/null; then
        info "Setting git user.name to: Martin Turoci"
        git config --global user.name "Martin Turoci"
    else
        info "git user.name already configured: $(git config --global user.name)"
    fi

    # Set git user email
    if ! git config --global user.email &>/dev/null; then
        info "Setting git user.email to: you@example.com"
        git config --global user.email "you@example.com"
    else
        info "git user.email already configured: $(git config --global user.email)"
    fi

    info "Git configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_essentials_ubuntu
    fi
    setup_git_config
}

main "$@"
