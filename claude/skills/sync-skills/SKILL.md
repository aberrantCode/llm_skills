---
name: sync-skills
description: Domain expertise for maintaining the LLM Skills Archive — source discovery, conflict resolution, README classification, and archive invariants. Use when syncing skills across projects or reasoning about archive structure.
---

# Sync-Skills Domain Expertise

You are an expert in maintaining the LLM Skills Archive at `C:\development\llm_skills`. This skill gives you the conceptual model, decision rules, and heuristics needed to reason about and execute skill synchronization correctly.

---

## Conceptual Model

### What the Archive Is
The archive (`C:\development\llm_skills`) is the single source of truth for all LLM skills, agents, and commands across every toolset (Claude, Codex, Gemini). It consolidates skills scattered across:
- The user's global Claude profile (`~/.claude/`)
- The archive repository itself (`llm_skills/.claude/`)
- All other projects under `C:\development\`

### Archive Structure
```
llm_skills/
├── .claude/
│   ├── commands/   # project-local commands (e.g. sync-skills itself)
│   └── skills/     # project-local skills (e.g. sync-skills domain skill)
├── claude/
│   ├── agents/     # archived Claude sub-agents
│   ├── commands/   # archived global Claude commands
│   └── skills/     # archived Claude skills
├── codex/
│   └── skills/     # archived Codex skills
└── gemini/
    └── skills/     # archived Gemini skills
