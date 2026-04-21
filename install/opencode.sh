#!/usr/bin/env bash
#
# OpenCode configuration
#

header "OpenCode"

if ! command -v opencode &> /dev/null; then
    info "OpenCode not installed, skipping configuration"
    return 0 2>/dev/null || exit 0
fi

mkdir -p "$HOME/.config/opencode"

# AGENTS.md (global instructions)
create_symlink "$DOTFILES_DIR/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

# opencode.json: merge shared defaults into the live local config so
# machine-specific settings can diverge without losing shared updates.
opencode_config="$HOME/.config/opencode/opencode.json"
shared_config="$DOTFILES_DIR/opencode/opencode.json"

if [[ ! -f "$opencode_config" ]]; then
    command cp -f "$shared_config" "$opencode_config"
    info "Copied OpenCode config to ~/.config/opencode/opencode.json"
elif command -v jq &>/dev/null; then
    tmp="$(mktemp)"
    if jq -s '.[0] * .[1]' "$shared_config" "$opencode_config" > "$tmp"; then
        command cp -f "$opencode_config" "${opencode_config}.bak"
        command mv -f "$tmp" "$opencode_config"
        info "Merged shared OpenCode config into ~/.config/opencode/opencode.json"
    else
        rm -f "$tmp"
        warn "Could not merge OpenCode config; leaving ~/.config/opencode/opencode.json unchanged"
    fi
else
    warn "jq not found — skipping OpenCode config merge"
fi

# oh-my-openagent.json: merge shared defaults + private model routing, then copy to live
omo_config="$HOME/.config/opencode/oh-my-openagent.json"
shared_omo="$DOTFILES_DIR/opencode/oh-my-openagent.json"
local_omo="$HOME/.local/dotfiles/oh-my-openagent.local.json"

if [[ -f "$local_omo" ]] && command -v jq &>/dev/null; then
    tmp="$(mktemp)"
    if jq -s '.[0] * .[1]' "$shared_omo" "$local_omo" > "$tmp"; then
        command cp -f "$tmp" "$omo_config"
        rm -f "$tmp"
        info "Installed oh-my-openagent config (shared + local) to ~/.config/opencode/oh-my-openagent.json"
    else
        rm -f "$tmp"
        warn "Could not merge oh-my-openagent config; leaving ~/.config/opencode/oh-my-openagent.json unchanged"
    fi
elif [[ -f "$local_omo" ]]; then
    warn "jq not found — copying local oh-my-openagent config without merging shared defaults"
    command cp -f "$local_omo" "$omo_config"
else
    command cp -f "$shared_omo" "$omo_config"
    info "Copied shared oh-my-openagent config to ~/.config/opencode/oh-my-openagent.json"
fi
