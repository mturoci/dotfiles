#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

OS=$(detect_os)

PACKAGES_DIR="$DOTFILES_DIR/packages"

get_available_packages() {
    local packages=()
    if [ -d "$PACKAGES_DIR" ]; then
        for dir in "$PACKAGES_DIR"/*; do
            if [ -d "$dir" ]; then
                packages+=("$(basename "$dir")")
            fi
        done
    fi
    echo "${packages[@]}"
}

AVAILABLE_PACKAGES=($(get_available_packages))
COMPONENTS=("${AVAILABLE_PACKAGES[@]}")

SKIP_PACKAGES=false
ONLY_COMPONENTS=()

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --skip-packages         Skip package installation, only setup configs
    --only PACKAGE[,...]    Only install specified packages (e.g., --only kitty,tmux)
    --help                  Show this help message

Available packages: ${AVAILABLE_PACKAGES[*]}

Examples:
    $0                          # Install everything
    $0 --only kitty,tmux        # Install only kitty and tmux
    $0 --skip-packages          # Only setup configs, skip package installation

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --only)
                if [ -z "$2" ]; then
                    error "Error: --only requires a comma-separated list of packages"
                    usage
                    exit 1
                fi
                IFS=',' read -ra ONLY_COMPONENTS <<< "$2"
                shift 2
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # If --only was specified, use only those components
    if [ ${#ONLY_COMPONENTS[@]} -gt 0 ]; then
        COMPONENTS=("${ONLY_COMPONENTS[@]}")
    fi
}

install_homebrew() {
    if [ "$OS" = "macos" ]; then
        if ! command_exists brew; then
            warn "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            info "Homebrew already installed"
        fi
    fi
}

install_essentials() {
    local install_script="$DOTFILES_DIR/essentials/install-${OS}.sh"

    if [ ! -f "$install_script" ]; then
        warn "No essentials installer found for $OS (expected: $install_script)"
        return
    fi

    info "Installing essential tools..."
    export SKIP_PACKAGES
    bash "$install_script"
}

run_package_installer() {
    local package=$1
    local install_script="$PACKAGES_DIR/$package/install-${OS}.sh"

    if [ ! -f "$install_script" ]; then
        warn "No installer found for $package on $OS (expected: $install_script)"
        return
    fi

    info "Installing $package..."
    export SKIP_PACKAGES
    bash "$install_script"
}

main() {
    parse_args "$@"

    info "Starting dotfiles installation..."
    info "Detected OS: $OS"
    info "Dotfiles directory: $DOTFILES_DIR"
    info "Packages directory: $PACKAGES_DIR"
    info "Packages to install: ${COMPONENTS[*]}"

    if [ "$OS" = "unknown" ] || [ "$OS" = "unknown-linux" ]; then
        error "Unsupported operating system. Only macOS, Ubuntu and Arch Linux are supported."
        exit 1
    fi

    if [ ${#COMPONENTS[@]} -eq 0 ]; then
        warn "No packages found in $PACKAGES_DIR"
        exit 0
    fi

    if [ "$SKIP_PACKAGES" = false ] && [ "$OS" = "macos" ]; then
        install_homebrew
    fi

    # Install essential tools first (gzip, tar, etc.)
    if [ "$SKIP_PACKAGES" = false ]; then
        install_essentials
    fi

    for package in "${COMPONENTS[@]}"; do
        run_package_installer "$package"
    done

    info ""
    info "✓ Dotfiles installation complete!"
    info ""
    info "Next steps:"
    info "  1. Restart your terminal or run: source ~/.zshrc"
    info "  2. Open tmux and press prefix + I (Ctrl+p then I) to install tmux plugins"
    info "  3. Configure Powerlevel10k by running: p10k configure"
    info "  4. Install JetBrainsMono Nerd Font for proper icon rendering"
    info "  5. Install language runtimes with asdf (e.g., asdf plugin add nodejs)"
    info ""
}

# Run main function
main "$@"
