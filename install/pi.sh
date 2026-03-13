#!/usr/bin/env bash
#
# pi Extensions
#

PI_EXTENSIONS=(
    https://github.com/davebcn87/pi-autoresearch
    npm:pi-mcp-adapter
)

if command -v pi &>/dev/null; then
    for ext in "${PI_EXTENSIONS[@]}"; do
        ext_name="$(basename "$ext")"
        if pi list 2>/dev/null | grep -q "$ext_name"; then
            info "$ext_name already installed"
        else
            spin "Installing $ext_name" pi install "$ext"
        fi
    done
fi
