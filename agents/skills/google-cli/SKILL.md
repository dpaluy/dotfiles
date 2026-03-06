---
name: google-cli
description: |
  Google Workspace CLI (gws) for Drive, Gmail, Calendar, Sheets, Docs, Chat, and Admin APIs.
  Use when the user wants to interact with Google Workspace: list/upload/download Drive files,
  send/read Gmail, manage Calendar events, read/write Sheets, create Docs, send Chat messages,
  or administer Google Workspace. Triggers: "google drive", "gmail", "google calendar",
  "google sheets", "google docs", "google chat", "gws", "workspace", or any Google Workspace action.
allowed-tools: Bash(gws:*)
---

# Google Workspace CLI (gws)

Unified CLI for Google Workspace APIs — one command surface for Drive, Gmail, Calendar, Sheets, Docs, Chat, and Admin. Dynamically built from Google's Discovery Service, so it supports new API endpoints automatically.

## Installation

```bash
npm install -g @googleworkspace/cli
```

## Authentication

Credentials are encrypted at rest (AES-256-GCM) with keys stored in OS keyring.

```bash
gws auth setup       # One-time: creates Cloud project, enables APIs
gws auth login       # Login with scope selection
gws auth list        # View registered accounts
```

### Multiple Accounts

```bash
gws auth login --account work@corp.com
gws auth login --account personal@gmail.com
gws auth default work@corp.com
gws --account personal@gmail.com drive files list   # One-off override
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `GOOGLE_WORKSPACE_CLI_TOKEN` | Pre-obtained OAuth access token |
| `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE` | Path to credentials JSON |
| `GOOGLE_WORKSPACE_CLI_ACCOUNT` | Default account email |
| `GOOGLE_WORKSPACE_CLI_IMPERSONATED_USER` | Email for domain-wide delegation |

## Global Flags

- `--dry-run` — Preview the HTTP request without executing
- `--page-all` — Auto-paginate (NDJSON, one JSON line per page)
- `--page-limit <N>` — Max pages to fetch (default: 10)
- `--page-delay <MS>` — Delay between pages (default: 100ms)
- `--account <EMAIL>` — Target a specific account
- `--upload <PATH>` — Attach file for multipart upload

## Schema Introspection

Discover available methods and their parameters before calling:

```bash
gws schema drive.files.list
gws schema gmail.users.messages.send
gws schema sheets.spreadsheets.values.get
```

## Drive

```bash
# List files
gws drive files list --params '{"pageSize": 10}'

# List with query filter
gws drive files list --params '{"q": "mimeType=\"application/pdf\"", "pageSize": 5}'

# Get file metadata
gws drive files get --params '{"fileId": "FILE_ID"}'

# Upload a file
gws drive files create --json '{"name": "report.pdf"}' --upload ./report.pdf

# Download/export
gws drive files export --params '{"fileId": "FILE_ID", "mimeType": "application/pdf"}'

# Create a folder
gws drive files create --json '{"name": "Projects", "mimeType": "application/vnd.google-apps.folder"}'

# Move file to folder
gws drive files update --params '{"fileId": "FILE_ID", "addParents": "FOLDER_ID", "removeParents": "OLD_PARENT_ID"}'

# Delete file
gws drive files delete --params '{"fileId": "FILE_ID"}'

# Search across all files (auto-paginate)
gws drive files list --params '{"q": "fullText contains \"quarterly report\"", "pageSize": 100}' --page-all
```

## Gmail

```bash
# List messages
gws gmail users messages list --params '{"userId": "me", "maxResults": 10}'

# List with query
gws gmail users messages list --params '{"userId": "me", "q": "from:boss@company.com is:unread"}'

# Get message
gws gmail users messages get --params '{"userId": "me", "id": "MSG_ID"}'

# Send message (base64-encoded RFC 2822)
gws gmail users messages send --params '{"userId": "me"}' --json '{"raw": "BASE64_ENCODED_MESSAGE"}'

# List labels
gws gmail users labels list --params '{"userId": "me"}'

# Modify labels (archive = remove INBOX)
gws gmail users messages modify --params '{"userId": "me", "id": "MSG_ID"}' --json '{"removeLabelIds": ["INBOX"]}'

# Trash message
gws gmail users messages trash --params '{"userId": "me", "id": "MSG_ID"}'
```

## Calendar

```bash
# List calendars
gws calendar calendarList list

