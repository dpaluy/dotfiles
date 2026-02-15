#!/usr/bin/env bash
#
# OpenAI Codex configuration
#

header "Codex"

if ! command -v codex &> /dev/null; then
    info "Codex not installed, skipping configuration"
    return 0 2>/dev/null || exit 0
fi

mkdir -p "$HOME/.codex"

# config.toml: copy, not symlink - codex doesn't support symlinked config
if [[ ! -f "$HOME/.codex/config.toml" ]]; then
    cp "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml"
    info "Copied codex config to ~/.codex/config.toml"
else
    info "Codex config already exists at ~/.codex/config.toml"
fi

# AGENTS.md: symlink for global instructions
create_symlink "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
