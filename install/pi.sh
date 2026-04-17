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
)

if command -v pi &>/dev/null && ask_yes_no "Install pi extensions?"; then
    for ext in "${PI_EXTENSIONS[@]}"; do
        ext_name="$(basename "$ext")"
        if pi list 2>/dev/null | grep -q "$ext_name"; then
            info "$ext_name already installed"
        else
            spin "Installing $ext_name" pi install "$ext"
        fi
    done
fi
