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
    arch)   sudo pacman -S --noconfirm git curl neovim tmux fzf fd ripgrep gum lazygit gnupg yt-dlp direnv ;;
    debian) sudo apt install -y git curl neovim tmux fzf fd-find ripgrep gnupg yt-dlp direnv ;;
    fedora) sudo dnf install -y git curl neovim tmux fzf fd-find ripgrep gnupg2 yt-dlp direnv ;;
esac

# Install GitHub CLI
if ! command -v gh &> /dev/null; then
    info "Installing GitHub CLI..."
    case "$OS" in
        arch)   sudo pacman -S --noconfirm github-cli ;;
        debian)
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update && sudo apt install -y gh
            ;;
        fedora)
            sudo dnf install -y gh
            ;;
    esac
    info "GitHub CLI installed"
else
    info "GitHub CLI already installed"
fi

# Install git-delta
if ! command -v delta &> /dev/null; then
    info "Installing git-delta..."
    case "$OS" in
        arch)   sudo pacman -S --noconfirm git-delta ;;
        debian)
            DELTA_VERSION=$(curl -fsSL "https://api.github.com/repos/dandavison/delta/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
            DELTA_ARCH=$(dpkg --print-architecture)
            curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${DELTA_ARCH}.deb" -o /tmp/git-delta.deb
            sudo dpkg -i /tmp/git-delta.deb
            rm /tmp/git-delta.deb
            ;;
        fedora)
            sudo dnf install -y git-delta
            ;;
    esac
    info "git-delta installed"
else
    info "git-delta already installed"
fi

# Install lazygit
if ! command -v lazygit &> /dev/null; then
    info "Installing lazygit..."
    case "$OS" in
        arch)
            # Already installed above
            ;;
        debian)
            LAZYGIT_VERSION=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
            curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" -o /tmp/lazygit.tar.gz
            tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
            sudo install /tmp/lazygit /usr/local/bin/lazygit
            rm /tmp/lazygit.tar.gz /tmp/lazygit
            ;;
        fedora)
            sudo dnf copr enable -y atim/lazygit
            sudo dnf install -y lazygit
            ;;
    esac
    info "Lazygit installed"
else
    info "Lazygit already installed"
fi

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
if fc-list | grep -qi "MartianMono Nerd Font"; then
    info "MartianMono Nerd Font already installed"
elif ask_yes_no "Install MartianMono Nerd Font as an alternative?" "n"; then
    info "Installing MartianMono Nerd Font..."
    mkdir -p "$FONT_DIR"
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/MartianMono.tar.xz -o /tmp/MartianMono.tar.xz
    tar -xf /tmp/MartianMono.tar.xz -C "$FONT_DIR"
    rm /tmp/MartianMono.tar.xz
    fc-cache -fv
    info "MartianMono Nerd Font installed"
fi
