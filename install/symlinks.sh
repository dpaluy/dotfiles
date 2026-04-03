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
# Use a local wrapper file as the live config and include the shared dotfiles
# config from there. That keeps the shared config tracked and the live file
# machine-owned.
create_git_config_wrapper() {
    local wrapper="$HOME/.config/git/config"
    local include_path="~/dotfiles/git/config"

    mkdir -p "$HOME/.config/git"

    if [[ -f "$wrapper" && ! -L "$wrapper" ]] && grep -qF "path = $include_path" "$wrapper" 2>/dev/null; then
        info "Git wrapper already configured"
        return 0
    fi

    backup_if_exists "$wrapper"

    cat > "$wrapper" << EOF
# ~/.config/git/config - Local machine Git config
# Shared settings are pulled from dotfiles; machine-specific settings belong here.

[include]
    path = $include_path

# Machine-specific settings below
EOF

    info "Created ~/.config/git/config wrapper"
}

create_git_config_wrapper
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

# gitmux config (git status for tmux status bar)
if command -v gitmux &>/dev/null; then
    mkdir -p "$HOME/.config/tmux"
    create_symlink "$DOTFILES_DIR/tmux/gitmux.yml" "$HOME/.config/tmux/gitmux.yml"
fi

# sesh config (copied, not symlinked — each machine customizes its own sessions)
if command -v sesh &>/dev/null; then
    mkdir -p "$HOME/.config/sesh"
    if [[ ! -f "$HOME/.config/sesh/sesh.toml" ]]; then
        cp "$DOTFILES_DIR/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml"
        info "Created default sesh config (customize at ~/.config/sesh/sesh.toml)"
    else
        info "sesh config already exists, skipping"
    fi
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

# RTK (token compression proxy)
if command -v rtk &>/dev/null; then
    mkdir -p "$HOME/.config/rtk"
    create_symlink "$DOTFILES_DIR/rtk/config.toml" "$HOME/.config/rtk/config.toml"
fi

# Worktrunk (git worktree manager)
if command -v wt &>/dev/null; then
    mkdir -p "$HOME/.config/worktrunk"
    create_symlink "$DOTFILES_DIR/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"
fi

# npm (supply chain security: delay installing packages < 3 days old)
create_symlink "$DOTFILES_DIR/npm/npmrc" "$HOME/.npmrc"

# uv (supply chain security: same delay for Python packages)
mkdir -p "$HOME/.config/uv"
create_symlink "$DOTFILES_DIR/uv/uv.toml" "$HOME/.config/uv/uv.toml"

# Linux-only: Hyprland
if [[ "$OS" != "macos" ]]; then
    if [[ -d "$DOTFILES_DIR/hypr" ]]; then
        mkdir -p "$HOME/.config/hypr"
        create_symlink "$DOTFILES_DIR/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
        create_symlink "$DOTFILES_DIR/hypr/bindings.conf" "$HOME/.config/hypr/bindings.conf"
    fi
fi
