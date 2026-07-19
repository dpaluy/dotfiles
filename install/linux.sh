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
    arch)   sudo pacman -S --noconfirm git curl neovim fzf fd ripgrep eza gum lazygit gnupg yt-dlp direnv ;;
    debian) sudo apt install -y git curl neovim fzf fd-find ripgrep eza gnupg yt-dlp direnv ;;
    fedora) sudo dnf install -y git curl neovim fzf fd-find ripgrep eza gnupg2 yt-dlp direnv ;;
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
            download_file "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${DELTA_ARCH}.deb" /tmp/git-delta.deb
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

# Install diffnav
if ! command -v diffnav &> /dev/null; then
    info "Installing diffnav..."
    DIFFNAV_VERSION=$(curl -fsSL "https://api.github.com/repos/dlvhdr/diffnav/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    DIFFNAV_ARCH="$(normalize_release_arch)"
    download_file "https://github.com/dlvhdr/diffnav/releases/download/v${DIFFNAV_VERSION}/diffnav_Linux_${DIFFNAV_ARCH}.tar.gz" /tmp/diffnav.tar.gz
    diffnav_checksums=$(mktemp)
    download_file "https://github.com/dlvhdr/diffnav/releases/download/v${DIFFNAV_VERSION}/diffnav_${DIFFNAV_VERSION}_checksums.txt" "$diffnav_checksums"
    verify_sha256_checksum "$diffnav_checksums" /tmp/diffnav.tar.gz "diffnav_Linux_${DIFFNAV_ARCH}.tar.gz"
    rm -f "$diffnav_checksums"
    tar -xf /tmp/diffnav.tar.gz -C /tmp diffnav
    sudo install /tmp/diffnav /usr/local/bin/diffnav
    rm /tmp/diffnav.tar.gz /tmp/diffnav
    info "diffnav installed"
else
    info "diffnav already installed"
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
            LAZYGIT_ARCH="$(normalize_release_arch)"
            download_file "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${LAZYGIT_ARCH}.tar.gz" /tmp/lazygit.tar.gz
            lazygit_checksums=$(mktemp)
            download_file "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/checksums.txt" "$lazygit_checksums"
            verify_sha256_checksum "$lazygit_checksums" /tmp/lazygit.tar.gz "lazygit_${LAZYGIT_VERSION}_linux_${LAZYGIT_ARCH}.tar.gz"
            rm -f "$lazygit_checksums"
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

# Install sesh (tmux session manager)
if ! command -v sesh &> /dev/null; then
    info "Installing sesh..."
    SESH_VERSION=$(curl -fsSL "https://api.github.com/repos/joshmedeski/sesh/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    SESH_ARCH="$(normalize_release_arch)"
    download_file "https://github.com/joshmedeski/sesh/releases/download/v${SESH_VERSION}/sesh_Linux_${SESH_ARCH}.tar.gz" /tmp/sesh.tar.gz
    sesh_checksums=$(mktemp)
    download_file "https://github.com/joshmedeski/sesh/releases/download/v${SESH_VERSION}/sesh_${SESH_VERSION}_checksums.txt" "$sesh_checksums"
    verify_sha256_checksum "$sesh_checksums" /tmp/sesh.tar.gz "sesh_Linux_${SESH_ARCH}.tar.gz"
    rm -f "$sesh_checksums"
    tar -xf /tmp/sesh.tar.gz -C /tmp sesh
    sudo install /tmp/sesh /usr/local/bin/sesh
    rm /tmp/sesh.tar.gz /tmp/sesh
    info "sesh installed"
else
    info "sesh already installed"
fi

# Install gitmux (git status for tmux status bar)
if ! command -v gitmux &> /dev/null; then
    info "Installing gitmux..."
    GITMUX_VERSION=$(curl -fsSL "https://api.github.com/repos/arl/gitmux/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    GITMUX_ARCH="$(normalize_release_arch)"
    case "$GITMUX_ARCH" in
        x86_64)  GITMUX_ARCH="amd64" ;;
        aarch64) GITMUX_ARCH="arm64" ;;
    esac
    download_file "https://github.com/arl/gitmux/releases/download/v${GITMUX_VERSION}/gitmux_v${GITMUX_VERSION}_linux_${GITMUX_ARCH}.tar.gz" /tmp/gitmux.tar.gz
    gitmux_checksums=$(mktemp)
    download_file "https://github.com/arl/gitmux/releases/download/v${GITMUX_VERSION}/checksums.txt" "$gitmux_checksums"
    verify_sha256_checksum "$gitmux_checksums" /tmp/gitmux.tar.gz "gitmux_v${GITMUX_VERSION}_linux_${GITMUX_ARCH}.tar.gz"
    rm -f "$gitmux_checksums"
    tar -xf /tmp/gitmux.tar.gz -C /tmp gitmux
    sudo install /tmp/gitmux /usr/local/bin/gitmux
    rm /tmp/gitmux.tar.gz /tmp/gitmux
    info "gitmux installed"
else
    info "gitmux already installed"
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
# Hyprland Plugins (hyprpm)
# ==============================================================================

if command -v hyprpm &> /dev/null; then
    header "Hyprland Plugins"

    HYPR_PLUGINS_REPO="https://github.com/hyprwm/hyprland-plugins"

    if hyprpm list 2>/dev/null | grep -q "hyprland-plugins"; then
        info "hyprland-plugins repo already added"
    else
        info "Adding hyprland-plugins repo..."
        hyprpm update
        hyprpm add "$HYPR_PLUGINS_REPO"
    fi

    if hyprpm list 2>/dev/null | grep -A1 "Plugin hyprbars" | grep -q "enabled: true"; then
        info "hyprbars already enabled"
    else
        info "Enabling hyprbars..."
        hyprpm enable hyprbars
    fi
else
    info "hyprpm not found, skipping Hyprland plugins"
fi

# ==============================================================================
# mise (Version Manager)
# ==============================================================================

header "mise"

if ! command -v mise &> /dev/null; then
    info "Installing mise..."
    run_remote_script sh https://mise.run

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
    download_file https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz /tmp/JetBrainsMono.tar.xz
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
    download_file https://github.com/ryanoasis/nerd-fonts/releases/latest/download/MartianMono.tar.xz /tmp/MartianMono.tar.xz
    tar -xf /tmp/MartianMono.tar.xz -C "$FONT_DIR"
    rm /tmp/MartianMono.tar.xz
    fc-cache -fv
    info "MartianMono Nerd Font installed"
fi
