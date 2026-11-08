#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

create_symlink() {
    local source=$1
    local target=$2

    if [ ! -e "$source" ]; then
        error "Source file does not exist: $source"
        return 1
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        rm -rf "$target"
    fi

    info "Creating symlink: $target -> $source"
    ln -sf "$source" "$target"
}

detect_os() {
    OS="$(uname -s)"
    case "${OS}" in
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
                    echo "ubuntu"
                elif [ "$ID" = "arch" ] || [ "$ID_LIKE" = "arch" ]; then
                    echo "arch"
                else
                    echo "unknown-linux"
                fi
            else
                echo "unknown-linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

setup_git_config() {
    info "Setting up git configuration..."

    if ! git config --global user.name &>/dev/null; then
        git config --global user.name "Martin Turoci"
    else
        info "git user.name already configured: $(git config --global user.name)"
    fi

    if ! git config --global user.email &>/dev/null; then
        local email
        read -rp "Git user.email: " email </dev/tty
        [ -n "$email" ] && git config --global user.email "$email" || warn "Skipped git user.email"
    else
        info "git user.email already configured: $(git config --global user.email)"
    fi

    info "Git configuration complete!"
}
