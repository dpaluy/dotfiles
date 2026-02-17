#!/usr/bin/env bash
#
# System Update Script
# Runs package managers, updates global tools, and installs new additions.
#
# Usage: ./update.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load utilities
source "$SCRIPT_DIR/install/lib.sh"

# Detect OS
OS=$(detect_os)

echo ""
if has_gum; then
    gum style --border rounded --padding "1 3" --border-foreground 214 "System Update"
else
    echo "========================"
    echo "    System Update"
    echo "========================"
fi
echo ""
info "Detected OS: $OS"
echo ""

# ==============================================================================
# macOS: Homebrew
# ==============================================================================

if [[ "$OS" == "macos" ]]; then
    header "Homebrew"
    if command -v brew &> /dev/null; then
        spin "Updating Homebrew" brew update
        spin "Upgrading packages" brew upgrade
        spin "Upgrading casks" brew upgrade --cask --greedy
        spin "Cleaning up" brew cleanup --prune=30
        info "Brewfile sync..."
        brew bundle --file="$DOTFILES_DIR/Brewfile" || warn "Some Brewfile entries failed"
    else
        warn "Homebrew not installed, skipping"
    fi
fi

# ==============================================================================
# Linux: System Packages
# ==============================================================================

if [[ "$OS" == "debian" ]]; then
    header "APT"
    sudo apt update
    sudo apt upgrade -y
    sudo apt autoremove -y
elif [[ "$OS" == "fedora" ]]; then
    header "DNF"
    sudo dnf upgrade -y --refresh
    sudo dnf autoremove -y
elif [[ "$OS" == "arch" ]]; then
    header "Pacman"
    sudo pacman -Syu --noconfirm
fi

# ==============================================================================
# mise
# ==============================================================================

if command -v mise &> /dev/null; then
    header "mise"
    spin "Updating mise" mise self-update --yes 2>/dev/null || true
    spin "Upgrading tools" mise upgrade --yes 2>/dev/null || true
    eval "$(mise activate bash)"
fi

# ==============================================================================
# npm Global Packages
# ==============================================================================
#
# Add new global npm packages here. They'll be installed on next run.
# Already-installed packages just get updated.
#

NPM_GLOBALS=(
    agent-browser
)

if command -v npm &> /dev/null && [[ ${#NPM_GLOBALS[@]} -gt 0 ]]; then
    header "npm Global Packages"
    for pkg in "${NPM_GLOBALS[@]}"; do
        spin "Installing/updating $pkg" npm install -g "$pkg"
    done
fi

# ==============================================================================
# Done
# ==============================================================================

echo ""
if has_gum; then
    gum style --border double --padding "0 2" --border-foreground 82 "Update complete!"
else
    echo "========================"
    echo "   Update complete!"
    echo "========================"
fi
echo ""
