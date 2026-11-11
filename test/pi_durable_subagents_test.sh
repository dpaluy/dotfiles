#!/usr/bin/env bash
# Offline recovery acceptance against the installed package and Pi.
# Correct only the scripted provider's cursor for Pi 1.5's persisted aborted
# assistant turns; do not change runtime code or acceptance assertions.
set -Eeuo pipefail

agent_dir="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
package_dir="$agent_dir/npm/node_modules/pi-durable-subagents"
if [[ ! -f "$package_dir/dist/cli/main.js" ]]; then
    printf '%s\n' 'Install npm:pi-durable-subagents with Pi before running this check.' >&2
    exit 1
fi

sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
cp -R "$package_dir" "$sandbox/package"
node --input-type=module - "$sandbox/package/dist/cli/chaos/provider.js" <<'JS'
import fs from 'node:fs';
const path = process.argv[2];
const original = fs.readFileSync(path, 'utf8');
const old = 'const cursor = answered.filter(m => m.provider === "dsa-chaos").length;';
const fixed = 'const cursor = answered.filter(m => m.provider === "dsa-chaos" && m.stopReason !== "aborted").length;';
// Fail closed when upstream changes: inspect the new harness rather than
// silently applying an obsolete workaround or weakening the assertions.
if (original.split(old).length !== 2) {
    throw new Error('Upstream chaos cursor changed; reassess the Pi 1.5 compatibility correction.');
}
fs.writeFileSync(path, original.replace(old, fixed));
console.log('Test-only correction: exclude aborted assistant turns from scripted response cursor.');
JS
node "$sandbox/package/dist/cli/main.js" smoke
node "$sandbox/package/dist/cli/main.js" chaos "$@"
