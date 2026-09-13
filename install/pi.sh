#!/usr/bin/env bash
#
# pi Extensions
#

if command -v pi &>/dev/null; then
    mkdir -p "$HOME/.pi/agent"
    create_symlink "$DOTFILES_DIR/pi/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
fi

if command -v pi &>/dev/null && ask_yes_no "Install or update pi extensions?" "y"; then
    # Pi requires Node.js. Read the shared settings so package sources and pins
    # cannot drift between the installer and the active configuration.
    pi_extensions="$(node -e '
        const settings = require(process.argv[1]);
        for (const source of settings.packages) {
            if (typeof source !== "string") throw new Error("Expected a Pi package source string");
            console.log(source);
        }
    ' "$DOTFILES_DIR/pi/settings.json")"
    if pi list 2>/dev/null | grep -q 'npm:pi-claude-bridge'; then
        spin "Removing npm:pi-claude-bridge" pi remove npm:pi-claude-bridge
    fi
    while IFS= read -r ext; do
        [[ -n "$ext" ]] || continue
        ext_name="$(basename "$ext")"
        # A source in `pi list` can still be missing from disk. Let Pi ensure
        # the package is installed instead of matching a partial package name.
        spin "Installing $ext_name" pi install "$ext"
    done <<< "$pi_extensions"
fi
