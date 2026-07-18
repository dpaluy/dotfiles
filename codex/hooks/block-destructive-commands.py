#!/usr/bin/env python3
"""Block destructive shell command prefixes before Codex executes them."""

from __future__ import annotations

import json
import sys
from typing import Any


BLOCKED_PREFIXES = (
    ("rm -rf /*", "Never delete the contents of the root filesystem."),
    ("rm -rf $HOME", "Never delete the entire home directory."),
    ("rm -rf /Users", "Never delete all user directories."),
    ("rm -rf /System", "Never delete macOS system files."),
    ("rm -rf /", "Never delete the root filesystem."),
    ("rm -rf ~", "Never delete the entire home directory."),
    ("diskutil eraseDisk", "Never erase or repartition a disk."),
    ("diskutil eraseVolume", "Never erase or repartition a disk."),
    ("diskutil partitionDisk", "Never erase or repartition a disk."),
    ("mkfs", "Never format a filesystem."),
)


def deny(reason: str) -> None:
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
    )
    sys.stdout.write("\n")


def read_command() -> str:
    try:
        payload: Any = json.load(sys.stdin)
        command = payload["tool_input"]["command"]
    except (json.JSONDecodeError, KeyError, TypeError) as error:
        raise ValueError("Invalid PreToolUse payload: expected tool_input.command") from error

    if not isinstance(command, str):
        raise ValueError("Invalid PreToolUse payload: tool_input.command must be a string")

    return command.lstrip()


def main() -> int:
    try:
        command = read_command()
    except ValueError as error:
        print(f"Destructive-command guard blocked malformed input: {error}", file=sys.stderr)
        return 2

    for prefix, reason in BLOCKED_PREFIXES:
        if command.startswith(prefix):
            deny(reason)
            break

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
