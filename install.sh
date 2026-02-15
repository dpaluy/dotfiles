#!/usr/bin/env bash
#
# Cross-Platform Dotfiles Installation Script
# Works on macOS and Linux (Debian/Ubuntu, Fedora, Arch)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load utilities
source "$SCRIPT_DIR/install/lib.sh"

# Detect OS
OS=$(detect_os)

# Show banner
show_banner

# Check if we're in the right directory
if [[ ! -d "$DOTFILES_DIR/zsh" ]]; then
    error "Dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

# OS-specific packages and tools
if [[ "$OS" == "macos" ]]; then
    source "$SCRIPT_DIR/install/macos.sh"
elif [[ "$OS" != "unknown" ]]; then
    source "$SCRIPT_DIR/install/linux.sh"
fi

# Cross-platform tools (Oh My Zsh, Atuin, shell setup)
source "$SCRIPT_DIR/install/common.sh"

# Optional: AI coding assistants
if ask_yes_no "Install AI coding assistants (Claude Code, Codex, OpenCode)?" "n"; then
    source "$SCRIPT_DIR/install/ai-tools.sh"
fi

# Configuration symlinks
source "$SCRIPT_DIR/install/symlinks.sh"

# Claude Code configuration
source "$SCRIPT_DIR/install/claude.sh"

# OpenCode configuration
source "$SCRIPT_DIR/install/opencode.sh"

# Local configuration templates
source "$SCRIPT_DIR/install/local-config.sh"

# Completion message
show_completion
