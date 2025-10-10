#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_essentials_macos() {
    info "Installing essential tools for macOS..."

    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    if ! xcode-select -p &>/dev/null; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install
        info "Please complete the Xcode Command Line Tools installation and re-run this script"
        exit 0
    else
        info "Xcode Command Line Tools already installed"
    fi

    if ! brew list gzip &>/dev/null; then
        info "Installing gzip via Homebrew..."
        brew install gzip
    else
        info "gzip already installed"
    fi

    if ! brew list gnu-tar &>/dev/null; then
        info "Installing gnu-tar via Homebrew..."
        brew install gnu-tar
    else
        info "gnu-tar already installed"
    fi

    if ! brew list make &>/dev/null; then
        info "Installing make via Homebrew..."
        brew install make
    else
        info "make already installed"
    fi

    if ! command_exists gh; then
        info "Installing GitHub CLI via Homebrew..."
        brew install gh
    else
        info "GitHub CLI already installed"
    fi

    if ! brew list llvm &>/dev/null; then
        info "Installing LLVM via Homebrew..."
        brew install llvm
    else
        info "LLVM already installed"
    fi

    if ! brew list zlib &>/dev/null; then
        info "Installing zlib via Homebrew..."
        brew install zlib
    else
        info "zlib already installed"
    fi

    info "Essential tools installed successfully!"
}

setup_git_config() {
    info "Setting up git configuration..."

    if ! git config --global user.name &>/dev/null; then
        git config --global user.name "Martin Turoci"
    else
        info "git user.name already configured: $(git config --global user.name)"
    fi

    if ! git config --global user.email &>/dev/null; then
        git config --global user.email "you@example.com"
    else
        info "git user.email already configured: $(git config --global user.email)"
    fi

    info "Git configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_essentials_macos
    fi
    setup_git_config
}

main "$@"
