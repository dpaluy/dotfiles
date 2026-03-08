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

# Agent Browser — headless browser automation for AI agents (separate prompt)
if command -v agent-browser &>/dev/null; then
    info "agent-browser already installed"
elif ask_yes_no "Install agent-browser (headless browser automation CLI for AI agents)?"; then
    if ensure_node; then
        info "Installing agent-browser..."
        npm install -g agent-browser
        info "Downloading Chromium for agent-browser..."
        agent-browser install
    else
        warn "npm not found and mise unavailable. Install Node.js manually."
    fi
fi

# pi-mcp-adapter — MCP support for pi coding agent (separate prompt)
if command -v pi &>/dev/null; then
    if pi list 2>/dev/null | grep -q 'pi-mcp-adapter'; then
        info "pi-mcp-adapter already installed"
    elif ask_yes_no "Install pi-mcp-adapter (MCP support for pi)?"; then
        info "Installing pi-mcp-adapter..."
        pi install npm:pi-mcp-adapter
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
        sed -e "s|__NODE_PATH__|$NODE_BIN|g" -e "s|__QMD_DIST__|$QMD_DIST|g" \
            "$DOTFILES_DIR/qmd/com.tobilu.qmd.plist" > "$plist"
        # bootout + bootstrap to reload; if not loaded yet, just bootstrap
        if launchctl bootout "gui/$(id -u)/com.tobilu.qmd" 2>/dev/null; then
            while launchctl print "gui/$(id -u)/com.tobilu.qmd" &>/dev/null; do sleep 0.1; done
        fi
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

    # Claude Code — use stdio transport (no auth required)
    if command -v claude &> /dev/null; then
        if ! claude mcp get qmd &>/dev/null; then
            claude mcp add --transport stdio --scope user qmd -- qmd mcp
            info "Registered qmd MCP with Claude Code (stdio)"
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

# ─────────────────────────────────────────────────────────────────────────────
# Perplexity MCP — AI-powered web search for coding assistants
# ─────────────────────────────────────────────────────────────────────────────
perplexity_targets=()
command -v claude &>/dev/null && perplexity_targets+=("Claude Code")
command -v codex &>/dev/null && perplexity_targets+=("Codex")
command -v opencode &>/dev/null && perplexity_targets+=("OpenCode")
command -v pi &>/dev/null && perplexity_targets+=("pi")

if [[ ${#perplexity_targets[@]} -gt 0 ]] && ask_yes_no "Install Perplexity MCP (AI-powered web search)?"; then
    if ! ensure_node; then
        warn "npm not found — cannot install Perplexity MCP"
    else
        # Warn if API key is missing
        if [[ -z "${PERPLEXITY_API_KEY:-}" ]]; then
            warn "PERPLEXITY_API_KEY not set — add it to ~/.local/dotfiles/exports.local"
        fi

        # Ask which tools to register with
        if has_gum; then
            perplexity_choices=$(gum choose --no-limit \
                --header "Register Perplexity MCP with (Space to select, Enter to confirm):" \
                --cursor-prefix "[ ] " \
                --selected-prefix "[x] " \
                "${perplexity_targets[@]}" || true)
        else
            echo "Register Perplexity MCP with which tools?"
            for i in "${!perplexity_targets[@]}"; do
                echo "  $((i + 1))) ${perplexity_targets[$i]}"
            done
            echo "  A) All"
            echo "  N) None"
            echo ""
            read -p "Enter choices (e.g., 1 3 or A for all): " -a perplexity_input
            perplexity_choices=""
            for choice in "${perplexity_input[@]}"; do
                case "$choice" in
                    [Aa]) perplexity_choices="${perplexity_targets[*]}" ;;
                    [Nn]) ;;
                    [1-9])
                        idx=$((choice - 1))
                        [[ -n "${perplexity_targets[$idx]:-}" ]] && perplexity_choices="$perplexity_choices ${perplexity_targets[$idx]}"
                        ;;
                    *) warn "Unknown option: $choice" ;;
                esac
            done
        fi

        # Claude Code — stdio transport (inherits PERPLEXITY_API_KEY from env)
        if [[ "${perplexity_choices:-}" == *"Claude"* ]]; then
            if claude mcp get perplexity &>/dev/null; then
                info "Perplexity MCP already registered with Claude Code"
            else
                claude mcp add perplexity --transport stdio --scope user -e PERPLEXITY_API_KEY="${PERPLEXITY_API_KEY:-}" -- npx -yq @perplexity-ai/mcp-server
                info "Registered Perplexity MCP with Claude Code"
            fi
        fi

        # Codex — de-symlink if needed, then append MCP config
        if [[ "${perplexity_choices:-}" == *"Codex"* ]]; then
            codex_config="$HOME/.codex/config.toml"
            if [[ -f "$codex_config" ]] && grep -q '\[mcp_servers\.perplexity\]' "$codex_config"; then
                info "Perplexity MCP already registered with Codex"
            elif [[ -f "$codex_config" ]]; then
                # De-symlink if needed (config.toml may be symlinked from dotfiles)
                if [[ -L "$codex_config" ]]; then
                    tmp="$(mktemp)"
                    cat "$codex_config" > "$tmp"
                    rm "$codex_config"
                    mv "$tmp" "$codex_config"
                fi
                cat >> "$codex_config" <<TOML

