#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_tmux_macos() {
    info "Installing tmux"

    if command_exists tmux; then
        info "tmux already installed"
        return
    fi

    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    info "Installing dependencies..."
    brew install tmux@3.5a

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

    cp "$SCRIPT_DIR/right_status.sh" "$HOME/.tmux/right_status.sh"
    chmod +x "$HOME/.tmux/right_status.sh"

    install_tpm

    info "Tmux configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_tmux_macos
    fi
    setup_tmux_config
}

main "$@"
