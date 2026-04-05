---
description: Create a new HomeRadar feature spec — interviews user, checks for overlaps, populates template, generates diagram, updates README
---

# HomeRadar: Add Feature

Creates a complete, approval-ready feature specification in `docs/features/`. Covers requirement gathering, overlap detection, template population, visual diagram generation, and README indexing.

---

## Phase 1 — Gather Feature Requirements

Check whether the user's message (the `$ARGUMENTS` passed to this command) contains a meaningful feature description.

If NO description was provided, use the `AskUserQuestion` tool to ask:
> "Tell me about the feature you want to add. What does it do, who uses it, and what problem does it solve?"

After receiving a description, confirm understanding by summarizing what you heard and use `AskUserQuestion` to ask about anything still unclear — at minimum:
- The **must-have capabilities** (P0 items that block launch)
- What is **explicitly out of scope** for this iteration

Do not proceed to Phase 2 until you have enough to draft a meaningful spec.

---

## Phase 2 — Overlap Detection

Read every `.md` file in `docs/features/` **except** `template.md` and `README.md`. For each file, note the capabilities listed in its **Capabilities** section.

Compare those capabilities against the proposed feature. Look for:
- **Full overlap** — another spec already covers the entire proposed feature
- **Partial overlap** — some capabilities already exist in another spec
- **Adjacent** — a related spec that could be extended vs. a separate spec warranting its own file

**If no overlap exists:** proceed to Phase 3.

**If overlap exists:** use `AskUserQuestion` to present the situation clearly:
- List the overlapping capabilities and which existing spec(s) contain them
- Offer options:
  - (a) Narrow the new spec to exclude overlapping capabilities (leave them where they are)
  - (b) Move overlapping capabilities from the existing spec into the new one (and edit the existing spec)
  - (c) Extend the existing spec instead of creating a new file

**Do not proceed until every capability in the planned feature exists in exactly one spec file.** If capabilities must be removed from an existing spec, edit that file now, before creating the new one.

---

## Phase 3 — Create the Spec File

1. **Choose a filename:** `docs/features/<feature-name>.md` — kebab-case, descriptive (e.g., `notification-center.md`, `bulk-import.md`). Derive from the feature's primary capability. If ambiguous, use `AskUserQuestion`.

2. **Choose a CAP-ID abbreviation:**
   - Open `docs/workflow/SDLC.md` and locate the **Feature Abbreviation Registry** table
   - Pick a 2-letter abbreviation not already in that table
   - Note it — you will reference it throughout and the user must add it to the registry after spec approval

3. **Copy the template:** Read `docs/features/template.md` in full, then write its content to the new file path.

---

## Phase 4 — Populate the Template

Fill in every section following these rules:

- **Delete every instruction blockquote** (`> ...` lines) after populating the section — never leave template instructions in the finished spec
- Use `AskUserQuestion` for any **REQUIRED** section where you lack enough information to write confidently
- Make reasonable inferences for optional sections; note assumptions as "Open Questions" if significant
- Never leave `[placeholder]` text — either fill it in or mark it `TBD` with a note

### Section-by-Section Guidance

**Metadata**
- `Status`: `Draft`
- `Last Updated`: today's date (2026-03-26)
- `Owner / Author`: ask via `AskUserQuestion` if not obvious from context
- `Version`: `1.0`

**Executive Overview**
Write 2–4 sentences of prose (no bullets): what it does, why it exists, who it serves, what success looks like.

**Problem Statement**
Draw from what the user described. Answer who is affected, what the current workaround is, and why it falls short.

**Use Cases**
Generate at least 3: one primary (happy path), one power-user, one admin. Use `AskUserQuestion` if the admin scenario is unclear.

**Capabilities**
- Use `[XX-CAP-NN]` format with the chosen 2-letter abbreviation
- Include priority tags `[P0]`, `[P1]`, `[P2]`
- Draft the list, then use `AskUserQuestion` to confirm the P0 items with the user before finalizing — these define the launch-blocking scope

