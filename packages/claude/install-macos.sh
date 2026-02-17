#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

setup_configs() {
    info "Setting up Claude configuration..."

    mkdir -p "$HOME/.claude"

    create_symlink "$SCRIPT_DIR/settings.json" "$HOME/.claude/settings.json"
    create_symlink "$SCRIPT_DIR/statusline.sh" "$HOME/.claude/statusline.sh"

    info "Claude configuration complete!"
}

main() {
    setup_configs
}

main "$@"
