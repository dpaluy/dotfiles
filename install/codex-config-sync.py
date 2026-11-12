#!/usr/bin/env python3
"""Report or apply drift between the dotfiles Codex config and the live copy.

Codex config.toml is copied, not symlinked, and Codex writes machine-local
state into it (project trust, MCP servers, plugins). This script syncs only the
managed keys listed below and leaves every other line of the live file alone.

    codex-config-sync.py SOURCE LIVE            list drifted managed keys
    codex-config-sync.py SOURCE LIVE --apply    back up LIVE, then sync them
"""

from __future__ import annotations

import re
import shutil
import sys
import time
from typing import Dict, List, Optional, Tuple

MANAGED: List[Tuple[Optional[str], str]] = [
    (None, "model"),
    (None, "model_reasoning_effort"),
    (None, "sandbox_mode"),
    (None, "approval_policy"),
    (None, "approvals_reviewer"),
    (None, "developer_instructions"),
    ("agents", "default_subagent_model"),
    ("agents", "default_subagent_reasoning_effort"),
    ("features", "guardian_approval"),
]

HEADER = re.compile(r"^\s*\[\[?\s*([^\]]+?)\s*\]\]?\s*(#.*)?$")
KEY = re.compile(r"^\s*([A-Za-z0-9_-]+)\s*=\s*(.*)$")

Span = Tuple[int, int]


def parse(lines: List[str]) -> Tuple[Dict[Tuple[Optional[str], str], Span], Dict[str, int]]:
    spans: Dict[Tuple[Optional[str], str], Span] = {}
    tables: Dict[str, int] = {}
    table: Optional[str] = None
    index = 0
    while index < len(lines):
        line = lines[index]
        header = HEADER.match(line)
        if header:
            table = header.group(1)
            tables.setdefault(table, index)
            index += 1
            continue
        key = KEY.match(line)
        if not key:
            index += 1
            continue
        end = index + 1
        value = key.group(2)
        for quote in ('"""', "'''"):
            if value.startswith(quote) and quote not in value[3:]:
                while end < len(lines) and quote not in lines[end]:
                    end += 1
                end = min(end + 1, len(lines))
                break
        spans.setdefault((table, key.group(1)), (index, end))
        index = end
    return spans, tables


def text_of(lines: List[str], span: Span) -> str:
    return "".join(lines[span[0]:span[1]])


def label(table: Optional[str], key: str) -> str:
    return f"{table}.{key}" if table else key


def summarize(text: Optional[str]) -> str:
    if text is None:
        return "(unset)"
    value = text.split("=", 1)[1].strip()
    return value if len(value) <= 40 and "\n" not in value else "(changed text)"


def drift(source: List[str], live: List[str]) -> List[Tuple[Optional[str], str, Optional[str], str]]:
    source_spans, _ = parse(source)
    live_spans, _ = parse(live)
    changes = []
    for table, key in MANAGED:
        if (table, key) not in source_spans:
            continue
        wanted = text_of(source, source_spans[(table, key)])
        current = text_of(live, live_spans[(table, key)]) if (table, key) in live_spans else None
        if current is None or current.strip() != wanted.strip():
            changes.append((table, key, current, wanted))
    return changes


def apply(source: List[str], live: List[str]) -> List[str]:
    for table, key, _current, wanted in drift(source, live):
        block = wanted if wanted.endswith("\n") else wanted + "\n"
        new_lines = block.splitlines(keepends=True)
        spans, tables = parse(live)
        if (table, key) in spans:
            start, end = spans[(table, key)]
            live[start:end] = new_lines
        elif table is None:
            first_table = min(tables.values()) if tables else len(live)
            live[first_table:first_table] = new_lines
        elif table in tables:
            position = tables[table] + 1
            live[position:position] = new_lines
        else:
            if live and not live[-1].endswith("\n"):
                live[-1] += "\n"
            live.extend(["\n", f"[{table}]\n", *new_lines])
    return live


def main(argv: List[str]) -> int:
    if len(argv) not in (3, 4) or (len(argv) == 4 and argv[3] != "--apply"):
        print(__doc__, file=sys.stderr)
        return 2
    source_path, live_path = argv[1], argv[2]
    with open(source_path, encoding="utf-8") as handle:
        source = handle.readlines()
    with open(live_path, encoding="utf-8") as handle:
        live = handle.readlines()

    changes = drift(source, live)
    for table, key, current, wanted in changes:
        print(f"{label(table, key)}: {summarize(current)} -> {summarize(wanted)}")
    if len(argv) == 4 and changes:
        shutil.copy2(live_path, f"{live_path}.backup.{time.strftime('%Y%m%d%H%M%S')}")
        with open(live_path, "w", encoding="utf-8") as handle:
            handle.writelines(apply(source, live))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
