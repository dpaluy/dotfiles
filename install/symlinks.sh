#!/usr/bin/env bash
#
# Configuration symlinks
#

header "Symlinks"

info "Creating symlinks..."

# Zsh - use wrapper pattern (local file sources dotfiles)
# This allows external tools (mise, atuin, fzf) to safely append their init lines
create_zshrc_wrapper() {
    local wrapper="$HOME/.zshrc"

    # Skip if valid wrapper already exists
    if [[ -f "$wrapper" && ! -L "$wrapper" ]] && grep -q "source.*dotfiles/zsh/zshrc" "$wrapper" 2>/dev/null; then
        info "Zsh wrapper already configured"
        return 0
    fi

    # Backup existing (symlink or file)
    backup_if_exists "$wrapper"

    # Create wrapper
    cat > "$wrapper" << 'EOF'
#!/usr/bin/env zsh
# ~/.zshrc - Local shell config (not version controlled)
# Source dotfiles
source "$HOME/dotfiles/zsh/zshrc"

# Tool additions below (mise, atuin, fzf, etc.)
# -----------------------------------------------
EOF

    info "Created ~/.zshrc wrapper"
}

create_zshrc_wrapper

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
