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

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_essentials_ubuntu
    fi
    setup_git_config
}

main "$@"
