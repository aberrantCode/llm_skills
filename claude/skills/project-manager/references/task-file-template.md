---
feature: "{{feature-slug}}"
phase: {{N}}
task: {{M}}
covers: ["XX-CAP-NN"]
role: "{{role}}"
agent: "{{agent-type}}"
status: in-progress      # set by orchestrator at spawn time
created: "{{TODAY}}"
---

# Task — `{{feature-slug}}-p{{N}}-t{{M}}`

> **Agent contract.** Read this entire file. Perform every action in the Action Plan section. When done, append a `## Completion` block at the bottom exactly as specified. Do not modify any content above your appended `## Completion` block.

---

## Spec excerpt

Pulled verbatim from `docs/features/{{feature-slug}}.md` — the orchestrator inlines the relevant capabilities and acceptance criteria so this task is self-contained.

> **Capabilities in scope**
> - `[XX-CAP-NN]` ...
>
> **Acceptance criteria**
> - **AC-NN** Given … When … Then …

---

## Plan excerpt

From `docs/plans/{{feature-slug}}-plan.md`:

> **Phase {{N}} goal.** ...
> **This task.** ...
> **Exit criteria.** ...

---

## Related completed work

The orchestrator lists previously archived task files in this feature that may inform the current task. Read them only if you need context.

- `docs/tasks/archive/{{feature-slug}}-p{{N-1}}-t{{Last}}.md` — summary line

---

## Action plan

1. ...
2. ...
3. ...

**Files you may create or modify**

- ...

**Files you must not touch**

- `docs/features/**` — specs are authority; if a change is needed, surface it in the completion notes, do not edit
- `docs/plans/**` — orchestrator-owned
- Other task files

---

## Constraints

- Tests-first. Write a failing test before implementation when adding behavior.
- Do not introduce new dependencies without listing them in `Notes` below.
- Do not silently expand scope. If a required change falls outside this task's `covers:` list, stop and surface it in `Notes`.

---

## Completion

> **The agent appends this block at the bottom of the file. The orchestrator polls for this heading. Use the exact field names.**

```
Status: success | failure | blocked
Summary: One-sentence outcome.
Artifacts:
  - relative/path/changed-file.ts
  - relative/path/test-file.spec.ts
Tests:
  added: N
  changed: N
  passing: true | false
Notes:
  - Anything the orchestrator should record in the plan notes column.
  - Surface any spec divergence here; do not edit the spec.
Error: (only present when Status is failure)
  Root cause: ...
  What was tried: ...
  Suggested corrective task: ...
```
