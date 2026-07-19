#!/usr/bin/env bash
#
# Terminal Multiplexer (Optional)
#
# tmux and herdr are both terminal multiplexers with a client-server model
# (herdr adds an agent-detection layer for orchestrating AI coding agents).
# Both are opt-in: select either, both, or neither.
#

header "Terminal Multiplexer"

install_tmux=false
install_herdr=false

# Detect which multiplexers are already installed
missing_tools=()
if command -v tmux &>/dev/null; then
    info "tmux already installed"
else
    missing_tools+=("tmux")
fi
if command -v herdr &>/dev/null; then
    info "herdr already installed"
else
    missing_tools+=("herdr")
fi

if [[ ${#missing_tools[@]} -eq 0 ]]; then
    info "All terminal multiplexers already installed"
elif has_gum; then
    mux_choices=$(gum choose --no-limit \
        --header "Select terminal multiplexers to install (Space to select, Enter to confirm):" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[x] " \
        "${missing_tools[@]}" || true)

    [[ "$mux_choices" == *"tmux"* ]] && install_tmux=true
    [[ "$mux_choices" == *"herdr"* ]] && install_herdr=true

    if [[ -z "$mux_choices" ]]; then
        info "Skipping terminal multiplexers"
    fi
else
    echo "Which terminal multiplexers would you like to install?"
    for i in "${!missing_tools[@]}"; do
        echo "  $((i + 1))) ${missing_tools[$i]}"
    done
    echo "  A) All"
    echo "  N) None"
    echo ""
    read -r -p "Enter choices (e.g., 1 2 or A for all): " -a mux_choices

    for choice in "${mux_choices[@]}"; do
        case "$choice" in
            [Aa])
                for tool in "${missing_tools[@]}"; do
                    [[ "$tool" == "tmux" ]] && install_tmux=true
                    [[ "$tool" == "herdr" ]] && install_herdr=true
                done
                ;;
            [Nn]) ;;
            [1-9])
                selected="${missing_tools[$((choice - 1))]:-}"
                case "$selected" in
                    tmux)  install_tmux=true ;;
                    herdr) install_herdr=true ;;
                    "")    warn "Unknown option: $choice" ;;
                esac
                ;;
            *) warn "Unknown option: $choice" ;;
        esac
    done
fi

if $install_tmux; then
    info "Installing tmux..."
    if [[ "$OS" == "macos" ]]; then
        brew install tmux
    else
        case "$OS" in
            arch)   sudo pacman -S --noconfirm tmux ;;
            debian) sudo apt install -y tmux ;;
            fedora) sudo dnf install -y tmux ;;
        esac
    fi
    info "tmux installed"
fi

if $install_herdr; then
    info "Installing herdr..."
    if [[ "$OS" == "macos" ]]; then
        brew install herdr
    else
        run_remote_script sh https://herdr.dev/install.sh
    fi
    info "herdr installed"
fi

# ------------------------------------------------------------------------------
# tmux config + companions (tmux.conf, sesh, gitmux)
#
# tmux.conf, sesh (session manager), and gitmux (git status in the tmux status
# bar) are only useful with tmux, so they are offered only when tmux is present.
# The sesh/gitmux config files are linked from install/symlinks.sh once the
# binaries exist; tmux.conf is linked here so declining the prompt is honored.
# ------------------------------------------------------------------------------

install_sesh() {
    info "Installing sesh..."
    if [[ "$OS" == "macos" ]]; then
        brew install sesh
    else
        local version arch checksums
        version=$(curl -fsSL "https://api.github.com/repos/joshmedeski/sesh/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        arch="$(normalize_release_arch)"
        download_file "https://github.com/joshmedeski/sesh/releases/download/v${version}/sesh_Linux_${arch}.tar.gz" /tmp/sesh.tar.gz
        checksums=$(mktemp)
        download_file "https://github.com/joshmedeski/sesh/releases/download/v${version}/sesh_${version}_checksums.txt" "$checksums"
        verify_sha256_checksum "$checksums" /tmp/sesh.tar.gz "sesh_Linux_${arch}.tar.gz"
        rm -f "$checksums"
        tar -xf /tmp/sesh.tar.gz -C /tmp sesh
        sudo install /tmp/sesh /usr/local/bin/sesh
        rm /tmp/sesh.tar.gz /tmp/sesh
    fi
    info "sesh installed"
}

install_gitmux() {
    info "Installing gitmux..."
    if [[ "$OS" == "macos" ]]; then
        brew install gitmux
    else
        local version arch checksums
        version=$(curl -fsSL "https://api.github.com/repos/arl/gitmux/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        arch="$(normalize_release_arch)"
        case "$arch" in
            x86_64)  arch="amd64" ;;
            aarch64) arch="arm64" ;;
        esac
        download_file "https://github.com/arl/gitmux/releases/download/v${version}/gitmux_v${version}_linux_${arch}.tar.gz" /tmp/gitmux.tar.gz
        checksums=$(mktemp)
        download_file "https://github.com/arl/gitmux/releases/download/v${version}/checksums.txt" "$checksums"
        verify_sha256_checksum "$checksums" /tmp/gitmux.tar.gz "gitmux_v${version}_linux_${arch}.tar.gz"
        rm -f "$checksums"
        tar -xf /tmp/gitmux.tar.gz -C /tmp gitmux
        sudo install /tmp/gitmux /usr/local/bin/gitmux
        rm /tmp/gitmux.tar.gz /tmp/gitmux
    fi
    info "gitmux installed"
}

if command -v tmux &>/dev/null; then
    needs=()
    [[ -e "$HOME/.tmux.conf" ]]    || needs+=("tmux.conf")
    command -v sesh &>/dev/null    || needs+=("sesh")
    command -v gitmux &>/dev/null  || needs+=("gitmux")

    if [[ ${#needs[@]} -eq 0 ]]; then
        info "tmux config + companions already set up"
    elif ask_yes_no "Set up tmux config + companions (${needs[*]})?" "y"; then
        for item in "${needs[@]}"; do
            case "$item" in
                tmux.conf) create_symlink "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf" ;;
                sesh)      install_sesh ;;
                gitmux)    install_gitmux ;;
            esac
        done
    else
        info "Skipping tmux config + companions"
    fi
fi
