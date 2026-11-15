#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

setup_configs() {
    info "Setting up misc config files..."

    create_symlink "$SCRIPT_DIR/.markdownlint.json" "$HOME/.markdownlint.json"

    info "Misc config setup complete!"
}

setup_sudoers() {
    info "Setting up sudoers for passwordless poweroff and reboot..."
    
    if [ -f "$SCRIPT_DIR/sudoers-poweroff-reboot" ]; then
        sudo install -m 440 "$SCRIPT_DIR/sudoers-poweroff-reboot" /etc/sudoers.d/poweroff-reboot
        info "Sudoers configuration installed successfully!"
    fi
}

main() {
    setup_configs
    setup_sudoers
}

main "$@"
