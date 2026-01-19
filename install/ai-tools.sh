#!/usr/bin/env bash
#
# AI Coding Assistants (Optional)
#

header "AI Coding Assistants"

install_claude=false
install_codex=false
install_gemini=false
install_opencode=false

if has_gum; then
    ai_choices=$(gum choose --no-limit \
        --header "Select AI coding assistants to install (Space to select, Enter to confirm):" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[x] " \
        "Claude Code" \
        "OpenAI Codex CLI" \
        "Gemini CLI" \
        "OpenCode" || true)

    [[ "$ai_choices" == *"Claude Code"* ]] && install_claude=true
    [[ "$ai_choices" == *"Codex CLI"* ]] && install_codex=true
    [[ "$ai_choices" == *"Gemini CLI"* ]] && install_gemini=true
    [[ "$ai_choices" == *"OpenCode"* ]] && install_opencode=true

    if [[ -z "$ai_choices" ]]; then
        info "Skipping AI coding assistants"
    fi
else
    echo "Which AI coding assistants would you like to install?"
    echo "  1) Claude Code"
    echo "  2) OpenAI Codex CLI"
    echo "  3) Gemini CLI"
    echo "  4) OpenCode"
    echo "  5) All"
    echo "  6) None"
    echo ""
    read -p "Enter choices (e.g., 1 3 or 5 for all): " -a ai_choices

    for choice in "${ai_choices[@]}"; do
        case "$choice" in
            1) install_claude=true ;;
            2) install_codex=true ;;
            3) install_gemini=true ;;
            4) install_opencode=true ;;
            5) install_claude=true; install_codex=true; install_gemini=true; install_opencode=true ;;
            6) ;;
            *) warn "Unknown option: $choice" ;;
        esac
    done
fi

if $install_claude; then
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

if $install_codex; then
    if command -v npm &> /dev/null; then
        info "Installing Codex..."
        npm i -g @openai/codex --force
    else
        warn "npm not found. Install Node.js first (e.g., via mise)."
    fi
fi

if $install_gemini; then
    if command -v npm &> /dev/null; then
        info "Installing Gemini CLI..."
        npm i -g @google/gemini-cli --force
    else
        warn "npm not found. Install Node.js first (e.g., via mise)."
    fi
fi

if $install_opencode; then
    info "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
fi

# Offer oh-my-opencode if OpenCode is installed
if $install_opencode || command -v opencode &> /dev/null; then
    if ask_yes_no "Install oh-my-opencode (enhanced agent harness)?"; then
        info "Installing oh-my-opencode..."
        bunx oh-my-opencode install
    fi
fi

# Offer CodexBar on macOS if any AI tools were installed
if [[ "$OSTYPE" == "darwin"* ]] && ($install_claude || $install_codex || $install_gemini || $install_opencode); then
    if ask_yes_no "Install CodexBar (menu bar usage monitor for AI tools)?"; then
        info "Installing CodexBar..."
        brew install --cask steipete/tap/codexbar
    fi
fi
