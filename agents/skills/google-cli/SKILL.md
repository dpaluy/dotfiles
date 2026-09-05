---
name: google-cli
description: Use the gws CLI for Google Workspace operations when the user requests gws or an available connector does not cover the task.
allowed-tools: Bash(gws:*)
---

# Google Workspace CLI

Use the user's chosen connector when it covers the task. For CLI work, check `gws auth list` and select the intended account with `--account EMAIL`.

Inspect `gws schema <method>` for the operation's current parameters. Use structured JSON for request parameters and bodies. Consult command help when a flag is uncertain.

Read only the relevant sections of [references/commands.md](references/commands.md) for setup, authentication, Drive, Gmail, Calendar, Sheets, Docs, Chat, or Admin examples. Examples require real resource IDs and task-specific dates. Resolve ambiguous matches before writing.

Use bounded queries; paginate when the answer requires a complete result set. Calendar queries should use the user's timezone and requested date interval.

Preview unfamiliar writes with `--dry-run`. Sending messages, changing access, deleting resources, and administration require the corresponding user authorization. Check the result before retrying a write.

Install or reconfigure the CLI only when setup is part of the request.
