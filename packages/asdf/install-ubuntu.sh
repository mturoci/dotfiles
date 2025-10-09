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

        ASDF_VERSION="v0.18.0"
        ASDF_URL="https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/asdf-${ASDF_VERSION}-linux-${ASDF_ARCH}.tar.gz"

        info "Downloading asdf ${ASDF_VERSION} for ${ASDF_ARCH}..."
        info "URL: $ASDF_URL"

        rm -rf /tmp/asdf.tar.gz
        if ! curl -fsSL "$ASDF_URL" -o /tmp/asdf.tar.gz; then
            error "Failed to download asdf from $ASDF_URL"
            error "Please check your internet connection or try again later"
            exit 1
        fi

        info "Download complete, extracting..."

        mkdir -p "$HOME/.local/bin"

        # Extract to temporary directory first to see the structure
        TEMP_EXTRACT_DIR=$(mktemp -d)
        if ! tar -xzf /tmp/asdf.tar.gz -C "$TEMP_EXTRACT_DIR" 2>/dev/null; then
            error "Failed to extract asdf archive"
            rm -f /tmp/asdf.tar.gz
            rm -rf "$TEMP_EXTRACT_DIR"
            exit 1
        fi

        # Find the asdf binary in the extracted files
        ASDF_BINARY=$(find "$TEMP_EXTRACT_DIR" -name "asdf" -type f | head -n 1)

        if [ -z "$ASDF_BINARY" ]; then
            error "Could not find asdf binary in extracted archive"
            rm -f /tmp/asdf.tar.gz
            rm -rf "$TEMP_EXTRACT_DIR"
            exit 1
        fi

        # Move the binary to the final location
        mv "$ASDF_BINARY" "$HOME/.local/bin/asdf"

        # Cleanup
        rm -f /tmp/asdf.tar.gz
        rm -rf "$TEMP_EXTRACT_DIR"

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
