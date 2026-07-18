#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_contains() {
    local file="$1"
    local pattern="$2"
    rg -q --fixed-strings -- "$pattern" "$file" || fail "$file is missing: $pattern"
}

assert_not_contains() {
    local file="$1"
    local pattern="$2"
    ! rg -q --fixed-strings -- "$pattern" "$file" || fail "$file still contains: $pattern"
}

assert_contains "$ROOT_DIR/harden-mac.sh" 'sudo systemsetup -getremotelogin'
assert_contains "$ROOT_DIR/install/lib.sh" 'normalize_release_arch()'
assert_contains "$ROOT_DIR/install/lib.sh" 'verify_sha256_checksum()'
assert_contains "$ROOT_DIR/install/lib.sh" 'DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$LIB_DIR/.." && pwd)}"'
assert_contains "$ROOT_DIR/install/linux.sh" 'DIFFNAV_ARCH="$(normalize_release_arch)"'
assert_contains "$ROOT_DIR/install/linux.sh" 'LAZYGIT_ARCH="$(normalize_release_arch)"'
assert_contains "$ROOT_DIR/install/linux.sh" 'lazygit_${LAZYGIT_VERSION}_linux_${LAZYGIT_ARCH}.tar.gz'
assert_contains "$ROOT_DIR/install/linux.sh" 'SESH_ARCH="$(normalize_release_arch)"'
assert_contains "$ROOT_DIR/install/skills.sh" 'Usage: ./install/skills.sh'
assert_contains "$ROOT_DIR/install/skills.sh" 'source "$SCRIPT_DIR/lib.sh"'
assert_contains "$ROOT_DIR/zsh/ai-tools/codex" '--dangerously-bypass-approvals-and-sandbox'
assert_not_contains "$ROOT_DIR/zsh/ai-tools/codex" '--profile'
assert_contains "$ROOT_DIR/codex/config.toml" 'personality = "pragmatic"'
assert_contains "$ROOT_DIR/codex/config.toml" 'model_verbosity = "low"'
assert_not_contains "$ROOT_DIR/codex/config.toml" 'plan_mode_reasoning_effort'
assert_contains "$ROOT_DIR/codex/config.toml" 'Delegate only when useful:'
assert_contains "$ROOT_DIR/install/codex.sh" 'block-destructive-commands.py'
[[ -x "$ROOT_DIR/codex/hooks/block-destructive-commands.py" ]] \
    || fail "missing executable Codex destructive-command hook"
python3 -m json.tool "$ROOT_DIR/codex/hooks.json" >/dev/null \
    || fail "codex/hooks.json is invalid JSON"
python3 "$ROOT_DIR/test/test_codex_hook.py"
for profile in dev fast quick research; do
    [[ ! -e "$ROOT_DIR/codex/$profile.config.toml" ]] \
        || fail "obsolete Codex profile still exists: $profile"
done
assert_not_contains "$ROOT_DIR/codex/config.toml" 'model_context_window'
assert_not_contains "$ROOT_DIR/codex/config.toml" 'model_auto_compact_token_limit'
assert_contains "$ROOT_DIR/ghostty/config" 'config-file = ?"~/.config/ghostty/platform.conf"'
assert_contains "$ROOT_DIR/install/symlinks.sh" 'ghostty_platform="$DOTFILES_DIR/ghostty/macos.conf"'
assert_contains "$ROOT_DIR/install/symlinks.sh" 'create_zshenv_wrapper'
assert_contains "$ROOT_DIR/install/symlinks.sh" 'ensure_zprofile_source'
assert_contains "$ROOT_DIR/install/claude.sh" 'mise-environment.sh'
[[ -f "$ROOT_DIR/ghostty/macos.conf" ]] || fail "missing ghostty/macos.conf"
[[ -f "$ROOT_DIR/ghostty/linux.conf" ]] || fail "missing ghostty/linux.conf"
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = ctrl+shift+w=close_surface'
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = super+d=new_split:right'
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = super+shift+d=new_split:down'
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = ctrl+shift+g=equalize_splits'
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = shift+enter=text:\n'
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = ctrl+shift+r=prompt_surface_title'
[[ -f "$ROOT_DIR/zsh/zshenv" ]] || fail "missing zsh/zshenv"
[[ -f "$ROOT_DIR/zsh/zprofile" ]] || fail "missing zsh/zprofile"
[[ -x "$ROOT_DIR/claude/hooks/mise-environment.sh" ]] || fail "missing executable Claude mise environment hook"

