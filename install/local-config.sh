#!/usr/bin/env bash
#
# Local configuration templates (private, not version controlled)
#

header "Local Configuration"

info "Setting up local dotfiles directory..."

mkdir -p "$DOTFILES_LOCAL"

create_local_template "$DOTFILES_LOCAL/aliases.local" "Local aliases"
create_local_template "$DOTFILES_LOCAL/functions.local" "Local shell functions"
create_local_template "$DOTFILES_LOCAL/exports.local" "Local environment variables (API keys, tokens, etc.)"
create_local_template "$DOTFILES_LOCAL/path.local" "Local PATH additions"
create_local_template "$DOTFILES_LOCAL/ghostty.local" "Local ghostty overrides (font, size, theme)"
create_local_template "$DOTFILES_LOCAL/ai.local" "Local AI tool settings (API keys, model preferences)"
create_local_template "$DOTFILES_LOCAL/rails.local" "Local Rails/Ruby settings"
create_local_template "$DOTFILES_LOCAL/projects.local" "Project-to-theme mappings for terminal theming"

# ------------------------------------------------------------------------------
# Git Configuration (name, email)
# ------------------------------------------------------------------------------

setup_git_config() {
    local gitconfig_file="$DOTFILES_LOCAL/gitconfig.local"

    # Check if git user is already configured
    if git config --get user.name &>/dev/null && git config --get user.email &>/dev/null; then
        info "Git user already configured"
        return
    fi

    # Check if gitconfig.local already has [user] section with actual values
    if [[ -f "$gitconfig_file" ]] && grep -q "^\[user\]" "$gitconfig_file" && \
       grep -q "^[[:space:]]*name = [^#]" "$gitconfig_file"; then
        info "Git config already set in gitconfig.local"
        return
    fi

    info "Setting up Git identity..."

    local git_name git_email

    if has_gum; then
        git_name=$(gum input --placeholder "Your Name" --header "Git user name:")
        git_email=$(gum input --placeholder "you@example.com" --header "Git email:")
    else
        read -p "Git user name: " git_name
        read -p "Git email: " git_email
    fi

    if [[ -n "$git_name" && -n "$git_email" ]]; then
        # Create or overwrite gitconfig.local with actual values
        cat > "$gitconfig_file" << EOF
# Local git config (name, email, signing keys)
# This file is not version controlled - add machine-specific settings here

[user]
    name = $git_name
    email = $git_email

# Optional: GPG signing
# [user]
#     signingkey = YOUR_GPG_KEY_ID
# [commit]
#     gpgsign = true
EOF
        info "Git identity configured: $git_name <$git_email>"
    else
        create_local_template "$gitconfig_file" "Local git config (name, email, signing keys)"
        warn "Git identity not set. Edit $gitconfig_file manually."
    fi
}

setup_git_config

# Add example content to projects.local if empty
if [[ $(wc -l < "$DOTFILES_LOCAL/projects.local") -le 3 ]]; then
    cat >> "$DOTFILES_LOCAL/projects.local" << 'EOF'
# Format: "path_prefix:theme_name:tab_title"
# Theme applies to the directory and all subdirectories
# Available themes: run 'theme --list' to see all options
#
# Example:
# PROJECT_THEMES=(
#     "$HOME/projects/myapp:ember:MyApp"
#     "$HOME/work/client:ocean:Client"
# )

PROJECT_THEMES=()
EOF
fi
