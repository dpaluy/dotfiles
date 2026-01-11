#!/usr/bin/env bash
#
# Cross-Platform Dotfiles Installation Script
# Works on macOS and Linux (Debian/Ubuntu, Fedora, Arch)
#

set -e

DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_LOCAL="$HOME/.local/dotfiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Backup existing file if it exists and is not a symlink
backup_if_exists() {
    local file="$1"
    if [[ -e "$file" && ! -L "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
        warn "Backing up $file to $backup"
        mv "$file" "$backup"
    elif [[ -L "$file" ]]; then
        rm "$file"
    fi
}

# Create symlink
create_symlink() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        warn "Source $src does not exist, skipping"
        return 0
    fi

    backup_if_exists "$dest"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$dest")"

    ln -sf "$src" "$dest"
    info "Linked $dest -> $src"
}

# Create local config template
create_local_template() {
    local file="$1"
    local comment="$2"

    if [[ ! -f "$file" ]]; then
        echo "# $comment" > "$file"
        echo "# This file is not version controlled - add machine-specific settings here" >> "$file"
        echo "" >> "$file"
        info "Created template: $file"
    else
        info "Skipping existing: $file"
    fi
}

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"

    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    read -p "$question $prompt " answer
    answer="${answer:-$default}"

    [[ "$answer" =~ ^[Yy] ]]
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

echo ""
echo "=================================="
echo "  Cross-Platform Dotfiles Setup"
echo "=================================="
echo ""
info "Detected OS: $OS"
echo ""

# Check if we're in the right directory
if [[ ! -d "$DOTFILES_DIR/zsh" ]]; then
    error "Dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

# ==============================================================================
# macOS: Homebrew
# ==============================================================================

if [[ "$OS" == "macos" ]]; then
    header "Homebrew"

    if ! command -v brew &> /dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for this session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        info "Homebrew installed"
    else
        info "Homebrew already installed"
    fi

    header "Brew Packages"
    info "Installing packages from Brewfile..."
    brew bundle --file="$DOTFILES_DIR/Brewfile"

    header "Optional Tools"
    if ask_yes_no "Install Raycast?"; then
        info "Installing Raycast..."
        brew install --cask raycast
    else
        info "Skipping Raycast"
    fi
fi

# ==============================================================================
# Linux: Package Installation
# ==============================================================================

if [[ "$OS" != "macos" && "$OS" != "unknown" ]]; then
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
        arch)   sudo pacman -S --noconfirm git curl neovim fzf fd ripgrep ;;
        debian) sudo apt install -y git curl neovim fzf fd-find ripgrep ;;
        fedora) sudo dnf install -y git curl neovim fzf fd-find ripgrep ;;
    esac
fi

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
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
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
# Create Symlinks
# ==============================================================================

header "Symlinks"

info "Creating symlinks..."

# Zsh
create_symlink "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"

# Git (XDG style)
mkdir -p "$HOME/.config/git"
create_symlink "$DOTFILES_DIR/git/config" "$HOME/.config/git/config"
create_symlink "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"

# Ghostty
mkdir -p "$HOME/.config/ghostty"
create_symlink "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

# Starship
create_symlink "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# Tmux (if exists)
if [[ -f "$DOTFILES_DIR/tmux/tmux.conf" ]]; then
    create_symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
fi

# Claude Code
mkdir -p "$HOME/.claude"
create_symlink "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# OpenAI Codex
mkdir -p "$HOME/.codex"
create_symlink "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml"

# Linux-only: Hyprland
if [[ "$OS" != "macos" ]]; then
    if [[ -d "$DOTFILES_DIR/hypr" ]]; then
        mkdir -p "$HOME/.config/hypr"
        create_symlink "$DOTFILES_DIR/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
        create_symlink "$DOTFILES_DIR/hypr/bindings.conf" "$HOME/.config/hypr/bindings.conf"
    fi
fi

# ==============================================================================
# Local Configuration Directory
# ==============================================================================

header "Local Configuration"

info "Setting up local dotfiles directory..."

mkdir -p "$DOTFILES_LOCAL"

create_local_template "$DOTFILES_LOCAL/aliases.local" "Local aliases"
create_local_template "$DOTFILES_LOCAL/functions.local" "Local shell functions"
create_local_template "$DOTFILES_LOCAL/exports.local" "Local environment variables (API keys, tokens, etc.)"
create_local_template "$DOTFILES_LOCAL/path.local" "Local PATH additions"
create_local_template "$DOTFILES_LOCAL/gitconfig.local" "Local git config (name, email, signing keys)"
create_local_template "$DOTFILES_LOCAL/ghostty.local" "Local ghostty overrides (font, size, theme)"
create_local_template "$DOTFILES_LOCAL/ai.local" "Local AI tool settings (API keys, model preferences)"
create_local_template "$DOTFILES_LOCAL/rails.local" "Local Rails/Ruby settings"

# Add example content to gitconfig.local if empty
if [[ $(wc -l < "$DOTFILES_LOCAL/gitconfig.local") -le 3 ]]; then
    cat >> "$DOTFILES_LOCAL/gitconfig.local" << 'EOF'
# Example:
# [user]
#     name = Your Name
#     email = your.email@example.com
#     signingkey = YOUR_GPG_KEY_ID
#
# [commit]
#     gpgsign = true
EOF
fi

# ==============================================================================
# macOS: LazyVim Setup
# ==============================================================================

if [[ "$OS" == "macos" ]]; then
    header "Neovim / LazyVim"

    if [[ ! -d "$HOME/.config/nvim" ]]; then
        if ask_yes_no "Install LazyVim starter configuration?" "y"; then
            info "Cloning LazyVim starter..."
            git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
            rm -rf "$HOME/.config/nvim/.git"
            info "LazyVim installed. Run 'nvim' to complete setup."
        fi
    else
        info "Neovim config already exists at ~/.config/nvim"
    fi
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

# ==============================================================================
# macOS: Tool Initialization
# ==============================================================================

if [[ "$OS" == "macos" ]]; then
    header "Tool Initialization"

    # Initialize fzf if not already done
    if [[ ! -f "$HOME/.fzf.zsh" ]]; then
        info "Setting up fzf..."
        "$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
    fi
fi

# ==============================================================================
# Done
# ==============================================================================

echo ""
echo "=================================="
echo "  Installation Complete!"
echo "=================================="
echo ""
info "Public configs: $DOTFILES_DIR"
info "Local configs:  $DOTFILES_LOCAL"
echo ""
if [[ "$SHELL" != *"zsh"* ]]; then
    warn "Log out and back in to start using zsh"
else
    info "To apply changes, run: source ~/.zshrc"
fi
echo ""
info "Next steps:"
echo "  1. Edit $DOTFILES_LOCAL/gitconfig.local with your name/email"
if [[ "$OS" == "macos" ]]; then
    echo "  2. Run 'nvim' to complete LazyVim setup"
    echo "  3. Run 'atuin login' or 'atuin register' for shell history sync"
else
    echo "  2. Run 'atuin login' or 'atuin register' for shell history sync"
    echo "  3. Edit ghostty config keybindings (comment macOS, uncomment Linux)"
fi
echo ""
