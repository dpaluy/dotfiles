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
        command mv -f "$tmp" "$opencode_config"
        info "Merged shared OpenCode config into ~/.config/opencode/opencode.json"
    else
        rm -f "$tmp"
        warn "Could not merge OpenCode config; leaving ~/.config/opencode/opencode.json unchanged"
    fi
else
    warn "jq not found — skipping OpenCode config merge"
fi
