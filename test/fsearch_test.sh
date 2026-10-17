#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_DIR="$ROOT_DIR"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
export HOME="$TEST_DIR/home"
mkdir -p "$HOME"
export OSTYPE=darwin
info() { echo "INFO: $*"; }
warn() { echo "WARN: $*"; }
ask_yes_no() { return 0; }
uname() { echo "${TEST_ARCH:-arm64}"; }
# Mock download/installation: never execute the upstream installer in tests.
curl() { [[ "${FAIL_DOWNLOAD:-0}" == 0 ]]; }
shasum() { cat >/dev/null; [[ "${FAIL_CHECKSUM:-0}" == 0 ]]; }
tar() {
    cat > fsearch <<'SH'
#!/usr/bin/env bash
[[ "$1" == install ]] || exit 1
mkdir -p "$HOME/.local/bin"
printf '#!/bin/sh\nexit 0\n' > "$HOME/.local/bin/fsearch"
chmod +x "$HOME/.local/bin/fsearch"
SH
    chmod +x fsearch
}
claude() {
    [[ "$*" == "mcp add fsearch --transport stdio --scope user -- $HOME/.local/bin/fsearch mcp" ]]
    echo claude >> "$TEST_DIR/registrations"
    mkdir -p "$HOME/.claude"
    jq -n --arg bin "$HOME/.local/bin/fsearch" \
        '{mcpServers:{fsearch:{command:$bin,args:["mcp"]}}}' > "$HOME/.claude.json"
}
codex() {
    [[ "$*" == "mcp add fsearch -- $HOME/.local/bin/fsearch mcp" ]]
    echo codex >> "$TEST_DIR/registrations"
    mkdir -p "$HOME/.codex"
    printf '[mcp_servers.fsearch]\ncommand = "%s"\nargs = ["mcp"]\n' "$HOME/.local/bin/fsearch" >> "$HOME/.codex/config.toml"
}
pi() { return 0; }
check_configs() {
    jq -e --arg bin "$HOME/.local/bin/fsearch" \
        '.mcpServers.fsearch == {command:$bin,args:["mcp"]}' "$HOME/.pi/agent/mcp.json" >/dev/null
    [[ "$(wc -l < "$TEST_DIR/registrations" | tr -d ' ')" == 2 ]]
}
# Fresh install creates the binary and all three MCP registrations.
source "$ROOT_DIR/install/fsearch.sh"
[[ -x "$HOME/.local/bin/fsearch" ]]
check_configs
head -n "$(wc -l < "$ROOT_DIR/codex/config.toml" | tr -d ' ')" "$HOME/.codex/config.toml" > "$TEST_DIR/codex-template"
cmp "$ROOT_DIR/codex/config.toml" "$TEST_DIR/codex-template"
echo 'ok - fresh release install and MCP registration (mocked download and CLIs)'
# Re-run must neither download nor invoke registration CLIs nor rewrite files.
/usr/bin/shasum -a 256 "$HOME/.local/bin/fsearch" "$HOME/.claude.json" \
    "$HOME/.pi/agent/mcp.json" "$HOME/.codex/config.toml" > "$TEST_DIR/before"
curl() { echo 'unexpected download' >&2; return 1; }
source "$ROOT_DIR/install/fsearch.sh"
/usr/bin/shasum -a 256 "$HOME/.local/bin/fsearch" "$HOME/.claude.json" \
    "$HOME/.pi/agent/mcp.json" "$HOME/.codex/config.toml" > "$TEST_DIR/after"
cmp "$TEST_DIR/before" "$TEST_DIR/after"
check_configs
echo 'ok - repeat run leaves binary and all configs byte-unchanged'
# Existing pi servers survive insertion of fsearch.
echo '{"mcpServers":{"other":{"command":"keep-me"}},"otherSetting":true}' > "$HOME/.pi/agent/mcp.json"
source "$ROOT_DIR/install/fsearch.sh"
jq -e '.mcpServers.other.command == "keep-me" and .otherSetting and .mcpServers.fsearch.args == ["mcp"]' "$HOME/.pi/agent/mcp.json" >/dev/null
echo 'ok - preserves unrelated pi config'
# Invalid pi JSON is not overwritten.
printf 'invalid json\n' > "$HOME/.pi/agent/mcp.json"
source "$ROOT_DIR/install/fsearch.sh" 2>/dev/null
grep -qx 'invalid json' "$HOME/.pi/agent/mcp.json"
echo 'ok - invalid pi config left untouched'
# Unsupported systems do not attempt installation/registration.
export HOME="$TEST_DIR/unsupported"
export OSTYPE=linux-gnu
source "$ROOT_DIR/install/fsearch.sh"
[[ ! -e "$HOME" ]]
export OSTYPE=darwin
TEST_ARCH=x86_64
source "$ROOT_DIR/install/fsearch.sh"
[[ ! -e "$HOME" ]]
unset TEST_ARCH
echo 'ok - Linux and Intel macOS skip unsupported release'
# Failed download/checksum never installs or registers anything.
curl() { [[ "${FAIL_DOWNLOAD:-0}" == 0 ]]; }
FAIL_DOWNLOAD=1
source "$ROOT_DIR/install/fsearch.sh"
[[ ! -e "$HOME" ]]
FAIL_DOWNLOAD=0
FAIL_CHECKSUM=1
source "$ROOT_DIR/install/fsearch.sh"
[[ ! -e "$HOME" ]]
echo 'ok - failed download/checksum does not install or register'
