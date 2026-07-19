#!/usr/bin/env bash
#
# Configuration symlinks
#

header "Symlinks"

info "Creating symlinks..."

# Zsh environment - use a wrapper so machine-local additions remain possible.
# .zshenv is loaded by interactive and non-interactive zsh processes.
create_zshenv_wrapper() {
    local wrapper="$HOME/.zshenv"

    if [[ -f "$wrapper" && ! -L "$wrapper" ]] && grep -q "source.*dotfiles/zsh/zshenv" "$wrapper" 2>/dev/null; then
        info "Zsh environment wrapper already configured"
        return 0
    fi

    backup_if_exists "$wrapper"

    cat > "$wrapper" << EOF
#!/usr/bin/env zsh
# ~/.zshenv - Environment shared by interactive and non-interactive shells
export DOTFILES_DIR="$DOTFILES_DIR"
source "$DOTFILES_DIR/zsh/zshenv"

# Machine-specific environment additions below
EOF

    info "Created ~/.zshenv wrapper"
}

create_zshenv_wrapper

# Login shells load /etc/zprofile after .zshenv. On macOS, path_helper can move
# system paths ahead of mise, so reapply the shared environment afterward.
ensure_zprofile_source() {
    local profile="$HOME/.zprofile"
    local source_line="source \"$DOTFILES_DIR/zsh/zprofile\""

    if [[ -f "$profile" ]] && grep -qF "$source_line" "$profile" 2>/dev/null; then
        info "Zsh login environment already configured"
        return 0
    fi

    if [[ -s "$profile" ]]; then
        printf '\n%s\n' "$source_line" >> "$profile"
    else
        printf '%s\n' "$source_line" > "$profile"
    fi

    info "Configured ~/.zprofile login environment"
}

ensure_zprofile_source

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
    cat > "$wrapper" << EOF
#!/usr/bin/env zsh
# ~/.zshrc - Local shell config (not version controlled)
# Source dotfiles
export DOTFILES_DIR="$DOTFILES_DIR"
source "$DOTFILES_DIR/zsh/zshrc"

# Tool additions below (mise, atuin, fzf, etc.)
# -----------------------------------------------

# Keep non-interactive wrapper commands from failing when the sourced dotfiles
# end on an optional missing-file check.
true
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
    local include_path="$DOTFILES_DIR/git/config"
    # The literal tilde is retained to recognize wrappers created by earlier versions.
    # shellcheck disable=SC2088
    local legacy_include_path="~/dotfiles/git/config"

    mkdir -p "$HOME/.config/git"

    if [[ -f "$wrapper" && ! -L "$wrapper" ]]; then
        if grep -qF "path = $include_path" "$wrapper" 2>/dev/null \
            || { [[ "$DOTFILES_DIR" == "$HOME/dotfiles" ]] && grep -qF "path = $legacy_include_path" "$wrapper" 2>/dev/null; }; then
            info "Git wrapper already configured"
            return 0
        fi
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
case "$OS" in
    macos) ghostty_platform="$DOTFILES_DIR/ghostty/macos.conf" ;;
    arch|debian|fedora) ghostty_platform="$DOTFILES_DIR/ghostty/linux.conf" ;;
esac
if [[ -n "${ghostty_platform:-}" ]]; then
    create_symlink "$ghostty_platform" "$HOME/.config/ghostty/platform.conf"
fi

# Starship
create_symlink "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# tmux.conf is linked from install/multiplexer.sh (gated on the tmux prompt).

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


# SSH - use Include pattern (preserves local host-specific config)
ensure_ssh_include() {
    local ssh_dir="$HOME/.ssh"
    local ssh_config="$ssh_dir/config"
    local include_line="Include $DOTFILES_DIR/ssh/config"
    # shellcheck disable=SC2088
    local legacy_include_line="Include ~/dotfiles/ssh/config"

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    if [[ -f "$ssh_config" ]]; then
        if grep -qF "$include_line" "$ssh_config" 2>/dev/null \
            || { [[ "$DOTFILES_DIR" == "$HOME/dotfiles" ]] && grep -qF "$legacy_include_line" "$ssh_config" 2>/dev/null; }; then
            info "SSH include already configured"
            return 0
        fi
    fi

    # Prepend Include (must be before Host blocks)
    if [[ -f "$ssh_config" ]]; then
        local tmp
        tmp=$(mktemp)
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

# npm
create_symlink "$DOTFILES_DIR/npm/npmrc" "$HOME/.npmrc"

# ruby
create_symlink "$DOTFILES_DIR/ruby/gemrc" "$HOME/.gemrc"

# uv
mkdir -p "$HOME/.config/uv"
create_symlink "$DOTFILES_DIR/uv/uv.toml" "$HOME/.config/uv/uv.toml"

# Ripgrep
mkdir -p "$HOME/.config/ripgrep"
create_symlink "$DOTFILES_DIR/ripgrep/config" "$HOME/.config/ripgrep/config"

# pi
mkdir -p "$HOME/.pi/agent/themes"
# models.json is copied (not symlinked) — pi writes real API keys into it at runtime
if [[ ! -f "$HOME/.pi/agent/models.json" ]]; then
    cp "$DOTFILES_DIR/pi/models.json" "$HOME/.pi/agent/models.json"
    info "Created ~/.pi/agent/models.json (add API keys there, not in dotfiles)"
else
    info "$HOME/.pi/agent/models.json already exists, skipping"
fi
# settings.json is copied (not symlinked) — pi writes runtime state into it,
# which would otherwise dirty the tracked dotfiles file.
if [[ -L "$HOME/.pi/agent/settings.json" ]]; then
    rm -f "$HOME/.pi/agent/settings.json"
fi
if [[ ! -f "$HOME/.pi/agent/settings.json" ]]; then
    cp "$DOTFILES_DIR/pi/settings.json" "$HOME/.pi/agent/settings.json"
    info "Created ~/.pi/agent/settings.json (pi writes runtime state here)"
else
    info "$HOME/.pi/agent/settings.json already exists, skipping"
fi
create_symlink "$DOTFILES_DIR/pi/themes/catppuccin-macchiato.json" "$HOME/.pi/agent/themes/catppuccin-macchiato.json"

# Linux-only: Hyprland
if [[ "$OS" != "macos" ]]; then
    if [[ -d "$DOTFILES_DIR/hypr" ]]; then
        mkdir -p "$HOME/.config/hypr"
        create_symlink "$DOTFILES_DIR/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
        create_symlink "$DOTFILES_DIR/hypr/bindings.conf" "$HOME/.config/hypr/bindings.conf"
        create_symlink "$DOTFILES_DIR/hypr/plugins.conf" "$HOME/.config/hypr/plugins.conf"

        if command -v hyprctl &> /dev/null && hyprctl monitors &> /dev/null; then
            hyprctl reload &> /dev/null && info "Reloaded Hyprland config"
        fi
    fi
fi
