#!/usr/bin/env bash
#
# Agent Skills Setup (shared across AI tools)
# Symlinks dotfiles skills + external skill repos into standard locations
#

# ─────────────────────────────────────────────────────────────────────────────
# Dotfiles skills (agents/skills/)
# ─────────────────────────────────────────────────────────────────────────────
# The Agent Skills standard (agentskills.io) uses ~/.agents/
# Always set up skills if the directory exists — tools may already be installed

if [[ -d "$DOTFILES_DIR/agents/skills" ]]; then
    # ~/.agents/skills: shared Agent Skills standard (agentskills.io)
    if ask_yes_no "Symlink dotfiles skills into ~/.agents/skills?"; then
        mkdir -p "$HOME/.agents/skills"
        for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
            [[ -d "$skill_dir" ]] || continue
            skill_name="$(basename "$skill_dir")"
            create_symlink "$skill_dir" "$HOME/.agents/skills/$skill_name"
        done
    fi

    # ~/.claude/skills: Claude Code skills
    if ($install_claude || command -v claude &> /dev/null) && ask_yes_no "Symlink dotfiles skills into ~/.claude/skills?"; then
        mkdir -p "$HOME/.claude/skills"
        for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
            [[ -d "$skill_dir" ]] || continue
            skill_name="$(basename "$skill_dir")"
            create_symlink "$skill_dir" "$HOME/.claude/skills/$skill_name"
        done
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Shaping Skills (Shape Up methodology for Claude Code)
# https://github.com/rjs/shaping-skills
# ─────────────────────────────────────────────────────────────────────────────
if ($install_claude || command -v claude &> /dev/null) && ask_yes_no "Install shaping skills (Shape Up methodology for Claude Code)?"; then
    SHAPING_SKILLS_DIR="$HOME/.local/share/shaping-skills"
    if [[ -d "$SHAPING_SKILLS_DIR/.git" ]]; then
        info "Updating shaping-skills..."
        git -C "$SHAPING_SKILLS_DIR" pull --ff-only 2>/dev/null || warn "Could not update shaping-skills (pull failed)"
    else
        info "Cloning shaping-skills..."
        mkdir -p "$(dirname "$SHAPING_SKILLS_DIR")"
        git clone https://github.com/rjs/shaping-skills.git "$SHAPING_SKILLS_DIR"
    fi

    if [[ -d "$SHAPING_SKILLS_DIR" ]]; then
        mkdir -p "$HOME/.claude/skills"
        for skill_dir in "$SHAPING_SKILLS_DIR"/*/; do
            [[ -d "$skill_dir" ]] || continue
            skill_name="$(basename "$skill_dir")"
            # Skip non-skill directories (e.g., hooks)
            ls "$skill_dir"[Ss][Kk][Ii][Ll][Ll].[Mm][Dd] &>/dev/null || continue
            create_symlink "$skill_dir" "$HOME/.claude/skills/$skill_name"
        done
        info "Shaping skills linked into ~/.claude/skills/"
    fi
fi
