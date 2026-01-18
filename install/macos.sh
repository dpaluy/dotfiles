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
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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

# ==============================================================================
# Fonts
# ==============================================================================

header "Fonts"
if brew list --cask font-martian-mono-nerd-font &>/dev/null; then
    info "MartianMono Nerd Font already installed"
else
    spin "Installing MartianMono Nerd Font" brew install --cask font-martian-mono-nerd-font
fi

# ==============================================================================
# Optional Tools
# ==============================================================================

header "Optional Tools"
if ask_yes_no "Install Raycast?"; then
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
