#!/usr/bin/env bash
#
# Cross-platform tools (Oh My Zsh, Atuin, shell setup)
#

# ==============================================================================
# Oh My Zsh
# ==============================================================================

header "Oh My Zsh"

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    info "Oh My Zsh installed"
else
    info "Oh My Zsh already installed"
fi

# Install zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    spin "Installing zsh-autosuggestions" git clone --quiet https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    spin "Installing zsh-syntax-highlighting" git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ==============================================================================
# Atuin (Shell History)
# ==============================================================================

header "Atuin"

if ! command -v atuin &> /dev/null; then
    info "Installing Atuin..."
    case "$OS" in
        macos)  brew install atuin ;;
        arch)   sudo pacman -S --noconfirm atuin ;;
        debian) curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh ;;
        fedora) sudo dnf install -y atuin ;;
        *)      curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh ;;
    esac
    info "Atuin installed"
else
    info "Atuin already installed"
fi

# ==============================================================================
# Default Shell
# ==============================================================================

header "Default Shell"

if [[ "$SHELL" != *"zsh"* ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    info "Default shell changed to zsh"
    warn "Please log out and back in for the change to take effect"
else
    info "Zsh is already the default shell"
fi
