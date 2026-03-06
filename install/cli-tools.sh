#!/usr/bin/env bash
#
# CLI Tools (Optional)
#

header "CLI Tools"

install_google_cli=false

# Detect which tools are already installed
missing_tools=()
command -v google &>/dev/null && info "Google CLI already installed" || missing_tools+=("Google CLI")

if [[ ${#missing_tools[@]} -eq 0 ]]; then
    info "All CLI tools already installed"
elif has_gum; then
    cli_choices=$(gum choose --no-limit \
        --header "Select CLI tools to install (Space to select, Enter to confirm):" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[x] " \
        "${missing_tools[@]}" || true)

    [[ "$cli_choices" == *"Google CLI"* ]] && install_google_cli=true

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
                done
                ;;
            [Nn]) ;;
            [1-9])
                selected="${missing_tools[$((choice - 1))]:-}"
                if [[ -n "$selected" ]]; then
                    [[ "$selected" == "Google CLI" ]] && install_google_cli=true
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
