---
name: 'kdh-uxui-redesign-full-auto-pipeline'
description: 'UXUI Redesign Pipeline v7.1 + ECC v1.9.0 (ProMax). 6 Phases. promax design-system DB + Playwright visual research + Stitch 2 MCP + party mode. BMAD real agent names. Step Grade system. Multi-theme support. Zero hardcoded colors.'
---

# UXUI Redesign Pipeline v7.1 + ECC v1.9.0 — ProMax Edition

6 Phase fully automated. **promax** for design system generation, **Playwright MCP** for visual research, **Stitch 2 MCP** for screen generation, **party mode** for quality gates.
Works on ANY frontend project — auto-detects framework, router, design tokens, and app shell.
Output root: `_uxui_redesign/`

## ABSOLUTE RULE: ZERO HARDCODED COLORS

This pipeline MUST NOT contain any hardcoded hex values, color names, or theme preferences.
ALL colors, fonts, and styles come from promax `--design-system` output at runtime.
If you see ANY specific color in this file → it is a BUG.

## Methodology Stack

- **ProMax**: Design intelligence DB — searchable 97 palettes, 57 font pairings, 50+ styles, 95 product types. Generates concrete design systems from keywords.
- **Party Mode**: 3-critic review. TeamCreate mandatory. Score >= 7/10. See [core/party-mode.md](../core/party-mode.md).
- **Playwright MCP**: Visual research — screenshot benchmark sites, compare rendered pages.
- **Stitch 2 MCP**: Screen generation — React/JSX + Tailwind CSS direct export from DESIGN.md.
- **code-review-graph**: Structural verification — blast radius, orphan detection, dependency analysis.
- **Accessibility** (from LibreUIUX): WCAG 2.1 AA audit only. Read `.claude/plugins/accessibility-compliance/README.md`.
- **Brand Systems 60-30-10** (from LibreUIUX): Color ratio validation only. Read `.claude/plugins/design-mastery/skills/brand-systems/SKILL.md` — use ONLY the 60-30-10 rule section.

## Mode Selection

- `all` or no args: Phase 0→5 fully automated
- `phase-N`: specific Phase only
- `resume`: Read pipeline-status.yaml → find first non-complete phase → resume
  - Run to completion. Do NOT stop at intermediate milestones.
  - Pipeline is NOT done until Phase 5 status=complete AND type-check passes AND deployed.

## Multi-Theme Support

This pipeline generates **multiple theme modes** in a single run. Each theme is a separate promax `--design-system` output with different keywords.

Default 3 themes (customizable per project — override via preset or project-context.yaml):
```yaml
themes:
  - name: "command"       # Example: dark premium theme
    keywords: "AI command center dark premium cyberpunk"
    target: "Power users, tech-savvy, dark mode lovers"
  - name: "studio"        # Example: light modern theme
    keywords: "AI virtual office collaboration modern clean"
    target: "Creative teams, daily users, light and friendly"
  - name: "corporate"     # Example: enterprise theme
    keywords: "AI enterprise SaaS dashboard professional trust"
    target: "Enterprise, formal, executive presentations"
```

User selects themes at pipeline start. Each theme gets its own `design-system/MASTER.md`.
Theme switching is implemented via CSS custom properties + a theme selector in settings.

## Step 0: Project Auto-Scan (runs before ANY mode)

> **Step 0: Project Auto-Scan**: See [core/project-scan.md](../core/project-scan.md)

**Output:** `_uxui_redesign/project-context.yaml`

Runs ONCE. Detects framework, router, all page routes, tailwind config, app shell files.

**ADDITION for v7.0:**
```
12. Count total pages across ALL packages (app + admin + landing)
13. Map page → package (which page belongs to which package)
14. Detect existing theme system (CSS variables, theme files, etc.)
```

## Scope: All Packages

v7.0 covers ALL frontend packages:

```yaml
packages:
  app:      # Main user app — all user-facing pages
  admin:    # Admin console — all management pages
  landing:  # Landing page — marketing/signup
```

