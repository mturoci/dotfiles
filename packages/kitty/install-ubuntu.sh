#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_kitty_ubuntu() {
    info "Installing Kitty for Ubuntu..."

    # Kitty installation
    if ! command_exists kitty; then
        info "Installing Kitty terminal..."
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

        # Create symbolic links
        sudo ln -sf ~/.local/kitty.app/bin/kitty /usr/local/bin/
        sudo cp ~/.local/kitty.app/share/applications/kitty.desktop /usr/share/applications/
        sudo sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" /usr/share/applications/kitty.desktop
    else
        info "Kitty already installed"
    fi
}

setup_kitty_config() {
    info "Setting up Kitty configuration..."

    # Create kitty config directory if it doesn't exist
    mkdir -p "$HOME/.config/kitty"

    # Create symlinks for kitty configs
    create_symlink "$SCRIPT_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    create_symlink "$SCRIPT_DIR/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"

    info "Kitty configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_kitty_ubuntu
    fi
    setup_kitty_config
}

main "$@"
