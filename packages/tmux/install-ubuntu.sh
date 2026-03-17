#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_tmux_ubuntu() {
    info "Installing tmux"

    TMUX_VERSION="3.5a"

    if command_exists tmux; then
        info "tmux already installed"
        return
    fi

    info "Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config automake

    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    info "Downloading tmux $TMUX_VERSION..."
    wget "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
    tar -xzf "tmux-${TMUX_VERSION}.tar.gz"
    cd "tmux-${TMUX_VERSION}"

    info "Building tmux from source..."
    ./configure
    make
    sudo make install

    cd "$HOME"
    rm -rf "$TEMP_DIR"

    info "tmux $TMUX_VERSION installed successfully"
}

install_tpm() {
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        info "Installing Tmux Plugin Manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        info "TPM already installed"
    fi
}

setup_tmux_config() {
    info "Setting up tmux configuration..."

    mkdir -p "$HOME/.tmux"

    create_symlink "$SCRIPT_DIR/.tmux.conf" "$HOME/.tmux.conf"
    create_symlink "$SCRIPT_DIR/start_tmux.sh" "$HOME/start_tmux.sh"

    create_symlink "$SCRIPT_DIR/right_status.sh" "$HOME/.tmux/right_status.sh"

    install_tpm

    info "Tmux configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_tmux_ubuntu
    fi
    setup_tmux_config
}

main "$@"
