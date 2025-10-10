#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_nvim() {
    info "Installing neovim for Ubuntu..."

    if command_exists nvim; then
        info "neovim already installed"
        return
    fi

    # Install neovim from official release tarball
    NVIM_VERSION="0.9.4"
    NVIM_TARBALL="nvim-linux64.tar.gz"
    NVIM_URL="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/${NVIM_TARBALL}"
    INSTALL_DIR="$HOME/.local/share"

    info "Downloading neovim ${NVIM_VERSION}..."
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    if command_exists wget; then
        wget -q "$NVIM_URL"
    elif command_exists curl; then
        curl -L -o "$NVIM_TARBALL" "$NVIM_URL"
    else
        error "Neither wget nor curl found. Please install one of them first."
        exit 1
    fi

    info "Extracting neovim..."
    mkdir -p "$INSTALL_DIR"
    tar xzvf "$NVIM_TARBALL" -C "$INSTALL_DIR"

    cd -
    rm -rf "$TMP_DIR"

    info "neovim installation complete! Location: $INSTALL_DIR/nvim-linux64"
}

install_delta() {
    info "Installing delta for Ubuntu..."

    if command_exists delta; then
        info "delta already installed"
        return
    fi

    # Get latest release version
    DELTA_VERSION="0.16.5"
    DELTA_ARCH="x86_64-unknown-linux-gnu"
    DELTA_PACKAGE="git-delta_${DELTA_VERSION}_amd64.deb"
    DELTA_URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/${DELTA_PACKAGE}"

    info "Downloading delta ${DELTA_VERSION}..."
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    if command_exists wget; then
        wget -q "$DELTA_URL"
    elif command_exists curl; then
        curl -L -o "$DELTA_PACKAGE" "$DELTA_URL"
    else
        error "Neither wget nor curl found. Please install one of them first."
        exit 1
    fi

    info "Installing delta via dpkg..."
    sudo dpkg -i "$DELTA_PACKAGE"

    # Clean up
    cd -
    rm -rf "$TMP_DIR"

    info "delta installation complete!"
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
        install_nvim
        install_delta
    fi
    setup_nvim_config
}

main "$@"
