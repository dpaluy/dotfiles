#!/usr/bin/env bash
# SessionStart hook: persist mise shims for Claude's non-interactive Bash tools.

[[ -n "${CLAUDE_ENV_FILE:-}" ]] || exit 0
[[ -d "$HOME/.local/share/mise/shims" ]] || exit 0

line='export PATH="$HOME/.local/share/mise/shims:$PATH"'
if [[ ! -f "$CLAUDE_ENV_FILE" ]] || ! grep -Fqx "$line" "$CLAUDE_ENV_FILE"; then
    printf '%s\n' "$line" >> "$CLAUDE_ENV_FILE"
fi
