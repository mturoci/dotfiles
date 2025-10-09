#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_zsh_macos() {
    info "Installing zsh dependencies for macOS..."

    # Check if Homebrew is installed
    if ! command_exists brew; then
        error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    # Install oh-my-zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Install zsh plugins
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi

    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    # Install powerlevel10k
    if ! brew list powerlevel10k &>/dev/null; then
        info "Installing powerlevel10k..."
        brew install powerlevel10k
    fi
}

setup_zsh_config() {
    info "Setting up zsh configuration..."

    # Create symlink for .zshrc
    create_symlink "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

    # Set zsh as default shell if not already
    if [ "$SHELL" != "$(which zsh)" ]; then
        info "Setting zsh as default shell..."
        chsh -s "$(which zsh)"
    fi

    info "Zsh configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_zsh_macos
    fi
    setup_zsh_config
}

main "$@"
