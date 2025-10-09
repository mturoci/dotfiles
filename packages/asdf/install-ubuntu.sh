#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_asdf_ubuntu() {
    info "Installing asdf for Ubuntu..."

    if ! command_exists asdf; then
        info "Installing asdf (precompiled binary)..."

        # Determine architecture
        ARCH=$(uname -m)
        case "${ARCH}" in
            x86_64)  ASDF_ARCH="amd64";;
            aarch64) ASDF_ARCH="arm64";;
            *)
                error "Unsupported architecture: ${ARCH}"
                error "Please install asdf manually from https://asdf-vm.com"
                exit 1
                ;;
        esac

        ASDF_VERSION="v0.14.1"
        ASDF_URL="https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/asdf_${ASDF_VERSION}_linux_${ASDF_ARCH}.tar.gz"

        info "Downloading asdf ${ASDF_VERSION} for ${ASDF_ARCH}..."
        info "URL: $ASDF_URL"

        if ! curl -fsSL "$ASDF_URL" -o /tmp/asdf.tar.gz; then
            error "Failed to download asdf from $ASDF_URL"
            error "Please check your internet connection or try again later"
            exit 1
        fi

        # Verify download
        if [ ! -f /tmp/asdf.tar.gz ] || [ ! -s /tmp/asdf.tar.gz ]; then
            error "Downloaded file is missing or empty"
            exit 1
        fi

        info "Download complete, extracting..."

        # Extract to ~/.local/bin
        mkdir -p "$HOME/.local/bin"

        if ! tar -xzf /tmp/asdf.tar.gz -C "$HOME/.local/bin" bin/asdf 2>/dev/null; then
            error "Failed to extract asdf binary"
            rm -f /tmp/asdf.tar.gz
            exit 1
        fi

        mv "$HOME/.local/bin/bin/asdf" "$HOME/.local/bin/asdf"
        rmdir "$HOME/.local/bin/bin" 2>/dev/null || true
        rm /tmp/asdf.tar.gz

        chmod +x "$HOME/.local/bin/asdf"

        # Verify installation
        if [ -x "$HOME/.local/bin/asdf" ]; then
            info "asdf installed successfully to ~/.local/bin/asdf"
        else
            error "asdf installation failed"
            exit 1
        fi
    else
        info "asdf already installed"
    fi
}

install_asdf_plugins() {
    info "Installing asdf plugins and language runtimes..."

    # Add ~/.local/bin to PATH if not already there (for current session)
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

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
        install_asdf_ubuntu
    fi
    install_asdf_plugins
}

main "$@"
