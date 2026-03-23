#!/usr/bin/env bash
#
# MCP Server Registration (qmd, Perplexity)
# Registers MCP servers with installed AI coding assistants
#

# ─────────────────────────────────────────────────────────────────────────────
# qmd MCP daemon — register with all installed AI tools
# ─────────────────────────────────────────────────────────────────────────────
if command -v qmd &> /dev/null; then
    QMD_MCP_URL="http://localhost:8181/mcp"

    # Install and start qmd MCP daemon service.
    # Use the discovered qmd executable directly; service managers can execute
    # symlinks, and this avoids introducing a python3 dependency just to
    # canonicalize the path.
    QMD_BIN="$(command -v qmd)"
    BUN_DIR="$(dirname "$(command -v bun)")"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        plist="$HOME/Library/LaunchAgents/com.tobilu.qmd.plist"
        sed -e "s|__QMD_BIN__|$QMD_BIN|g" -e "s|__BUN_DIR__|$BUN_DIR|g" \
            "$DOTFILES_DIR/qmd/com.tobilu.qmd.plist" > "$plist"
        # bootout + bootstrap to reload; if not loaded yet, just bootstrap
        if launchctl bootout "gui/$(id -u)/com.tobilu.qmd" 2>/dev/null; then
            while launchctl print "gui/$(id -u)/com.tobilu.qmd" &>/dev/null; do sleep 0.1; done
        fi
        launchctl bootstrap "gui/$(id -u)" "$plist"
        info "Installed qmd MCP launchd service ($QMD_BIN)"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        unit_dir="$HOME/.config/systemd/user"
        mkdir -p "$unit_dir"
        sed -e "s|__QMD_BIN__|$QMD_BIN|g" -e "s|__BUN_DIR__|$BUN_DIR|g" \
            "$DOTFILES_DIR/qmd/qmd-mcp.service" > "$unit_dir/qmd-mcp.service"
        systemctl --user daemon-reload
        systemctl --user enable --now qmd-mcp.service
        info "Installed qmd MCP systemd user service ($QMD_BIN)"
    fi

    # Claude Code — skip if qmd plugin is installed (plugin manages its own MCP);
    # otherwise ensure HTTP transport registration (replace stale stdio if present)
    if command -v claude &> /dev/null; then
        if [[ -d "$HOME/.claude/plugins/marketplaces/qmd" ]]; then
            # Plugin manages its own MCP; remove manual registration if it exists
            claude mcp remove qmd 2>/dev/null && info "Removed manual qmd MCP (plugin manages its own)"
        else
            # Re-register unconditionally to fix stale stdio registrations
            claude mcp remove qmd 2>/dev/null
            claude mcp add --transport http --scope user qmd "$QMD_MCP_URL"
            info "Registered qmd MCP with Claude Code (http)"
        fi
    fi

    # Codex — config.toml is copied, not symlinked; ensure correct URL
    if command -v codex &> /dev/null && [[ -f "$HOME/.codex/config.toml" ]]; then
        if grep -q '\[mcp_servers\.qmd\]' "$HOME/.codex/config.toml"; then
            # Update existing entry to correct URL
            sed -i.bak '/\[mcp_servers\.qmd\]/,/^$\|^\[/{s|url = .*|url = "'"$QMD_MCP_URL"'"|;}' \
                "$HOME/.codex/config.toml" && rm -f "$HOME/.codex/config.toml.bak"
            info "Updated qmd MCP URL in Codex config"
        else
            cat >> "$HOME/.codex/config.toml" <<TOML

