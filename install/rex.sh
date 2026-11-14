#!/usr/bin/env bash
#
# Optional Rex configuration. App installation requires beta access.
#

header "Rex"

if ask_yes_no "Set up Rex configuration?" "n"; then
    rex_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/rex"
    mkdir -p "$rex_config_dir"
    create_symlink "$DOTFILES_DIR/rex/init.lua" "$rex_config_dir/init.lua"

    if command -v rex &>/dev/null; then
        info "Rex configuration linked. Run 'rex config reload' to apply it."
    else
        warn "Rex is not installed. Install it from https://www.superlogical.com/rex/docs/installation"
    fi
else
    info "Skipping Rex configuration"
fi
