#!/usr/bin/env python3
"""Focused tests for the destructive-command PreToolUse hook."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import unittest


HOOK = Path(__file__).parents[1] / "codex" / "hooks" / "block-destructive-commands.py"


class DestructiveCommandHookTest(unittest.TestCase):
    def run_hook(self, payload: object) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(HOOK)],
            input=json.dumps(payload),
            capture_output=True,
            check=False,
            text=True,
        )

    def test_blocks_every_requested_prefix_with_its_reason(self) -> None:
        cases = {
            "rm -rf /": "Never delete the root filesystem.",
            "rm -rf /*": "Never delete the contents of the root filesystem.",
            "rm -rf ~": "Never delete the entire home directory.",
            "rm -rf $HOME": "Never delete the entire home directory.",
            "rm -rf /Users": "Never delete all user directories.",
            "rm -rf /System": "Never delete macOS system files.",
            "diskutil eraseDisk disk0": "Never erase or repartition a disk.",
            "diskutil eraseVolume APFS Test disk1": "Never erase or repartition a disk.",
            "diskutil partitionDisk disk0 GPT APFS Test 100%": (
                "Never erase or repartition a disk."
            ),
            "mkfs.ext4 /dev/disk1": "Never format a filesystem.",
        }

        for command, reason in cases.items():
            with self.subTest(command=command):
                result = self.run_hook({"tool_input": {"command": f"  {command}"}})
                self.assertEqual(result.returncode, 0)
                output = json.loads(result.stdout)
                self.assertEqual(
                    output["hookSpecificOutput"],
                    {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": "deny",
                        "permissionDecisionReason": reason,
                    },
                )

    def reason_for(self, command: object) -> str | None:
        result = self.run_hook({"tool_input": {"command": command}})
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stderr, "")
        if not result.stdout:
            return None
        return json.loads(result.stdout)["hookSpecificOutput"]["permissionDecisionReason"]

    def test_blocks_wrapped_reordered_and_chained_forms(self) -> None:
        cases = {
            "sudo rm -rf /": "Never delete the root filesystem.",
            "sudo -u root rm -rf /": "Never delete the root filesystem.",
            "rm -fr /": "Never delete the root filesystem.",
            "rm -r -f /": "Never delete the root filesystem.",
            "rm --recursive --force /": "Never delete the root filesystem.",
            "rm -rf -- /": "Never delete the root filesystem.",
            "rm -rf /tmp/../": "Never delete the root filesystem.",
            "/bin/rm -rf /": "Never delete the root filesystem.",
            "FOO=1 rm -rf /": "Never delete the root filesystem.",
            "echo ok && rm -rf /": "Never delete the root filesystem.",
            "echo ok\nrm -rf /": "Never delete the root filesystem.",
            "bash -lc 'rm -rf /'": "Never delete the root filesystem.",
            "cd / && rm -rf *": "Never delete the contents of the root filesystem.",
            "rm -rf ./build /": "Never delete the root filesystem.",
            'rm -rf "$HOME/"': "Never delete the entire home directory.",
            "rm -rf ${HOME}": "Never delete the entire home directory.",
            "rm -rf ~/*": "Never delete the entire home directory.",
            "cd ~ && rm -rf *": "Never delete the entire home directory.",
            "rm -rf /Users/*": "Never delete all user directories.",
            "rm -rf /System/Library": "Never delete macOS system files.",
            "rm -rf /usr": "Never delete a top-level system directory.",
            "sudo diskutil eraseDisk APFS Test disk0": "Never erase or repartition a disk.",
            "diskutil apfs deleteContainer disk1": "Never erase or repartition a disk.",
            "sudo mkfs.ext4 /dev/disk1": "Never format a filesystem.",
        }

        for command, reason in cases.items():
            with self.subTest(command=command):
                self.assertEqual(self.reason_for(command), reason)

    def test_blocks_argv_list_payloads(self) -> None:
        self.assertEqual(
            self.reason_for(["bash", "-lc", "rm -rf /"]),
            "Never delete the root filesystem.",
        )

    def test_allows_safe_commands_without_output(self) -> None:
        commands = (
            "rm -rf ./build",
            "rm -rf /tmp/build",
            "rm -rf /tmp/*",
            "rm -rf ~/projects/app/tmp",
            "rm -rf $HOME/.cache/thing",
            "rm -rf /Users/someone/project/node_modules",
            "rm /",
            "cd /tmp && rm -rf *",
            "cd app && rm -rf *",
            'echo "rm -rf /"',
            "git commit -m 'rm -rf / is blocked'",
            "grep -r 'mkfs' docs",
            "diskutil list",
            "diskutil apfs list",
            "echo safe",
        )
        for command in commands:
            with self.subTest(command=command):
                result = self.run_hook({"tool_input": {"command": command}})
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")
                self.assertEqual(result.stderr, "")

    def test_malformed_payload_fails_closed(self) -> None:
        result = self.run_hook({"tool_input": {}})

        self.assertEqual(result.returncode, 2)
        self.assertIn("expected tool_input.command", result.stderr)

        result = self.run_hook({"tool_input": {"command": 7}})

        self.assertEqual(result.returncode, 2)
        self.assertIn("must be a string or a list of strings", result.stderr)


if __name__ == "__main__":
    unittest.main()
