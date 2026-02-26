---
description: Scan the Claude profile and all C:\development projects for new or changed skills, agents, and commands. Copy them into this archive under the correct toolset subfolder, update README.md, and print a change summary.
---

# /sync-skills

Sync the LLM Skills Archive against all known skill sources.

## 1 — Discover sources

Scan the following locations. Treat every path as Windows-style but use forward-slash equivalents in tool calls.

### Claude global profile (`~/.claude/` → `C:\Users\<username>\.claude\`)

| Path pattern | Archive destination |
|---|---|
| `skills/*/SKILL.md` | `claude/skills/<name>/SKILL.md` |
| `agents/*.md` | `claude/agents/<name>.md` |
| `commands/*.md` | `claude/commands/<name>.md` |

### All projects under `C:\development\` (skip `llm_skills` itself)

For each project directory, check all of the paths below. A skill's toolset is determined by the directory it lives in:

| Source path (within project) | Toolset | Archive destination |
|---|---|---|
| `skills/*/SKILL.md` | Claude | `claude/skills/<name>/SKILL.md` |
| `.claude/skills/*/SKILL.md` | Claude | `claude/skills/<name>/SKILL.md` |
| `.claude/agents/*.md` | Claude | `claude/agents/<name>.md` |
| `.claude/commands/*.md` | Claude | `claude/commands/<name>.md` |
| `codex/skills/*/SKILL.md` | Codex | `codex/skills/<name>/SKILL.md` |
| `.codex/skills/*/SKILL.md` | Codex | `codex/skills/<name>/SKILL.md` |
| `gemini/skills/*/SKILL.md` | Gemini | `gemini/skills/<name>/SKILL.md` |
| `.gemini/skills/*/SKILL.md` | Gemini | `gemini/skills/<name>/SKILL.md` |

## 2 — Classify changes

For every discovered file, compare it against the archive counterpart:

- **New** — source exists, archive copy does not → schedule copy
- **Changed** — both exist, but content differs → schedule overwrite
- **Unchanged** — content identical → skip

Do not delete anything from the archive, even if the source no longer exists.

## 3 — Copy files

For each new or changed file:

1. Create the destination directory if it does not exist.
2. Copy the source file to the archive path.
3. Record the action (toolset, type, name, status) for the summary.

## 4 — Update README.md

For every **new** skill (not agents or commands — those table sections are manually curated):

1. Read the file's YAML frontmatter `description` field (between `---` fences). If absent, use the first non-heading paragraph.
2. Infer the **Subsection** by matching keywords in the description against existing subsection names in the README table. If no match, use `Uncategorized`.
3. Append a new row to the consolidated skills table with `✓` in the correct toolset column (Claude / Codex / Gemini).
4. Increment the corresponding `Skills (<Toolset>)` count in the Summary table.
5. Increment `Total Skills` accordingly.

For **changed** skills, update the Description cell in the existing row if the frontmatter description changed.

## 5 — Print summary

Output the following to the console after all changes are applied:

```
╔══════════════════════════════════════╗
║        Skill Sync — Summary          ║
╠══════════════════════════════════════╣
║  New      <n> (Claude: <n>  Codex: <n>  Gemini: <n>)
║  Updated  <n> (Claude: <n>  Codex: <n>  Gemini: <n>)
║  Skipped  <n> unchanged
╠══════════════════════════════════════╣
║  New items:
║    + [claude]  agents    │ <name>
║    + [claude]  commands  │ <name>
║    + [claude]  skills    │ <subsection> │ <name>
║    + [codex]   skills    │ <subsection> │ <name>
║    + [gemini]  skills    │ <subsection> │ <name>
║
║  Changed items:
║    ~ [claude]  skills    │ <name>
╠══════════════════════════════════════╣
║  Archive totals after sync:
║    Claude  agents:   <n>
║    Claude  commands: <n>
║    Claude  skills:   <n>
║    Codex   skills:   <n>
║    Gemini  skills:   <n>
╚══════════════════════════════════════╝
```

If there are no changes, print:

```
╔══════════════════════════════╗
║  Skill Sync — Nothing to do  ║
║  Archive is already up-to-date.
╚══════════════════════════════╝
```

## Notes

- The archive root is always the directory containing this file's parent `.claude/` folder (i.e., `C:\development\llm_skills\`).
- When comparing file content for change detection, ignore trailing whitespace differences.
- If a skill name already exists in the README table (matched by the `Skill` column), do not add a duplicate row — only update the Description if it changed.
- Skill names that conflict across toolsets (same name in claude and codex) get separate rows, distinguished by their Subsection and toolset column `✓`.
