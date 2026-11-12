#!/usr/bin/env bash
#
# OpenCode configuration
#
# Works for OpenCode 1 (`opencode`) and OpenCode 2 (`opencode2`). Both read
# ~/.config/opencode/opencode.json, and V2 still accepts the V1 config format,
# so the shared file stays in the V1 shape that both hosts understand.
#

header "OpenCode"

if ! command -v opencode &> /dev/null && ! command -v opencode2 &> /dev/null; then
    info "OpenCode not installed, skipping configuration"
    return 0 2>/dev/null || exit 0
fi

opencode_dir="$HOME/.config/opencode"
opencode_stamp="$(date +%Y%m%d%H%M%S)"
mkdir -p "$opencode_dir"

# Replace a live JSON file only when its content changes, keeping a timestamped
# backup of what was there.
install_opencode_json() {
    local candidate="$1" dest="$2" label="$3"
    if [[ -f "$dest" ]] && [[ "$(jq -S . "$dest" 2>/dev/null)" == "$(jq -S . "$candidate")" ]]; then
        rm -f "$candidate"
        info "$label already up to date"
        return 0
    fi
    [[ -f "$dest" ]] && command cp -f "$dest" "$dest.backup.$opencode_stamp"
    command mv -f "$candidate" "$dest"
    info "Updated $label"
}

# AGENTS.md (global instructions)
create_symlink "$DOTFILES_DIR/opencode/AGENTS.md" "$opencode_dir/AGENTS.md"

# Oh My OpenAgent (formerly oh-my-opencode) is retired: its plugin does not run
# on OpenCode 2. Rename its live config out of the way so nothing reads it.
for retired_omo in oh-my-openagent.json oh-my-openagent.jsonc oh-my-opencode.json oh-my-opencode.jsonc; do
    if [[ -f "$opencode_dir/$retired_omo" ]]; then
        command mv -f "$opencode_dir/$retired_omo" "$opencode_dir/$retired_omo.retired.$opencode_stamp"
        info "Retired ~/.config/opencode/$retired_omo"
    fi
done
if command -v bun &>/dev/null && bun pm ls -g 2>/dev/null | grep -q "oh-my-openagent"; then
    bun remove -g oh-my-openagent &>/dev/null \
        && info "Removed the oh-my-openagent global package" \
        || warn "Could not remove the oh-my-openagent global package; run: bun remove -g oh-my-openagent"
fi
if [[ -f "$HOME/.local/dotfiles/oh-my-openagent.local.json" ]]; then
    warn "~/.local/dotfiles/oh-my-openagent.local.json is no longer read; move private model routing to ~/.local/dotfiles/oh-my-opencode-slim.local.json"
fi

if ! command -v jq &>/dev/null; then
    warn "jq not found — skipping OpenCode config, plugin registration, and oh-my-opencode-slim config"
    return 0 2>/dev/null || exit 0
fi

# Drops retired plugin entries from a plugin array and keeps everything else,
# including [package, options] tuples.
opencode_plugin_filter='
    def retired: type == "string" and test("^oh-my-(openagent|opencode)(@.*)?$");
    def slim: type == "string" and test("^oh-my-opencode-slim(@.*)?$");
'

# opencode.json: machine-local settings win over shared defaults, except for
# the entries dotfiles owns: the qmd MCP server and the plugin list. Plugins
# are merged by name, so local plugins stay, retired ones go, and the pinned
# oh-my-opencode-slim entry replaces any other version of itself.
opencode_config="$opencode_dir/opencode.json"
shared_config="$DOTFILES_DIR/opencode/opencode.json"

if [[ ! -f "$opencode_config" ]]; then
    command cp -f "$shared_config" "$opencode_config"
    info "Copied OpenCode config to ~/.config/opencode/opencode.json"
else
    tmp="$(mktemp)"
    if jq -s "$opencode_plugin_filter"'
        .[0] as $shared | .[1] as $live
        | ($shared * $live)
        | .mcp.qmd = $shared.mcp.qmd
        | .plugin = (
            [($live.plugin // [])[] | select((retired or slim) | not)]
            + ($shared.plugin // [])
          )
        | if (.plugins | type) == "array"
          then .plugins |= map(select((retired or slim) | not))
          else . end
    ' "$shared_config" "$opencode_config" > "$tmp"; then
        install_opencode_json "$tmp" "$opencode_config" "~/.config/opencode/opencode.json"
    else
        rm -f "$tmp"
        warn "Could not merge OpenCode config; leaving ~/.config/opencode/opencode.json unchanged"
    fi
fi

# tui.json: the retired plugin may also be registered for the TUI.
opencode_tui="$opencode_dir/tui.json"
if [[ -f "$opencode_tui" ]] && jq -e "$opencode_plugin_filter"'
        [(.plugin // [])[] | select(retired)] | length > 0' "$opencode_tui" &>/dev/null; then
    tmp="$(mktemp)"
    if jq "$opencode_plugin_filter"'.plugin |= map(select(retired | not))' "$opencode_tui" > "$tmp"; then
        install_opencode_json "$tmp" "$opencode_tui" "~/.config/opencode/tui.json"
    else
        rm -f "$tmp"
    fi
fi

# oh-my-opencode-slim.json: owned by dotfiles. Private model routing, such as
# cross-provider fallback chains, goes in the local override and is merged on
# top. A live file that differs is backed up before it is replaced.
slim_config="$opencode_dir/oh-my-opencode-slim.json"
shared_slim="$DOTFILES_DIR/opencode/oh-my-opencode-slim.json"
local_slim="$HOME/.local/dotfiles/oh-my-opencode-slim.local.json"

tmp="$(mktemp)"
if [[ -f "$local_slim" ]]; then
    if jq -s '.[0] * .[1]' "$shared_slim" "$local_slim" > "$tmp"; then
        install_opencode_json "$tmp" "$slim_config" "~/.config/opencode/oh-my-opencode-slim.json (shared + local)"
    else
        rm -f "$tmp"
        warn "Could not merge oh-my-opencode-slim config; leaving the live file unchanged"
    fi
else
    command cp -f "$shared_slim" "$tmp"
    install_opencode_json "$tmp" "$slim_config" "~/.config/opencode/oh-my-opencode-slim.json"
fi
