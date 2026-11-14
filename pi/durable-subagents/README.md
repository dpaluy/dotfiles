# Durable subagents

The sole delegation provider is [purboo/pi-durable-subagents](https://github.com/purboo/pi-durable-subagents), npm package `pi-durable-subagents` (not the similarly named scoped package). It exposes `subagents` and `/subagents`.

`install/pi.sh` reads package sources from `pi/settings.json`, links missing `pi/agents/*.md` definitions, and copies `config.json` only when absent. Existing agents, configuration, journals, and legacy subagent-manager files are preserved. If a local agent with the same name exists, compare it with the new shared definition before choosing which to retain.

## Updates

All sources in `pi/settings.json` are unpinned. Run `pi update --extensions` to update configured packages. `extensionChangelogVersions` stores changelog read markers, not version constraints.

## Migration

- Restart Pi after installing the configured package; an already running session still has its old tools. Do not load subagent-manager alongside this provider through project settings or explicit extension arguments.
- Model preference lists are now named pools in `config.json`; thinking levels are attached to each candidate. Pools can spill to a later model when the preferred provider has no free slot, unlike manager's first-available selection.
- The six manager role overrides are now standalone Markdown agents; designer and reviewer-fast retain their specialized prompts, with `ask` replacing manager-only pause/update tools.
- Provider concurrency is four slots per configured provider, not a global four-call cap. Shared instructions limit concurrent delegation to four; nested agents are unsupported. Writer locking serializes writes in a shared worktree.
- Normal quit pauses workflows (`onQuit: "pause"`). For unattended jobs that must continue after normal quit, use a separate `DSA_HOME` with `onQuit: "continue"`. Crash recovery retains completed results but cannot guarantee exactly-once external side effects.