```

### Invariants — Never Violate These
1. **Never delete from the archive.** Even if a source file no longer exists, the archive copy stays. Deletions are manual curatorial decisions.
2. **Flow is always source → archive.** Never write back to a source project from the archive.
3. **The archive README is the authoritative index.** Every archived skill must have a row; every row must point to a real file.
4. **Toolset is determined by directory, not content.** A file in `codex/skills/` is a Codex skill regardless of what it says inside.

---

## Source Discovery

### Canonical Source Locations

| Source | Path Pattern | Toolset | Archive Destination |
|--------|-------------|---------|---------------------|
| Global profile | `~/.claude/skills/*/SKILL.md` | Claude | `claude/skills/<name>/SKILL.md` |
| Global profile | `~/.claude/agents/*.md` | Claude | `claude/agents/<name>.md` |
| Global profile | `~/.claude/commands/*.md` | Claude | `claude/commands/<name>.md` |
| This repo | `.claude/skills/*/SKILL.md` | Claude | `claude/skills/<name>/SKILL.md` |
| This repo | `.claude/agents/*.md` | Claude | `claude/agents/<name>.md` |
| This repo | `.claude/commands/*.md` | Claude | `claude/commands/<name>.md` |
| Other projects | `skills/*/SKILL.md` | Claude | `claude/skills/<name>/SKILL.md` |
| Other projects | `.claude/skills/*/SKILL.md` | Claude | `claude/skills/<name>/SKILL.md` |
| Other projects | `.claude/agents/*.md` | Claude | `claude/agents/<name>.md` |
| Other projects | `.claude/commands/*.md` | Claude | `claude/commands/<name>.md` |
| Other projects | `codex/skills/*/SKILL.md` | Codex | `codex/skills/<name>/SKILL.md` |
| Other projects | `.codex/skills/*/SKILL.md` | Codex | `codex/skills/<name>/SKILL.md` |
| Other projects | `gemini/skills/*/SKILL.md` | Gemini | `gemini/skills/<name>/SKILL.md` |
| Other projects | `.gemini/skills/*/SKILL.md` | Gemini | `gemini/skills/<name>/SKILL.md` |

### Nested Paths
Some sources have extra path depth (e.g. `skills/claude.ai/vercel-deploy-claimable/SKILL.md`). The skill `<name>` is always the **leaf directory** containing `SKILL.md`, not any intermediate folders. Intermediate path segments are discarded.

---

## Conflict Resolution

When the same skill name is discovered in multiple sources, apply these rules in order:

1. **Same toolset, same name → last-writer wins with priority.**
   Priority order (highest to lowest):
   - Global profile (`~/.claude/`)
   - This repo's `.claude/` folder
   - Other projects (alphabetical by project name for determinism)

2. **Same name, different toolsets → both are valid, separate archive entries.**
   Each gets its own row in the README with `✓` in only its toolset column.

3. **Archive is ahead of all sources (file exists in archive but no source has it) → do nothing.** The archive copy was likely added manually or the source was deleted. Never remove it.

4. **Content identical across multiple sources → skip all copies, count as unchanged.**

---

## Change Classification

For every discovered source file, compare against the archive counterpart using content diff (ignore trailing whitespace):

| Condition | Classification | Action |
|-----------|---------------|--------|
| Archive copy does not exist | **New** | Copy to archive |
| Both exist, content differs | **Changed** | Overwrite archive copy |
| Both exist, content identical | **Unchanged** | Skip |
| Archive exists, no source | **Orphan** | Skip (never delete) |

---

## README Classification Heuristics

When adding a new skill row to the README, infer the subsection by matching keywords from the skill's `description` field:

| Keywords | Subsection |
|----------|-----------|
| git, branch, commit, PR, merge, workflow, session, team, coordination, repo | Foundations & Workflow |
| TypeScript, Python, Node.js, runtime, language | Languages & Runtimes |
| React, Vue, Next.js, frontend framework, PWA, Flutter | Frontend Frameworks |
| Android, iOS, mobile native, Kotlin, Swift | Mobile (Native) |
| UI, UX, design, Tailwind, accessibility, visual, diagram, explainer | UI & Design |
| database, SQL, Supabase, Firebase, DynamoDB, Aurora, Cosmos, D1, schema | Databases & Storage |
| code review, testing, quality, lint, coverage, Playwright, duplication | Code Quality |
| security, credentials, auth, OWASP, secrets, vulnerability | Security & Credentials |
| AI, LLM, agent, prompt, model, Anthropic, OpenAI, Gemini | AI & LLM |
| commerce, Shopify, WooCommerce, Medusa, Stripe, payment | Commerce & Payments |
| Klaviyo, Reddit, Teams, PostHog, third-party, integration | Third-Party Integrations |
| SEO, sitemap, robots, web presence, content, GEO | SEO & Web Presence |
| tooling, DevOps, CLI, deploy, Vercel, render, CI/CD | Tooling & DevOps |
| OSINT, research, intelligence, GEOINT, worldview, forensics | Research & OSINT |

If no keywords match, use **Uncategorized**.

If multiple subsections match, prefer the one with the most keyword hits. Break ties by choosing the more specific subsection.

---

## README Update Rules

### For new skills only (not agents or commands — those are manually curated):
1. Extract `description` from YAML frontmatter (`---` fences). If absent, use the first non-heading paragraph.
2. Classify into a subsection using the heuristics above.
3. Insert a new row in the skills table — keep rows grouped by subsection, alphabetical within each group.
4. Mark `✓` in the correct toolset column (Claude / Codex / Gemini). Leave others blank.
5. Increment `Skills (<Toolset>)` count and `Total Skills` in the Summary table.
6. Update the structure comment (`skills/ # N domain-specific knowledge modules`) for the relevant toolset.

### For changed skills:
- Update the Description cell only if the frontmatter `description` changed.
- Do not move the row or change its subsection.

### Deduplication:
- Match existing rows by the `Skill` column value (the link text, not the href).
- Never add a duplicate row. If the skill already exists in the table, only update its description if it changed.
- Same-named skills across toolsets get **separate rows**, each with `✓` in only their own column.

---

## Edge Cases

### The archive as its own source
`llm_skills/.claude/` is itself a source. Only scan that specific folder — do not recurse into `claude/` (the archive destination). Scanning the archive as a source would create circular copies.

### Skills that are also commands
A file in `commands/*.md` is a command. A file in `skills/*/SKILL.md` is a skill. They can share a name (e.g. `sync-skills`) without conflict — they are different artifact types and go to different archive destinations. Do not conflate them.

### Missing YAML frontmatter
If a `SKILL.md` has no `---` frontmatter block, fall back to the first non-heading paragraph for the description. If that is also absent, use the filename as the description.

### Project directories to skip
- `llm_skills` itself (handled separately via its `.claude/` folder)
- Any directory that is not a real project: `nul`, `emby-opbta.p12`, `fullchain.pem`, `privkey.pem`, `recovery_app`, loose files

### Large or binary files
If a discovered `SKILL.md` exceeds 500 KB, flag it in the summary as a warning but still copy it.