Each package gets its own Stitch generation batch in Phase 3, but shares the same design system.

---

## Pipeline Overview

| Phase | Name | Party Mode | Steps | Key Tools |
|-------|------|-----------|-------|-----------|
| 0 | Auto-Scan | none | 1 | project-context.yaml |
| 1 | Visual Research | none | 3 | **Playwright MCP** (HARD GATE) |
| 2 | Design System | **3R party x N themes** | 2 | **promax --design-system** |
| 3 | Screen Generation | none | 4 | **Stitch 2 MCP** |
| 4 | Integration | **3R party** | 5 | Rebuild + API binding |
| 5 | Verification | **3R party** | 3 | **Playwright** + **code-review-graph** + a11y |

Output folders: `phase-0-scan/`, `phase-1-research/`, `phase-2-design-system/`, `phase-3-generated/`, `phase-4-integration/`, `phase-5-verification/`, `context-snapshots/`, `party-logs/`, `pipeline-status.yaml`

## Step Grade System

> **Scoring**: See [core/scoring.md](../core/scoring.md)

Each step has a grade that determines retry count, Party Mode depth, and agent model.

| Phase | Step | Grade |
|-------|------|-------|
| Phase 1 | 1-1 Benchmark Selection | C |
| Phase 1 | 1-2 Screenshot Capture | B |
| Phase 1 | 1-3 Visual Analysis | B |
| Phase 2 | 2-1 promax Generation | A |
| Phase 2 | 2-2 Party Review | A |
| Phase 3 | 3-1 Create Stitch Project | C |
| Phase 3 | 3-2 Generate Screens | B |
| Phase 3 | 3-3 Coverage Verification | B |
| Phase 3 | 3-4 Visual Review | B |
| Phase 4 | 4-0 App Shell | A |
| Phase 4 | 4-1 Page Rebuild | B |
| Phase 4 | 4-2 API Binding | A |
| Phase 4 | 4-3 Completeness Gate | B |
| Phase 4 | 4-4 Landing Page | B |
| Phase 5 | 5-1 Visual Verification | B |
| Phase 5 | 5-2 E2E Functional | A |
| Phase 5 | 5-3 Accessibility | B |

**Grade definitions:**
- **Grade A (critical):** 3 retries, minimum 2 Party Mode cycles, Devil's Advocate on cycle 2
- **Grade B (important):** 2 retries, minimum 1 cycle + cross-talk verified
- **Grade C (setup):** 1 retry, Writer Solo (no Party Mode)

## Model Strategy

- **Orchestrator**: Opus (always)
- **Writer**: Opus for Grade A steps, Sonnet for Grade B/C
- **Critics**: Opus for Phase 2 (design decisions) + Phase 4-2 (API binding) + Phase 5-2 (E2E). Sonnet for others.

## Party Mode

> **Party Mode Protocol**: See [core/party-mode.md](../core/party-mode.md)

- TeamCreate mandatory for all party mode phases. No standalone subagents.
- 3R = Write → Review x 3 critics → Fix → Verify → Score
- Pass: avg score >= 7/10. Fail: retry (max per Grade) → escalate → continue.
- Orchestrator relays ALL messages (no Writer↔Critic direct). Idle agents don't auto-wake.

**Critics (BMAD Real Agents):**
- **sally (UX Practicality):** Does this actually work for users? Fitts's Law, cognitive load, click depth.
  - Persona: load `_bmad/bmm/agents/ux-designer.md` at team creation
- **winston (Visual Consistency):** Does every page look like it belongs to the same product? Color ratio 60-30-10, spacing rhythm, typography hierarchy.
  - Persona: load `_bmad/bmm/agents/architect.md` at team creation
- **quinn (Technical Reality):** Can this be built? Bundle size, render performance, CSS complexity, framework compatibility.
  - Persona: load `_bmad/bmm/agents/qa.md` at team creation

