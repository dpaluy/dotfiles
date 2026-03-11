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
    local gitconfig_file="$HOME/.config/git/config"

    # Check if git user is already configured
    if git config --get user.name &>/dev/null && git config --get user.email &>/dev/null; then
        info "Git user already configured"
        return
    fi

    # Check if ~/.config/git/config already has [user] section with actual values
    if [[ -f "$gitconfig_file" ]] && grep -q "^\[user\]" "$gitconfig_file" && \
       grep -q "^[[:space:]]*name = [^#]" "$gitconfig_file"; then
        info "Git config already set in ~/.config/git/config"
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
        git config --file "$gitconfig_file" user.name "$git_name"
        git config --file "$gitconfig_file" user.email "$git_email"
        info "Git identity configured: $git_name <$git_email>"
    else
        warn "Git identity not set. Edit $gitconfig_file manually."
    fi
}

setup_git_config

# ------------------------------------------------------------------------------
# GPG Commit Signing
# ------------------------------------------------------------------------------

setup_gpg_signing() {
    local gitconfig_file="$HOME/.config/git/config"

    if ! ask_yes_no "Set up GPG commit signing?" "n"; then
        return
    fi

    if ! command -v gpg &>/dev/null; then
        warn "gpg not found. Install gnupg first, then re-run."
        return
    fi

    local key_output
    key_output=$(gpg --list-secret-keys --keyid-format long 2>/dev/null)

    if [[ -z "$key_output" ]]; then
        warn "No GPG secret keys found."
        GPG_NEEDS_SETUP=true
        return
    fi

    info "Available GPG secret keys:"
    echo "$key_output"
    echo ""

    # Extract key IDs (long format after sec rsa.../KEY_ID)
    local key_ids=()
    while IFS= read -r line; do
        key_ids+=("$line")
    done < <(echo "$key_output" | grep -E '^\s+[A-F0-9]{16,}' | sed 's/^[[:space:]]*//')

    if [[ ${#key_ids[@]} -eq 0 ]]; then
        # Fallback: try parsing from sec line (sec rsa4096/KEY_ID date)
        while IFS= read -r line; do
            key_ids+=("$line")
        done < <(echo "$key_output" | grep '^sec' | sed 's|.*/\([A-F0-9]*\).*|\1|')
    fi

    if [[ ${#key_ids[@]} -eq 0 ]]; then
        warn "Could not parse key IDs. Set manually in $gitconfig_file"
        return
    fi

    local selected_key
    if [[ ${#key_ids[@]} -eq 1 ]]; then
        selected_key="${key_ids[0]}"
        info "Using key: $selected_key"
    elif has_gum; then
        selected_key=$(printf '%s\n' "${key_ids[@]}" | gum choose --header "Select a GPG key:")
    else
        echo "Select a GPG key:"
        local i=1
        for kid in "${key_ids[@]}"; do
            echo "  $i) $kid"
            ((i++))
        done
        local choice
        read -p "Enter number: " choice
        selected_key="${key_ids[$((choice - 1))]}"
    fi

    if [[ -z "$selected_key" ]]; then
        warn "No key selected."
        return
    fi

    git config --file "$gitconfig_file" user.signingkey "$selected_key"
    git config --file "$gitconfig_file" commit.gpgsign true
    info "GPG signing configured with key $selected_key"
}

setup_gpg_signing

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
