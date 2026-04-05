---
name: create-feature-spec
description: Create a comprehensive feature specification from a single sentence description
trigger: /create-feature-spec
---

You are tasked with creating a comprehensive feature specification document using the template at
  `@docs/templates/FEATURE_SPECIFICATION.md`.

  **Input**: The user will provide a single sentence describing the new feature.

  **Your Process**:

  1. **Initial Analysis**:
     - Read `@docs/templates/FEATURE_SPECIFICATION.md` to understand the required structure
     - Parse the user's feature description to identify the core problem and proposed solution
     - Identify which sections of the template are most relevant (some may be optional based on feature scope)

  2. **Gather Context** (use tools, don't ask yet):
     - Search the codebase for similar features using Glob/Grep
     - Identify relevant existing components, services, and data models
     - Understand current architecture patterns from CLAUDE.md and existing feature docs
     - Check for related API endpoints, UI components, database tables

  3. **Ask Clarifying Questions**:
     - Use the `AskUserQuestion` tool to ask 3-4 strategic questions that will help you create a better spec
     - Focus on: scope boundaries, user personas, technical approach preferences, integration points
     - Example questions:
       - "What is the primary user problem this feature solves?"
       - "Should this integrate with existing features (e.g., workflows, companies)?"
       - "What level of technical detail do you want (high-level vs implementation-focused)?"
       - "Are there any known constraints or requirements?"

  4. **Create Initial Draft**:
     - Generate a complete feature specification following the template structure
     - Fill in all REQUIRED sections with substantive content (not just placeholders)
     - Include optional sections where relevant
     - Use examples from the codebase to ground technical details
     - Follow NeuroRep conventions (hexagonal architecture, canonical models, API standards)
     - Match the quality and depth of `@docs/features/WORKFLOW_v2.md`

  5. **Iterative Refinement**:
     - After presenting the initial draft, use `AskUserQuestion` to ask:
       - "What sections need more detail or clarification?"
       - "Are there any missing aspects or concerns not addressed?"
       - "Should any sections be expanded, condensed, or restructured?"
     - Continue refining based on feedback until the user approves
     - Each iteration should improve specific sections, not rewrite the entire document

  6. **Quality Checklist** (before marking complete):
     - [ ] All REQUIRED sections have substantive content
     - [ ] User personas and user stories are clear and actionable
     - [ ] Architecture section shows how feature fits into existing system
     - [ ] Data model includes canonical models, database schema, validation rules
     - [ ] API specification has detailed endpoint examples with request/response
     - [ ] Implementation strategy broken into logical phases with deliverables
     - [ ] Success metrics are measurable and specific
     - [ ] Open questions and future enhancements are captured
     - [ ] Related documentation and ADRs are linked
     - [ ] Examples in appendices illustrate key use cases

  7. **Output Location**:
     - Save the final specification to `/docs/features/{FEATURE_NAME}.md`
     - Use kebab-case for the filename (e.g., `real-time-chat.md`)
     - Ensure the filename matches the feature name in the document header

  **Key Principles**:
  - **Iterative**: Use AskUserQuestion at each major decision point
  - **Comprehensive**: Don't skip sections - if optional, explain why it's not applicable
  - **Grounded**: Reference existing code, patterns, and components from the codebase
  - **User-focused**: Write for multiple audiences (product, engineering, UX)
  - **Actionable**: Implementation strategy should be clear enough for a developer to start work

  **Your First Action**: Ask the user 3-4 clarifying questions using `AskUserQuestion` to understand:
  1. The core problem and user need
  2. Scope and boundaries (what's in vs out)
  3. Integration requirements (which existing features/entities)
  4. Technical preferences or constraints

  Then proceed to create the specification iteratively.

## Diagram

[View diagram](diagram.html)