**Persona loading is MANDATORY.** Each critic agent MUST be initialized with its persona file. If the persona file is missing, log a warning but still create the critic with the role description above.

### Cross-talk Protocol (mandatory)

After critic reviews (parallel), a cross-talk round MUST happen:
- **sally <-> winston:** "UX comfort vs technical feasibility?"
- **winston <-> quinn:** "Architecture concerns vs implementation reality?"
- **quinn <-> sally:** "QA gaps vs user experience tradeoffs?"

Cross-talk MUST happen. Each critic updates their party-log with a `## Cross-talk` section.

### Orchestrator Phase Completion Checklist (BLOCKING)

Before accepting [Phase Complete], Orchestrator MUST verify ALL:
- [ ] All critic party-log files exist (not just messages)
- [ ] Each critic log has `## Cross-talk` section
- [ ] Score stdev >= 0.5 (no rubber-stamp)
- [ ] Grade A phases: 2nd cycle completed with Devil's Advocate
- [ ] grep hardcoded hex in changed files → 0 matches
- [ ] Context snapshot saved

ANY item unchecked → REJECT

---

## Phase 1: Visual Research (HARD GATE — Playwright Required)

**Output:** `phase-1-research/screenshots/`, `phase-1-research/benchmark-analysis.md`

**This is the #1 failure point. Text-only research produces text-only designs.**

### Step 1-1: Benchmark Site Selection

```
1. Read project-context.yaml → understand product domain
2. WebSearch for top 15 benchmark sites in these categories:
   a. Direct competitors (3-4 sites)
   b. Best SaaS dashboards (3-4: Vercel, Linear, Notion, Supabase, etc.)
   c. Best admin panels (2-3: Retool, Appsmith, Forest Admin, etc.)
   d. Best landing pages (2-3: Stripe, Clerk, Lemon Squeezy, etc.)
   e. Design inspiration (1-2: Dribbble award winners, Awwwards)
3. Output: phase-1-research/benchmark-sites.md — URL list with category + why selected
```

### Step 1-2: Screenshot Capture (HARD GATE)

```
FOR EACH of the 15 benchmark sites:
  1. Playwright MCP → browser_navigate to URL
  2. browser_take_screenshot → save to phase-1-research/screenshots/{site-name}-desktop.png
  3. browser_resize to 390x844 (mobile)
  4. browser_take_screenshot → save to phase-1-research/screenshots/{site-name}-mobile.png
  5. browser_snapshot → save DOM structure to phase-1-research/snapshots/{site-name}.txt

HARD GATE: minimum 10 sites successfully screenshotted.
If Playwright fails → try WebFetch as fallback for structure analysis.
But: "0 screenshots" = pipeline STOPS. Do NOT proceed with text-only research.
```

### Step 1-3: Visual Analysis

```
FOR EACH screenshot:
  1. Read the screenshot image
  2. Analyze and document:
     - Layout pattern (sidebar+content, top-nav+content, full-width, etc.)
     - Color scheme (dark/light, primary/accent colors observed)
     - Typography (heading size relative to body, font personality)
     - Spacing rhythm (dense vs airy, card padding patterns)
     - Navigation pattern (sidebar items, grouping, icons)
     - Key UX patterns (command palette, search, notifications, empty states)
  3. Rate relevance to project (1-5)

Output: phase-1-research/benchmark-analysis.md
  - Per-site analysis with screenshot references
  - Cross-site pattern synthesis: "8 of 15 sites use collapsible sidebar"
  - TOP 5 patterns to adopt (with screenshot evidence)
  - TOP 3 anti-patterns to avoid (with screenshot evidence)

git commit "docs(uxui): Phase 1 complete — {N} benchmark sites screenshotted and analyzed"
```

---

## Phase 2: Design System Generation (promax + Party Mode)

**Output:** `phase-2-design-system/{theme-name}/MASTER.md` per theme

### Step 2-1: promax Design System Generation

