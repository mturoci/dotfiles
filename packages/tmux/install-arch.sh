#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_tmux_arch() {
    info "Installing tmux"

    if command_exists tmux; then
        info "tmux already installed"
        return
    fi

    info "Installing tmux via pacman..."
    sudo pacman -Sy --needed --noconfirm tmux

    info "tmux installed successfully"
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
        install_tmux_arch
    fi
    setup_tmux_config
}

main "$@"
