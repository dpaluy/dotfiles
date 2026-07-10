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
assert_contains "$ROOT_DIR/codex/dev.config.toml" 'personality = "pragmatic"'
assert_not_contains "$ROOT_DIR/codex/dev.config.toml" 'model_personality'
assert_not_contains "$ROOT_DIR/codex/config.toml" 'model_context_window'
assert_not_contains "$ROOT_DIR/codex/config.toml" 'model_auto_compact_token_limit'
assert_contains "$ROOT_DIR/ghostty/config" 'config-file = ?"~/.config/ghostty/platform.conf"'
assert_contains "$ROOT_DIR/install/symlinks.sh" 'ghostty_platform="$DOTFILES_DIR/ghostty/macos.conf"'
[[ -f "$ROOT_DIR/ghostty/macos.conf" ]] || fail "missing ghostty/macos.conf"
[[ -f "$ROOT_DIR/ghostty/linux.conf" ]] || fail "missing ghostty/linux.conf"
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = ctrl+shift+w=close_surface'
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = super+d=new_split:right'
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = super+shift+d=new_split:down'
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = ctrl+shift+g=equalize_splits'
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = shift+enter=text:\n'
assert_contains "$ROOT_DIR/ghostty/linux.conf" 'keybind = ctrl+shift+r=prompt_surface_title'
assert_not_contains "$ROOT_DIR/README.md" 'min-release-age'
assert_not_contains "$ROOT_DIR/README.md" 'Comment out macOS section'
assert_not_contains "$ROOT_DIR/install/symlinks.sh" 'source "$HOME/dotfiles/zsh/zshrc"'

[[ "$(bash -c 'source "$1"; normalize_release_arch aarch64' _ "$ROOT_DIR/install/lib.sh")" == "arm64" ]] \
    || fail "aarch64 did not normalize to arm64"
[[ "$(bash -c 'source "$1"; normalize_release_arch x86_64' _ "$ROOT_DIR/install/lib.sh")" == "x86_64" ]] \
    || fail "x86_64 did not normalize to x86_64"

"$ROOT_DIR/install/skills.sh" --help | rg -q '^Usage: ./install/skills.sh' \
    || fail "install/skills.sh --help is not usable standalone"

resume_args="$(HOME=/private/tmp/dotfiles-cdx-test zsh -f -c '
    codex() { print -rl -- "$@"; }
    source "$1"
    cdx -r
' _ "$ROOT_DIR/zsh/ai-tools/codex")"
expected_resume_args=$'--profile\ndev\n--dangerously-bypass-approvals-and-sandbox\n--search\nresume\n--last'
[[ "$resume_args" == "$expected_resume_args" ]] \
    || fail "cdx -r did not resume the most recent session"

research_resume_args="$(HOME=/private/tmp/dotfiles-cdx-test zsh -f -c '
    codex() { print -rl -- "$@"; }
    source "$1"
    cdx r --resume session-123
' _ "$ROOT_DIR/zsh/ai-tools/codex")"
expected_research_resume_args=$'--profile\nresearch\n--dangerously-bypass-approvals-and-sandbox\n--search\nresume\nsession-123'
[[ "$research_resume_args" == "$expected_research_resume_args" ]] \
    || fail "cdx research --resume did not preserve the explicit session ID"

echo "dotfiles behavior checks passed"
