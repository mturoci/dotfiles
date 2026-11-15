#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTFILES_DIR/lib/utils.sh"

SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
SSH_KEY_COMMENT="${1}"

if [ -z "$SSH_KEY_COMMENT" ] || [ "$SSH_KEY_COMMENT" = "help" ] || [ "$SSH_KEY_COMMENT" = "-h" ] || [ "$SSH_KEY_COMMENT" = "--help" ]; then
    cat << EOF
Usage: setup-ssh-github.sh COMMENT

Generate a new SSH key and upload it to GitHub.

Arguments:
    COMMENT        Identification comment for the key (e.g., "home", "work-laptop")

Examples:
    setup-ssh-github.sh home
    setup-ssh-github.sh work-laptop

Requirements:
    - GitHub CLI (gh) installed and authenticated: gh auth login

EOF
    exit 0
fi

check_dependencies() {
    if ! command_exists gh; then
        error "GitHub CLI (gh) not found. Install with: brew install gh"
        exit 1
    fi

    if ! gh auth status >/dev/null 2>&1; then
        error "GitHub CLI is not authenticated. Run: gh auth login"
        exit 1
    fi

    info "Dependencies check passed ✓"
}

request_admin_scope() {
    info "Requesting admin:public_key and admin:ssh_signing_key scopes..."
    if ! gh auth refresh -s admin:public_key -s admin:ssh_signing_key --web 2>&1 | grep -q "Credential saved"; then
        warn "Could not automatically refresh scopes, attempting with --hostname"
        gh auth refresh -h github.com -s admin:public_key -s admin:ssh_signing_key || {
            error "Failed to request admin scopes"
            exit 1
        }
    fi
    info "Scopes granted ✓"
}

generate_ssh_key() {
    if [ -f "$SSH_KEY_PATH" ]; then
        warn "SSH key already exists at: $SSH_KEY_PATH"
        read -rp "Overwrite? (y/N): " -n 1 overwrite
        echo ""
        if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
            info "Keeping existing key"
            return
        fi
        rm -f "$SSH_KEY_PATH" "${SSH_KEY_PATH}.pub"
    fi

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    info "Generating SSH key: $SSH_KEY_PATH"
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -C "$SSH_KEY_COMMENT" -N "" || {
        error "Failed to generate SSH key"
        exit 1
    }

    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "${SSH_KEY_PATH}.pub"
    info "SSH key generated ✓"
}

add_key_to_github() {
    info "Uploading to GitHub as authentication key..."
    if ! gh ssh-key add "${SSH_KEY_PATH}.pub" --title "$SSH_KEY_COMMENT" --type authentication 2>&1; then
        error "Failed to upload SSH key to GitHub"
        exit 1
    fi
    info "Authentication key uploaded ✓"

    info "Adding same key for signing..."
    if ! gh ssh-key add "${SSH_KEY_PATH}.pub" --title "$SSH_KEY_COMMENT (signing)" --type signing 2>&1; then
        warn "Failed to add signing key, but authentication key was uploaded"
    else
        info "Signing key added ✓"
    fi
}

revoke_admin_scope() {
    info "Revoking admin scopes..."
    info "Logging out and re-authenticating without admin scopes..."
    
    gh auth logout --hostname github.com || true
    
    info "Authenticating with GitHub CLI..."
    gh auth login
    
    info "Admin scopes revoked ✓"
}

test_github_connection() {
    info "Testing SSH connection..."
    mkdir -p "$HOME/.ssh"
    if ! grep -q "github.com" "$HOME/.ssh/known_hosts" 2>/dev/null; then
        ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
    fi

    if ssh -i "$SSH_KEY_PATH" -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        info "Connection successful ✓"
    else
        warn "Could not verify SSH connection (might be normal, try again in a moment)"
    fi
}

info "GitHub SSH Key Setup"
check_dependencies
request_admin_scope
generate_ssh_key
add_key_to_github
revoke_admin_scope
test_github_connection
info "Done!"
