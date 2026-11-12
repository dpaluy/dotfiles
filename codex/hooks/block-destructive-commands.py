#!/usr/bin/env python3
"""Block destructive shell commands before Codex executes them.

The command is tokenized and each simple command is inspected, so wrappers
(`sudo`, `env`, `bash -c`), flag spellings (`-fr`, `-r -f`, `--recursive`), and
chained commands (`cd / && rm -rf *`) are covered, while quoted text and
ordinary absolute paths (`rm -rf /tmp/build`) are not blocked.
"""

from __future__ import annotations

import json
import os
import posixpath
import re
import shlex
import sys
from typing import Any, Iterable, Optional


ROOT = "Never delete the root filesystem."
ROOT_CONTENTS = "Never delete the contents of the root filesystem."
HOME = "Never delete the entire home directory."
USERS = "Never delete all user directories."
SYSTEM = "Never delete macOS system files."
TOP_LEVEL = "Never delete a top-level system directory."
DISK = "Never erase or repartition a disk."
FORMAT = "Never format a filesystem."

SEPARATORS = set("();<>|&")
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
WRAPPERS = {"sudo", "doas", "env", "command", "exec", "nohup", "time", "builtin"}
SUDO_OPTIONS_WITH_VALUE = {"-u", "-g", "-h", "-p", "-C", "-D", "-R", "-T", "-U"}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}
HOME_TOKENS = {"~", "$HOME", "${HOME}"}
USER_ROOTS = {"/Users", "/home"}
DISKUTIL_VERBS = {
    "erasedisk",
    "erasevolume",
    "partitiondisk",
    "reformat",
    "zerodisk",
    "randomdisk",
    "secureerase",
}


def tokenize(command: str) -> list[str]:
    command = command.replace("\n", " ; ")
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    try:
        return list(lexer)
    except ValueError:
        return command.split()


def segments(tokens: Iterable[str]) -> Iterable[list[str]]:
    current: list[str] = []
    for token in tokens:
        if token and set(token) <= SEPARATORS:
            if current:
                yield current
            current = []
        else:
            current.append(token)
    if current:
        yield current


def strip_wrappers(words: list[str]) -> list[str]:
    index = 0
    while index < len(words):
        word = words[index]
        if ASSIGNMENT.match(word):
            index += 1
            continue
        if posixpath.basename(word) in WRAPPERS:
            index += 1
            while index < len(words) and words[index].startswith("-"):
                index += 2 if words[index] in SUDO_OPTIONS_WITH_VALUE else 1
            continue
        break
    return words[index:]


def expand_home(path: str) -> str:
    for token in ("${HOME}", "$HOME", "~"):
        if path == token or path.startswith(token + "/"):
            return "~" + path[len(token):]
    home = os.path.expanduser("~").rstrip("/")
    if home and home != "/" and (path == home or path.startswith(home + "/")):
        return "~" + path[len(home):]
    return path


def resolve(target: str, cwd: Optional[str]) -> str:
    path = expand_home(target)
    if not path.startswith(("/", "~")) and cwd is not None:
        path = cwd.rstrip("/") + "/" + path
    if path.startswith("~"):
        rest = posixpath.normpath("/" + path[1:].lstrip("/"))
        return "~" if rest == "/" else "~" + rest
    if path.startswith("/"):
        return posixpath.normpath("/" + path.lstrip("/"))
    return path


def classify_target(path: str) -> Optional[str]:
    if path == "/":
        return ROOT
    if path == "/*":
        return ROOT_CONTENTS
    if path in {"~", "~/*"}:
        return HOME
    base = path[:-2] if path.endswith("/*") else path
    if base in USER_ROOTS:
        return USERS
    if base == "/System" or base.startswith("/System/"):
        return SYSTEM
    if path.startswith("/") and base.count("/") == 1 and path != "/tmp/*":
        return TOP_LEVEL
    return None


def check_rm(args: list[str], cwd: Optional[str]) -> Optional[str]:
    recursive = False
    targets: list[str] = []
    options_done = False
    for arg in args:
        if not options_done and arg == "--":
            options_done = True
        elif not options_done and arg.startswith("--"):
            recursive = recursive or arg == "--recursive"
        elif not options_done and arg.startswith("-") and len(arg) > 1:
            recursive = recursive or "r" in arg or "R" in arg
        else:
            targets.append(arg)
    if not recursive:
        return None
    for target in targets:
        reason = classify_target(resolve(target, cwd))
        if reason:
            return reason
    return None


def check_tokens(tokens: list[str], depth: int = 0) -> Optional[str]:
    cwd: Optional[str] = None
    for segment in segments(tokens):
        words = strip_wrappers(segment)
        if not words:
            continue
        name = posixpath.basename(words[0])
        args = words[1:]

        if name == "cd":
            destination = args[0] if args else "~"
            resolved = resolve(destination, cwd)
            cwd = resolved if resolved.startswith(("/", "~")) else None
        elif name == "rm":
            reason = check_rm(args, cwd)
            if reason:
                return reason
        elif name == "diskutil":
            verbs = [arg.lower() for arg in args if not arg.startswith("-")]
            if verbs[:1] == ["apfs"]:
                verbs = verbs[1:]
            if verbs and (verbs[0] in DISKUTIL_VERBS or verbs[0] == "deletecontainer"):
                return DISK
        elif name == "mkfs" or name.startswith(("mkfs.", "newfs")):
            return FORMAT
        elif name in SHELLS and depth < 3:
            for position, arg in enumerate(args):
                is_command_flag = arg.startswith("-") and not arg.startswith("--") and "c" in arg
                if is_command_flag and position + 1 < len(args):
                    reason = check_tokens(tokenize(args[position + 1]), depth + 1)
                    if reason:
                        return reason
                    break
    return None


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


def read_tokens() -> list[str]:
    try:
        payload: Any = json.load(sys.stdin)
        command = payload["tool_input"]["command"]
    except (json.JSONDecodeError, KeyError, TypeError) as error:
        raise ValueError("Invalid PreToolUse payload: expected tool_input.command") from error

    if isinstance(command, str):
        return tokenize(command)
    if isinstance(command, list) and all(isinstance(part, str) for part in command):
        return list(command)
    raise ValueError(
        "Invalid PreToolUse payload: tool_input.command must be a string or a list of strings"
    )


def main() -> int:
    try:
        tokens = read_tokens()
    except ValueError as error:
        print(f"Destructive-command guard blocked malformed input: {error}", file=sys.stderr)
        return 2

    reason = check_tokens(tokens)
    if reason:
        deny(reason)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
