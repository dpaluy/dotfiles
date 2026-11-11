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

## Validation

Run `bash test/pi_durable_subagents_test.sh` from the repository root. It exercises the installed package and Pi offline, using disposable fixtures with no live model requests.

Against package 1.4.3 and Pi 1.5.2 on macOS, smoke checks and all nine recovery scenarios passed, including host termination and recovery. No duplicate runs, lost results, or restarted-from-scratch sessions were observed. Interactive TTY behavior was not tested. No login service is configured.

The stock 1.4.3 chaos harness has a Pi 1.5 compatibility bug: it counts a persisted aborted assistant turn as a scripted provider response. After host termination in scenario 9, that advances the cursor past `REVIEW: accept`, returning `Acknowledged.` and skipping the integrator. The check copies the installed package to a temporary directory and excludes aborted turns from that test-only cursor. Runtime code and acceptance assertions remain unchanged; the installed package is not patched. The wrapper fails explicitly if upstream changes the affected code, so reassess it after updates rather than silently retaining an obsolete correction.
