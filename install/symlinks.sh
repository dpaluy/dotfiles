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

# Tmux
if [[ -f "$DOTFILES_DIR/tmux/tmux.conf" ]]; then
    create_symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
fi

# Zellij
mkdir -p "$HOME/.config/zellij"
create_symlink "$DOTFILES_DIR/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"

# SSH - use Include pattern (preserves local host-specific config)
ensure_ssh_include() {
    local ssh_dir="$HOME/.ssh"
    local ssh_config="$ssh_dir/config"
    local include_line="Include ~/dotfiles/ssh/config"

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    if [[ -f "$ssh_config" ]] && grep -qF "$include_line" "$ssh_config" 2>/dev/null; then
        info "SSH include already configured"
        return 0
    fi

    # Prepend Include (must be before Host blocks)
    if [[ -f "$ssh_config" ]]; then
        local tmp=$(mktemp)
        echo "$include_line" > "$tmp"
        echo "" >> "$tmp"
        cat "$ssh_config" >> "$tmp"
        command mv -f "$tmp" "$ssh_config"
    else
        echo "$include_line" > "$ssh_config"
    fi

    chmod 600 "$ssh_config"
    info "Added SSH include for dotfiles"
}

ensure_ssh_include

# gh-dash
if gh extension list 2>/dev/null | grep -q "dlvhdr/gh-dash"; then
    mkdir -p "$HOME/.config/gh-dash"
    create_symlink "$DOTFILES_DIR/gh-dash/config.yml" "$HOME/.config/gh-dash/config.yml"
fi

# Worktrunk (git worktree manager)
if command -v wt &>/dev/null; then
    mkdir -p "$HOME/.config/worktrunk"
    create_symlink "$DOTFILES_DIR/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"
fi

# Linux-only: Hyprland
if [[ "$OS" != "macos" ]]; then
    if [[ -d "$DOTFILES_DIR/hypr" ]]; then
        mkdir -p "$HOME/.config/hypr"
        create_symlink "$DOTFILES_DIR/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
        create_symlink "$DOTFILES_DIR/hypr/bindings.conf" "$HOME/.config/hypr/bindings.conf"
    fi
fi
