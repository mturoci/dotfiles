#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_asdf_macos() {
    info "Installing asdf for macOS..."

    # Check if Homebrew is installed
    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    # Install asdf
    if ! command_exists asdf; then
        info "Installing asdf via Homebrew..."
        brew install asdf
    else
        info "asdf already installed"
    fi
}

install_asdf_plugins() {
    info "Installing asdf plugins and language runtimes..."

    # Ensure asdf is available in current shell
    if command_exists asdf; then
        # Install Node.js plugin
        if ! asdf plugin list | grep -q nodejs; then
            info "Adding Node.js plugin..."
            asdf plugin add nodejs
        fi

        # Install Python plugin
        if ! asdf plugin list | grep -q python; then
            info "Adding Python plugin..."
            asdf plugin add python
        fi

        # Install Golang plugin
        if ! asdf plugin list | grep -q golang; then
            info "Adding Golang plugin..."
            asdf plugin add golang
        fi

        info "asdf plugins installed successfully!"
        info "To install a language runtime, run:"
        info "  asdf install nodejs latest"
        info "  asdf global nodejs latest"
    else
        warn "asdf not found in PATH. Please restart your shell and run this script again."
    fi
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_asdf_macos
    fi
    install_asdf_plugins
}

main "$@"
