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

main() {
    setup_configs
}

main "$@"
