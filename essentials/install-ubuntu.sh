#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

install_essentials_ubuntu() {
    info "Installing essential tools for Ubuntu..."

    if ! dpkg -l | grep -q "^ii  build-essential"; then
        info "Installing build-essential via apt..."
        sudo apt-get update
        sudo apt-get install -y build-essential
    else
        info "build-essential already installed"
    fi

    if ! command_exists gzip; then
        info "Installing gzip via apt..."
        sudo apt-get install -y gzip
    else
        info "gzip already installed"
    fi

    if ! command_exists tar; then
        info "Installing tar via apt..."
        sudo apt-get install -y tar
    else
        info "tar already installed"
    fi

    if ! command_exists unzip; then
        info "Installing unzip via apt..."
        sudo apt-get install -y unzip
    else
        info "unzip already installed"
    fi

    if ! command_exists gh; then
        info "Installing GitHub CLI..."

        if ! command_exists wget; then
            sudo apt-get update
            sudo apt-get install -y wget
        fi

        sudo mkdir -p -m 755 /etc/apt/keyrings

        out=$(mktemp)
        wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg
        cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        rm "$out"

        sudo mkdir -p -m 755 /etc/apt/sources.list.d
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

        sudo apt-get update
        sudo apt-get install -y gh
    else
        info "GitHub CLI already installed"
    fi

    if ! command_exists clang; then
        info "Installing clang via apt..."
        sudo apt-get install -y clang
    else
        info "clang already installed"
    fi

    if ! dpkg -l | grep -q "^ii  zlib1g-dev"; then
        info "Installing zlib via apt..."
        sudo apt-get install -y zlib1g-dev
    else
        info "zlib already installed"
    fi

    if ! dpkg -l | grep -q "^ii  libbz2-dev"; then
        info "Installing bzip2 via apt..."
        sudo apt-get install -y libbz2-dev
    else
        info "bzip2 already installed"
    fi

    if ! dpkg -l | grep -q "^ii  libreadline-dev"; then
        info "Installing readline via apt..."
        sudo apt-get install -y libreadline-dev
    else
        info "readline already installed"
    fi

    if ! dpkg -l | grep -q "^ii  libsqlite3-dev"; then
        info "Installing sqlite3 via apt..."
        sudo apt-get install -y libsqlite3-dev
    else
        info "sqlite3 already installed"
    fi

    if ! dpkg -l | grep -q "^ii  tk-dev"; then
        info "Installing tk via apt..."
        sudo apt-get install -y tk-dev
    else
        info "tk already installed"
    fi

    if ! dpkg -l | grep -q "^ii  liblzma-dev"; then
        info "Installing lzma via apt..."
        sudo apt-get install -y liblzma-dev
    else
        info "lzma already installed"
    fi

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
        install_essentials_ubuntu
    fi
    setup_git_config
    setup_config_symlinks
}

main "$@"
