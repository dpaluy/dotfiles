#!/usr/bin/env bash
#
# AI Coding Assistants (Optional)
#

header "AI Coding Assistants"

install_claude=false
install_codex=false
install_gemini=false
install_opencode=false
install_pi=false
install_qmd=false

# Detect which tools are already installed
missing_tools=()
command -v claude &>/dev/null && info "Claude Code already installed" || missing_tools+=("Claude Code")
command -v codex &>/dev/null && info "OpenAI Codex CLI already installed" || missing_tools+=("OpenAI Codex CLI")
command -v gemini &>/dev/null && info "Gemini CLI already installed" || missing_tools+=("Gemini CLI")
command -v opencode &>/dev/null && info "OpenCode already installed" || missing_tools+=("OpenCode")
command -v pi &>/dev/null && info "pi already installed" || missing_tools+=("pi (coding agent)")
command -v qmd &>/dev/null && info "qmd already installed" || missing_tools+=("qmd (local markdown search)")

if [[ ${#missing_tools[@]} -eq 0 ]]; then
    info "All AI coding assistants already installed"
elif has_gum; then
    ai_choices=$(gum choose --no-limit \
        --header "Select AI coding assistants to install (Space to select, Enter to confirm):" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[x] " \
        "${missing_tools[@]}" || true)

    [[ "$ai_choices" == *"Claude Code"* ]] && install_claude=true
    [[ "$ai_choices" == *"Codex CLI"* ]] && install_codex=true
    [[ "$ai_choices" == *"Gemini CLI"* ]] && install_gemini=true
    [[ "$ai_choices" == *"OpenCode"* ]] && install_opencode=true
    [[ "$ai_choices" == *"pi"* ]] && install_pi=true
    [[ "$ai_choices" == *"qmd"* ]] && install_qmd=true

    if [[ -z "$ai_choices" ]]; then
        info "Skipping AI coding assistants"
    fi
else
    echo "Which AI coding assistants would you like to install?"
    for i in "${!missing_tools[@]}"; do
        echo "  $((i + 1))) ${missing_tools[$i]}"
    done
    echo "  A) All"
    echo "  N) None"
    echo ""
    read -p "Enter choices (e.g., 1 3 or A for all): " -a ai_choices

    for choice in "${ai_choices[@]}"; do
        case "$choice" in
            [Aa])
                for tool in "${missing_tools[@]}"; do
                    [[ "$tool" == "Claude Code" ]] && install_claude=true
                    [[ "$tool" == *"Codex"* ]] && install_codex=true
                    [[ "$tool" == *"Gemini"* ]] && install_gemini=true
                    [[ "$tool" == "OpenCode" ]] && install_opencode=true
                    [[ "$tool" == *"pi"* ]] && install_pi=true
                    [[ "$tool" == *"qmd"* ]] && install_qmd=true
                done
                ;;
            [Nn]) ;;
            [1-9])
                selected="${missing_tools[$((choice - 1))]:-}"
                if [[ -n "$selected" ]]; then
                    [[ "$selected" == "Claude Code" ]] && install_claude=true
                    [[ "$selected" == *"Codex"* ]] && install_codex=true
                    [[ "$selected" == *"Gemini"* ]] && install_gemini=true
                    [[ "$selected" == "OpenCode" ]] && install_opencode=true
                    [[ "$selected" == *"pi"* ]] && install_pi=true
                    [[ "$selected" == *"qmd"* ]] && install_qmd=true
                else
                    warn "Unknown option: $choice"
                fi
                ;;
            *) warn "Unknown option: $choice" ;;
        esac
    done
fi

if $install_claude; then
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
fi

if $install_codex; then
    if ensure_node; then
        info "Installing Codex..."
        npm i -g @openai/codex --force
    else
        warn "npm not found and mise unavailable. Install Node.js manually."
    fi
fi

if $install_gemini; then
    if ensure_node; then
        info "Installing Gemini CLI..."
        npm i -g @google/gemini-cli --force
    else
        warn "npm not found and mise unavailable. Install Node.js manually."
    fi
