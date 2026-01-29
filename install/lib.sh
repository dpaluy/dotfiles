#!/usr/bin/env bash
#
# Shared utility functions for dotfiles installation
#

# Directory paths
DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_LOCAL="$HOME/.local/dotfiles"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if gum is available
has_gum() {
    command -v gum &> /dev/null
}

info() {
    if has_gum; then
        gum style --foreground 82 "✓ $1"
    else
        echo -e "${GREEN}[INFO]${NC} $1"
    fi
}

warn() {
    if has_gum; then
        gum style --foreground 214 "⚠ $1"
    else
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
}

error() {
    if has_gum; then
        gum style --foreground 196 "✗ $1"
    else
        echo -e "${RED}[ERROR]${NC} $1"
    fi
}

header() {
    if has_gum; then
        echo ""
        gum style --border double --padding "0 2" --border-foreground 39 "$1"
        echo ""
    else
        echo -e "\n${BLUE}=== $1 ===${NC}\n"
    fi
}

# Run command with spinner (falls back to direct execution)
spin() {
    local title="$1"
    shift
    if has_gum; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        echo -n "$title... "
        "$@"
        echo "done"
    fi
}

# Backup existing file if it exists and is not a symlink
backup_if_exists() {
    local file="$1"
    if [[ -e "$file" && ! -L "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
        warn "Backing up $file to $backup"
        mv "$file" "$backup"
    elif [[ -L "$file" ]]; then
        rm -f "$file"
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

    if has_gum; then
        if [[ "$default" == "y" ]]; then
            gum confirm "$question" --default=true
        else
            gum confirm "$question" --default=false
        fi
    else
        if [[ "$default" == "y" ]]; then
            prompt="[Y/n]"
        else
            prompt="[y/N]"
        fi

        read -p "$question $prompt " answer
        answer="${answer:-$default}"

        [[ "$answer" =~ ^[Yy] ]]
    fi
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

# Show installation banner
show_banner() {
    echo ""
    if has_gum; then
        gum style --border rounded --padding "1 3" --border-foreground 39 "Cross-Platform Dotfiles Setup"
    else
        echo "=================================="
        echo "  Cross-Platform Dotfiles Setup"
        echo "=================================="
    fi
    echo ""
    info "Detected OS: $OS"
    echo ""
}

# Show completion message
show_completion() {
    echo ""
    if has_gum; then
        gum style --border double --padding "1 3" --border-foreground 82 "✓ Installation Complete!"
    else
        echo "=================================="
        echo "  Installation Complete!"
        echo "=================================="
    fi
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
    if has_gum; then
        gum style --foreground 39 --bold "Next steps:"
    else
        info "Next steps:"
    fi
    echo "  1. Edit $DOTFILES_LOCAL/gitconfig.local with your name/email"
    if [[ "$OS" == "macos" ]]; then
        echo "  2. Run 'nvim' to complete LazyVim setup"
        echo "  3. Run 'atuin login' or 'atuin register' for shell history sync"
    else
        echo "  2. Run 'atuin login' or 'atuin register' for shell history sync"
        echo "  3. Edit ghostty config keybindings (comment macOS, uncomment Linux)"
    fi
    echo ""
}
