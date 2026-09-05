---
name: agent-browser
description: Use the agent-browser CLI for website interaction, rendered content extraction, and browser testing when a browser session is needed.
allowed-tools: Bash(npx agent-browser:*), Bash(agent-browser:*)
---

# Browser Automation with agent-browser

Use an available purpose-built read or search tool when it can answer the request. Use this CLI when the task needs a browser and the user has not selected another browser tool.

Use a task-specific named session to avoid interfering with other work:

```bash
agent-browser --session task-name open https://example.com
agent-browser --session task-name snapshot -i
```

Use refs from the current snapshot for interactions. Refresh the snapshot after navigation or page changes before reusing refs. Inspect text with `get text`; use `screenshot --annotate` for visual content or unlabeled controls.

Wait for the relevant element, URL, or readiness signal when content is still loading. Use network idle only when it reflects readiness for that page. Continue while there is observable progress; investigate stalled or failed navigation.

Check the visible result of the requested action. Close only the session created for this task when finished. Do not close a user's existing session.

For complex `eval` expressions, use `--stdin` with a quoted heredoc or correctly encoded `-b` input to avoid shell expansion.

## References

Read only what the task requires:

- [Commands](references/commands.md): command syntax and options.
- [Snapshot refs](references/snapshot-refs.md): locators and stale-ref problems.
- [Session management](references/session-management.md): connecting to browsers, isolation, and state persistence.
- [Authentication](references/authentication.md): login, OAuth, and saved sessions. Treat saved cookies as credentials.
- [Recording](references/video-recording.md): video capture.
- [Profiling](references/profiling.md): performance traces.
- [Proxies](references/proxy-support.md): proxy setup.
- [Advanced usage](references/advanced.md): iOS, local files, and persistent configuration.

Existing templates provide [form automation](templates/form-automation.sh), [authenticated sessions](templates/authenticated-session.sh), and [content capture](templates/capture-workflow.sh). Inspect a template before running it against a real account.
