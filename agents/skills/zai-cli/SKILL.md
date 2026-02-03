---
name: zai-cli
description: |
  Z.AI CLI providing:
  - Vision: image/video analysis, OCR, UI-to-code, error diagnosis (GLM-4.6V)
  - Search: real-time web search with domain/recency filtering
  - Reader: web page to markdown extraction
  - Repo: GitHub code search and reading via ZRead
  - Tools: MCP tool discovery and raw calls
  - Code: TypeScript tool chaining
  Use for visual content analysis, web search, page reading, or GitHub exploration.
---

# ZAI CLI

Access Z.AI capabilities via `npx zai-cli`. The CLI is self-documenting - use `--help` at any level.

## Credentials

```bash
echo $Z_AI_API_KEY
```

## Commands

| Command | Purpose | Help |
|---------|---------|------|
| vision | Analyze images, screenshots, videos | `--help` for 8 subcommands |
| search | Real-time web search | `--help` for filtering options |
| read | Fetch web pages as markdown | `--help` for format options |
| repo | GitHub code search and reading | `--help` for tree/search/read |
| tools | List available MCP tools | |
| tool | Show tool schema | |
| call | Raw MCP tool invocation | |
| code | TypeScript tool chaining | |
| doctor | Check setup and connectivity | |

## Quick Start

```bash
# Analyze an image
npx zai-cli vision analyze ./screenshot.png "What errors do you see?"

# Search the web
npx zai-cli search "React 19 new features" --count 5

# Read a web page
npx zai-cli read https://docs.example.com/api

# Explore a GitHub repo
npx zai-cli repo search facebook/react "server components"

# Check setup
npx zai-cli doctor
```

## Output

Default: **data-only** (raw output for token efficiency).
Use `--output-format json` for `{ success, data, timestamp }` wrapping.