[mcp_servers.qmd]
url = "$QMD_MCP_URL"
TOML
            info "Registered qmd MCP with Codex"
        fi
    fi

    # OpenCode — installer merges shared config into the live local config
    if command -v opencode &> /dev/null; then
        info "qmd MCP already configured in opencode.json via shared OpenCode config"
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
        perplexity_mcp_shell='source ~/.zshrc && exec npx -yq @perplexity-ai/mcp-server'

        # Warn if API key is missing
        if [[ -z "${PERPLEXITY_API_KEY:-}" ]]; then
            warn "PERPLEXITY_API_KEY not set — add it to ~/.local/dotfiles/ai.local"
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

        # Claude Code — re-register with a shell wrapper so it reads the live env
        if [[ "${perplexity_choices:-}" == *"Claude"* ]]; then
            claude mcp remove perplexity 2>/dev/null
            claude mcp add perplexity --transport stdio --scope user -- zsh -lc "$perplexity_mcp_shell"
            info "Configured Perplexity MCP for Claude Code"
        fi

        # Codex — rewrite the MCP block so it always uses the live shell env
        if [[ "${perplexity_choices:-}" == *"Codex"* ]]; then
            codex_config="$HOME/.codex/config.toml"
            if [[ -f "$codex_config" ]]; then
                # De-symlink if needed (config.toml may be symlinked from dotfiles)
                if [[ -L "$codex_config" ]]; then
                    tmp="$(mktemp)"
                    cat "$codex_config" > "$tmp"
                    rm "$codex_config"
                    mv "$tmp" "$codex_config"
                fi

                tmp="$(mktemp)"
                awk '
                    BEGIN { skip = 0 }
                    /^\[mcp_servers\.perplexity(\.env)?\]/ { skip = 1; next }
                    skip && /^\[/ { skip = 0 }
                    !skip { print }
                ' "$codex_config" > "$tmp"
                mv "$tmp" "$codex_config"

                cat >> "$codex_config" <<TOML

[mcp_servers.perplexity]
command = "zsh"
args = ["-lc", "$perplexity_mcp_shell"]
TOML
                info "Configured Perplexity MCP for Codex"
            else
                warn "Codex config not found at ~/.codex/config.toml"
            fi
        fi

        # OpenCode — overwrite the MCP block so it always uses the live shell env
        if [[ "${perplexity_choices:-}" == *"OpenCode"* ]]; then
            oc_config="$HOME/.config/opencode/opencode.json"
            if [[ -f "$oc_config" ]] && command -v jq &>/dev/null; then
                # De-symlink if needed (opencode.json may be symlinked from dotfiles)
                if [[ -L "$oc_config" ]]; then
                    tmp="$(mktemp)"
                    cat "$oc_config" > "$tmp"
                    rm "$oc_config"
                    mv "$tmp" "$oc_config"
                fi

                jq --arg shell "$perplexity_mcp_shell" \
                    '.mcp.perplexity = {"type":"local","command":["zsh","-lc",$shell],"enabled":true}' \
                    "$oc_config" > "$oc_config.tmp" && mv "$oc_config.tmp" "$oc_config"
                info "Configured Perplexity MCP for OpenCode"
            else
                warn "OpenCode config not found or jq unavailable"
            fi
        fi

        # pi — configure a shell wrapper so it reads the live env at launch
        if [[ "${perplexity_choices:-}" == *"pi"* ]]; then
            pi_mcp="$HOME/.pi/agent/mcp.json"
            if command -v jq &>/dev/null; then
                mkdir -p "$HOME/.pi/agent"
                if [[ -f "$pi_mcp" ]]; then
                    jq --arg shell "$perplexity_mcp_shell" \
                        '.mcpServers.perplexity = {"command":"zsh","args":["-lc",$shell],"directTools":true}' \
                        "$pi_mcp" > "$pi_mcp.tmp" && mv "$pi_mcp.tmp" "$pi_mcp"
                else
                    cat > "$pi_mcp" <<JSON
{
  "mcpServers": {
    "perplexity": {
      "command": "zsh",
      "args": ["-lc", "$perplexity_mcp_shell"],
      "directTools": true
    }
  }
}
JSON
                fi
                info "Configured Perplexity MCP for pi using the live shell environment"
            else
                warn "jq not found — cannot register Perplexity MCP with pi"
            fi
        fi

        if [[ -n "${perplexity_choices:-}" ]]; then
            info "Make sure PERPLEXITY_API_KEY is exported in ~/.local/dotfiles/ai.local before launching tools that use Perplexity MCP"
        fi
    fi
fi
