#!/usr/bin/env bash
#
# Linux-specific installation (packages, fonts)
#

# ==============================================================================
# System Packages
# ==============================================================================

header "System Packages"

# Install zsh if not present
if ! command -v zsh &> /dev/null; then
    info "Installing zsh..."
    case "$OS" in
        arch)   sudo pacman -S --noconfirm zsh ;;
        debian) sudo apt update && sudo apt install -y zsh ;;
        fedora) sudo dnf install -y zsh ;;
    esac
    info "Zsh installed"
else
    info "Zsh already installed"
fi

# Install common tools
info "Installing common tools (git, curl, etc.)..."
case "$OS" in
    arch)   sudo pacman -S --noconfirm git curl neovim tmux fzf fd ripgrep gum ;;
    debian) sudo apt install -y git curl neovim tmux fzf fd-find ripgrep ;;
    fedora) sudo dnf install -y git curl neovim tmux fzf fd-find ripgrep ;;
esac

# Install zellij
if ! command -v zellij &> /dev/null; then
    info "Installing zellij..."
    case "$OS" in
        arch)   sudo pacman -S --noconfirm zellij ;;
        debian)
            ZELLIJ_ARCH=$(uname -m)
            curl -fsSL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ZELLIJ_ARCH}-unknown-linux-musl.tar.gz" -o /tmp/zellij.tar.gz
            tar -xf /tmp/zellij.tar.gz -C /tmp
            sudo install /tmp/zellij /usr/local/bin/zellij
            rm /tmp/zellij.tar.gz /tmp/zellij
            ;;
        fedora) sudo dnf install -y zellij ;;
    esac
    info "Zellij installed"
else
    info "Zellij already installed"
fi

# Install gum for better TUI (if not already installed)
if ! command -v gum &> /dev/null; then
    info "Installing gum for better UI..."
    case "$OS" in
        arch)
            # Already installed above
            ;;
        debian)
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt update && sudo apt install -y gum
            ;;
        fedora)
            echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
            sudo dnf install -y gum
            ;;
    esac
fi

# ==============================================================================
# mise (Version Manager)
# ==============================================================================

header "mise"

if ! command -v mise &> /dev/null; then
    info "Installing mise..."
    curl https://mise.run | sh

    # Add to PATH for this session
    export PATH="$HOME/.local/bin:$PATH"
    info "mise installed"
else
    info "mise already installed"
fi

# Activate mise for this session (enables Node.js, Python, etc.)
if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi

# ==============================================================================
# Fonts
# ==============================================================================

header "Fonts"
FONT_DIR="$HOME/.local/share/fonts"

# Always install JetBrainsMono (default font)
if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    info "JetBrainsMono Nerd Font already installed"
else
    info "Installing JetBrainsMono Nerd Font..."
    mkdir -p "$FONT_DIR"
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz -o /tmp/JetBrainsMono.tar.xz
    tar -xf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"
    rm /tmp/JetBrainsMono.tar.xz
    fc-cache -fv
    info "JetBrainsMono Nerd Font installed"
fi

# Ask about MartianMono
if ask_yes_no "Install MartianMono Nerd Font as an alternative?" "n"; then
    if fc-list | grep -qi "MartianMono Nerd Font"; then
        info "MartianMono Nerd Font already installed"
    else
        info "Installing MartianMono Nerd Font..."
        mkdir -p "$FONT_DIR"
        curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/MartianMono.tar.xz -o /tmp/MartianMono.tar.xz
        tar -xf /tmp/MartianMono.tar.xz -C "$FONT_DIR"
        rm /tmp/MartianMono.tar.xz
        fc-cache -fv
        info "MartianMono Nerd Font installed"
    fi
fi
