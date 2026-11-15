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
    # for asdf, fonts, and general utilities.
    local packages=(
        git
        curl
        less
        which
        man-db
        gzip
        tar
        unzip
        openssh
        github-cli
        clang
        zlib
        bzip2
        readline
        sqlite
        tk
        xz
        ttf-jetbrains-mono-nerd
    )

    for pkg in "${packages[@]}"; do
        if ! pkg_installed "$pkg"; then
            info "Installing $pkg via pacman..."
            sudo pacman -S --needed --noconfirm "$pkg"
        else
            info "$pkg already installed"
        fi
    done

    install_yay

    info "Essential tools installed successfully!"
}

install_yay() {
    if ! command_exists yay; then
        info "Installing yay (AUR helper)..."
        local temp_dir
        temp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$temp_dir"
        (cd "$temp_dir" && makepkg -si --noconfirm)
        rm -rf "$temp_dir"
        info "yay installed successfully!"
    else
        info "yay already installed"
    fi
}
setup_config_symlinks() {
    info "Setting up config file symlinks..."

    local configs_dir="$SCRIPT_DIR/configs"

    if [ ! -d "$configs_dir" ]; then
        warn "Configs directory not found: $configs_dir"
        return
    fi

    shopt -s dotglob nullglob
    for config_file in "$configs_dir"/*; do
        if [ -f "$config_file" ]; then
            local filename=$(basename "$config_file")
            create_symlink "$config_file" "$HOME/$filename"
        fi
    done
    shopt -u dotglob nullglob

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
