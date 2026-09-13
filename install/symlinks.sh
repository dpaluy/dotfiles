#!/usr/bin/env bash
#
# Configuration symlinks
#

header "Symlinks"

info "Creating symlinks..."

# Zsh environment - use a wrapper so machine-local additions remain possible.
# .zshenv is loaded by interactive and non-interactive zsh processes.
ensure_zsh_wrapper() {
    local name="$1"
    local wrapper="$HOME/.$name"
    local input="$wrapper" tmp has_source=false
    tmp="$(mktemp)" || return "$?"

    # A direct link to the shared script becomes a source-only wrapper.
    # Other local files and linked wrappers retain their existing contents.
    if [[ ! -f "$wrapper" ]] || { [[ -L "$wrapper" ]] && [[ "$wrapper" -ef "$DOTFILES_DIR/zsh/$name" ]]; }; then
        input=/dev/null
    fi
    if grep -Eq "^[[:space:]]*(source|\.)[[:space:]]+.*[/]zsh[/]$name[\"']?[[:space:]]*(#.*)?$" "$input"; then
        has_source=true
    fi
    DOTFILES_WRAPPER_ROOT="$DOTFILES_DIR" DOTFILES_WRAPPER_NAME="$name" \
        DOTFILES_WRAPPER_HAS_SOURCE="$has_source" awk '
        BEGIN {
            root = ENVIRON["DOTFILES_WRAPPER_ROOT"]
            name = ENVIRON["DOTFILES_WRAPPER_NAME"]
            pattern = "^[[:space:]]*(source|\\.)[[:space:]]+.*[/]zsh[/]" name "[\"\047]?[[:space:]]*(#.*)?$"
            if (ENVIRON["DOTFILES_WRAPPER_HAS_SOURCE"] != "true") {
                print "export DOTFILES_DIR=\"" root "\""
                print "source \"" root "/zsh/" name "\""
                configured = root_set = 1
            }
        }
        /^[[:space:]]*export[[:space:]]+DOTFILES_DIR=/ {
            if (!root_set++) print "export DOTFILES_DIR=\"" root "\""
            next
        }
        $0 ~ pattern {
            if (!configured++) {
                if (!root_set++) print "export DOTFILES_DIR=\"" root "\""
                print "source \"" root "/zsh/" name "\""
            }
            next
        }
        { print }
    ' "$input" > "$tmp" || { rm -f "$tmp"; return 1; }
    if [[ ! -L "$wrapper" ]] && cmp -s "$tmp" "$wrapper"; then
        rm -f "$tmp"
    else
        mv -f "$tmp" "$wrapper"
    fi
    info "Configured ~/.$name wrapper"
}

ensure_zsh_wrapper zshenv

# Login shells load /etc/zprofile after .zshenv. On macOS, path_helper can move
# system paths ahead of mise, so reapply the shared environment afterward.
ensure_zsh_wrapper zprofile

# Zsh - use wrapper pattern (local file sources dotfiles)
# This allows external tools (mise, atuin, fzf) to safely append their init lines
ensure_zsh_wrapper zshrc

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
        local configured_path
        while IFS= read -r configured_path; do
            if [[ "$configured_path" == "$include_path" ]] \
                || { [[ "$DOTFILES_DIR" == "$HOME/dotfiles" ]] && [[ "$configured_path" == "$legacy_include_path" ]]; }; then
                info "Git wrapper already configured"
                return 0
            fi
        done < <(git config --file "$wrapper" --get-all include.path || true)
    fi

    local tmp
    tmp="$(mktemp)" || return "$?"
    git config --file "$tmp" --add include.path "$include_path"
    # Shared defaults go first so existing machine settings still take priority.
    if [[ -f "$wrapper" ]] && ! { [[ -L "$wrapper" ]] && [[ "$wrapper" -ef "$include_path" ]]; }; then
        printf '\n' >> "$tmp"
        cat "$wrapper" >> "$tmp"
    fi
    mv -f "$tmp" "$wrapper"

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

# Hunk (review-first terminal diff viewer)
if command -v hunk &>/dev/null || [[ -x "$HOME/.hunk/bin/hunk" ]]; then
    mkdir -p "$HOME/.config/hunk"
    create_symlink "$DOTFILES_DIR/hunk/config.toml" "$HOME/.config/hunk/config.toml"
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

# Atuin (shell history + AI)
if command -v atuin &>/dev/null; then
    create_symlink "$DOTFILES_DIR/atuin/config.toml" "$HOME/.config/atuin/config.toml"
fi

# pi
mkdir -p "$HOME/.pi/agent/themes"
# models.json is copied (not symlinked) — pi writes real API keys into it at runtime
if [[ ! -f "$HOME/.pi/agent/models.json" ]]; then
    cp "$DOTFILES_DIR/pi/models.json" "$HOME/.pi/agent/models.json"
    info "Created ~/.pi/agent/models.json (add API keys there, not in dotfiles)"
else
    info "$HOME/.pi/agent/models.json already exists, skipping"
fi
# Use the shared settings directly, including package and model selections.
create_symlink "$DOTFILES_DIR/pi/settings.json" "$HOME/.pi/agent/settings.json"
create_symlink "$DOTFILES_DIR/pi/pi-fusion.json" "$HOME/.pi/agent/pi-fusion.json"
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
