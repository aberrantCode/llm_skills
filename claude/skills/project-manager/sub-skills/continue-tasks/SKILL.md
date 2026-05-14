---
name: continue-tasks
description: Run the full project orchestration loop — pick up the next todo task, spawn the appropriate agent, monitor its completion sentinel, and iterate until all tasks complete or the failure budget is exhausted
---

# Continue Tasks

Invoke the `project-manager` skill and execute the `/continue-tasks` command exactly as specified there.

Follow all steps in the `/continue-tasks` section:
1. Bootstrap check — verify feature specs exist
2. Generate any missing plans
3. Find the next `todo` task
4. Write the task file
5. Spawn the appropriate agent
6. Monitor for completion sentinel and loop
