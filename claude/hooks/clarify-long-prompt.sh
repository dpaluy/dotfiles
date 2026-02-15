#!/bin/bash
# UserPromptSubmit hook: ask Claude to verify intent on long prompts (>50 words)
prompt=$(jq -r '.prompt // empty' 2>/dev/null)
[ -z "$prompt" ] && exit 0

word_count=$(echo "$prompt" | wc -w | tr -d ' ')
[ "$word_count" -le 50 ] && exit 0

echo "Prompt is ${word_count} words. Before proceeding, briefly confirm your understanding of the desired outcome in one sentence."
