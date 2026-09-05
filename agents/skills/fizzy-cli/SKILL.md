---
name: fizzy-cli
description: Manage Fizzy boards, cards, and notifications with the fizzy CLI when the task names Fizzy or the project maps work to Fizzy.
allowed-tools: Bash(fizzy:*)
---

# Fizzy CLI

Check `fizzy auth status` and `fizzy identity --json` to resolve the account. Prefer a per-command `--account /SLUG` over changing the default account.

Use the board mapping in the project's `.fizzy.yml` or the user's supplied target. If neither identifies the board, list candidates and ask only if the target remains ambiguous. Do not choose the first board by position.

Cards use integer **numbers**; other resources use **IDs**. Columns require `--board BOARD_ID`. Steps and comments require `--card NUMBER`. Steps are returned by `fizzy cards get`; there is no separate steps list endpoint.

Use `--json` for parsing. Consult `fizzy cards help` or the relevant subcommand's help for the installed CLI.

For command examples, read the relevant section of [references/commands.md](references/commands.md): authentication, boards, cards, columns, steps, comments, reactions, users, or notifications.

Operate within the requested account and task. Check the resulting resource after a write; commands such as assignment toggles must not be retried blindly.
