---
name: project-skill-audit
description: Audit a project's existing skills or use project history to recommend skills for recurring workflows.
---

# Project Skill Audit

Start with the requested scope and the repository's skill locations, including installer source directories. Check descriptions, bodies, linked resources, and any `agents/openai.yaml` for overlap, stale paths, excessive procedure, and conflicting invocation rules.

For an audit of existing instructions, current files and concrete failure examples can be sufficient. Use history when evaluating recurring needs or when the user requests it:

- Search the supplied memory summary and `memories/MEMORY.md` under the configured Codex home (default `~/.codex`) for the project path or workflow.
- Open relevant summaries in `memories/rollout_summaries/`. Use raw `sessions/` JSONL only for missing evidence.
- Keep retrieval targeted and check memory-derived claims against current repository state.

Prefer updating an existing skill. Recommend a new skill only for a demonstrated recurring workflow that needs reusable guidance and is not already covered by an available skill. A topic or one-off bug is not enough.

Keep descriptions short and specific. Keep task routing and essential constraints in the entrypoint; put conditional detail in linked references. Preserve useful examples, user preferences, permission boundaries, and support for the models that use the skill.

Report actionable findings with file evidence and the smallest useful correction. Do not force empty report sections or invent recommendations.

If the request includes improvements, apply the supported corrections using skill-creator guidance and validate the changed skills. If it asks only for an audit, return findings without edits.