```
FOR EACH theme in themes list:
  1. Run promax --design-system with theme keywords:
     python3 .claude/skills/ui-ux-pro-max/scripts/search.py "{keywords}" \
       --design-system --persist -p "{project}-{theme-name}"

  2. Run supplementary searches:
     python3 search.py "{keywords}" --domain style -n 5
     python3 search.py "{keywords}" --domain typography -n 5
     python3 search.py "{keywords}" --domain landing -n 3
     python3 search.py "{keywords}" --stack react -n 5

  3. Read promax output → enhance with Phase 1 visual research patterns

  4. Validate with 60-30-10 rule (from Brand Systems):
     - 60% dominant (backgrounds/surfaces)
     - 30% secondary (supporting)
     - 10% accent (CTAs/highlights)
     - If ratio is off → adjust before saving

  5. Generate DESIGN.md for Stitch 2:
     - ALL values from promax output (ZERO manual color picks)
     - Include: colors, fonts, spacing, shadows, radii, animations
     - Include: "CONTENT AREA ONLY — no sidebar/topbar in pages"
     - Include: icon library choice (Lucide React default)
     - Include: color-mode declaration (from promax recommendation)

  6. Generate page-specific overrides for key pages

  7. Save to phase-2-design-system/{theme-name}/MASTER.md
  8. Save DESIGN.md to phase-2-design-system/{theme-name}/DESIGN.md
```

### Step 2-2: Party Mode Review (per theme)

```
Spawn team: Writer + sally + winston + quinn
(Load persona files: _bmad/bmm/agents/ux-designer.md, architect.md, qa.md)

FOR EACH theme:
  Writer presents: MASTER.md + DESIGN.md + Phase 1 benchmark comparison

  sally: "Will users find this comfortable for 8-hour daily use?"
  winston: "Is the 60-30-10 ratio correct? Typography hierarchy clear at all sizes?"
  quinn: "Can Tailwind express all these tokens? Any CSS performance issues?"

  Score >= 7 → PASS. Score < 7 → adjust promax keywords and re-run Step 2-1.

Present ALL theme candidates to user for selection (or keep all for multi-theme).

git commit "docs(uxui): Phase 2 complete — {N} theme design systems generated"
```

