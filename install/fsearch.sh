#!/usr/bin/env bash
# FSearch — https://github.com/noahdunnagan/fsearch
# Upstream supports macOS; its prebuilt release is Apple Silicon only.
# Use the documented release + `fsearch install` flow, never a project-local binary.

if [[ "$OSTYPE" == "darwin"* ]]; then
    fsearch_bin="$HOME/.local/bin/fsearch"
    if [[ -x "$fsearch_bin" ]]; then
        info "fsearch already installed at $fsearch_bin"
    elif [[ "$(uname -m)" != "arm64" ]]; then
        warn "fsearch prebuilt release requires Apple Silicon; see upstream for a Rust source build"
    elif ask_yes_no "Install fsearch (whole-disk file search and MCP server)?"; then
        # Pin the upstream release and its published SHA-256. Bump both together.
        # Extract in a temporary directory so no binary is left in the caller's cwd.
        if (
            fsearch_tmp="$(mktemp -d)" || exit 1
            trap 'rm -rf "$fsearch_tmp"' EXIT
            cd "$fsearch_tmp" || exit 1
            curl -fL --retry 3 -o fsearch.tar.gz \
                "https://github.com/noahdunnagan/fsearch/releases/download/v0.2.1/fsearch-aarch64-apple-darwin.tar.gz" &&
            echo "08f68fe10362732f701be3ddf59cb370920c5a08af63e76b15addf8aca118d2f  fsearch.tar.gz" | shasum -a 256 -c - &&
            tar -xzf fsearch.tar.gz &&
            ./fsearch install
        ); then
            info "Installed fsearch at $fsearch_bin (daemon starts on first use)"
        else
            warn "Could not install fsearch"
        fi
    fi

    if [[ -x "$fsearch_bin" ]]; then
        # Claude Code — leave existing machine-local registrations untouched.
        if command -v claude &>/dev/null; then
            if ! command -v jq &>/dev/null; then
                warn "jq not found — cannot check fsearch MCP registration for Claude Code"
            elif [[ -f "$HOME/.claude.json" ]] && ! jq empty "$HOME/.claude.json"; then
                warn "Invalid ~/.claude.json — leaving it unchanged"
            elif [[ -f "$HOME/.claude.json" ]] && jq -e '.mcpServers | has("fsearch")' "$HOME/.claude.json" >/dev/null; then
                info "fsearch MCP already registered with Claude Code"
            elif claude mcp add fsearch --transport stdio --scope user -- "$fsearch_bin" mcp; then
                info "Registered fsearch MCP with Claude Code"
            else
                warn "Could not register fsearch MCP with Claude Code"
            fi
        fi

        # Codex — config.toml is machine-local, copied rather than symlinked.
        if command -v codex &>/dev/null; then
            # mcp.sh runs before codex.sh. Seed its normal template on a fresh
            # machine so `codex mcp add` cannot create a bare config first.
            if [[ ! -f "$HOME/.codex/config.toml" ]]; then
                mkdir -p "$HOME/.codex"
                cp "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml"
            fi
            if [[ -f "$HOME/.codex/config.toml" ]] && grep -Eq '^\[mcp_servers\.fsearch\][[:space:]]*(#.*)?$' "$HOME/.codex/config.toml"; then
                info "fsearch MCP already registered with Codex"
            elif codex mcp add fsearch -- "$fsearch_bin" mcp; then
                info "Registered fsearch MCP with Codex"
            else
                warn "Could not register fsearch MCP with Codex"
            fi
        fi

        # pi — merge only this server, preserving other MCP entries.
        if command -v pi &>/dev/null; then
            pi_mcp="$HOME/.pi/agent/mcp.json"
            if ! command -v jq &>/dev/null; then
                warn "jq not found — cannot register fsearch MCP with pi"
            elif [[ -f "$pi_mcp" ]] && ! jq empty "$pi_mcp"; then
                warn "Invalid pi MCP config — leaving it unchanged"
            elif [[ -f "$pi_mcp" ]] && jq -e '.mcpServers | has("fsearch")' "$pi_mcp" >/dev/null; then
                info "fsearch MCP already registered with pi"
            else
                mkdir -p "$HOME/.pi/agent"
                fsearch_config_tmp="$(mktemp "$HOME/.pi/agent/mcp.json.XXXXXX")"
                if jq --arg bin "$fsearch_bin" \
                    '.mcpServers.fsearch = {"command":$bin,"args":["mcp"]}' \
                    <(if [[ -f "$pi_mcp" ]]; then cat "$pi_mcp"; else echo '{}'; fi) \
                    > "$fsearch_config_tmp"; then
                    mv "$fsearch_config_tmp" "$pi_mcp"
                    info "Registered fsearch MCP with pi"
                else
                    rm -f "$fsearch_config_tmp"
                    warn "Could not register fsearch MCP with pi"
                fi
            fi
        fi
    fi
fi
