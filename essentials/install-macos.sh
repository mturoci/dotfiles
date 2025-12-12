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

    if ! brew list unzip &>/dev/null; then
        info "Installing unzip via Homebrew..."
        brew install unzip
    else
        info "unzip already installed"
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

    if ! brew list bzip2 &>/dev/null; then
        info "Installing bzip2 via Homebrew..."
        brew install bzip2
    else
        info "bzip2 already installed"
    fi

    if ! brew list readline &>/dev/null; then
        info "Installing readline via Homebrew..."
        brew install readline
    else
        info "readline already installed"
    fi

    if ! brew list sqlite &>/dev/null; then
        info "Installing sqlite via Homebrew..."
        brew install sqlite
    else
        info "sqlite already installed"
    fi

    if ! brew list tcl-tk &>/dev/null; then
        info "Installing tcl-tk via Homebrew..."
        brew install tcl-tk
    else
        info "tcl-tk already installed"
    fi

    if ! brew list xz &>/dev/null; then
        info "Installing xz via Homebrew..."
        brew install xz
    else
        info "xz already installed"
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

setup_config_symlinks() {
    info "Setting up config file symlinks..."

    local configs_dir="$SCRIPT_DIR/configs"

    if [ ! -d "$configs_dir" ]; then
        warn "Configs directory not found: $configs_dir"
        return
    fi

    for config_file in "$configs_dir"/*; do
        if [ -f "$config_file" ]; then
            local filename=$(basename "$config_file")
            create_symlink "$config_file" "$HOME/$filename"
        fi
    done

    info "Config symlinks setup complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_essentials_macos
    fi
    setup_git_config
    setup_config_symlinks
}

main "$@"
