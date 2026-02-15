#!/bin/bash
# UserPromptSubmit hook: suggests optimization when previous turn had 8+ tool calls
COUNTER_FILE="/tmp/claude-tool-count"

# Read and reset counter from previous turn
count=0
[ -f "$COUNTER_FILE" ] && count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
echo 0 > "$COUNTER_FILE"

# Skip if fewer than 8 tool calls
[ "${count:-0}" -lt 8 ] && exit 0

# Read user prompt from stdin JSON
prompt=$(jq -r '.prompt // empty' 2>/dev/null)

# Skip if exploratory (questions, investigation, browsing)
if echo "$prompt" | grep -qiE '(^\s*(what|how|why|where|who|which|show|explain|describe|list|find|search|explore|investigate|browse|check|review|analyze|understand)\b|\?\s*$)'; then
  exit 0
fi

echo "Previous turn used ${count} tool calls. Append ONE actionable optimization hint (reusable skill, memory pattern, or workflow fix) as a blockquote. One sentence max."
