#!/usr/bin/env bash
#
# CLI Tools (Optional)
#

header "CLI Tools"

install_google_cli=false
install_gh_dash=false

# Detect which tools are already installed
missing_tools=()
command -v gws &>/dev/null && info "Google CLI already installed" || missing_tools+=("Google CLI")
gh extension list 2>/dev/null | grep -q "dlvhdr/gh-dash" && info "gh-dash already installed" || missing_tools+=("gh-dash")

if [[ ${#missing_tools[@]} -eq 0 ]]; then
    info "All CLI tools already installed"
elif has_gum; then
    cli_choices=$(gum choose --no-limit \
        --header "Select CLI tools to install (Space to select, Enter to confirm):" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[x] " \
        "${missing_tools[@]}" || true)

    [[ "$cli_choices" == *"Google CLI"* ]] && install_google_cli=true
    [[ "$cli_choices" == *"gh-dash"* ]] && install_gh_dash=true

    if [[ -z "$cli_choices" ]]; then
        info "Skipping CLI tools"
    fi
else
    echo "Which CLI tools would you like to install?"
    for i in "${!missing_tools[@]}"; do
        echo "  $((i + 1))) ${missing_tools[$i]}"
    done
    echo "  A) All"
    echo "  N) None"
    echo ""
    read -p "Enter choices (e.g., 1 3 or A for all): " -a cli_choices

    for choice in "${cli_choices[@]}"; do
        case "$choice" in
            [Aa])
                for tool in "${missing_tools[@]}"; do
                    [[ "$tool" == "Google CLI" ]] && install_google_cli=true
                    [[ "$tool" == "gh-dash" ]] && install_gh_dash=true
                done
                ;;
            [Nn]) ;;
            [1-9])
                selected="${missing_tools[$((choice - 1))]:-}"
                if [[ -n "$selected" ]]; then
                    [[ "$selected" == "Google CLI" ]] && install_google_cli=true
                    [[ "$selected" == "gh-dash" ]] && install_gh_dash=true
                else
                    warn "Unknown option: $choice"
                fi
                ;;
            *) warn "Unknown option: $choice" ;;
        esac
    done
fi

if $install_google_cli; then
    if ensure_node; then
        info "Installing Google CLI..."
        npm install -g @googleworkspace/cli
    else
        warn "npm not found and mise unavailable. Install Node.js manually."
    fi
fi

if $install_gh_dash; then
    if command -v gh &>/dev/null; then
        info "Installing gh-dash..."
        gh extension install dlvhdr/gh-dash
        info "gh-dash installed — run 'gh dash' to launch"
    else
        warn "gh (GitHub CLI) not found. Install it first."
    fi
fi
