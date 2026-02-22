---
name: fizzy-cli
description: |
  Fizzy project management CLI for boards, cards, columns, steps, comments, and notifications.
  Use when the user wants to manage tasks, track work, create/update cards, organize boards,
  or interact with Fizzy (fizzy.do). Triggers: "create a card", "list my boards", "move card",
  "check notifications", "update task", "fizzy", "board", "card", or any project management action.
allowed-tools: Bash(fizzy:*)
---

# Fizzy CLI

Ruby CLI for [Fizzy](https://fizzy.do) project management. Installed as `fizzy` gem.

## Authentication

Credentials stored at `~/.config/fizzy-cli/tokens.yml`. Check status before operations:

```bash
fizzy auth status
```

If not authenticated:

```bash
fizzy auth login --token YOUR_PAT_TOKEN
```

Generate a Personal Access Token from your Fizzy profile > API section > "Personal access tokens".

Multi-account:

```bash
fizzy auth accounts           # List accounts (* = default)
fizzy auth switch /SLUG       # Change default (e.g. /6160537)
```

## Global Flags

All commands support:
- `--json` — Machine-readable JSON output (use for parsing)
- `--account /SLUG` — Target a specific account

## Identity

```bash
fizzy identity               # Show all accounts and user info
fizzy identity --json        # JSON format
```

## Boards

```bash
fizzy boards list
fizzy boards get BOARD_ID
fizzy boards create "Board Name"
fizzy boards update BOARD_ID --name "New Name"
fizzy boards delete BOARD_ID
```

## Cards

Cards are addressed by **number** (integer), not ID. The `--board` flag is only required for `create`.

### CRUD

```bash
fizzy cards list                                    # All open cards
fizzy cards list --board BOARD_ID                    # Filter by board
fizzy cards list --status closed                     # open (default), closed, all
fizzy cards list --column COLUMN_ID                  # Filter by column
fizzy cards list --assignee USER_ID                  # Filter by assignee
fizzy cards get 42                                   # Show card details + steps
fizzy cards create "Title" --board BOARD_ID           # Create (--body, --column optional)
fizzy cards update 42 --title "New title"             # Update (--body optional)
fizzy cards delete 42
```

### Card Actions

```bash
fizzy cards close 42                                 # Close (mark done)
fizzy cards reopen 42                                # Reopen a closed card
fizzy cards not-now 42                               # Defer card
fizzy cards triage 42 --column COLUMN_ID             # Move to column
fizzy cards untriage 42                              # Remove from triage
fizzy cards tag 42 "bug"                             # Add tag by title
fizzy cards assign 42 USER_ID                        # Toggle assignment
fizzy cards watch 42                                 # Subscribe to updates
fizzy cards unwatch 42                               # Unsubscribe
fizzy cards golden 42                                # Mark as golden
fizzy cards ungolden 42                              # Remove golden
```

## Columns

Columns are scoped to a board — `--board` is always required.

```bash
fizzy columns list --board BOARD_ID
fizzy columns get COLUMN_ID --board BOARD_ID
fizzy columns create "To Do" --board BOARD_ID
fizzy columns update COLUMN_ID --board BOARD_ID --name "Done"
fizzy columns delete COLUMN_ID --board BOARD_ID
```

## Steps (Card Checklists)

Steps are scoped to a card — `--card NUMBER` is always required.
No list endpoint; steps are returned inline in `fizzy cards get`.

```bash
fizzy steps create "Write tests" --card 42
fizzy steps get STEP_ID --card 42
fizzy steps update STEP_ID --card 42 --completed       # Mark done
fizzy steps update STEP_ID --card 42 --no-completed    # Unmark
fizzy steps update STEP_ID --card 42 --description "Updated text"
fizzy steps delete STEP_ID --card 42
```

## Comments

Scoped to a card — `--card NUMBER` is always required.

```bash
fizzy comments list --card 42
fizzy comments get COMMENT_ID --card 42
fizzy comments create "Looks good" --card 42
fizzy comments update COMMENT_ID --card 42 --body "Updated text"
fizzy comments delete COMMENT_ID --card 42
```

## Reactions

Works on cards and optionally on comments — `--card NUMBER` always required.

```bash
fizzy reactions list --card 42                         # Card reactions
fizzy reactions list --card 42 --comment COMMENT_ID    # Comment reactions
fizzy reactions create "thumbsup" --card 42
fizzy reactions create "heart" --card 42 --comment COMMENT_ID
fizzy reactions delete REACTION_ID --card 42
```

## Tags

```bash
fizzy tags list                                        # All tags for account
```

## Users

```bash
fizzy users list
fizzy users get USER_ID
fizzy users update USER_ID --name "New Name"
fizzy users deactivate USER_ID
```

## Notifications

```bash
fizzy notifications list
fizzy notifications read NOTIFICATION_ID
fizzy notifications unread NOTIFICATION_ID
fizzy notifications mark-all-read
```

## Pins

```bash
fizzy pins pin 42                                      # Pin a card
fizzy pins unpin 42                                    # Unpin a card
```

Note: `fizzy pins list` requires session auth (not available with PAT).

## Common Workflows

### Discover boards and cards

```bash
fizzy boards list --json
BOARD_ID=$(fizzy boards list --json | jq -r '.[0].id')
fizzy cards list --board $BOARD_ID
fizzy columns list --board $BOARD_ID
```

### Create and organize a card

```bash
fizzy cards create "Ship feature X" --board $BOARD_ID
fizzy cards triage 42 --column $COLUMN_ID
fizzy cards assign 42 $USER_ID
fizzy cards tag 42 "feature"
```

### Add checklist steps to a card

```bash
fizzy steps create "Write tests" --card 42
fizzy steps create "Update docs" --card 42
fizzy cards get 42                                     # Shows steps inline
```

### Card lifecycle

```bash
fizzy cards create "Bug fix" --board $BOARD_ID         # Created
fizzy cards triage 42 --column $IN_PROGRESS_ID         # In progress
fizzy cards close 42                                   # Done
fizzy cards reopen 42                                  # Needs more work
fizzy cards not-now 42                                 # Deferred
```

### Check what's assigned to you

```bash
MY_ID=$(fizzy identity --json | jq -r '.accounts[0].user.id')
fizzy cards list --assignee $MY_ID
```

## Tips

- Always use `--json` when parsing output programmatically
- Cards use **numbers** (integers), everything else uses **IDs** (base36 UUIDs)
- `fizzy cards get` returns steps inline — no separate steps list endpoint
- Append `help` to any subcommand: `fizzy cards help`, `fizzy columns help`
- Credentials at `~/.config/fizzy-cli/tokens.yml`
- Override account per-command with `--account /SLUG`