[mcp_servers.perplexity]
command = "npx"
args = ["-yq", "@perplexity-ai/mcp-server"]

[mcp_servers.perplexity.env]
PERPLEXITY_API_KEY = "${PERPLEXITY_API_KEY:-}"
TOML
                info "Registered Perplexity MCP with Codex"
            else
                warn "Codex config not found at ~/.codex/config.toml"
            fi
        fi

        # OpenCode — patch opencode.json with jq
        if [[ "${perplexity_choices:-}" == *"OpenCode"* ]]; then
            oc_config="$HOME/.config/opencode/opencode.json"
            if [[ -f "$oc_config" ]] && command -v jq &>/dev/null; then
                if jq -e '.mcp.perplexity' "$oc_config" &>/dev/null; then
                    info "Perplexity MCP already registered with OpenCode"
                else
                    # De-symlink if needed (opencode.json may be symlinked from dotfiles)
                    if [[ -L "$oc_config" ]]; then
                        tmp="$(mktemp)"
                        cat "$oc_config" > "$tmp"
                        rm "$oc_config"
                        mv "$tmp" "$oc_config"
                    fi
                    jq --arg key "${PERPLEXITY_API_KEY:-}" '.mcp.perplexity = {"type":"local","command":["npx","-yq","@perplexity-ai/mcp-server"],"env":{"PERPLEXITY_API_KEY":$key},"enabled":true}' \
                        "$oc_config" > "$oc_config.tmp" && mv "$oc_config.tmp" "$oc_config"
                    info "Registered Perplexity MCP with OpenCode"
                fi
            else
                warn "OpenCode config not found or jq unavailable"
            fi
        fi

        # pi — requires pi-mcp-adapter for MCP support
        if [[ "${perplexity_choices:-}" == *"pi"* ]]; then
            pi_mcp="$HOME/.pi/agent/mcp.json"
            if command -v jq &>/dev/null; then
                mkdir -p "$HOME/.pi/agent"
                if [[ -f "$pi_mcp" ]]; then
                    jq '.mcpServers.perplexity = {"command":"npx","args":["-yq","@perplexity-ai/mcp-server"],"env":{"PERPLEXITY_API_KEY":"${PERPLEXITY_API_KEY}"},"directTools":true}' \
                        "$pi_mcp" > "$pi_mcp.tmp" && mv "$pi_mcp.tmp" "$pi_mcp"
                else
                    cat > "$pi_mcp" <<'JSON'
{
  "mcpServers": {
    "perplexity": {
      "command": "npx",
      "args": ["-yq", "@perplexity-ai/mcp-server"],
      "env": {
        "PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY}"
      },
      "directTools": true
    }
  }
}
JSON
                fi
                info "Configured Perplexity MCP for pi using PERPLEXITY_API_KEY from the shell environment"
            else
                warn "jq not found — cannot register Perplexity MCP with pi"
            fi
        fi

        if [[ -n "${perplexity_choices:-}" ]]; then
            info "Make sure PERPLEXITY_API_KEY is exported before launching tools that use Perplexity MCP"
        fi
    fi
fi

# Offer CodexBar on macOS if any AI tools were installed
if [[ "$OSTYPE" == "darwin"* ]] && ($install_claude || $install_codex || $install_gemini || $install_opencode || $install_pi || $install_qmd); then
    if brew list --cask steipete/tap/codexbar &>/dev/null; then
        info "CodexBar already installed"
    elif ask_yes_no "Install CodexBar (menu bar usage monitor for AI tools)?"; then
        info "Installing CodexBar..."
        brew install --cask steipete/tap/codexbar
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# AI tool configurations (skipped if tool not installed)
# ─────────────────────────────────────────────────────────────────────────────
source "$DOTFILES_DIR/install/claude.sh"
source "$DOTFILES_DIR/install/codex.sh"
source "$DOTFILES_DIR/install/opencode.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Agent Skills Setup (shared across AI tools)
# ─────────────────────────────────────────────────────────────────────────────
# The Agent Skills standard (agentskills.io) uses ~/.agents/
# Always set up skills if the directory exists — tools may already be installed

if [[ -d "$DOTFILES_DIR/agents/skills" ]]; then
    # ~/.agents/skills: shared Agent Skills standard (agentskills.io)
    if ask_yes_no "Symlink dotfiles skills into ~/.agents/skills?"; then
        mkdir -p "$HOME/.agents/skills"
        for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
            [[ -d "$skill_dir" ]] || continue
            skill_name="$(basename "$skill_dir")"
            create_symlink "$skill_dir" "$HOME/.agents/skills/$skill_name"
        done
    fi

    # ~/.claude/skills: Claude Code skills
    if ($install_claude || command -v claude &> /dev/null) && ask_yes_no "Symlink dotfiles skills into ~/.claude/skills?"; then
        mkdir -p "$HOME/.claude/skills"
        for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
            [[ -d "$skill_dir" ]] || continue
            skill_name="$(basename "$skill_dir")"
            create_symlink "$skill_dir" "$HOME/.claude/skills/$skill_name"
        done
    fi
fi

