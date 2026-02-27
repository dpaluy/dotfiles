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
ai_all_installed=true
for ai_cmd in claude codex gemini opencode qmd; do
    command -v "$ai_cmd" &>/dev/null || { ai_all_installed=false; break; }
done

if $ai_all_installed; then
    info "All AI coding assistants already installed"
elif ask_yes_no "Install AI coding assistants (Claude Code, Codex, OpenCode)?" "n"; then
    source "$SCRIPT_DIR/install/ai-tools.sh"
fi

# Configuration symlinks
source "$SCRIPT_DIR/install/symlinks.sh"

# Agent Skills (shared across AI tools, independent of installation)
if [[ -d "$DOTFILES_DIR/agents/skills" ]]; then
    # ~/.agents/skills: shared Agent Skills standard (agentskills.io)
    if ask_yes_no "Symlink dotfiles skills into ~/.agents/skills?"; then
        mkdir -p "$HOME/.agents/skills"
        for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
            [[ -d "$skill_dir" ]] || continue
            skill_name="$(basename "$skill_dir")"
            create_symlink "$skill_dir" "$HOME/.agents/skills/$skill_name"
        done
    fi

    # ~/.claude/skills: Claude Code skills
    if command -v claude &> /dev/null && ask_yes_no "Symlink dotfiles skills into ~/.claude/skills?"; then
        mkdir -p "$HOME/.claude/skills"
        for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
            [[ -d "$skill_dir" ]] || continue
            skill_name="$(basename "$skill_dir")"
            create_symlink "$skill_dir" "$HOME/.claude/skills/$skill_name"
        done
    fi
fi

# AI tool configurations (skipped if tool not installed)
source "$SCRIPT_DIR/install/claude.sh"
source "$SCRIPT_DIR/install/codex.sh"
source "$SCRIPT_DIR/install/opencode.sh"

# Local configuration templates
source "$SCRIPT_DIR/install/local-config.sh"

# Completion message
show_completion