**Acceptance Criteria**
Write `Given / When / Then` ACs for every P0 capability and any P1 items with clear testable outcomes.

**Out of Scope**
Include items deferred during the requirements conversation and any capabilities removed from existing specs during overlap resolution.

**Success Metrics**
Propose reasonable adoption, outcome, and guardrail metrics. Use `AskUserQuestion` if the user has specific targets.

**UX Flows & Design**
Describe the user journey as numbered steps or an ASCII flow diagram. If no design exists yet, write the expected UX. Include happy path and the primary error path.

**Technical Architecture**
- Fill in known file paths and descriptions; use `[TBD]` where design is not yet determined — do not fabricate file paths
- Data Model: match field names to conventions in `prisma/schema.prisma`; remember prices are integers (cents)
- API Endpoints: include auth requirements and rate limit tier
- Configuration: list any new env vars

**Security Considerations**
Apply standard HomeRadar patterns: JWT auth, user-scoped data (`user_id`), input validation, rate limiting. Call out elevated concerns explicitly.

**Edge Cases**
Generate plausible boundary conditions from the capabilities. Reference HomeRadar conventions (stub listings with `price = 0`, concurrent scrapes, `__NEXT_DATA__` availability).

**Error States & Handling**
Cover external service failures, invalid input, auth failures, and partial-success scenarios.

**Testing Strategy**
List test files to be created or updated, using the standard locations:
- API unit: `api/tests/unit/test_<name>.py`
- API integration: `api/tests/integration/test_<name>.py`
- Extension: `extension/src/__tests__/<name>.test.ts`
- Web: `web/src/__tests__/<Name>.test.tsx`
- E2E: `web/e2e/<name>.spec.ts`

**Dependencies & Affected Features**
Identify which existing features this depends on and which existing features may need updates.

**Known Issues & Limitations**
Include any deferred items discussed during requirements gathering.

**Open Questions**
Move unresolved decisions here. Write "None" only if everything is resolved.

**Change History**
Single row: `2026-03-26 | [author] | Initial draft`

---

## Phase 5 — Generate the Diagram

After saving the spec file, invoke the `visual-explainer:generate-web-diagram` skill to generate an HTML diagram for this feature.

Instruct the diagram to illustrate:
- The primary user flow (entry point → key actions → outcome)
- System components involved (API, Extension, Worker, DB, Redis, Web UI)
- Data flows between components
- Key decision points or branching conditions

**Save location:** `docs/features/diagrams/<feature-name>.html`

After generating, add a **Diagram** section to the spec file, inserted just before the **Change History** section:

```markdown
## Diagram

[Feature flow diagram](diagrams/<feature-name>.html)
```

Open the diagram in the browser for the user to review.

---

## Phase 6 — Update the Feature Index

Open `docs/features/README.md` and add the new feature to the most appropriate category table (Core Features, Discovery & Analysis, Organization & Settings, Integrations).

If the feature doesn't fit any existing category, use `AskUserQuestion` to decide whether to add a new category or choose the closest existing one.

Match the existing row format exactly:

```markdown
| [Feature Name](feature-name.md) | One-line description | Key capabilities summary |
```

---

## Completion Checklist

When all phases are done, verify:
- [ ] `docs/features/<feature-name>.md` exists with all sections populated and no instruction blockquotes remaining
- [ ] `docs/features/diagrams/<feature-name>.html` exists and has been opened in the browser
- [ ] `docs/features/README.md` includes the new feature entry with a link
- [ ] The CAP-ID abbreviation chosen is not already in `docs/workflow/SDLC.md`

Tell the user:

> "The spec is ready for review at `docs/features/<name>.md`. When you're satisfied with the content, set `Status` to `Approved` — that's the signal for the team to begin implementation planning. Also add `XX` → `<feature-name>` to the Feature Abbreviation Registry in `docs/workflow/SDLC.md`."
