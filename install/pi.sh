#!/usr/bin/env bash
#
# pi Extensions
#

install_pi_durable_subagents_config() {
    local src dest agent
    src="$DOTFILES_DIR/pi/durable-subagents/config.json"
    dest="${DSA_HOME:-$HOME/.pi/durable-subagents}/config.json"
    # Runtime configuration and existing agent definitions belong to the user.
    if [[ -f "$src" && ! -e "$dest" && ! -L "$dest" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
    elif [[ -f "$src" && -f "$dest" && ! -L "$dest" ]] && command -v jq &>/dev/null \
        && jq -e . "$dest" &>/dev/null \
        && ! jq -e --slurpfile shared "$src" '.pools == $shared[0].pools' "$dest" &>/dev/null; then
        # The copied config is never rewritten silently. When its model pools
        # differ from dotfiles, offer to replace only the pools, after a backup.
        if ask_yes_no "Pi durable-subagent pools differ from dotfiles. Sync pools (a backup is kept)?"; then
            cp "$dest" "$dest.backup.$(date +%Y%m%d%H%M%S)"
            jq --slurpfile shared "$src" '.pools = $shared[0].pools' "$dest" > "$dest.tmp" \
                && mv "$dest.tmp" "$dest"
        fi
    fi
    mkdir -p "$HOME/.pi/agent/agents"
    for agent in "$DOTFILES_DIR"/pi/agents/*.md; do
        [[ -f "$agent" ]] || continue
        dest="$HOME/.pi/agent/agents/$(basename "$agent")"
        [[ -e "$dest" || -L "$dest" ]] && continue
        create_symlink "$agent" "$dest"
    done
}

if command -v pi &>/dev/null; then
    mkdir -p "$HOME/.pi/agent"
    create_symlink "$DOTFILES_DIR/pi/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
fi

# Pi writes changelog bookkeeping into the symlinked settings.json. A git clean
# filter (see .gitattributes) drops those keys on staging so runtime writes do
# not dirty the tracked file. Filter definitions live in local git config.
if command -v jq &>/dev/null && git -C "$DOTFILES_DIR" rev-parse --git-dir &>/dev/null; then
    git -C "$DOTFILES_DIR" config filter.pi-settings.clean \
        "jq --indent 2 'del(.lastChangelogVersion, .extensionChangelogVersions)'"
    git -C "$DOTFILES_DIR" config filter.pi-settings.smudge cat
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
    while IFS= read -r ext; do
        [[ -n "$ext" ]] || continue
        ext_name="$(basename "$ext")"
        # A source in `pi list` can still be missing from disk. Let Pi ensure
        # the package is installed instead of matching a partial package name.
        spin "Installing $ext_name" pi install "$ext"
    done <<< "$pi_extensions"
fi

if command -v pi &>/dev/null; then
    # Leave legacy manager configuration and durable runtime state untouched.
    install_pi_durable_subagents_config
fi