> **ECC Enhancement — design-system + design-principles + design-masters**: The `design-system` skill supplements promax with AI slop detection and 10-dimension visual audit. `design-principles` applies timeless design rules (Rams, Muller-Brockmann). `design-masters` references legendary designer patterns. These are advisory inputs to promax, not replacements. See [core/ecc-integration.md §4.1](../core/ecc-integration.md#41-design-system-phase--design-system--design-principles--design-masters).

---

## Phase 3: Screen Generation (Stitch 2 MCP)

**Output:** `phase-3-generated/{theme-name}/{package}/{page-name}.tsx`

### Step 3-1: Create Stitch Project

```
FOR EACH theme:
  1. Call Stitch MCP create_project: "{project}-{theme-name}"
  2. Save projectId to pipeline-status.yaml
  3. Upload DESIGN.md from Phase 2 as design system context
```

### Step 3-2: Generate All Package Screens

```
FOR EACH theme:
  FOR EACH package (from project-context.yaml):
    FOR EACH page route (from project-context.yaml, grouped in batches of 5):
      1. Build prompt from:
         - DESIGN.md (theme-specific)
         - Page purpose (from project-context.yaml or tech spec)
         - Phase 1 benchmark patterns (relevant to this page type)
         - "Generate React/JSX + Tailwind CSS. CONTENT AREA ONLY. No sidebar/topbar."
      2. Call Stitch MCP generate_screen_from_text
      3. Call get_screen → save .tsx to phase-3-generated/{theme}/{package}/{page}.tsx
      4. Save screenshot .png if available

git commit per package: "docs(uxui): Phase 3-2 {package} screens generated for {theme}"
```

### Step 3-3: Coverage Verification

```
FOR EACH theme:
  1. Count generated .tsx files vs total page routes
  2. GATE: ALL routes must have a corresponding .tsx
  3. Missing pages → auto-generate prompt from existing page code + DESIGN.md → generate
  4. Verify: 0 missing pages
```

### Step 3-4: Visual Review

```
FOR EACH theme:
  1. Read ALL generated screenshots
  2. Check against DESIGN.md: colors match? fonts match? spacing consistent?
  3. Check against Phase 1 benchmarks: layout patterns adopted?
  4. Flag mismatches → re-generate with refined prompt (max 2 retries)

Output: phase-3-generated/stitch-review.md
git commit "docs(uxui): Phase 3 complete — all screens generated and reviewed"
```

---

## User Gate Protocol

| # | Phase | Step | Question |
|---|-------|------|----------|
| 1 | Phase 2 | 2-2 Design System | Design system direction confirmed — colors/fonts per theme correct? |
| 2 | Phase 3 | 3-4 Visual Review | Stitch output reviewed — satisfied? Pages to modify? |
| 3 | Phase 4 | 4-0 App Shell | App Shell rebuild result — sidebar/layout correct? |

GATE steps pause for user input. Never auto-proceed.

---

## Phase 4: Integration (Code Rebuild + Party Mode)

### Step 4-0: App Shell Theme Sync (MANDATORY FIRST)

```
FOR EACH package (from project-context.yaml, frontend packages):
  1. Read MASTER.md for the DEFAULT theme (or first theme)
  2. Build CSS custom properties file (themes.css):
     FOR EACH theme:
       [data-theme="{theme-name}"] {
         --color-bg: {from MASTER.md};
         --color-surface: {from MASTER.md};
         --color-primary: {from MASTER.md};
         --color-text: {from MASTER.md};
         /* ... all tokens as CSS vars */
       }
  3. Update entry file:
     - Set default theme via data-theme attribute
     - Remove any hardcoded color classes from previous designs
  4. Rebuild Layout:
     - Use CSS var(--color-bg) instead of hardcoded values
     - Structure from Stitch app-shell output (if exists)
  5. Rebuild Sidebar:
     - Use CSS var(--color-sidebar-bg), var(--color-sidebar-text), etc.
     - Navigation items from project-context.yaml
  6. Update index.html:
     - Font CDN links from MASTER.md
     - Remove old font links
  7. Update tailwind.config:
     - Extend with CSS variable references
     - No hardcoded hex values — all via var()
  8. Add theme switcher component (for settings page)
  9. Type-check → must pass

git commit "feat(uxui): Phase 4-0 app shell synced with multi-theme system"
```

### Step 4-1: Page Rebuild (parallel agents)

```
FOR EACH package:
  1. Generate color-mapping.md:
     Stitch output class → CSS variable mapping
  2. Split pages into batches of 4-5
  3. Launch parallel agents, each agent:
     a. Read Stitch .tsx for the page
     b. Read existing page code
     c. EXTRACT from Stitch: layout, sections, cards, spacing, typography
     d. PRESERVE from existing: hooks, API calls, state, event handlers, types
     e. REWRITE render output using CSS variables (NOT hardcoded colors)
     f. Type-check
  4. Wait for ALL agents → type-check full project

CRITICAL: This is a REBUILD, not a patch.
CRITICAL: ALL colors via CSS variables. grep for hardcoded hex → must be 0.
```

> **ECC Enhancement — coding-standards + tdd-workflow**: Rebuild agents follow `coding-standards` for TypeScript/React patterns (immutability, error handling). Component tests use `tdd-workflow` RED→GREEN→REFACTOR. See [core/ecc-integration.md §4.2](../core/ecc-integration.md#42-implementation-phase--coding-standards--tdd-workflow).

### Step 4-2: API Binding + Routing (Party Mode)

```
Spawn team for review:
  1. Verify all data-fetching hooks work (useQuery, fetch, etc.)
  2. Verify routing: all lazy imports resolve
  3. Verify navigation links match routes
  4. Verify SSE/WebSocket connections
  5. Verify forms submit to correct endpoints
  6. Run existing tests
  7. Type-check: 0 errors

Party mode critics review the API binding quality.
Score >= 7 → proceed. Score < 7 → fix and re-review.
```

### Step 4-3: File Completeness Gate (HARD GATE)

```
1. Parse ALL router files across ALL packages
2. Verify every import resolves to an existing file
3. GATE: 0 missing files
4. Create missing files from Stitch output if needed
5. Type-check after any file creation
```

### Step 4-4: Landing Page Build

```
1. Read Stitch landing page output
2. Build landing page in landing package:
   - Hero section with product value prop
   - Feature highlights
   - Screenshots/demo section
   - CTA → app registration
   - Footer
3. Use same CSS variable theme system
4. Connect routing
5. Type-check

git commit "feat(uxui): Phase 4 complete — all pages rebuilt with multi-theme"
```

---

## Phase 5: Verification (Party Mode)

### Step 5-1: Visual Verification (Playwright)

```
FOR EACH theme:
  FOR EACH page:
    1. Start dev server
    2. Set theme via data-theme attribute
    3. Playwright → navigate to page
    4. Screenshot desktop (1280x800) + mobile (390x844)
    5. Compare against Stitch reference
    6. Check: no dark/light conflicts, colors match theme
    7. Check: console errors (0 critical)

Output: phase-5-verification/visual-report.md
```

### Step 5-2: E2E Functional Verification (Playwright + code-review-graph)

```
1. Build code-review-graph for project
2. Analyze: orphan components, circular dependencies, missing connections
3. FOR EACH page:
   - List ALL interactive elements
   - Test EVERY button, input, form, dropdown, tab, link
   - CRUD cycles where applicable
   - Empty/loading/error states
   - Console errors: 0 critical
4. "Screenshot only" = NOT verified. Every element must be clicked/typed.

Output: phase-5-verification/e2e-report.md
```

> **ECC Enhancement — click-path-audit + browser-qa**: `click-path-audit` maps rebuilt pages' state stores and traces all handlers. `browser-qa` 4-phase protocol structures verification. See [core/ecc-integration.md §4.3](../core/ecc-integration.md#43-verification-phase--click-path-audit--browser-qa).

### Step 5-3: Accessibility Audit (Party Mode)

```
Read: .claude/plugins/accessibility-compliance/README.md

FOR EACH theme:
  1. WCAG 2.1 AA contrast ratios for ALL text/bg pairs
  2. Focus indicators visible
  3. Keyboard navigation works
  4. Touch targets >= 44px
  5. prefers-reduced-motion respected
  6. Screen reader landmarks present

Party mode critics score the accessibility.
Score >= 7 → PASS.

Output: phase-5-verification/accessibility-report.md
git commit "docs(uxui): Phase 5 complete — all verification passed"
```

> **ECC Enhancement — synthesis-master + libre commands**: `synthesis-master` coordinates all LibreUIUX plugins. `/libre-ui-critique` (design feedback), `/libre-a11y-audit` (WCAG 2.1 AA), `/libre-ui-responsive` (responsive check). synthesis-master coordinates but doesn't replace party mode critics. See [core/ecc-integration.md §4.4](../core/ecc-integration.md#44-final-review--synthesis-master--libre-commands).

---

## Anti-Patterns (ranked by failure frequency)

1. **Hardcoded colors in pipeline file** — ALL colors from promax at runtime. ZERO in pipeline.
2. **Text-only research** — Playwright screenshots required (HARD GATE).
3. **"Add classes" instead of "rebuild"** — Phase 4 = REWRITE render output, not add utility classes.
4. **Stitch sidebar treated as authoritative** — IGNORE Stitch nav/sidebar. Content area only.
5. **promax not invoked** — promax is Phase 2 core, not optional.
6. **Single theme assumption** — Generate N themes. CSS variables enable runtime switching.
7. **Some packages ignored** — v7.0 covers ALL packages.
8. **Screenshot-only QA** — Every interactive element must be tested.
9. **Missing files shipped** — Phase 4-3 completeness gate: 0 missing files.
10. **No blast radius analysis** — code-review-graph for structural verification.
11. **Knowledge sidebar default open on mobile** — Sidebar initializes as open on all screen sizes, overlaps content on 390px. FIX: `useState(() => window.innerWidth >= 1024)` for panels with sidebar.
12. **CI lockfile mismatch** — After dependency updates, regenerate lockfile in runner workdir AND local, commit from runner environment.
13. **Inactive DB entities block login** — Test user or company `is_active=false` blocks E2E verification login. FIX: Phase 0 Pre-flight verifies test user + company active status before Playwright tests.

## Safeguards & Timeouts

| Mechanism | Value |
|-----------|-------|
| max_retry | 2 per step |
| step_timeout | 15min + 2min grace |
| party_timeout | 10min per round |
| Stitch MCP timeout | 5min per screen |
| Playwright timeout | 30s per page |
| stall_threshold | 5min no message |

## Completion Gate (ALL must pass)

```
[ ] Step 0: project-context.yaml with all packages and routes
[ ] Phase 1: >= 10 benchmark screenshots captured and analyzed
[ ] Phase 2: promax design system generated for each theme, party score >= 7
[ ] Phase 2: 60-30-10 color ratio validated
[ ] Phase 2: DESIGN.md generated per theme (zero hardcoded colors)
[ ] Phase 3: ALL page routes have Stitch-generated .tsx (per theme)
[ ] Phase 3: Visual review PASS
[ ] Phase 4-0: App shell synced with CSS variable theme system
[ ] Phase 4-0: Theme switcher component working
[ ] Phase 4-1: ALL pages rebuilt (REBUILD not patch)
[ ] Phase 4-1: grep for hardcoded hex in pages → 0 matches
[ ] Phase 4-2: API binding verified, party score >= 7
[ ] Phase 4-3: 0 missing files (completeness gate)
[ ] Phase 4-4: Landing page built and routed
[ ] Phase 5-1: Every page screenshotted per theme
[ ] Phase 5-2: Every interactive element tested
[ ] Phase 5-2: code-review-graph: 0 orphan components
[ ] Phase 5-3: WCAG 2.1 AA pass for all themes
[ ] Type-check: 0 errors
[ ] git commit + push + deploy successful
[ ] pipeline-status.yaml: all phases complete
```

## Core Rules

1. **ZERO hardcoded colors.** All colors from promax → CSS variables → Tailwind. grep for hex in pages = 0.
2. **Playwright screenshots are mandatory.** 0 screenshots = pipeline STOPS.
3. **promax --design-system is the single source of design decisions.** No manual color picking.
4. **Phase 4 = REBUILD, not patch.** Rewrite render output to match Stitch structure.
5. **ALL packages covered.** No package left behind.
6. **Multi-theme via CSS variables.** No theme-specific hardcoded classes in pages.
7. **Party mode uses TeamCreate.** No standalone subagents. Orchestrator relays all messages.
8. **Run to completion.** Not done until Phase 5 complete + type-check + deployed.
9. **Content area only from Stitch.** Ignore Stitch sidebar/topbar. App shell is shared.
10. **Every interactive element tested.** "Looks fine" ≠ "works fine".
11. **code-review-graph for structural verification.** Orphans, circular deps, missing connections.
12. **pipeline-status.yaml is single source of truth.** On resume: read it first.
13. **ECC design skills are advisory.** design-system/design-principles/design-masters inform promax, not override it. promax remains the single source of design decisions. synthesis-master coordinates but doesn't replace party mode critics.

## Non-BMAD Fallback

If `_bmad/` directory doesn't exist:
- Use 3 generic critics: "UX Reviewer", "Tech Reviewer", "QA Reviewer"
- Skip persona file loading
- All other protocols (Party Mode, Cross-talk, Score Variance) still apply
- Output to `_uxui_redesign/` (same structure)