assert_not_contains "$ROOT_DIR/README.md" 'min-release-age'
assert_not_contains "$ROOT_DIR/README.md" 'Comment out macOS section'
assert_not_contains "$ROOT_DIR/install/symlinks.sh" 'source "$HOME/dotfiles/zsh/zshrc"'

[[ "$(bash -c 'source "$1"; normalize_release_arch aarch64' _ "$ROOT_DIR/install/lib.sh")" == "arm64" ]] \
    || fail "aarch64 did not normalize to arm64"
[[ "$(bash -c 'source "$1"; normalize_release_arch x86_64' _ "$ROOT_DIR/install/lib.sh")" == "x86_64" ]] \
    || fail "x86_64 did not normalize to x86_64"

"$ROOT_DIR/install/skills.sh" --help | rg -q '^Usage: ./install/skills.sh' \
    || fail "install/skills.sh --help is not usable standalone"

shim_home="$(mktemp -d)"
trap 'rm -rf "$shim_home"' EXIT
mkdir -p "$shim_home/.local/share/mise/shims"
shim_path="$(HOME="$shim_home" PATH="/usr/bin:/bin:$shim_home/.local/share/mise/shims" zsh -f -c '
    source "$1"
    source "$1"
    print -r -- "$PATH"
' _ "$ROOT_DIR/zsh/zshenv")"
expected_shim_path="$shim_home/.local/share/mise/shims:/usr/bin:/bin"
[[ "$shim_path" == "$expected_shim_path" ]] \
    || fail "zshenv did not prepend the mise shim directory exactly once"

login_path="$(HOME="$shim_home" DOTFILES_DIR="$ROOT_DIR" PATH="/usr/bin:/bin:$shim_home/.local/share/mise/shims" zsh -f -c '
    source "$1"
    print -r -- "$PATH"
' _ "$ROOT_DIR/zsh/zprofile")"
[[ "$login_path" == "$expected_shim_path" ]] \
    || fail "zprofile did not restore mise shims after login PATH setup"

claude_env_file="$shim_home/claude-env"
HOME="$shim_home" CLAUDE_ENV_FILE="$claude_env_file" "$ROOT_DIR/claude/hooks/mise-environment.sh"
HOME="$shim_home" CLAUDE_ENV_FILE="$claude_env_file" "$ROOT_DIR/claude/hooks/mise-environment.sh"
[[ "$(wc -l < "$claude_env_file" | tr -d " ")" == "1" ]] \
    || fail "Claude mise environment hook wrote duplicate exports"
assert_contains "$claude_env_file" 'export PATH="$HOME/.local/share/mise/shims:$PATH"'

resume_args="$(HOME=/private/tmp/dotfiles-cdx-test zsh -f -c '
    codex() { print -rl -- "$@"; }
    source "$1"
    cdx -r
' _ "$ROOT_DIR/zsh/ai-tools/codex")"
expected_resume_args=$'--dangerously-bypass-approvals-and-sandbox\n--search\nresume\n--last'
[[ "$resume_args" == "$expected_resume_args" ]] \
    || fail "cdx -r did not resume the most recent session"

explicit_resume_args="$(HOME=/private/tmp/dotfiles-cdx-test zsh -f -c '
    codex() { print -rl -- "$@"; }
    source "$1"
    cdx --resume session-123
' _ "$ROOT_DIR/zsh/ai-tools/codex")"
expected_explicit_resume_args=$'--dangerously-bypass-approvals-and-sandbox\n--search\nresume\nsession-123'
[[ "$explicit_resume_args" == "$expected_explicit_resume_args" ]] \
    || fail "cdx --resume did not preserve the explicit session ID"

echo "dotfiles behavior checks passed"
