#!/usr/bin/env bash
#
# Herdr Terminal Multiplexer (Optional)
#

header "Herdr Terminal Multiplexer"

if command -v herdr &>/dev/null; then
    info "herdr already installed"
elif ask_yes_no "Install Herdr (terminal multiplexer for AI coding agents)?" "n"; then
    info "Installing herdr..."
    if [[ "$OS" == "macos" ]]; then
        brew install herdr
    else
        run_remote_script sh https://herdr.dev/install.sh
    fi
    info "herdr installed"
else
    info "Skipping Herdr"
fi

# ------------------------------------------------------------------------------
# herdr Oh My Zsh plugin
#
# zsh/zshrc lists `herdr` in the Oh My Zsh plugins array. `herdr plugin install`
# clones it into $ZSH_CUSTOM/plugins/herdr and registers the Herdr-side plugin
# (sidebar toasts, reload-all keybinding). Skip when herdr is not present; the
# zsh plugin is a no-op outside Herdr.
# ------------------------------------------------------------------------------

if command -v herdr &>/dev/null; then
    if herdr plugin list 2>/dev/null | grep -q 'herdr-ohmyzsh'; then
        info "herdr-ohmyzsh plugin already installed"
    else
        spin "Installing herdr-ohmyzsh plugin" herdr plugin install robbyrussell/herdr-ohmyzsh -y
        info "herdr-ohmyzsh plugin installed"
    fi
fi
