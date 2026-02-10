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
# Yazi (Terminal File Manager)
# ==============================================================================

header "Yazi"

if ask_yes_no "Install Yazi (terminal file manager)?" "n"; then
    if ! command -v yazi &> /dev/null; then
        info "Installing Yazi..."
        case "$OS" in
            macos)
                brew install yazi ffmpeg sevenzip poppler zoxide imagemagick
                ;;
            arch)
                sudo pacman -S --noconfirm yazi ffmpeg 7zip poppler fd ripgrep fzf zoxide imagemagick
                ;;
            debian)
                YAZI_ARCH=$(uname -m)
                YAZI_VERSION=$(curl -fsSL "https://api.github.com/repos/sxyazi/yazi/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
                curl -fsSL "https://github.com/sxyazi/yazi/releases/download/${YAZI_VERSION}/yazi-${YAZI_ARCH}-unknown-linux-gnu.zip" -o /tmp/yazi.zip
                unzip -o /tmp/yazi.zip -d /tmp/yazi-extract
                sudo install /tmp/yazi-extract/yazi-${YAZI_ARCH}-unknown-linux-gnu/yazi /usr/local/bin/yazi
                rm -rf /tmp/yazi.zip /tmp/yazi-extract
                ;;
            fedora)
                sudo dnf copr enable -y lihaohong/yazi
                sudo dnf install -y yazi
                ;;
        esac
        info "Yazi installed"
    else
        info "Yazi already installed"
    fi
else
    info "Skipping Yazi"
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
