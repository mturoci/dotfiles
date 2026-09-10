#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

SHARE_DIR="$HOME/.local/share/twingate-net"
APP="$HOME/Applications/Twingate Toggle.app"

install_twingate_macos() {
    info "Installing Twingate for macOS..."

    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    if [ -d "/Applications/Twingate.app" ]; then
        info "Twingate client already installed"
    else
        info "Installing Twingate client via Homebrew..."
        brew install --cask twingate
    fi
}

build_helpers() {
    info "Building twingate-net helpers..."

    if ! command_exists swiftc; then
        error "swiftc not found. Install Xcode command line tools: xcode-select --install"
        exit 1
    fi

    mkdir -p "$SHARE_DIR"
    osacompile -o "$SHARE_DIR/logic.scpt" "$SCRIPT_DIR/logic.applescript"
    swiftc -O "$SCRIPT_DIR/click.swift" -o "$SHARE_DIR/click"
}

build_shim_app() {
    # The applet only loads logic.scpt at runtime, so it never needs a rebuild.
    # Rebuilding it changes the ad-hoc signature TCC pinned, which silently
    # revokes the Accessibility grant and breaks every menu interaction.
    if [ -d "$APP" ]; then
        info "Shim app already present, leaving it untouched"
        return
    fi

    info "Building shim app..."
    mkdir -p "$HOME/Applications"
    osacompile -o "$APP" "$SCRIPT_DIR/shim.applescript"
    plutil -replace LSUIElement -bool true "$APP/Contents/Info.plist"
    plutil -replace CFBundleIdentifier -string com.mturoci.twingate-toggle "$APP/Contents/Info.plist"
    codesign --force --sign - "$APP"

    warn "Grant Accessibility to 'Twingate Toggle' in System Settings > Privacy & Security > Accessibility"
    warn "Then verify with: twingate-net status"
}

setup_twingate_config() {
    info "Setting up twingate-net..."

    mkdir -p "$HOME/.local/bin"
    create_symlink "$SCRIPT_DIR/twingate-net" "$HOME/.local/bin/twingate-net"

    info "twingate-net setup complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_twingate_macos
    fi
    build_helpers
    build_shim_app
    setup_twingate_config
}

main "$@"
