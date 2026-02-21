#!/usr/bin/env bash
#
# AI Coding Assistants (Optional)
#

header "AI Coding Assistants"

# ------------------------------------------------------------------------------
# Helper: Ensure Node.js and Bun are available via mise
# ------------------------------------------------------------------------------
ensure_js_runtimes() {
    if command -v mise &> /dev/null; then
        if ! command -v npm &> /dev/null; then
            info "Installing Node.js via mise..."
            mise use --global node@lts
        fi
        if ! command -v bun &> /dev/null; then
            info "Installing Bun via mise..."
            mise use --global bun@latest
        fi
        eval "$(mise activate bash)"
        export PATH="$HOME/.cache/.bun/bin:$PATH"
    fi
}

ensure_node() {
    command -v npm &> /dev/null && return 0
    ensure_js_runtimes
    command -v npm &> /dev/null
}

ensure_bun() {
    command -v bun &> /dev/null && return 0
    ensure_js_runtimes
    command -v bun &> /dev/null
}

install_claude=false
install_codex=false
install_gemini=false
install_opencode=false
install_qmd=false

if has_gum; then
    ai_choices=$(gum choose --no-limit \
        --header "Select AI coding assistants to install (Space to select, Enter to confirm):" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[x] " \
        "Claude Code" \
        "OpenAI Codex CLI" \
        "Gemini CLI" \
        "OpenCode" \
        "qmd (local markdown search)" || true)

    [[ "$ai_choices" == *"Claude Code"* ]] && install_claude=true
    [[ "$ai_choices" == *"Codex CLI"* ]] && install_codex=true
    [[ "$ai_choices" == *"Gemini CLI"* ]] && install_gemini=true
    [[ "$ai_choices" == *"OpenCode"* ]] && install_opencode=true
    [[ "$ai_choices" == *"qmd"* ]] && install_qmd=true

    if [[ -z "$ai_choices" ]]; then
        info "Skipping AI coding assistants"
    fi
else
    echo "Which AI coding assistants would you like to install?"
    echo "  1) Claude Code"
    echo "  2) OpenAI Codex CLI"
    echo "  3) Gemini CLI"
    echo "  4) OpenCode"
    echo "  5) qmd (local markdown search)"
    echo "  6) All"
    echo "  7) None"
    echo ""
    read -p "Enter choices (e.g., 1 3 or 6 for all): " -a ai_choices

    for choice in "${ai_choices[@]}"; do
        case "$choice" in
            1) install_claude=true ;;
            2) install_codex=true ;;
            3) install_gemini=true ;;
            4) install_opencode=true ;;
            5) install_qmd=true ;;
            6) install_claude=true; install_codex=true; install_gemini=true; install_opencode=true; install_qmd=true ;;
            7) ;;
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

if $install_qmd; then
    if ensure_node; then
        info "Installing qmd (local markdown search)..."
        # macOS requires Homebrew's SQLite for extension support
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install sqlite 2>/dev/null || true
        fi
        npm install -g @tobilu/qmd
    else
        warn "npm not found and mise unavailable. Install Node.js manually."
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# qmd MCP daemon — register with all installed AI tools
# ─────────────────────────────────────────────────────────────────────────────
if command -v qmd &> /dev/null; then
    QMD_MCP_URL="http://localhost:8181/mcp"

    # Install and start qmd MCP daemon service
    # Resolve node + qmd dist.js to avoid PATH issues in service managers
    NODE_BIN="$(command -v node)"
    QMD_DIST="$(npm root -g)/@tobilu/qmd/dist/qmd.js"
    if [[ ! -f "$QMD_DIST" ]]; then
        warn "qmd dist not found at $QMD_DIST — skipping service install"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        plist="$HOME/Library/LaunchAgents/com.tobilu.qmd.plist"
        launchctl bootout "gui/$(id -u)/com.tobilu.qmd" 2>/dev/null || true
        sed -e "s|__NODE_PATH__|$NODE_BIN|g" -e "s|__QMD_DIST__|$QMD_DIST|g" \
            "$DOTFILES_DIR/qmd/com.tobilu.qmd.plist" > "$plist"
        launchctl bootstrap "gui/$(id -u)" "$plist"
        info "Installed qmd MCP launchd service ($NODE_BIN → $QMD_DIST)"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        unit_dir="$HOME/.config/systemd/user"
        mkdir -p "$unit_dir"
        sed -e "s|__NODE_PATH__|$NODE_BIN|g" -e "s|__QMD_DIST__|$QMD_DIST|g" \
            "$DOTFILES_DIR/qmd/qmd-mcp.service" > "$unit_dir/qmd-mcp.service"
        systemctl --user daemon-reload
        systemctl --user enable --now qmd-mcp.service
        info "Installed qmd MCP systemd user service ($NODE_BIN → $QMD_DIST)"
    fi

    # Claude Code
    if command -v claude &> /dev/null; then
        if ! claude mcp get qmd &>/dev/null; then
            claude mcp add --transport http --scope user qmd "$QMD_MCP_URL"
            info "Registered qmd MCP with Claude Code"
        fi
    fi

    # Codex — config.toml is copied, not symlinked; patch if missing
    if command -v codex &> /dev/null && [[ -f "$HOME/.codex/config.toml" ]]; then
        if ! grep -q '\[mcp_servers\.qmd\]' "$HOME/.codex/config.toml"; then
            cat >> "$HOME/.codex/config.toml" <<TOML

[mcp_servers.qmd]
url = "$QMD_MCP_URL"
TOML
            info "Registered qmd MCP with Codex"
        fi
    fi

    # OpenCode — symlinked from dotfiles, already includes qmd MCP
    if command -v opencode &> /dev/null; then
        info "qmd MCP already configured in opencode.json (via dotfiles symlink)"
    fi
fi

# Offer CodexBar on macOS if any AI tools were installed
if [[ "$OSTYPE" == "darwin"* ]] && ($install_claude || $install_codex || $install_gemini || $install_opencode || $install_qmd); then
    if ask_yes_no "Install CodexBar (menu bar usage monitor for AI tools)?"; then
        info "Installing CodexBar..."
        brew install --cask steipete/tap/codexbar
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Agent Skills Setup (shared across AI tools)
# ─────────────────────────────────────────────────────────────────────────────
# The Agent Skills standard (agentskills.io) uses ~/.agents/
# Only set up skills for tools the user chose to install

if [[ -d "$DOTFILES_DIR/agents" ]] && ($install_claude || $install_codex); then
    info "Setting up Agent Skills..."

    # ~/.agents → dotfiles/agents (canonical location)
    create_symlink "$DOTFILES_DIR/agents" "$HOME/.agents"

    # Claude Code needs skills symlinked into ~/.claude/
    if $install_claude; then
        mkdir -p "$HOME/.claude"
        create_symlink "$HOME/.agents/skills" "$HOME/.claude/skills"
    fi
fi
