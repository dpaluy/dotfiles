---
name: astra-orchestrate
description: Coordinate substantial work with GPT-6 Astra, select workers by task, and resume on completion events. Keep simple edits and tightly coupled work on the main agent.
---

# Astra Orchestration

Use GPT-6 Astra as the primary coordinator. Own scope, shared interfaces, task division,
integration, and the final response. This skill does not switch the running model.
If the session uses another model, report that fact and apply the same workflow
without claiming Astra is active.

## Choose the work to delegate

Delegate when a bounded task can run beside useful work on the main agent, or when
an independent review can resolve a material risk. Keep small edits, sequential
investigations, and routine Git operations local. Do not create agents to fill slots.

Read the runtime's available tools, models, roles, and concurrency limit. Use that
limit as a ceiling. Workers are leaves. If delegation is unavailable, continue
locally where possible.

## Select a worker

Select the model by task clarity and required judgment. Use Luna max by default
for well-defined work with clear acceptance criteria, including implementation,
tests, and fixes. Use Sol when work needs more judgment across requirements or
interfaces. Use Astra for difficult reasoning, architecture, and material review.
These are local routing choices, not measured performance rankings. An explicit
user model choice takes precedence.

| Assignment | Default model | Starting effort |
| --- | --- | --- |
| Well-defined search, code trace, or mechanical edit | `gpt-5.6-luna` | max |
| Well-defined implementation, tests, or fixes with clear acceptance criteria | `gpt-5.6-luna` | max |
| Work requiring judgment across requirements or interfaces | `gpt-5.6-sol` | medium |
| Difficult debugging or ambiguous implementation within agreed scope | `gpt-6-astra` | high |
| Independent review of a material risk | `gpt-6-astra`, fresh context | high |

Keep the primary session at medium effort by default. Raise effort for demonstrated
complexity when the runtime permits it. Do not require high or ultra for ordinary
coordination. Respect the user's model selection and the runtime's supported options.

Inspect the available role metadata before selecting a role. If a role is absent or
pins a different model or effort, use a generic agent with an explicit supported
model and effort. In particular, do not select a Luna-pinned `routine_worker` for
a Sol assignment. Do not change installed role configuration to route one task.
Do not use a plugin role unless its owning skill is active. A requested
read-only behavior is not proof of an enforced sandbox.

## Give a complete assignment

Prefer `fork_turns: "none"` for scouts, independent reviews, and self-contained
implementation. Include the objective, relevant paths, known interface contracts,
acceptance criteria, and essential user, tool, and permission constraints.
Include the coordinator's return address, the supported completion mechanism, and
the checkout path. Specify whether the worker may commit or perform external actions.

Use inherited history only when earlier decisions are needed. Full-history forks
inherit the parent's model and effort and do not accept overrides in this runtime.
Use a fresh or supported partial fork when selecting a different model or effort.

Assign exact files or a distinct read-only question. Tell each worker:

- Complete this assignment directly. Do not spawn agents.
- You share the workspace with other agents. Preserve their changes and edit only
  your assigned files. Report a conflict before overwriting another worker's work.
- Resolve routine choices from context. Return material scope or permission choices
  to the main agent. Delegation grants no additional authority.
- Return the result, paths changed or inspected, checks run and their outcomes, and
  unresolved issues. Report completion only for your assignment.
- Send one completion report through the agreed mechanism after checks finish.
  Report a blocker or required decision early. Do not send routine progress pings
  to wake an idle coordinator. If final results are delivered automatically, use
  that delivery instead of sending a duplicate completion message.

Set shared interfaces before parallel edits. Give one owner to each shared file.
Do not investigate the same question while a scout owns it. Workers may send useful
findings directly to teammates without creating more agents.

## Dispatch and resume on completion

Prefer this sequence: plan, dispatch, yield, receive completion, integrate.
Use subagents for subtasks of the current request. Create a separate user-visible
task only when the user explicitly requests one and the runtime permits it.

Before dispatch, verify how completion reaches the coordinator. A message tool's
existence does not prove that it wakes an ended turn. For an explicitly requested
separate task, give the worker the actual coordinator task ID and an available
message tool that starts a follow-up turn. Never invent IDs or callback APIs.

Continue useful independent work after dispatch. When no independent work remains:

- If the runtime explicitly supports resuming an ended coordinator turn on worker
  completion, record the pending assignment and return address in the handoff,
  then end the turn. State that work is pending, not complete. Resume when the
  completion event arrives.
- If wakeup after turn end is unavailable or unknown, keep the turn active with
  the runtime's event wait, such as `wait_agent`. Use bounded waits within the
  session's limits. This is a fallback, not proof of cross-turn wakeup support.

Do not run repeated status reads, timer sleeps, or scheduled checks to simulate
completion events. Use a status read only to diagnose a missing event, a failure,
or an explicit user status request. Follow any runtime-required dispatch check.

## Integrate and finish

Continue independent work while workers run. Answer user questions briefly, apply
corrections to affected assignments, and retain the original goal unless replaced.
Reuse an existing worker for a related correction rather than starting duplicate work.

Inspect returned evidence and the integrated diff. Run checks needed to validate
interactions or unresolved risks; do not repeat successful checks without a reason.
Use an independent review when the user requests one or a concrete risk justifies it.
Give a reviewer the objective and actual artifacts without prescribing its verdict.

Keep material product, permission, and release decisions with the user. Complete
authorized preparation before requesting a decision. Stop when the requested outcome
and relevant checks are complete, or state the exact blocker and required decision.

## Basis

Adapted from the completion-driven workflow in the supplied
[Create Agent Prompt Guide](chatgpt-conversation://6aa713b0-52f0-83ea-a159-d80fbdb6d302),
which references [Eric Provencher's post](https://x.com/pvncher/status/2098841379837260144).
The supplied guide was truncated and the post could not be fetched during this
revision. Treat the guide as workflow intent; verify tool behavior in the runtime.
The model routing and effort defaults above are local choices.
[OpenAI's Astra guidance](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-6-astra)
supports explicit delegation criteria, scope-aware follow-through, and proportional
verification. Review model and tool availability when the runtime changes.
