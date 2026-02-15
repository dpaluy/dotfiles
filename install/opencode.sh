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

# opencode.json config (only if no existing config)
if [[ ! -f "$HOME/.config/opencode/opencode.json" ]]; then
    create_symlink "$DOTFILES_DIR/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
else
    info "OpenCode config already exists at ~/.config/opencode/opencode.json"
fi
