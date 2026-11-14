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

# Oh My OpenAgent (formerly oh-my-opencode) and oh-my-opencode-slim are
# retired: their plugins do not run on OpenCode 2. Rename their live configs
# out of the way so nothing reads them.
for retired_omo in oh-my-openagent.json oh-my-openagent.jsonc oh-my-opencode.json oh-my-opencode.jsonc oh-my-opencode-slim.json oh-my-opencode-slim.jsonc; do
    if [[ -f "$opencode_dir/$retired_omo" ]]; then
        command mv -f "$opencode_dir/$retired_omo" "$opencode_dir/$retired_omo.retired.$opencode_stamp"
        info "Retired ~/.config/opencode/$retired_omo"
    fi
done
for retired_pkg in oh-my-openagent oh-my-opencode-slim; do
    if command -v bun &>/dev/null && bun pm ls -g 2>/dev/null | grep -q "$retired_pkg"; then
        bun remove -g "$retired_pkg" &>/dev/null \
            && info "Removed the $retired_pkg global package" \
            || warn "Could not remove the $retired_pkg global package; run: bun remove -g $retired_pkg"
    fi
done
for retired_local in oh-my-openagent oh-my-opencode-slim; do
    if [[ -f "$HOME/.local/dotfiles/$retired_local.local.json" ]]; then
        warn "~/.local/dotfiles/$retired_local.local.json is no longer read; the plugin was removed, delete the file when ready"
    fi
done

if ! command -v jq &>/dev/null; then
    warn "jq not found — skipping OpenCode config and plugin cleanup"
    return 0 2>/dev/null || exit 0
fi

# Drops retired plugin entries from a plugin array and keeps everything else,
# including [package, options] tuples.
opencode_plugin_filter='
    def retired: type == "string" and test("^oh-my-(openagent|opencode(-slim)?)(@.*)?$");
'

# opencode.json: machine-local settings win over shared defaults, except for
# the entries dotfiles owns: the qmd MCP server and the plugin list. Plugins
# are merged by name, so local plugins stay, retired ones go, and any shared
# pins replace other versions of themselves.
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
            [($live.plugin // [])[] | select(retired | not)]
            + ($shared.plugin // [])
          )
        | if (.plugins | type) == "array"
          then .plugins |= map(select(retired | not))
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

