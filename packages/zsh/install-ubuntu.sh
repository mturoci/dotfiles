#!/usr/bin/env bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/lib/utils.sh"

install_zsh_ubuntu() {
    info "Installing zsh dependencies for Ubuntu..."

    # Install zsh and other dependencies
    if ! command_exists zsh; then
        info "Installing zsh via apt..."
        sudo apt-get update
        sudo apt-get install -y zsh git curl
    else
        info "zsh already installed"
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
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        info "Installing powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    fi
}

setup_zsh_config() {
    info "Setting up zsh configuration..."

    # Create symlink for .zshrc
    create_symlink "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

    # Set zsh as default shell if not already
    local zsh_path="$(which zsh)"

    # Check if $SHELL ends with zsh
    if [[ ! "$SHELL" =~ zsh$ ]]; then
        info "Setting zsh as default shell..."
        info "Current shell: $SHELL"
        info "Target shell: $zsh_path"

        # Ensure zsh is in /etc/shells
        if ! grep -q "^${zsh_path}$" /etc/shells; then
            info "Adding $zsh_path to /etc/shells..."
            echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
        fi

        # Try chsh first, then fall back to usermod
        if chsh -s "$zsh_path" 2>/dev/null; then
            info "Shell changed using chsh"
        elif sudo chsh -s "$zsh_path" "$USER" 2>/dev/null; then
            info "Shell changed using sudo chsh"
        elif sudo usermod -s "$zsh_path" "$USER" 2>/dev/null; then
            info "Shell changed using usermod"
        else
            error "Failed to change default shell automatically"
            error "Please manually run: sudo chsh -s $zsh_path $USER"
            return 1
        fi

        # Verify the change
        local new_shell="$(getent passwd "$USER" | cut -d: -f7)"
        if [ "$new_shell" = "$zsh_path" ]; then
            info "✓ Default shell successfully changed to zsh!"
            info "Please log out and log back in for the change to take effect."
        else
            error "Shell change verification failed. Current shell is still: $new_shell"
            error "Please manually run: sudo chsh -s $zsh_path $USER"
        fi
    else
        info "zsh is already the default shell"
    fi

    info "Zsh configuration complete!"
}

main() {
    if [ "$SKIP_PACKAGES" != "true" ]; then
        install_zsh_ubuntu
    fi
    setup_zsh_config
}

main "$@"
