#!/usr/bin/env bash
#
# CLI Tools (Optional)
#

header "CLI Tools"

install_gh_dash=false
install_bash_lsp=false

# Detect which tools are already installed
missing_tools=()
gh extension list 2>/dev/null | grep -q "dlvhdr/gh-dash" && info "gh-dash already installed" || missing_tools+=("gh-dash")
command -v bash-language-server &>/dev/null && info "bash-language-server already installed" || missing_tools+=("bash-language-server")

if [[ ${#missing_tools[@]} -eq 0 ]]; then
    info "All CLI tools already installed"
elif has_gum; then
    cli_choices=$(gum choose --no-limit \
        --header "Select CLI tools to install (Space to select, Enter to confirm):" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[x] " \
        "${missing_tools[@]}" || true)

    [[ "$cli_choices" == *"gh-dash"* ]] && install_gh_dash=true
    [[ "$cli_choices" == *"bash-language-server"* ]] && install_bash_lsp=true

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
    read -r -p "Enter choices (e.g., 1 3 or A for all): " -a cli_choices

    for choice in "${cli_choices[@]}"; do
        case "$choice" in
            [Aa])
                for tool in "${missing_tools[@]}"; do
                    [[ "$tool" == "gh-dash" ]] && install_gh_dash=true
                    [[ "$tool" == "bash-language-server" ]] && install_bash_lsp=true
                done
                ;;
            [Nn]) ;;
            [1-9])
                selected="${missing_tools[$((choice - 1))]:-}"
                if [[ -n "$selected" ]]; then
                    [[ "$selected" == "gh-dash" ]] && install_gh_dash=true
                    [[ "$selected" == "bash-language-server" ]] && install_bash_lsp=true
                else
                    warn "Unknown option: $choice"
                fi
                ;;
            *) warn "Unknown option: $choice" ;;
        esac
    done
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

if $install_bash_lsp; then
    if command -v npm &>/dev/null; then
        info "Installing bash-language-server..."
        npm install -g bash-language-server
        info "bash-language-server installed"
    else
        warn "npm not found. Install Node.js (e.g., via mise) to use bash-language-server."
    fi
fi
