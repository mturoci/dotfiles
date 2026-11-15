#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_brave_ubuntu() {
    if command_exists brave-browser; then
        info "Brave already installed"
        return
    fi

    info "Setting up Brave repository..."
    sudo apt-get update
    sudo apt-get install -y curl
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" |
        sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null

    info "Installing Brave..."
    sudo apt-get update
    sudo apt-get install -y brave-browser
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_brave_ubuntu
    fi
}

main "$@"
