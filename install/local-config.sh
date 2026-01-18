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
create_local_template "$DOTFILES_LOCAL/gitconfig.local" "Local git config (name, email, signing keys)"
create_local_template "$DOTFILES_LOCAL/ghostty.local" "Local ghostty overrides (font, size, theme)"
create_local_template "$DOTFILES_LOCAL/ai.local" "Local AI tool settings (API keys, model preferences)"
create_local_template "$DOTFILES_LOCAL/rails.local" "Local Rails/Ruby settings"
create_local_template "$DOTFILES_LOCAL/projects.local" "Project-to-theme mappings for terminal theming"

# Add example content to gitconfig.local if empty
if [[ $(wc -l < "$DOTFILES_LOCAL/gitconfig.local") -le 3 ]]; then
    cat >> "$DOTFILES_LOCAL/gitconfig.local" << 'EOF'
# Example:
# [user]
#     name = Your Name
#     email = your.email@example.com
#     signingkey = YOUR_GPG_KEY_ID
#
# [commit]
#     gpgsign = true
EOF
fi

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
