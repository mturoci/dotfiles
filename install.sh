#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

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

# Install packages based on OS
install_packages() {
    info "Installing packages for ${MACHINE}..."

    if [ "$MACHINE" = "Mac" ]; then
        # Check if Homebrew is installed
        if ! command_exists brew; then
            warn "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        # Install packages
        info "Installing packages via Homebrew..."
        brew install tmux kitty

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

        # Install asdf
        if ! command_exists asdf; then
            info "Installing asdf..."
            brew install asdf
        fi

    elif [ "$MACHINE" = "Linux" ]; then
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        else
            error "Cannot detect Linux distribution"
            exit 1
        fi

        if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
            info "Installing packages via apt..."
            sudo apt-get update
            sudo apt-get install -y tmux zsh git curl

            # Kitty installation
            if ! command_exists kitty; then
                info "Installing Kitty terminal..."
                curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

                # Create symbolic links
                sudo ln -sf ~/.local/kitty.app/bin/kitty /usr/local/bin/
                sudo cp ~/.local/kitty.app/share/applications/kitty.desktop /usr/share/applications/
                sudo sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" /usr/share/applications/kitty.desktop
            fi
        else
            warn "Unsupported Linux distribution: $DISTRO"
            warn "Please install tmux, kitty, and zsh manually"
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

        # Install asdf
        if ! command_exists asdf; then
            info "Installing asdf (precompiled binary)..."

            # Determine architecture
            ARCH=$(uname -m)
            case "${ARCH}" in
                x86_64)  ASDF_ARCH="amd64";;
                aarch64) ASDF_ARCH="arm64";;
                *)
                    warn "Unsupported architecture: ${ARCH}"
                    warn "Please install asdf manually from https://asdf-vm.com"
                    ;;
            esac

            if [ -n "$ASDF_ARCH" ]; then
                ASDF_VERSION="v0.14.1"
                ASDF_URL="https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/asdf_${ASDF_VERSION}_linux_${ASDF_ARCH}.tar.gz"

                info "Downloading asdf ${ASDF_VERSION} for ${ASDF_ARCH}..."
                curl -sL "$ASDF_URL" -o /tmp/asdf.tar.gz

                # Extract to ~/.local/bin
                mkdir -p "$HOME/.local/bin"
                tar -xzf /tmp/asdf.tar.gz -C "$HOME/.local/bin" bin/asdf
                mv "$HOME/.local/bin/bin/asdf" "$HOME/.local/bin/asdf"
                rmdir "$HOME/.local/bin/bin"
                rm /tmp/asdf.tar.gz

                chmod +x "$HOME/.local/bin/asdf"

                # Verify installation
                if [ -x "$HOME/.local/bin/asdf" ]; then
                    info "asdf installed successfully to ~/.local/bin/asdf"
                else
                    error "asdf installation failed"
                fi
            fi
        fi
    else
        error "Unsupported operating system: ${MACHINE}"
        exit 1
    fi
}

# Install tmux plugin manager
install_tpm() {
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        info "Installing Tmux Plugin Manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        info "TPM already installed"
    fi
}

# Setup tmux configuration
setup_tmux() {
    info "Setting up tmux configuration..."

    # Create tmux directory if it doesn't exist
    mkdir -p "$HOME/.tmux"

    # Create symlink for .tmux.conf
    create_symlink "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

    # Copy right_status.sh script
    cp "$DOTFILES_DIR/tmux/right_status.sh" "$HOME/.tmux/right_status.sh"
    chmod +x "$HOME/.tmux/right_status.sh"

    install_tpm

    info "Tmux configuration complete!"
}

# Setup kitty configuration
setup_kitty() {
    info "Setting up kitty configuration..."

    # Create kitty config directory if it doesn't exist
    mkdir -p "$HOME/.config/kitty"

    # Create symlinks for kitty configs
    create_symlink "$DOTFILES_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    create_symlink "$DOTFILES_DIR/kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"

    info "Kitty configuration complete!"
}

# Setup zsh configuration
setup_zsh() {
    info "Setting up zsh configuration..."

    # Create symlink for .zshrc
    create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

    # Set zsh as default shell if not already
    if [ "$SHELL" != "$(which zsh)" ]; then
        info "Setting zsh as default shell..."
        chsh -s "$(which zsh)"
    fi

    info "Zsh configuration complete!"
}

# Main installation function
main() {
    info "Starting dotfiles installation for ${MACHINE}..."
    info "Dotfiles directory: ${DOTFILES_DIR}"

    # Parse command line arguments
    SKIP_PACKAGES=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                echo "Usage: $0 [--skip-packages]"
                exit 1
                ;;
        esac
    done

    # Install packages if not skipped
    if [ "$SKIP_PACKAGES" = false ]; then
        install_packages
    else
        warn "Skipping package installation"
    fi

    # Setup configurations
    setup_tmux
    setup_kitty
    setup_zsh

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
