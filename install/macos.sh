#!/usr/bin/env bash
#
# macOS-specific installation (Homebrew, fonts, tools)
#

# ==============================================================================
# Homebrew
# ==============================================================================

header "Homebrew"

if ! command -v brew &> /dev/null; then
    info "Installing Homebrew..."
    run_remote_script /bin/bash https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh

    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    info "Homebrew installed"
else
    info "Homebrew already installed"
fi

# ==============================================================================
# Brew Packages
# ==============================================================================

header "Brew Packages"
spin "Installing packages from Brewfile" brew bundle --file="$DOTFILES_DIR/Brewfile"

# Activate mise for this session (enables Node.js, Python, etc.)
if command -v mise &> /dev/null; then
    eval "$(mise activate bash)"
fi

# ==============================================================================
# Fonts
# ==============================================================================

header "Fonts"

# Always install JetBrainsMono (default font)
if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
    info "JetBrainsMono Nerd Font already installed"
else
    spin "Installing JetBrainsMono Nerd Font" brew install --cask font-jetbrains-mono-nerd-font
fi

install_martian=false
install_monaspace=false

missing_fonts=()
brew list --cask font-martian-mono-nerd-font &>/dev/null && info "MartianMono Nerd Font already installed" || missing_fonts+=("MartianMono Nerd Font")
brew list --cask font-monaspace &>/dev/null && info "Monaspace already installed" || missing_fonts+=("Monaspace")

if [[ ${#missing_fonts[@]} -eq 0 ]]; then
    info "All optional fonts already installed"
elif has_gum; then
    font_choices=$(gum choose --no-limit \
        --header "Select fonts to install (Space to select, Enter to confirm):" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[x] " \
        "${missing_fonts[@]}" || true)

    [[ "$font_choices" == *"MartianMono Nerd Font"* ]] && install_martian=true
    [[ "$font_choices" == *"Monaspace"* ]] && install_monaspace=true

    if [[ -z "$font_choices" ]]; then
        info "Skipping optional fonts"
    fi
else
    echo "Which fonts would you like to install?"
    for i in "${!missing_fonts[@]}"; do
        echo "  $((i + 1))) ${missing_fonts[$i]}"
    done
    echo "  A) All"
    echo "  N) None"
    echo ""
    read -r -p "Enter choices (e.g., 1 2 or A for all): " -a font_choices

    for choice in "${font_choices[@]}"; do
        case "$choice" in
            [Aa])
                for font in "${missing_fonts[@]}"; do
                    [[ "$font" == "MartianMono Nerd Font" ]] && install_martian=true
                    [[ "$font" == "Monaspace" ]] && install_monaspace=true
                done
                ;;
            [Nn]) ;;
            [1-9])
                selected="${missing_fonts[$((choice - 1))]:-}"
                if [[ -n "$selected" ]]; then
                    [[ "$selected" == "MartianMono Nerd Font" ]] && install_martian=true
                    [[ "$selected" == "Monaspace" ]] && install_monaspace=true
                else
                    warn "Unknown option: $choice"
                fi
                ;;
            *) warn "Unknown option: $choice" ;;
        esac
    done
fi

if $install_martian; then
    spin "Installing MartianMono Nerd Font" brew install --cask font-martian-mono-nerd-font
fi

if $install_monaspace; then
    spin "Installing Monaspace" brew install --cask font-monaspace
fi

# ==============================================================================
# Optional Tools
# ==============================================================================

header "Optional Tools"

if command -v op &>/dev/null; then
    info "1Password CLI already installed"
elif ask_yes_no "Install 1Password CLI (op)?"; then
    spin "Installing 1Password CLI" brew install --cask 1password-cli
else
    info "Skipping 1Password CLI"
fi

if brew list --cask raycast &>/dev/null || [[ -d "/Applications/Raycast.app" ]]; then
    info "Raycast already installed"
elif ask_yes_no "Install Raycast?"; then
    spin "Installing Raycast" brew install --cask raycast
else
    info "Skipping Raycast"
fi

# ==============================================================================
# LazyVim Setup
# ==============================================================================

header "Neovim / LazyVim"

if [[ ! -d "$HOME/.config/nvim" ]]; then
    if ask_yes_no "Install LazyVim starter configuration?" "y"; then
        spin "Cloning LazyVim starter" git clone --quiet https://github.com/LazyVim/starter "$HOME/.config/nvim"
        rm -rf "$HOME/.config/nvim/.git"
        info "LazyVim installed. Run 'nvim' to complete setup."
    fi
else
    info "Neovim config already exists at ~/.config/nvim"
fi

# ==============================================================================
# Tool Initialization
# ==============================================================================

header "Tool Initialization"

# Initialize fzf if not already done
if [[ ! -f "$HOME/.fzf.zsh" ]]; then
    info "Setting up fzf..."
    "$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
fi
