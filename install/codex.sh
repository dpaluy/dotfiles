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

# Profile configs: copy, not symlink, matching config.toml behavior
for profile_config in "$DOTFILES_DIR/codex/"*.config.toml; do
    [[ -f "$profile_config" ]] || continue
    profile_name="$(basename "$profile_config")"
    profile_dest="$HOME/.codex/$profile_name"

    if [[ ! -f "$profile_dest" ]]; then
        cp "$profile_config" "$profile_dest"
        info "Copied codex profile config to ~/.codex/$profile_name"
    else
        info "Codex profile config already exists at ~/.codex/$profile_name"
    fi
done

# Migrate deprecated hook feature flags while preserving native hook support.
# Keep MCP, skills, prompts, AGENTS.md, and non-OMX hooks intact.
if [[ -f "$HOME/.codex/config.toml" ]]; then
    perl -0pi -e 's/^(\s*)codex_hooks(\s*=\s*true\s*)$/${1}hooks${2}/mg' "$HOME/.codex/config.toml"
fi

for profile_config in "$HOME/.codex/"*.config.toml; do
    [[ -f "$profile_config" ]] || continue
    perl -0pi -e 's/\n?\[hooks\.state\."[^"]*hooks\.json:[^"]*"\]\n(?:[^\[]*?)(?=\n\[|\z)/\n/g; s/\n?\[hooks\.state\]\n\s*(?=\[|\z)/\n/g' "$profile_config"
done

if [[ -f "$HOME/.codex/hooks.json" ]]; then
    if command -v jq &>/dev/null; then
        tmp="$(mktemp)"
        if jq '
            def omx_hook:
                ((.command // "") | contains("codex-native-hook.js"));

            .hooks |= (
                with_entries(
                    .value |= (
                        map(.hooks = ((.hooks // []) | map(select(omx_hook | not))))
                        | map(select(((.hooks // []) | length) > 0))
                    )
                )
                | with_entries(select((.value | length) > 0))
            )
            | if ((.hooks // {}) | length) == 0 then del(.hooks) else . end
        ' "$HOME/.codex/hooks.json" > "$tmp"; then
            command mv -f "$tmp" "$HOME/.codex/hooks.json"
            if [[ ! -s "$HOME/.codex/hooks.json" || "$(jq -r 'keys | length' "$HOME/.codex/hooks.json")" == "0" ]]; then
                command rm -f "$HOME/.codex/hooks.json"
            fi
        else
            command rm -f "$tmp"
            warn "Failed to clean OMX hooks from ~/.codex/hooks.json"
        fi
    else
        warn "jq not found, leaving ~/.codex/hooks.json unchanged"
    fi
fi

# AGENTS.md: symlink for global instructions
create_symlink "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

# Skills: symlink each skill directory from dotfiles into ~/.codex/skills/
if [[ -d "$DOTFILES_DIR/codex/skills" ]]; then
    mkdir -p "$HOME/.codex/skills"
    for skill_dir in "$DOTFILES_DIR/codex/skills"/*/; do
        skill_name="$(basename "$skill_dir")"
        create_symlink "$skill_dir" "$HOME/.codex/skills/$skill_name"
    done
fi