# List events
gws calendar events list --params '{"calendarId": "primary", "maxResults": 10, "timeMin": "2026-03-01T00:00:00Z"}'

# Get event
gws calendar events get --params '{"calendarId": "primary", "eventId": "EVENT_ID"}'

# Create event
gws calendar events insert --params '{"calendarId": "primary"}' --json '{
  "summary": "Team standup",
  "start": {"dateTime": "2026-03-06T09:00:00-06:00"},
  "end": {"dateTime": "2026-03-06T09:30:00-06:00"},
  "attendees": [{"email": "colleague@company.com"}]
}'

# Update event
gws calendar events patch --params '{"calendarId": "primary", "eventId": "EVENT_ID"}' --json '{"summary": "Updated title"}'

# Delete event
gws calendar events delete --params '{"calendarId": "primary", "eventId": "EVENT_ID"}'
```

## Sheets

```bash
# Create spreadsheet
gws sheets spreadsheets create --json '{"properties": {"title": "Q1 Budget"}}'

# Read values
gws sheets spreadsheets values get --params '{"spreadsheetId": "SHEET_ID", "range": "Sheet1!A1:C10"}'

# Write values
gws sheets spreadsheets values update \
  --params '{"spreadsheetId": "SHEET_ID", "range": "Sheet1!A1", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["Name", "Score"], ["Alice", 95]]}'

# Append rows
gws sheets spreadsheets values append \
  --params '{"spreadsheetId": "SHEET_ID", "range": "Sheet1!A1", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["Bob", 88]]}'

# Clear range
gws sheets spreadsheets values clear --params '{"spreadsheetId": "SHEET_ID", "range": "Sheet1!A1:C10"}'

# Get spreadsheet metadata
gws sheets spreadsheets get --params '{"spreadsheetId": "SHEET_ID"}'
```

## Docs

```bash
# Create document
gws docs documents create --json '{"title": "Meeting Notes"}'

# Get document
gws docs documents get --params '{"documentId": "DOC_ID"}'

# Batch update (insert text)
gws docs documents batchUpdate --params '{"documentId": "DOC_ID"}' --json '{
  "requests": [{"insertText": {"location": {"index": 1}, "text": "Hello World\n"}}]
}'
```

## Chat

```bash
# List spaces
gws chat spaces list

# Send message
gws chat spaces messages create \
  --params '{"parent": "spaces/SPACE_ID"}' \
  --json '{"text": "Deploy complete."}'

# List messages in a space
gws chat spaces messages list --params '{"parent": "spaces/SPACE_ID"}'
```

## Admin (Directory API)

```bash
# List users
gws admin directory users list --params '{"domain": "company.com", "maxResults": 10}'

# Get user
gws admin directory users get --params '{"userKey": "user@company.com"}'

# List groups
gws admin directory groups list --params '{"domain": "company.com"}'
```

## Common Workflows

### Find and download a file

```bash
FILE_ID=$(gws drive files list --params '{"q": "name=\"report.pdf\"", "pageSize": 1}' | jq -r '.files[0].id')
gws drive files get --params "{\"fileId\": \"$FILE_ID\", \"alt\": \"media\"}"
```

### Search Gmail and read results

```bash
MSGS=$(gws gmail users messages list --params '{"userId": "me", "q": "subject:invoice after:2026/01/01", "maxResults": 5}')
MSG_ID=$(echo "$MSGS" | jq -r '.messages[0].id')
gws gmail users messages get --params "{\"userId\": \"me\", \"id\": \"$MSG_ID\"}"
```

### Check today's calendar

```bash
gws calendar events list --params "{\"calendarId\": \"primary\", \"timeMin\": \"$(date -u +%Y-%m-%dT00:00:00Z)\", \"timeMax\": \"$(date -u -v+1d +%Y-%m-%dT00:00:00Z)\", \"singleEvents\": true, \"orderBy\": \"startTime\"}"
```

## Tips

- All output is structured JSON — pipe to `jq` for extraction
- Use `--dry-run` to preview requests before executing
- Use `gws schema <method>` to discover parameters for any API method
- Use `--page-all` for large result sets (auto-pagination as NDJSON)
- The CLI dynamically discovers API surface — if Google adds a new endpoint, `gws` supports it automatically
- Append `--help` to any subcommand for usage info
