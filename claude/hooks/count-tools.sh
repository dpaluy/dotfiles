#!/bin/bash
# PostToolUse hook: increments per-turn tool call counter
COUNTER_FILE="/tmp/claude-tool-count"
count=0
[ -f "$COUNTER_FILE" ] && count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
echo $((count + 1)) > "$COUNTER_FILE"
exit 0
