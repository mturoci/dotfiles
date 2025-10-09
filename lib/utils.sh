#!/usr/bin/env bash

# Shared utility functions for dotfiles installation

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Backup existing file
backup_file() {
    local file=$1
    if [ -f "$file" ] || [ -L "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backing up $file to $backup"
        mv "$file" "$backup"
    fi
}

# Create symlink
create_symlink() {
    local source=$1
    local target=$2

    backup_file "$target"

    info "Creating symlink: $target -> $source"
    ln -sf "$source" "$target"
}

# Detect operating system
detect_os() {
    OS="$(uname -s)"
    case "${OS}" in
        Linux*)
            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
                    echo "ubuntu"
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
