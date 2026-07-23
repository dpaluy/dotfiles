#!/usr/bin/env bash
#
# pi Extensions
#

if command -v pi &>/dev/null; then
    mkdir -p "$HOME/.pi/agent"
    create_symlink "$DOTFILES_DIR/pi/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
fi

PI_EXTENSIONS=(
    https://github.com/davebcn87/pi-autoresearch
    npm:pi-side-chat
    npm:pi-mcp-adapter
    npm:pi-subagents
    npm:pi-xai-oauth
    https://github.com/jhochenbaum/pi-autoresearch-studio
    npm:pi-web-access
    npm:@ff-labs/pi-fff
    https://github.com/nicobailon/pi-boomerang
    https://github.com/zereraz/pi-goal
    npm:pi-cursor-provider
    npm:pi-claude-bridge
    https://github.com/disler/fusion-harness
    git:github.com/algal/pi-openai-server-compaction
)

if command -v pi &>/dev/null && ask_yes_no "Install or update pi extensions?" "y"; then
    for ext in "${PI_EXTENSIONS[@]}"; do
        ext_name="$(basename "$ext")"
        if pi list 2>/dev/null | grep -q "$ext_name"; then
            info "$ext_name already installed"
        else
            spin "Installing $ext_name" pi install "$ext"
        fi
    done

    # fusion-harness keeps its entry point below extensions/fusion-harness/ rather
    # than at the conventional extensions/*.ts package path, so load it explicitly.
    pi_settings="$HOME/.pi/agent/settings.json"
    fusion_harness_extension="git/github.com/disler/fusion-harness/extensions/fusion-harness/fusion-harness.ts"
    if [[ -f "$pi_settings" ]] && command -v jq &>/dev/null; then
        tmp_settings="$(mktemp)"
        if jq --arg extension "$fusion_harness_extension" \
            'if ((.extensions // []) | index($extension)) then . else .extensions = ((.extensions // []) + [$extension]) end' \
            "$pi_settings" > "$tmp_settings"; then
            mv "$tmp_settings" "$pi_settings"
            info "Configured fusion-harness extension entry point"
        else
            rm -f "$tmp_settings"
            warn "Could not configure fusion-harness in $pi_settings"
        fi
    else
        warn "jq or $pi_settings unavailable; fusion-harness was cloned but its nested extension is not enabled"
    fi
fi
