#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_tmux_ubuntu() {
    info "Installing tmux for Ubuntu..."

    if ! command_exists tmux; then
        info "Installing tmux via apt..."
        sudo apt-get update
        sudo apt-get install -y tmux
    else
        info "tmux already installed"
    fi
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

    # Create tmux directory if it doesn't exist
    mkdir -p "$HOME/.tmux"

    # Create symlink for .tmux.conf
    create_symlink "$SCRIPT_DIR/.tmux.conf" "$HOME/.tmux.conf"

    # Copy right_status.sh script
    cp "$SCRIPT_DIR/right_status.sh" "$HOME/.tmux/right_status.sh"
    chmod +x "$HOME/.tmux/right_status.sh"

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
