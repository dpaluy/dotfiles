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
