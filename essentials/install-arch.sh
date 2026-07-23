#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

pkg_installed() {
    pacman -Qi "$1" >/dev/null 2>&1
}

install_essentials_arch() {
    info "Installing essential tools for Arch Linux..."

    if ! pkg_installed base-devel; then
        info "Installing base-devel via pacman..."
        sudo pacman -Sy --needed --noconfirm base-devel
    else
        info "base-devel already installed"
    fi

    # base-devel already covers most build tooling; the rest are Python build deps
    # for asdf and general utilities.
    local packages=(gzip tar unzip github-cli clang zlib bzip2 readline sqlite tk xz)

    for pkg in "${packages[@]}"; do
        if ! pkg_installed "$pkg"; then
            info "Installing $pkg via pacman..."
            sudo pacman -S --needed --noconfirm "$pkg"
        else
            info "$pkg already installed"
        fi
    done

    info "Essential tools installed successfully!"
}

setup_git_config() {
    info "Setting up git configuration..."

    if ! git config --global user.name &>/dev/null; then
        git config --global user.name "Martin Turoci"
    else
        info "git user.name already configured: $(git config --global user.name)"
    fi

    if ! git config --global user.email &>/dev/null; then
        git config --global user.email "you@example.com"
    else
        info "git user.email already configured: $(git config --global user.email)"
    fi

    info "Git configuration complete!"
}

setup_config_symlinks() {
    info "Setting up config file symlinks..."

    local configs_dir="$SCRIPT_DIR/configs"

    if [ ! -d "$configs_dir" ]; then
        warn "Configs directory not found: $configs_dir"
        return
    fi

    for config_file in "$configs_dir"/*; do
        if [ -f "$config_file" ]; then
            local filename=$(basename "$config_file")
            create_symlink "$config_file" "$HOME/$filename"
        fi
    done

    info "Config symlinks setup complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_essentials_arch
    fi
    setup_git_config
    setup_config_symlinks
}

main "$@"
