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

    def test_allows_unlisted_commands_without_output(self) -> None:
        for command in ("rm -rf ./build", "diskutil list", "echo safe"):
            with self.subTest(command=command):
                result = self.run_hook({"tool_input": {"command": command}})
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")
                self.assertEqual(result.stderr, "")

    def test_malformed_payload_fails_closed(self) -> None:
        result = self.run_hook({"tool_input": {}})

        self.assertEqual(result.returncode, 2)
        self.assertIn("expected tool_input.command", result.stderr)


if __name__ == "__main__":
    unittest.main()
