---
name: visual-explainer
description: Generate beautiful, self-contained HTML pages that visually explain systems, code changes, plans, and data. Use when the user asks for a diagram, architecture overview, diff review, plan review, project recap, comparison table, or any visual explanation of technical concepts. Also use proactively when you are about to render a complex ASCII table (4+ rows or 3+ columns) — present it as a styled HTML page instead.
license: MIT
compatibility: Requires a browser to view generated HTML files. Optional surf-cli for AI image generation.
metadata:
  author: nicobailon
  version: "0.2.0"
---

# Visual Explainer

Generate self-contained HTML files for technical diagrams, visualizations, and data tables. Always open the result in the browser. Never fall back to ASCII art when this skill is loaded.

**Proactive table rendering.** When you're about to present tabular data as an ASCII box-drawing table in the terminal (comparisons, audits, feature matrices, status reports, any structured rows/columns), generate an HTML page instead. The threshold: if the table has 4+ rows or 3+ columns, it belongs in the browser. Don't wait for the user to ask — render it as HTML automatically and tell them the file path. You can still include a brief text summary in the chat, but the table itself should be the HTML page.

## Workflow

### 1. Think

Before writing HTML, commit to a direction. Don't default to "dark theme with blue accents" every time.

**What type of diagram?** Architecture, flowchart, sequence, data flow, schema/ER, state machine, mind map, data table, timeline, or dashboard.

**What aesthetic?** Pick one and commit:
- Blueprint (technical drawing feel, deep slate/blue palette, monospace labels)
- Editorial (serif headlines, generous whitespace, muted earth tones)
- Paper/ink (warm cream background, terracotta/sage accents)
- Monochrome terminal (green/amber on near-black, monospace)
- IDE-inspired (Dracula, Nord, Catppuccin, Solarized, Gruvbox — commit to the actual palette)

**Explicitly forbidden:**
- Neon dashboard (cyan + magenta + purple on dark)
- Any combination of Inter font + violet/indigo accents + gradient text

### 2. Structure

**Choosing a rendering approach:**

| Diagram type | Approach |
|---|---|
| Architecture (text-heavy) | CSS Grid cards + flow arrows |
| Architecture (topology-focused) | Mermaid `graph TD/LR` |
| Flowchart / pipeline | Mermaid |
| Sequence diagram | Mermaid `sequenceDiagram` |
| ER / schema diagram | Mermaid `erDiagram` |
| State machine | Mermaid `stateDiagram-v2` or `flowchart LR` |
| Mind map | Mermaid `mindmap` |
| Data table | HTML `<table>` |
| Timeline | CSS (central line + cards) |
| Dashboard | CSS Grid + Chart.js |

**Mermaid:** Always use `theme: 'base'` with custom `themeVariables` so colors match your page palette. Use `layout: 'elk'` for complex graphs. Always add zoom controls (+/−/reset buttons) and Ctrl/Cmd+scroll zoom to every `.mermaid-wrap` container.

**Mermaid CSS collision:** Never define `.node` as a page-level CSS class — Mermaid uses it internally. Use `.ve-card` for card components.

### 3. Style

**Typography:** Pick a distinctive font pairing. Load via Google Fonts CDN.
- DM Sans + Fira Code
- Instrument Serif + JetBrains Mono
- IBM Plex Sans + IBM Plex Mono
- Bricolage Grotesque + Fragment Mono
- Plus Jakarta Sans + Azeret Mono

**Forbidden as `--font-body`:** Inter, Roboto, Arial, Helvetica, system-ui alone.

**Color:** Use CSS custom properties. Define `--bg`, `--surface`, `--border`, `--text`, `--text-dim`, and 3–5 accent colors with dim variants. Support both light and dark themes via `@media (prefers-color-scheme: dark)`.

**Forbidden accent colors:** `#8b5cf6`, `#7c3aed`, `#a78bfa` (indigo/violet), `#d946ef`, the cyan-magenta-pink combination.

**Good accent palettes:**
- Terracotta + sage (`#c2410c`, `#65a30d`)
- Teal + slate (`#0891b2`, `#0369a1`)
- Rose + cranberry (`#be123c`, `#881337`)
- Amber + emerald (`#d97706`, `#059669`)
- Deep blue + gold (`#1e3a5f`, `#d4a73a`)

**Depth:** Vary card depth — hero sections get elevated shadows and accent-tinted backgrounds. Body content stays flat. Code blocks feel recessed.

**Animation:** Staggered fade-ins on page load guide the eye. Always respect `prefers-reduced-motion`. Forbidden: animated glowing box-shadows, pulsing/breathing effects.

### 4. Deliver

**Output location:** Write to `~/.agent/diagrams/`. Use a descriptive filename based on content.

**Open in browser:**
```bash
# macOS
open ~/.agent/diagrams/filename.html
# Linux
xdg-open ~/.agent/diagrams/filename.html
```

Tell the user the file path.

## File Structure

Every diagram is a single self-contained `.html` file. No external assets except CDN links (fonts, optional libraries).

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Descriptive Title</title>
  <link href="https://fonts.googleapis.com/css2?family=...&display=swap" rel="stylesheet">
  <style>
    /* CSS custom properties, theme, layout, components — all inline */
  </style>
</head>
<body>
  <!-- Semantic HTML: sections, headings, lists, tables, inline SVG -->
  <!-- Optional: <script> for Mermaid, Chart.js, or anime.js when used -->
</body>
</html>
```

## Built-in Commands

Six prompt templates are available in `skills/visual-explainer/prompts/`:

| Command | File | What it does |
|---------|------|--------------|
| `/generate-web-diagram` | `generate-web-diagram.md` | Generate an HTML diagram for any topic |
| `/generate-slides` | `generate-slides.md` | Generate a magazine-quality slide deck |
| `/diff-review` | `diff-review.md` | Visual diff review with architecture comparison and code review |
| `/plan-review` | `plan-review.md` | Compare a plan against the codebase with risk assessment |
| `/project-recap` | `project-recap.md` | Mental model snapshot for context-switching back to a project |
| `/fact-check` | `fact-check.md` | Verify accuracy of a review page or plan doc against actual code |

## Quality Checks

Before delivering, verify:
- **Squint test:** Blur your eyes — can you still perceive hierarchy?
- **Swap test:** Would replacing fonts/colors with a generic dark theme make this indistinguishable from a template?
- **Both themes:** Toggle OS between light and dark. Both should look intentional.
- **No overflow:** Resize to different widths. No content should clip. Every grid/flex child needs `min-width: 0`.
- **Mermaid zoom controls:** Every `.mermaid-wrap` must have zoom controls and scroll zoom.

## Anti-Patterns (AI Slop)

Forbidden patterns that signal "AI-generated template":
1. Inter or Roboto font with purple/violet gradient accents
2. Every heading has `background-clip: text` gradient
3. Emoji icons leading every section
4. Glowing cards with animated shadows
5. Cyan-magenta-pink color scheme on dark background
6. Perfectly uniform card grid with no visual hierarchy
7. Three-dot code block chrome (red/yellow/green dots)

If two or more are present, regenerate with a different aesthetic — Editorial, Blueprint, Paper/ink, or a specific IDE theme.
