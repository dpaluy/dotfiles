#!/usr/bin/env bash
#
# System Update Script
# Runs package managers, updates global tools, and installs new additions.
#
# Usage: ./update.sh
#

set -Eeuo pipefail

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

run_foreground() {
    local title="$1"
    shift

    if has_gum; then
        gum style --foreground 39 "$title"
    else
        echo "$title..."
    fi

    "$@"
}

upgrade_casks() {
    local log_file
    log_file="$(mktemp)"

    if env HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --cask --greedy > >(tee "$log_file") 2>&1; then
        rm -f "$log_file"
        return 0
    fi

    local missing_app_casks=()
    local cask
    while IFS= read -r cask; do
        missing_app_casks+=("$cask")
    done < <(sed -n "s/^Error: \([^:]*\): It seems the App source '.*' is not there\\.$/\1/p" "$log_file" | sort -u)
    rm -f "$log_file"

    if [[ ${#missing_app_casks[@]} -eq 0 ]]; then
        return 1
    fi

    warn "Repairing casks with missing app bundles: ${missing_app_casks[*]}"
    for cask in "${missing_app_casks[@]}"; do
        run_foreground "Reinstalling $cask" bash -c '
            set -e
            cask="$1"
            env HOMEBREW_NO_INSTALL_CLEANUP=1 brew uninstall --cask --force "$cask" || true
            env HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --cask "$cask"
        ' _ "$cask"
    done

    env HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --cask --greedy
}

# ==============================================================================
# macOS: Homebrew
# ==============================================================================

if [[ "$OS" == "macos" ]]; then
    header "Homebrew"
    if command -v brew &> /dev/null; then
        spin "Updating Homebrew" brew update
        run_foreground "Upgrading packages" env HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade
        run_foreground "Upgrading casks" upgrade_casks
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
    @mariozechner/pi-coding-agent
)

if command -v npm &> /dev/null && [[ ${#NPM_GLOBALS[@]} -gt 0 ]]; then
    header "npm Global Packages"
    for pkg in "${NPM_GLOBALS[@]}"; do
        spin "Installing/updating $pkg" npm install -g "$pkg"
    done
fi

# ==============================================================================
# pi
# ==============================================================================

if command -v pi &> /dev/null; then
    header "pi"
    spin "Updating pi" pi update
fi

# ==============================================================================
# bun Global Packages
# ==============================================================================

BUN_GLOBALS=(
    https://github.com/tobi/qmd
)

if command -v opencode &>/dev/null; then
    BUN_GLOBALS+=(oh-my-openagent)
fi

if command -v codex &>/dev/null; then
    BUN_GLOBALS+=(oh-my-codex)
fi

if command -v pi &>/dev/null; then
    BUN_GLOBALS+=(https://github.com/can1357/oh-my-pi)
fi

if command -v bun &> /dev/null && [[ ${#BUN_GLOBALS[@]} -gt 0 ]]; then
    header "bun Global Packages"
    for pkg in "${BUN_GLOBALS[@]}"; do
        spin "Installing/updating $(basename "$pkg")" bun install -g "$pkg"
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
