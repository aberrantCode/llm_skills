---
name: review-tasks
description: >
  Dry-run project status report. Produces a read-only snapshot of all feature specs, plans, and
  task progress without spawning any agents or modifying any files. Use this when the user invokes
  /review-tasks or asks for a project status snapshot, completion percentage, or "what's left".
---

# Review Tasks Skill

Produce a read-only status report. Do not modify any files.

## Steps

1. Count feature specs in `docs/features/`
2. Count plans in `docs/plans/` and identify specs missing a plan
3. For each plan: count tasks by status (todo / in-progress / done / blocked)
4. List any active task files in `docs/tasks/active/`
5. List any open issues in `docs/issues/`
6. Output a structured markdown report showing:
   - Overall completion percentage
   - Per-feature progress table
   - Next recommended action

This command is safe to run at any time to get a project snapshot.

## Directory Conventions

```
docs/
  INITIAL_PROMPT.md          # Source of truth for product intent (never modified)
  features/                  # Feature specs — final authority on scope
    {feature-slug}.md
  plans/                     # One plan per feature spec
    {feature-slug}-plan.md
  tasks/                     # Active task files (one at a time per phase)
    active/
      {feature-slug}-p{N}-t{M}.md
    archive/
      {feature-slug}-p{N}-t{M}.md
  guides/                    # Supporting docs, architecture notes (optional)
  issues/                    # Logged failures and blockers
```

## Related Commands

- `/continue-tasks` — run the full orchestration loop (spawns agents, executes tasks)
- `/update-tasks` — sync active task files that may have been completed by agents
- `/reinit` — archive legacy state, normalize specs, then launch