fi

if $install_opencode; then
    info "Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
fi

if $install_pi; then
    if ensure_node; then
        info "Installing pi..."
        npm install -g @mariozechner/pi-coding-agent
    else
        warn "npm not found and mise unavailable. Install Node.js manually."
    fi
fi

if $install_qmd; then
    if command -v bun &>/dev/null; then
        info "Installing qmd (local markdown search)..."
        # macOS requires Homebrew's SQLite for extension support
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install sqlite 2>/dev/null || true
        fi
        bun install -g @tobilu/qmd
    else
        warn "bun not found. Install bun first (qmd requires bun runtime)."
    fi
fi

# Agent Browser — headless browser automation for AI agents (Rust native binary)
if command -v agent-browser &>/dev/null; then
    info "agent-browser already installed"
elif ask_yes_no "Install agent-browser (headless browser automation CLI for AI agents)?"; then
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &>/dev/null; then
        info "Installing agent-browser via Homebrew..."
        brew install agent-browser
    elif command -v cargo &>/dev/null; then
        info "Installing agent-browser via cargo..."
        cargo install agent-browser
    else
        warn "cargo not found. Install Rust (https://rustup.rs) first."
    fi
    if command -v agent-browser &>/dev/null; then
        info "Downloading Chromium for agent-browser..."
        if [[ "$OSTYPE" == "linux"* ]]; then
            agent-browser install --with-deps
        else
            agent-browser install
        fi
    fi
fi

# RTK — token compression proxy for AI coding tools (Rust binary)
if command -v rtk &>/dev/null; then
    info "rtk already installed"
elif ask_yes_no "Install rtk (token compression proxy — saves 60-90% tokens in AI coding sessions)?"; then
    info "Installing rtk via official installer..."
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | bash
fi

# Configure rtk hooks (runs for both fresh and existing installs)
if command -v rtk &>/dev/null; then
    mkdir -p "$HOME/.config/rtk"
    cp "$DOTFILES_DIR/rtk/config.toml" "$HOME/.config/rtk/config.toml"
    export RTK_TELEMETRY_DISABLED=1
    if command -v claude &>/dev/null; then
        info "Setting up rtk hooks for Claude Code..."
        rtk init -g --auto-patch
    fi
    if command -v codex &>/dev/null; then
        info "Setting up rtk for Codex CLI..."
        # Creates ~/.codex/RTK.md (referenced by @RTK.md in AGENTS.md)
        # Don't use rtk init --codex here — it rewrites AGENTS.md and breaks our symlink
        mkdir -p "$HOME/.codex"
        rtk init -g --codex 2>/dev/null || true
        # Re-establish symlink in case rtk init replaced it
        create_symlink "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
    fi
    if command -v opencode &>/dev/null; then
        info "Setting up rtk plugin for OpenCode..."
        rtk init -g --opencode --auto-patch
    fi
fi

# pi extensions
source "$DOTFILES_DIR/install/pi.sh"

# Offer CodexBar on macOS if any AI tools were installed
if [[ "$OSTYPE" == "darwin"* ]] && ($install_claude || $install_codex || $install_gemini || $install_opencode || $install_pi || $install_qmd); then
    if brew list --cask steipete/tap/codexbar &>/dev/null; then
        info "CodexBar already installed"
    elif ask_yes_no "Install CodexBar (menu bar usage monitor for AI tools)?"; then
        info "Installing CodexBar..."
        brew install --cask steipete/tap/codexbar
    fi
fi

# MCP server registration (qmd, Perplexity)
source "$DOTFILES_DIR/install/mcp.sh"

# AI tool configurations (skipped if tool not installed)
source "$DOTFILES_DIR/install/claude.sh"
source "$DOTFILES_DIR/install/codex.sh"
source "$DOTFILES_DIR/install/opencode.sh"

# Agent skills + external skill repos
source "$DOTFILES_DIR/install/skills.sh"
