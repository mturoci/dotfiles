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

        # Install Lua plugin
        if ! asdf plugin list | grep -q lua; then
            info "Adding Lua plugin..."
            asdf plugin add lua https://github.com/Stratus3D/asdf-lua.git
        fi

        info "asdf plugins installed successfully!"
    else
        warn "asdf not found in PATH. Please restart your shell and run this script again."
        return
    fi
}

install_runtimes() {
    info "Checking and installing language runtimes..."

    # Source asdf to make shims available
    if [ -f "$(brew --prefix asdf)/libexec/asdf.sh" ]; then
        source "$(brew --prefix asdf)/libexec/asdf.sh"
    fi

    # Check and install Node.js
    if ! command_exists node; then
        info "Node.js not found in PATH. Installing latest version via asdf..."
        asdf install nodejs latest
        NODEJS_VERSION=$(asdf list nodejs | tail -n 1 | xargs)
        asdf set --home nodejs "$NODEJS_VERSION"
        info "Node.js $NODEJS_VERSION installed and set as global"
    else
        info "Node.js already available in PATH"
    fi

    # Check and install Python
    if ! command_exists python && ! command_exists python3; then
        info "Python not found in PATH. Installing latest version via asdf..."
        asdf install python latest
        PYTHON_VERSION=$(asdf list python | tail -n 1 | xargs)
        asdf set --home python "$PYTHON_VERSION"
        info "Python $PYTHON_VERSION installed and set as global"
    else
        info "Python already available in PATH"
    fi

    # Check and install Go
    if ! command_exists go; then
        info "Go not found in PATH. Installing latest version via asdf..."
        asdf install golang latest
        GOLANG_VERSION=$(asdf list golang | tail -n 1 | xargs)
        asdf set --home golang "$GOLANG_VERSION"
        info "Go $GOLANG_VERSION installed and set as global"
    else
        info "Go already available in PATH"
    fi

    # Check and install Lua 5.1.5
    if ! command_exists lua || ! lua -v 2>&1 | grep -q "5.1.5"; then
        info "Lua 5.1.5 not found. Installing via asdf..."
        asdf install lua 5.1.5
        asdf set --home lua 5.1.5
        info "Lua 5.1.5 installed and set as global"
    else
        info "Lua 5.1.5 already available"
    fi

    info "Runtime installation complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_asdf_macos
    fi
    install_asdf_plugins
    install_runtimes
}

main "$@"
