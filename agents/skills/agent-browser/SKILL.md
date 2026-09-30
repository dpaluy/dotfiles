---
name: agent-browser
description: Use the agent-browser CLI for website interaction, rendered content extraction, and browser testing when headless browsing can complete the task. Use Chrome DevTools MCP instead for headed demos, existing browser authentication, and real-browser diagnostics.
allowed-tools: Bash(npx agent-browser:*), Bash(agent-browser:*)
---

# Browser Automation with agent-browser

Honor the user's requested tool or interaction method. Use an available purpose-built read or search tool when it can answer the request without browser interaction.

Use this CLI when headless browsing can complete the task. Use Chrome DevTools MCP for headed demonstrations, opening links with existing browser authentication, and diagnostics in the real browser. Verify the connected browser, target tab, and account before authenticated actions. Do not assume a named agent-browser session shares the user's Chrome authentication.

Use Cua Driver for native applications, desktop controls, browser controls outside page content, or UI that browser tools cannot reach. An explicit GUI-only request excludes DOM/CDP and application APIs. Do not switch to foreground desktop input without authorization.

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
