#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_docker_arch() {
    info "Installing Docker for Arch Linux..."

    if command_exists docker; then
        info "Docker already installed"
        return
    fi

    info "Installing Docker packages via pacman..."
    sudo pacman -Sy --needed --noconfirm docker docker-buildx docker-compose

    info "Enabling Docker service..."
    sudo systemctl enable --now docker.service

    info "Docker installation complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_docker_arch
    fi
}

main "$@"
