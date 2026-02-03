#!/usr/bin/env bash
#
# Interactive AI Skills Installer
# Usage: ./install/skills.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SKILLS_SRC="$DOTFILES_DIR/agents/skills"

# ------------------------------------------------------------------------------
# Target destinations
# ------------------------------------------------------------------------------
get_target_dir() {
    case "$1" in
        codex) echo "$HOME/.codex/skills" ;;
        claude) echo "$HOME/.claude/skills" ;;
    esac
}

# ------------------------------------------------------------------------------
# List available skills
# ------------------------------------------------------------------------------
list_skills() {
    for skill_dir in "$SKILLS_SRC"/*/; do
        [[ -d "$skill_dir" ]] && basename "$skill_dir"
    done
}

# ------------------------------------------------------------------------------
# Install skill to target
# ------------------------------------------------------------------------------
install_skill() {
    local skill_name="$1"
    local target_type="$2"
    local target_dir="$3"

    local skill_src="$SKILLS_SRC/$skill_name"

    case "$target_type" in
        codex)
            # Codex: symlink entire skill folder
            mkdir -p "$target_dir"
            local dest="$target_dir/$skill_name"
            if [[ -e "$dest" ]]; then
                warn "Already exists: $dest"
            else
                ln -s "$skill_src" "$dest"
                info "Installed $skill_name to Codex"
            fi
            ;;
        claude)
            # Claude: symlink entire skill folder
            mkdir -p "$target_dir"
            local dest="$target_dir/$skill_name"
            if [[ -e "$dest" ]]; then
                warn "Already exists: $dest"
            else
                ln -s "$skill_src" "$dest"
                info "Installed $skill_name to Claude"
            fi
            ;;
        folder)
            # Custom folder: symlink entire skill folder
            mkdir -p "$target_dir"
            local dest="$target_dir/$skill_name"
            if [[ -e "$dest" ]]; then
                warn "Already exists: $dest"
            else
                ln -s "$skill_src" "$dest"
                info "Installed $skill_name to $target_dir"
            fi
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
header "AI Skills Installer"

# Get available skills
skills=($(list_skills))
if [[ ${#skills[@]} -eq 0 ]]; then
    error "No skills found in $SKILLS_SRC"
    exit 1
fi

# Select targets (multi-select)
install_codex=false
install_claude=false
install_folder=false
custom_dir=""

if has_gum; then
    target_choices=$(gum choose --no-limit \
        --header "Select targets (Space to select, Enter to confirm):" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[x] " \
        "Codex (~/.codex/skills/)" \
        "Claude (~/.claude/skills/)" \
        "Custom folder" || true)

    [[ "$target_choices" == *"Codex"* ]] && install_codex=true
    [[ "$target_choices" == *"Claude"* ]] && install_claude=true
    [[ "$target_choices" == *"Custom"* ]] && install_folder=true
else
    echo "Select targets (comma-separated, e.g., 1,2):"
    echo "  1) Codex (~/.codex/skills/)"
    echo "  2) Claude (~/.claude/skills/)"
    echo "  3) Custom folder"
    read -p "Choice: " choice
    [[ "$choice" == *"1"* ]] && install_codex=true
    [[ "$choice" == *"2"* ]] && install_claude=true
    [[ "$choice" == *"3"* ]] && install_folder=true
fi

if ! $install_codex && ! $install_claude && ! $install_folder; then
    error "No targets selected"
    exit 1
fi

# Get custom folder path if selected
if $install_folder; then
    if has_gum; then
        custom_dir=$(gum input --placeholder "/path/to/skills" --header "Custom folder path:")
    else
        read -p "Custom folder path: " custom_dir
    fi
fi

# Select skills (multi-select)
if has_gum; then
    skill_choices=$(gum choose --no-limit \
        --header "Select skills (Space to select, Enter to confirm):" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[x] " \
        "${skills[@]}" || true)
else
    echo "Available skills: ${skills[*]}"
    read -p "Enter skill names (space-separated, or 'all'): " skill_choices
    [[ "$skill_choices" == "all" ]] && skill_choices="${skills[*]}"
fi

[[ -z "$skill_choices" ]] && { error "No skills selected"; exit 1; }

# Install selected skills to each target
for skill in "${skills[@]}"; do
    [[ "$skill_choices" != *"$skill"* ]] && continue

    $install_codex && install_skill "$skill" "codex" "$(get_target_dir codex)"
    $install_claude && install_skill "$skill" "claude" "$(get_target_dir claude)"
    $install_folder && install_skill "$skill" "folder" "$custom_dir"
done

info "Done!"
