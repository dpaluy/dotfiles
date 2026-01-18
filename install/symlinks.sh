#!/usr/bin/env bash
#
# Configuration symlinks
#

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
