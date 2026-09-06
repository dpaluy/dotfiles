---
name: astra-orchestrate
description: Coordinate substantial work with GPT-6 Astra when independent subtasks or a separate review justify agents. Keep simple edits and tightly coupled work on the main agent.
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

Use the available concurrency limit as a ceiling. The current configuration permits
four workers in addition to the main agent, with one delegation level. Workers are
leaves. If tools or capacity are unavailable, continue locally where possible.

## Select a worker

Use the user's selected Luna max setting for scouts and routine workers. These
assignments are routing choices, not measured performance rankings:

| Assignment | Model and effort | Available role |
| --- | --- | --- |
| Narrow read-only search or code trace | GPT-5.6 Luna, max | `fast_scan` |
| Bounded implementation with clear interfaces | GPT-5.6 Luna, max | `routine_worker` |
| Difficult debugging or implementation within agreed scope | GPT-6 Astra, high | `deep_worker` |
| Independent review of a material risk | GPT-6 Astra, high, fresh context | Generic agent with a read-only assignment |

Keep the primary session at medium effort by default. Raise effort for demonstrated
complexity when the runtime permits it. Do not require high or ultra for ordinary
coordination. Respect the user's model selection and the runtime's supported options.

Inspect the available role metadata before selecting a role. If a role is absent or
pins a different model, use a generic agent with an explicit supported model and
effort. Do not use a plugin role unless its owning skill is active. A requested
read-only behavior is not proof of an enforced sandbox.

## Give a complete assignment

Prefer `fork_turns: "none"` for scouts, independent reviews, and self-contained
implementation. Include the objective, relevant paths, known interface contracts,
acceptance criteria, and essential user, tool, and permission constraints.

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

Set shared interfaces before parallel edits. Give one owner to each shared file.
Do not investigate the same question while a scout owns it. Workers may send useful
findings directly to teammates without creating more agents.

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

Adapted from the role, context, and ownership ideas in Eric Provencher's
[Practical multi-agent orchestration in Codex](https://x.com/pvncher/status/2080707291603407077).
The Astra coordinator, mixed-model defaults, and review rules are local choices.
[OpenAI's Astra guidance](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-6-astra)
supports explicit delegation criteria, scope-aware follow-through, and proportional
verification. Review model and tool availability when the runtime changes.
