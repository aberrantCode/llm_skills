---
description: >
  Full lifecycle management of LLM skills — find, sync, install, update, and import.
  Invoke with an operation name (/find-skills, /sync-skill, /install-skill, /update-skill,
  /import-skill) or without arguments to choose interactively.
---

# /skills-manager

Apply the `skills-manager` skill. All user interaction uses the `AskUserQuestion` tool.

If an operation and arguments were provided (e.g. `/skills-manager sync-skill project-manager`), pass them directly to the corresponding operation.

If no operation was specified, use `AskUserQuestion` to ask:
- Question: "Which skills-manager operation would you like to run?"
- Options: "Find new/changed skills" | "Sync a skill to archive" | "Install a skill into a project" | "Update installed skills" | "Import project changes to archive"
