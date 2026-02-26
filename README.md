# LLM Skills Archive

Consolidated archive of custom agents, commands, and skills for Claude Code, OpenAI Codex CLI, and Google Gemini CLI. Deduplicated from the global profile (`~/.claude/`) and all projects under `C:\development\`.

## Structure

```
llm_skills/
├── claude/
│   ├── agents/     # 15 sub-agents invoked via the Task tool
│   ├── commands/   # 18 slash commands
│   └── skills/     # 64 domain-specific knowledge modules
├── codex/
│   └── skills/     # 1 domain-specific knowledge module
└── gemini/         # Google Gemini CLI skills (future)
```

---

## Agents

Specialized sub-agents invoked via the Task tool. Proactive agents fire automatically when conditions are met.

> All agents are Claude-based and live in `claude/agents/`.

| Agent | Model | Description |
|-------|-------|-------------|
| [`architect`](claude/agents/architect.md) | Opus | Software architecture specialist — system design, scalability, ADRs, trade-off evaluation |
| [`backend-api-developer`](claude/agents/backend-api-developer.md) | Sonnet | FastAPI routes, SQLModel/Pydantic models, Alembic migrations, pytest, ruff/black/mypy |
| [`build-error-resolver`](claude/agents/build-error-resolver.md) | Opus | Fixes TypeScript and build errors with minimal diffs — no architectural changes, just green builds |
| [`code-reviewer`](claude/agents/code-reviewer.md) | Opus | Quality, security, and maintainability review — must be used after every code change |
| [`doc-updater`](claude/agents/doc-updater.md) | Opus | Generates `docs/CODEMAPS/*`, updates READMEs and guides from source-of-truth |
| [`docs-test-engineer`](claude/agents/docs-test-engineer.md) | Sonnet | Documentation (README, API docs, specs) and test suites for Python/FastAPI and React/TypeScript |
| [`e2e-runner`](claude/agents/e2e-runner.md) | Opus | Playwright E2E tests — manages test journeys, quarantines flaky tests, uploads screenshots/videos/traces |
| [`non-blocking-loading`](claude/agents/non-blocking-loading.md) | — | Applies skeleton UI / non-blocking loading pattern instead of full-screen spinners |
| [`planner`](claude/agents/planner.md) | Opus | Creates detailed implementation plans with phases, dependencies, and risk assessment |
| [`refactor-cleaner`](claude/agents/refactor-cleaner.md) | Opus | Dead code removal using knip/depcheck/ts-prune — categorizes by risk, verifies with tests after each batch |
| [`security-reviewer`](claude/agents/security-reviewer.md) | Opus | Flags secrets, SSRF, injection, unsafe crypto, and OWASP Top 10 — runs before committing sensitive code |
| [`ship-to-prod`](claude/agents/ship-to-prod.md) | — | Creates a PR from `uat` → `main` with safety checks, deployment runbook, and rollback plan |
| [`ship-to-uat`](claude/agents/ship-to-uat.md) | — | Creates a PR from `dev` → `uat` for User Acceptance Testing |
| [`tdd-guide`](claude/agents/tdd-guide.md) | Opus | Enforces write-tests-first — Red/Green/Refactor cycle, 80%+ coverage minimum |
| [`webui-developer`](claude/agents/webui-developer.md) | Sonnet | React/TypeScript components, Storybook stories, Vitest tests, cross-platform scripts (PowerShell/bash) |

---

## Project Commands

Slash commands scoped to this archive — available only when Claude Code is opened inside `llm_skills/`. They live in `.claude/commands/`.

| Command | Description |
|---------|-------------|
| [`/sync-skills`](.claude/commands/sync-skills.md) | Scan the Claude profile and all `C:\development` projects for new/changed skills, copy them into the archive, update this README, and print a change summary |

---

## Commands

Slash commands available globally in Claude Code. Most delegate to a specialized agent above.

> All commands are Claude-based and live in `claude/commands/`.

| Command | Description |
|---------|-------------|
| [`/analyze-repo`](claude/commands/analyze-repo.md) | Analyze an existing repo's structure, conventions, and guardrails — auto-runs on first `/initialize-project` |
| [`/analyze-workspace`](claude/commands/analyze-workspace.md) | Full dynamic analysis of workspace topology, dependencies, and contracts across a monorepo |
| [`/build-fix`](claude/commands/build-fix.md) | Incrementally fix TypeScript and build errors one at a time, grouped by file and sorted by severity |
| [`/check-contributors`](claude/commands/check-contributors.md) | Check who's working on the project; optionally converts to multi-person mode with shared state |
| [`/code-review`](claude/commands/code-review.md) | Comprehensive security and quality review of uncommitted changes — blocks commit on CRITICAL/HIGH issues |
| [`/commit`](claude/commands/commit.md) | Stage all changes, pull latest (with conflict handling), commit with conventional format, and push |
| [`/diagnose`](claude/commands/diagnose.md) | Load diagnostic context for AC_OSM — execution flow, log locations, and common failure points |
| [`/e2e`](claude/commands/e2e.md) | Generate and run Playwright E2E tests — captures screenshots, videos, and traces |
| [`/initialize-project`](claude/commands/initialize-project.md) | Full project setup with Claude coding guardrails — idempotent, safe to re-run anytime |
| [`/new-action`](claude/commands/new-action.md) | Guided creator for OSM profile action JSON files (RegistryAction, IOAction, MethodAction, ScheduledTaskAction) |
| [`/plan`](claude/commands/plan.md) | Restate requirements, assess risks, create step-by-step plan — waits for user confirmation before touching code |
| [`/refactor-clean`](claude/commands/refactor-clean.md) | Safely identify and remove dead code with test verification after each batch |
| [`/sync-contracts`](claude/commands/sync-contracts.md) | Lightweight incremental update of workspace contracts without a full re-analysis |
| [`/tdd`](claude/commands/tdd.md) | Enforce TDD workflow — scaffold interfaces, generate tests first, implement minimal code, ensure 80%+ coverage |
| [`/test-coverage`](claude/commands/test-coverage.md) | Run tests with coverage reporting and generate missing tests for uncovered code |
| [`/update-code-index`](claude/commands/update-code-index.md) | Regenerate `CODE_INDEX.md` — scans for all functions, classes, hooks, and components |
| [`/update-codemaps`](claude/commands/update-codemaps.md) | Analyze codebase structure and regenerate architecture documentation in `docs/CODEMAPS/` |
| [`/update-docs`](claude/commands/update-docs.md) | Sync documentation from source-of-truth: package.json scripts, JSDoc/TSDoc, API signatures |

---

## Skills

Domain-specific knowledge modules loaded into AI context. Claude skills live in `claude/skills/<name>/`, Gemini skills in `gemini/skills/<name>/`.

| Skill | Subsection | Description | Claude | Codex | Gemini |
|-------|------------|-------------|:------:|:-----:|:------:|
| [`base`](claude/skills/base/) | Foundations & Workflow | Universal coding patterns, constraints, TDD workflow, and atomic todos | ✓ | | |
| [`iterative-development`](claude/skills/iterative-development/) | Foundations & Workflow | Self-referential TDD iteration (Ralph Wiggum loops) — cycles until tests pass | ✓ | | |
| [`session-management`](claude/skills/session-management/) | Foundations & Workflow | Context preservation, tiered summarization, and resumability across long sessions | ✓ | | |
| [`team-coordination`](claude/skills/team-coordination/) | Foundations & Workflow | Multi-person projects — shared state, todo claiming, and handoffs | ✓ | | |
| [`existing-repo`](claude/skills/existing-repo/) | Foundations & Workflow | Analyze existing repositories, maintain their structure, setup guardrails | ✓ | | |
| [`subagent-driven-development`](claude/skills/subagent-driven-development/) | Foundations & Workflow | Parallel task execution using sub-agents for independent implementation steps | ✓ | | |
| [`create-feature-spec`](claude/skills/create-feature-spec/) | Foundations & Workflow | Create a comprehensive feature specification from a single sentence description | ✓ | | |
| [`finishing-a-development-branch`](claude/skills/finishing-a-development-branch/) | Foundations & Workflow | Guides branch completion — presents options: merge, PR, squash, or cleanup | ✓ | | |
| [`using-git-worktrees`](claude/skills/using-git-worktrees/) | Foundations & Workflow | Isolated git worktrees for feature work — smart directory selection and safety verification | ✓ | | |
| [`requesting-code-review`](claude/skills/requesting-code-review/) | Foundations & Workflow | Use when completing tasks or before merging to verify work meets requirements | ✓ | | |
| [`ship-to-dev`](claude/skills/ship-to-dev/) | Foundations & Workflow | Automated flow: commit → push → PR to dev → merge → branch cleanup | ✓ | | |
| [`commit-hygiene`](claude/skills/commit-hygiene/) | Foundations & Workflow | Atomic commits, PR size limits, commit thresholds, stacked PRs | ✓ | | |
| [`typescript`](claude/skills/typescript/) | Languages & Runtimes | TypeScript strict mode with eslint and jest | ✓ | | |
| [`python`](claude/skills/python/) | Languages & Runtimes | Python development with ruff, mypy, pytest — TDD and type safety | ✓ | | |
| [`nodejs-backend`](claude/skills/nodejs-backend/) | Languages & Runtimes | Node.js backend patterns with Express/Fastify, repository pattern | ✓ | | |
| [`react-web`](claude/skills/react-web/) | Frontend Frameworks | React web development with hooks, React Query, Zustand | ✓ | | |
| [`react-native`](claude/skills/react-native/) | Frontend Frameworks | React Native mobile patterns, platform-specific code | ✓ | | |
| [`flutter`](claude/skills/flutter/) | Frontend Frameworks | Flutter with Riverpod, Freezed, go_router, and mocktail testing | ✓ | | |
| [`pwa-development`](claude/skills/pwa-development/) | Frontend Frameworks | Progressive Web Apps — service workers, caching strategies, offline support, Workbox | ✓ | | |
| [`android-java`](claude/skills/android-java/) | Mobile (Native) | Android Java development with MVVM, ViewBinding, and Espresso testing | ✓ | | |
| [`android-kotlin`](claude/skills/android-kotlin/) | Mobile (Native) | Android Kotlin with Coroutines, Jetpack Compose, Hilt, and MockK testing | ✓ | | |
| [`ui-mobile`](claude/skills/ui-mobile/) | Mobile (Native) | Mobile UI patterns — React Native, iOS/Android, touch targets | ✓ | | |
| [`ui-web`](claude/skills/ui-web/) | UI & Design | Web UI — glassmorphism, Tailwind, dark mode, accessibility | ✓ | | |
| [`ui-testing`](claude/skills/ui-testing/) | UI & Design | Visual testing — catch invisible buttons, broken layouts, contrast issues | ✓ | | |
| [`design-taste-frontend`](claude/skills/design-taste-frontend/) | UI & Design | Senior UI/UX guidance — metric-based rules, CSS hardware acceleration, balanced design engineering | ✓ | | |
| [`frontend-design`](claude/skills/frontend-design/) | UI & Design | Production-grade frontend interfaces — polished, distinctive, avoiding generic AI aesthetics | ✓ | | |
| [`user-journeys`](claude/skills/user-journeys/) | UI & Design | UX flows — journey mapping, UX validation, error recovery | ✓ | | |
| [`doc-coauthoring`](claude/skills/doc-coauthoring/) | UI & Design | Structured co-authoring workflow for documentation, proposals, and technical specs | ✓ | | |
| [`explain-code`](claude/skills/explain-code/) | UI & Design | Explains code with visual diagrams and analogies | ✓ | | |
| [`supabase`](claude/skills/supabase/) | Databases & Storage | Core Supabase CLI, migrations, RLS, Edge Functions | ✓ | | |
| [`supabase-nextjs`](claude/skills/supabase-nextjs/) | Databases & Storage | Next.js with Supabase and Drizzle ORM | ✓ | | |
| [`supabase-node`](claude/skills/supabase-node/) | Databases & Storage | Express/Hono with Supabase and Drizzle ORM | ✓ | | |
| [`supabase-python`](claude/skills/supabase-python/) | Databases & Storage | FastAPI with Supabase and SQLAlchemy/SQLModel | ✓ | | |
| [`firebase`](claude/skills/firebase/) | Databases & Storage | Firebase Firestore, Auth, Storage, real-time listeners, security rules | ✓ | | |
| [`aws-aurora`](claude/skills/aws-aurora/) | Databases & Storage | AWS Aurora Serverless v2, RDS Proxy, Data API, connection pooling | ✓ | | |
| [`aws-dynamodb`](claude/skills/aws-dynamodb/) | Databases & Storage | AWS DynamoDB single-table design, GSI patterns, SDK v3 TypeScript/Python | ✓ | | |
| [`azure-cosmosdb`](claude/skills/azure-cosmosdb/) | Databases & Storage | Azure Cosmos DB partition keys, consistency levels, change feed, SDK patterns | ✓ | | |
| [`cloudflare-d1`](claude/skills/cloudflare-d1/) | Databases & Storage | Cloudflare D1 SQLite database with Workers, Drizzle ORM, migrations | ✓ | | |
| [`database-schema`](claude/skills/database-schema/) | Databases & Storage | Schema awareness — read before coding, type generation, prevent column errors | ✓ | | |
| [`code-review`](claude/skills/code-review/) | Code Quality | Mandatory code reviews via `/code-review` before commits and deploys | ✓ | | |
| [`code-deduplication`](claude/skills/code-deduplication/) | Code Quality | Prevent semantic code duplication with capability index and check-before-write | ✓ | | |
| [`codex-review`](claude/skills/codex-review/) | Code Quality | OpenAI Codex CLI code review with GPT-5.2-Codex, CI/CD integration | ✓ | | |
| [`gemini-review`](claude/skills/gemini-review/) | Code Quality | Google Gemini CLI code review with Gemini 2.5 Pro and 1M token context | ✓ | | |
| [`playwright-testing`](claude/skills/playwright-testing/) | Code Quality | E2E testing with Playwright — Page Objects, cross-browser, CI/CD integration | ✓ | | |
| [`security`](claude/skills/security/) | Security & Credentials | OWASP security patterns, secrets management, security testing | ✓ | | |
| [`credentials`](claude/skills/credentials/) | Security & Credentials | Centralized API key management from Access.txt | ✓ | | |
| [`agentic-development`](claude/skills/agentic-development/) | AI & LLM | Build AI agents with Pydantic AI (Python) and Claude SDK (Node.js) | ✓ | | |
| [`llm-patterns`](claude/skills/llm-patterns/) | AI & LLM | AI-first application patterns, LLM testing, prompt management | ✓ | | |
| [`ai-models`](claude/skills/ai-models/) | AI & LLM | Latest AI models reference — Claude, OpenAI, Gemini, Eleven Labs, Replicate | ✓ | | |
| [`shopify-apps`](claude/skills/shopify-apps/) | Commerce & Payments | Shopify app development — Remix, Admin API, checkout extensions | ✓ | | |
| [`woocommerce`](claude/skills/woocommerce/) | Commerce & Payments | WooCommerce REST API — products, orders, customers, webhooks | ✓ | | |
| [`medusa`](claude/skills/medusa/) | Commerce & Payments | Medusa headless commerce — modules, workflows, API routes, admin UI | ✓ | | |
| [`web-payments`](claude/skills/web-payments/) | Commerce & Payments | Stripe Checkout, subscriptions, webhooks, customer portal | ✓ | | |
| [`klaviyo`](claude/skills/klaviyo/) | Third-Party Integrations | Klaviyo email/SMS marketing — profiles, events, flows, segmentation | ✓ | | |
| [`reddit-api`](claude/skills/reddit-api/) | Third-Party Integrations | Reddit API with PRAW (Python) and Snoowrap (Node.js) | ✓ | | |
| [`reddit-ads`](claude/skills/reddit-ads/) | Third-Party Integrations | Reddit Ads API — campaigns, targeting, conversions, agentic optimization | ✓ | | |
| [`ms-teams-apps`](claude/skills/ms-teams-apps/) | Third-Party Integrations | Microsoft Teams bots and AI agents — Claude/OpenAI, Adaptive Cards, Graph API | ✓ | | |
| [`posthog-analytics`](claude/skills/posthog-analytics/) | Third-Party Integrations | PostHog analytics, event tracking, feature flags, dashboards | ✓ | | |
| [`site-architecture`](claude/skills/site-architecture/) | SEO & Web Presence | Technical SEO — robots.txt, sitemap, meta tags, Core Web Vitals | ✓ | | |
| [`web-content`](claude/skills/web-content/) | SEO & Web Presence | SEO and AI discovery (GEO) — schema, ChatGPT/Perplexity optimization | ✓ | | |
| [`aeo-optimization`](claude/skills/aeo-optimization/) | SEO & Web Presence | AI Engine Optimization — semantic triples, page templates, content clusters for AI citations | ✓ | | |
| [`project-tooling`](claude/skills/project-tooling/) | Tooling & DevOps | gh, vercel, supabase, render CLI and deployment platform setup | ✓ | | |
| [`workspace`](claude/skills/workspace/) | Tooling & DevOps | Multi-repo and monorepo awareness — topology analysis, API contract tracking, cross-repo context | ✓ | | |
| [`youtube-prd-forensics`](claude/skills/youtube-prd-forensics/) | Research & OSINT | Create or update a detailed PRD from a YouTube demo video using evidence-first analysis — timestamps, keyframes, transcript, and embedded screenshots | ✓ | ✓ | |

---

## Summary

| Type | Count |
|------|-------|
| Agents | 15 |
| Commands | 18 |
| Skills (Claude) | 64 |
| Skills (Codex) | 1 |
| Skills (Gemini) | 0 |
| **Total Skills** | **65** |
