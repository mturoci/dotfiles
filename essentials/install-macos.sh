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

    # Check if Xcode Command Line Tools are installed
    if ! xcode-select -p &>/dev/null; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install
        info "Please complete the Xcode Command Line Tools installation and re-run this script"
        exit 0
    else
        info "Xcode Command Line Tools already installed"
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

    # Install GitHub CLI
    if ! command_exists gh; then
        info "Installing GitHub CLI via Homebrew..."
        brew install gh
    else
        info "GitHub CLI already installed"
    fi

    # Install LLVM (includes clang)
    if ! brew list llvm &>/dev/null; then
        info "Installing LLVM (includes clang) via Homebrew..."
        brew install llvm
    else
        info "LLVM already installed"
    fi

    info "Essential tools installed successfully!"
    info "Note: GNU tar is available as 'gtar' command"
    info "Note: GNU gzip is available in PATH with priority over system version"
    info "Note: Xcode Command Line Tools include Apple clang"
    info "Note: LLVM clang is available at /opt/homebrew/opt/llvm/bin/clang"
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
        install_essentials_macos
    fi
    setup_git_config
}

main "$@"
