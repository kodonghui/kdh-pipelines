---
name: 'kdh-code-review-full-auto'
description: 'Universal full-auto code review + auto-fix pipeline v3.0. 8 phases: Static Gate → Visual/E2E → Risk → 3-Critic Party → Verdict → Auto-Fix → Re-Review → Final. Works on ANY project. Usage: /kdh-code-review-full-auto [PR-url|commit-range|changed-files]'
---

# KDH Code Review Full-Auto Pipeline v3.0 (Universal)

8-phase automated code review + auto-fix: Static Gate → Visual/E2E Gate → Risk Classification → AI 3-Critic Party → Resolution → Auto-Fix → Re-Review → Final Verdict.
Integrates Playwright visual regression, axe-core accessibility, Lighthouse performance, BMAD party mode, and automated remediation loop.

**Universal**: Works on any project. Auto-detects project structure, build tools, design tokens, and architecture docs.

## kdh-review vs kdh-code-review-full-auto (역할 구분)

| 측면 | kdh-review | kdh-code-review-full-auto |
|------|-----------|--------------------------|
| 범위 | 스토리 1개 | PR / 커밋 범위 / 전체 코드 |
| 트리거 | /kdh-build 후 자동 | 수동 또는 CI 훅 |
| 채점 | D1-D6 루브릭 (critic-rubric.md 가중 평균) | Security x3, Architecture x2, UX-Perf x1 |
| 리뷰어 | BMAD 에이전트 (winston/quinn/john) | 범용 비평가 (Security/Arch/UX-Perf) |
| 수정 | CONDITIONAL → kdh-build fix → 재리뷰 | 자동수정 에이전트 (worktree) |
| 블로킹 | 다음 스토리 차단 | PR 머지 차단 |

서로 대체하지 않음:
- Sprint 스토리 빌드 후 → `/kdh-review` (필수, party mode)
- PR 머지 전 → `/kdh-code-review-full-auto`
- Sprint 후 전체 점검 → `/kdh-code-review-full-auto`

## Mode Selection

- No args: Review uncommitted changes (`git diff HEAD`)
- PR URL: Review PR diff (`gh pr diff {number}`)
- Commit range: Review specific commits (`git diff {base}..{head}`)
- `full`: Full codebase audit (slow, use sparingly)

## Model Strategy

| Role | Model | Notes |
|------|-------|-------|
| Orchestrator | opus | Risk classification, final verdict, fix orchestration |
| Critic-Security | **opus** | OWASP, injection, auth bypass — security has zero compromise |
| Critic-Architecture | **opus** | Boundary violations, patterns, DRY — architecture judgment needs accuracy |
| Critic-UX-Perf | **opus** | Playwright VRT, a11y, bundle size — subtle UI bug detection |
| Fixer-Agent(s) | **opus** | Worktree isolation, per-issue fixes — precise fixes are critical |
| Re-Reviewer | **opus** | Delta-only verification — ensure fixes don't create new problems |

**All Opus rationale**: Code review must catch subtle bugs/security vulnerabilities — accuracy > speed. Sonnet risks false negatives.

---

## Anti-Patterns

1. **Reviewing all files equally** — FIX: Risk-classify first, focus effort on HIGH risk
2. **Vague comments** — FIX: Conventional Comments format mandatory (label: message)
3. **Nitpicking style issues** — FIX: ESLint/Prettier handle style. Critics focus on logic/security/architecture
4. **Skipping tests** — FIX: Phase 2 gates are mandatory. No skip.
5. **Approving without evidence** — FIX: Each critic must cite file:line and explain WHY

---

## Step 0: Project Auto-Detection (pre-flight, ~5sec)

Before any phase runs, Orchestrator auto-detects the project environment:

```
Orchestrator auto-detects:
├── Build System:
│   ├── Find all tsconfig.json files → collect for tsc checks
│   ├── Find package.json → detect package manager (npm/yarn/pnpm/bun)
│   ├── Detect monorepo: turbo.json, pnpm-workspace.yaml, lerna.json, nx.json
│   ├── If monorepo: identify all packages/workspaces
│   └── Detect test runner: jest, vitest, bun:test, mocha, pytest, go test
│
├── Frontend Detection:
│   ├── Framework: React (vite.config), Next.js (next.config), Nuxt (nuxt.config),
│   │   SvelteKit (+layout.svelte), Angular (angular.json), Vue (vue.config)
│   ├── Entry files: App.tsx, main.tsx, app.vue, +layout.svelte, _app.tsx, etc.
│   ├── Router files: routes.tsx, router.ts, app-router/, pages/ directory
│   ├── Layout/Shell files: layout.tsx, sidebar.tsx, shell.tsx, nav.tsx
│   └── UI directories: src/components/, src/ui/, src/pages/, src/views/
│
├── Design Tokens:
│   ├── Read tailwind.config.{ts,js,mjs,cjs} → extract theme.extend.colors
│   ├── Read design-tokens.md or design-tokens.json if exists
│   ├── Read CSS variables in globals.css, app.css, index.css, styles.css
│   ├── Read theme.ts or theme.js if exists
│   └── Store detected tokens for Critic-UX-Perf reference
│
├── Architecture Docs:
│   ├── Read architecture.md, ARCHITECTURE.md if exists
│   ├── Read ADR/ or docs/adr/ directory if exists
│   ├── Read CLAUDE.md, .cursorrules, AGENTS.md for project conventions
│   └── Store architecture decisions for Critic-Architecture reference
│
├── CI/CD:
│   ├── .github/workflows/ → GitHub Actions
│   ├── .gitlab-ci.yml → GitLab CI
│   ├── Jenkinsfile, .circleci/ → other CI
│   └── Dockerfile, docker-compose* → container config
│
└── Output: review-report/phase-0-detection.md
    Contains: all detected paths, tools, tokens, and conventions
```

---

## Phase 1: Static Gate (parallel, ~1min)

Run ALL in parallel. Any FAIL = block review.

```
Orchestrator runs simultaneously:
├── TypeScript: for each tsconfig.json detected → tsc --noEmit -p {path}
├── Linting: detect and run project linter
│   ├── ESLint: npx eslint {changed-files} --no-warn-ignored
│   ├── Or: biome, oxlint, ruff (Python), golangci-lint (Go), clippy (Rust)
│   └── Use whatever linter is configured in the project
├── Tests: run affected tests using detected test runner
│   ├── bun test / npx vitest run / npx jest --changedSince / pytest / go test
│   └── Only run tests affected by changed files (use --changedSince or manual matching)
├── Build check: if build script exists, run it (detect from package.json scripts)
└── Bundle size check: if dist/build output exists, compare to baseline
```

**Gate criteria:**
- Type check errors: 0
- Lint errors: 0 (warnings OK)
- Tests: all pass
- Bundle size: no increase > 10KB gzip vs main (if measurable)

**Output:** `review-report/phase-1-static.md`

---

## Phase 2: Visual & E2E Gate (parallel, ~12min)

Run if Phase 1 passes AND changed files include frontend/UI files (auto-detected from Step 0).

### Phase 2A: Static E2E (existing Playwright specs, ~2min)

Orchestrator runs existing test suites directly:

```
IF packages/e2e/ or tests/e2e/ exists:
  npx playwright test --reporter=json 2>&1 | tee review-report/phase-2a-static.json
ELIF tests/ or __tests__/ with *.spec.* files exist:
  Run detected test runner (vitest, jest, etc.)
ELSE:
  Skip Phase 2A, note "No existing E2E specs"
```

**Output:** `review-report/phase-2a-static.md`

### Phase 2B: 소크라테스 Dynamic E2E (team agents, ~8min)

TRIGGER: Always run when UI files changed. Phase 2A failure does NOT block 2B.

Uses 소크라테스 QA methodology: state expected result BEFORE verification, then compare.
Uses Claude Code TeamCreate for 4 parallel agents, each with Playwright MCP (--headless).

```
Step 2B.0: Pre-flight (orchestrator, ~15s)
  ├── Read phase-0-detection.md → routes, auth, base URL, design tokens
  ├── git diff → changed files → map to affected routes (priority)
  ├── Map unchanged pages sharing components → regression targets
  ├── Detect PRD/feature-spec for scenario generation (Tier 1/2/3 fallback)
  ├── Auto-detect routes universally:
  │   ├── React Router: parse App.tsx for <Route path>
  │   ├── Next.js: list app/ or pages/ directory
  │   ├── Vue Router: parse router/index.ts
  │   ├── SvelteKit: list src/routes/
  │   └── Fallback: grep for path: in config files
  ├── Generate route assignments (round-robin, priority routes first)
  ├── AUTH PRE-CHECK: Orchestrator tests login via Playwright MCP BEFORE spawning agents
  │   ├── Login success → proceed
  │   └── Login failure → Phase 2B FAIL immediately (don't waste agent resources)
  └── Write: review-report/socrates-e2e/phase-2b-preflight.md
      (includes: route assignments, credentials, design tokens, changed files, PRD path)

Step 2B.1: Team Creation (~5s)
  TeamCreate(team_name: "socrates-e2e")
  Create shared blockers file: review-report/socrates-e2e/blockers.md (empty)

Step 2B.2: Spawn 4 Agents (staggered 10s apart to avoid resource contention)
  Agent A: socrates-functional (CRUD, forms, navigation, data persistence)
  Agent B: socrates-visual (screenshots, design tokens, responsive, icons)
  Agent C: socrates-edge (empty states, security/auth bypass, console errors, input boundaries)
  Agent D: socrates-regression (sidebar sweep, shared component consumers, theme consistency)

  Each agent:
  - Reads phase-2b-preflight.md for assignments
  - Reads blockers.md before starting (other agents may have found blockers)
  - Logs in independently via Playwright MCP
  - Uses 소크라테스 method: 기댓값 → navigate → snapshot → interact → screenshot → compare

Step 2B.3: Agent Work (parallel, timeout: 8min per agent)
  Each agent executes its specialized checklist on assigned routes:

  12-item universal checklist (agent-specific focus):
    Agent A: items 3(buttons), 5(forms), 10(CRUD)
    Agent B: items 1(load), 2(layout), 11(empty state)
    Agent C: items 8(delete dialogs), 11(empty state), 12(console errors) + security
    Agent D: items 1(load), 2(layout), 3(buttons) + sidebar sweep

  FOR EACH assigned route:
    1. State 기댓값 (expected result) BEFORE verification
    2. browser_navigate → browser_snapshot → interact
    3. browser_take_screenshot (on bugs or significant states)
    4. Compare actual vs expected
    5. Mismatch → BUG record (severity, screenshot, console errors, fix suggestion)
    6. Check blockers.md — if blocker found by another agent, skip affected routes

  Write results → review-report/socrates-e2e/agent-{A|B|C|D}.md
  Write blockers → review-report/socrates-e2e/blockers.md (if found)

Step 2B.4: Aggregation (orchestrator, ~30s)
  ├── Read all 4 agent reports (partial results OK if timeout)
  ├── De-duplicate bugs (same page + same symptom = 1 bug, cross-referenced)
  ├── Assign final severity: Critical / Major / Minor / Security
  ├── Calculate Phase 2B score: (pages_passed / pages_tested) × 10
  ├── Collect fix suggestions for Phase 6 input
  └── Write: review-report/phase-2b-socrates.md
```

**Gate criteria (Phase 2A + 2B combined):**
- Phase 2A: existing E2E specs pass (if they exist)
- Phase 2B: 0 Critical bugs
- Phase 2B: 0 Security bugs (unauthorized access)
- Phase 2B: page load success rate >= 80%
- Phase 2B: 0 Uncaught/ChunkLoadError console errors across all pages

**Output:**
- `review-report/phase-2a-static.md`
- `review-report/phase-2b-socrates.md`
- `review-report/socrates-e2e/agent-{A|B|C|D}.md`
- `review-report/socrates-e2e/screenshots/agent-{A|B|C|D}/`

---

## Phase 3: Risk Classification (auto, ~10sec)

Orchestrator classifies each changed file using pattern-based rules that work on ANY project.

### Auto-Detected Risk Patterns

```
HIGH RISK (mandatory deep review — score: 10 per file):
  Authentication & Security:
    - **/auth*, **/login*, **/token*, **/session*
    - **/middleware*, **/guard*, **/interceptor*, **/policy*
    - **/encrypt*, **/credential*, **/secret*, **/password*
    - **/permission*, **/rbac*, **/acl*
  Core Logic:
    - **/engine*, **/core*, **/kernel*
    - **/schema*, **/migration*, **/model* (data layer)
    - **/db/*, **/database/*
  Infrastructure:
    - Dockerfile, docker-compose*, .github/workflows/**
    - .gitlab-ci.yml, Jenkinsfile, .circleci/**
    - terraform/**, k8s/**, helm/**
  Entry & Layout Files (auto-detected in Step 0):
    - App.tsx, main.tsx, main.ts, index.tsx (entry files)
    - app.vue, +layout.svelte, _app.tsx, _document.tsx
    - layout.tsx, sidebar.tsx, shell.tsx, nav.tsx, header.tsx
  Configuration:
    - tailwind.config.*, vite.config.*, next.config.*, nuxt.config.*
    - webpack.config.*, tsconfig.json, .env.example
  Shared Contracts:
    - **/shared/types*, **/shared/schema*, **/types/index*
    - **/api/types*, **/contracts/*

MEDIUM RISK (standard review — score: 5 per file):
  API Layer:
    - **/routes*, **/api*, **/endpoints*, **/controllers*
    - **/handlers*, **/resolvers* (GraphQL)
  Business Logic:
    - **/services*, **/lib*, **/utils*, **/helpers*
    - **/domain*, **/use-cases*, **/interactors*
  State Management:
    - **/hooks*, **/stores*, **/state*, **/context*
    - **/reducers*, **/actions*, **/selectors*
  Shared Components:
    - **/components/** (shared/reusable components)
  Router Files:
    - **/router*, **/routes.tsx, **/routing*

LOW RISK (quick scan — score: 1 per file):
  UI Pages:
    - **/pages/*, **/views/*, **/screens/*
  Tests:
    - **/*.test.*, **/*.spec.*, **/__tests__/**
  Documentation:
    - **/*.md, **/*.yaml, **/*.json (non-config)
    - **/docs/*, **/documentation/*
  Static Assets:
    - **/assets/*, **/public/*, **/static/*
    - **/*.svg, **/*.png, **/*.jpg, **/*.ico
  Design Artifacts:
    - **/design/*, **/mockups/*, **/wireframes/*
  Planning/Build Artifacts:
    - **/_*, **/dist/*, **/build/*, **/out/*
```

### Risk Score Modifiers

```
Bulk Change Detection (applied AFTER per-file scoring):
  - Changed files > 10         → +20 points (bulk change = higher integration risk)
  - Changed files > 30         → +40 points (major refactor = maximum scrutiny)

Always HIGH RISK Override (regardless of path pattern):
  - Entry file changed (App.tsx/main.tsx/app.vue/_app.tsx/+layout.svelte)  → force HIGH
  - Layout/Sidebar/Shell file changed                                       → force HIGH
  - Router file changed                                                     → force HIGH
  - Design tokens/tailwind.config changed                                   → force HIGH
  - Shared type definition files changed                                    → force HIGH
  - package.json dependency changes (not just devDeps)                      → force HIGH
```

### Verdict Thresholds

**Risk score**: Sum all file scores + modifiers.

| Score | Verdict | Action |
|-------|---------|--------|
| < 10 | **Ship** | Auto-approve if Phase 1+2 pass |
| 10-30 | **Show** | Async review (proceed through Phase 4) |
| > 30 | **Ask** | Full deep review (all critics at maximum depth) |

**Output:** `review-report/phase-3-risk.md` with file classification table

---

## Phase 4: AI 3-Critic Party Review (parallel critics, ~3min)

Launch 3 critic agents simultaneously. Each reads changed files FROM DISK.

### Critic-Security Prompt
```
You are CRITIC-SECURITY performing a universal code review.
Personas: Quinn (QA, coverage-first) + Dana (Security, paranoid)

BEFORE REVIEWING — Read project context:
- review-report/phase-0-detection.md (project structure, conventions)
- review-report/socrates-e2e/agent-C.md (Socrates security test results: auth bypass, credential exposure)
- Shared type/contract files (auto-detected in Step 0)

FOR EACH changed file (HIGH risk first):
1. Read file FROM DISK (full file, not just diff)
2. Check OWASP Top 10: injection, XSS, broken auth, sensitive data exposure
3. Check credential handling: no plaintext tokens, proper encryption
4. Check input validation: user inputs sanitized at boundary
5. Check authorization: proper tenant/user isolation, role checks
6. Check dependency safety: no known vulnerable patterns
7. Check error handling: no stack traces leaked, no sensitive data in errors
8. Check secrets: no hardcoded API keys, tokens, passwords, connection strings

OUTPUT FORMAT (Conventional Comments):
- issue: [SECURITY] SQL injection risk in {file}:{line} — {explanation}
- suggestion: [SECURITY] Consider parameterized query instead
- praise: [SECURITY] Good use of input sanitization

Write to: review-report/critic-security.md
Minimum 2 findings per HIGH risk file. Zero findings = re-analyze.
Score: X/10 (10=perfect, 0=critical vulnerabilities)
```

### Critic-Architecture Prompt
```
You are CRITIC-ARCHITECTURE performing a universal code review.
Personas: Winston (Architect, pragmatist) + Amelia (Dev, speaks in file paths)

BEFORE REVIEWING — Read project context:
- review-report/phase-0-detection.md (project structure, conventions)
- review-report/socrates-e2e/agent-D.md (Socrates regression findings: shared components, theme consistency)
- Architecture docs if detected (architecture.md, ADR/, CLAUDE.md conventions)
- Project entry points and module boundaries

FOR EACH changed file:
1. Read file FROM DISK
2. Check module boundaries: public API surfaces respected, no internal imports
3. Check architecture decisions: changes align with documented decisions (if any)
4. Check DRY: no duplicated logic across modules/packages
5. Check patterns: consistent with existing codebase patterns
6. Check imports: correct casing (match git ls-files), no circular deps
7. Check error handling: consistent error format, proper propagation
8. Check naming: consistent with project conventions

CROSS-FILE INTEGRATION CHECKS (mandatory for every review):

  1. Theme Consistency:
     - Entry file dark/light class matches page background colors
     - Layout/Sidebar theme matches page content theme
     - All pages use consistent color tokens (no mixed themes)
     - CSS class naming consistent across changed files

  2. Import Integrity:
     - All imports in router file resolve to existing files
     - No circular dependencies introduced
     - No imports referencing deleted/renamed files
     - Index re-exports still valid after changes

  3. Global Settings:
     - Entry file global CSS/class changes don't conflict with page-level styles
     - Font CDN in index.html matches font-family in code
     - Config file (tailwind, vite, etc.) theme matches actual usage in components
     - Environment variable usage consistent

  4. Data Flow:
     - API hooks/services still connected after UI changes
     - State management imports intact
     - Event handlers preserved (not replaced by static markup)
     - Props drilling / context providers not broken
     - Route parameters still passed correctly

OUTPUT FORMAT (Conventional Comments):
- issue: [ARCH] Module boundary violation — {file} imports from internal module
- issue: [INTEGRATION] Router references non-existent page after rename
- suggestion: [ARCH] Extract to shared utility to avoid duplication
- thought: [ARCH] Consider caching for this repeated query

Write to: review-report/critic-architecture.md
Score: X/10
```

### Critic-UX-Perf Prompt
```
You are CRITIC-UX-PERF performing a universal code review.
Personas: Sally (UX advocate) + Bob (Performance realist)

BEFORE REVIEWING — Auto-detect design tokens:
  1. Read review-report/phase-0-detection.md (detected tokens, project info)
  2. Read tailwind.config.{ts,js} → extract theme.extend.colors
  3. Read design-tokens.md or design-tokens.json if exists
  4. Read CSS variables in globals.css/app.css/index.css
  5. Read theme.ts or theme.js if exists
  6. Use detected tokens as the "correct" design system
  7. If no design system detected, use consistency-based review
     (flag any colors/fonts that appear only once = likely inconsistency)

Read Phase 2 results:
- review-report/phase-2a-static.md (existing Playwright spec results)
- review-report/phase-2b-socrates.md (Socrates dynamic E2E results)
- review-report/socrates-e2e/agent-B.md (detailed visual findings for cross-reference)

FOR EACH changed UI file:
1. Read file FROM DISK
2. Check responsive: mobile + desktop breakpoints
3. Check accessibility: ARIA labels, keyboard nav, focus management
4. Check performance: lazy loading, memo where needed, no layout thrash
5. Check design tokens:
   - Flag any hardcoded colors that don't match detected tokens
   - Flag any font-family that doesn't match detected tokens
   - Flag any spacing/sizing values inconsistent with token scale
6. Check Playwright VRT diffs: are visual changes intentional?
7. Check component patterns: consistent with other components in project

OUTPUT FORMAT (Conventional Comments):
- issue: [UX] Missing aria-label on interactive element {file}:{line}
- issue: [DESIGN] Hardcoded color #3b82f6 doesn't match token palette in {file}:{line}
- suggestion: [PERF] This large component should be lazy-loaded
- nitpick: [UX] Icon size inconsistent with design system

Write to: review-report/critic-ux-perf.md
Score: X/10
```

### Cross-Talk Round
After all 3 critics finish:
- Each critic reads the other 2 reports FROM FILE
- Each sends 1 summary message to the other 2 (cross-pollinate findings)
- Update own report with any new insights

---

## Phase 5: Resolution & Verdict

### Score Calculation
```
Final Score = (Security × 3 + Architecture × 2 + UX-Perf × 1) / 6
```
Security weighted 3x because vulnerabilities are hardest to catch later.

### Verdict
| Score | Verdict | Action |
|-------|---------|--------|
| 8.0+ | APPROVE | Auto-merge eligible (if Ship/Show risk) |
| 6.0-7.9 | CHANGES REQUESTED | Fix issues, re-run Phase 4 (max 2 retries) |
| < 6.0 | BLOCK | Escalate to human review, do NOT merge |

### Output
Generate final report: `review-report/verdict.md`

```markdown
# Code Review Verdict: {APPROVE|CHANGES_REQUESTED|BLOCK}

## Score: {X.X}/10
- Security: {X}/10 (weight 3x)
- Architecture: {X}/10 (weight 2x)
- UX & Performance: {X}/10 (weight 1x)

## Risk Classification: {Ship|Show|Ask} (score: {N})

## Phase 1 (Static): {PASS|FAIL}
- Type check: {0} errors ({N} tsconfig files checked)
- Linting: {0} errors
- Tests: {N}/{N} pass
- Bundle: {+/-N}KB

## Phase 2 (Visual): {PASS|FAIL|SKIPPED}
- E2E: {N}/{N} pass
- VRT: {N} diffs ({N} expected, {N} unexpected)
- Interaction: {N} console errors found
- axe-core: {N} critical, {N} serious
- Lighthouse: perf {N}, a11y {N}, bp {N}
- Integration smoke: {PASS|FAIL}

## Critical Issues ({N}):
{list of issue: comments from all critics}

## Suggestions ({N}):
{list of suggestion: comments}

## Praise ({N}):
{list of praise: comments}
```

---

## Phase 6: Auto-Fix (fixer agents, ~5min)

**Trigger**: Phase 5 verdict = CHANGES_REQUESTED (score 6.0-7.9). Skip if APPROVE or BLOCK.

### Step 6.1: Parse & Prioritize Issues

Orchestrator reads `review-report/verdict.md` and extracts all `issue:` findings.

**Priority order** (fix in this sequence to avoid cascading breaks):
```
1. SHARED types/contracts  — type definitions that other files depend on
2. SECURITY issues         — security vulnerabilities first (OWASP)
3. ARCHITECTURE issues     — API format, pattern consistency, boundaries
4. DATA LAYER             — database, schema, migration issues
5. STATE/HOOKS            — state management, query hooks
6. COMPONENTS             — UI components, accessibility
7. PAGES                  — page-level fixes
8. INTEGRATION            — cross-file consistency issues (last, after individual fixes)
```

**Batching strategy**:
```
Same file issues        → group into one batch
Dependent files         → sequential (shared → server → client order)
Independent files       → parallel (worktree isolation)
Integration issues      → after all individual file fixes
```

### Step 6.2: Generate Fix Spec

For each issue, Orchestrator creates a structured fix instruction:

```markdown
## Fix #{N}: {issue title}
- **Source**: {critic-security|critic-architecture|critic-ux-perf}
- **Priority**: P{0-7}
- **File**: {file_path}:{line_number}
- **Issue**: {exact issue: comment from critic}
- **Fix**: {specific instruction — WHAT to change, not just "fix it"}
- **Verify**: {command to verify — e.g., tsc --noEmit, specific test}
- **Risk**: {LOW|MEDIUM|HIGH — chance this fix breaks something else}
```

Write to: `review-report/phase-6-fix-spec.md`

### Step 6.3: Execute Fixes

**Strategy selection based on fix count and risk**:

| Fixes | Risk | Strategy |
|-------|------|----------|
| 1-3 | Any | Sequential in main — simplest, no merge needed |
| 4-8 | LOW-MED | Batch by file — group same-file fixes, sequential across files |
| 9+ | Any | Parallel worktrees — independent files in parallel, dependent files sequential |
| Any | HIGH | One-at-a-time with type-check gate after each — safest for risky changes |

**Fixer Agent Prompt Template**:
```
You are FIXER-AGENT. Your ONLY job is to fix specific code issues.

RULES:
1. Read the FULL file before editing (not just the line)
2. Fix ONLY the specific issue — do NOT refactor surrounding code
3. Do NOT add comments explaining the fix
4. Do NOT change formatting/style of untouched lines
5. After each edit, run the verify command
6. If verify fails, try a different approach (max 2 attempts)
7. If 2 attempts fail, write "ESCALATE: {reason}" to fix-results and move on

FIX SPEC:
{fix spec from Step 6.2}

CONTEXT FILES (read these first for understanding):
{list of related files the fixer should read for context}

After fixing, append result to: review-report/phase-6-fix-results.md
Format:
- [FIXED] Fix #{N}: {description} — verified by {command}
- [FAILED] Fix #{N}: {description} — reason: {why}
- [ESCALATE] Fix #{N}: {description} — needs human: {reason}
```

**Execution flow**:
```
For each batch (sequential across batches, parallel within batch):
  ├── Launch fixer agent(s) with fix spec
  ├── Each fixer: Read file → Apply fix → Run verify command
  │   ├── Verify pass → [FIXED] → next fix
  │   ├── Verify fail → Attempt 2 → [FIXED] or [FAILED]
  │   └── Can't understand → [ESCALATE]
  ├── After batch complete: run type check (all detected tsconfig files)
  │   ├── Type check pass → proceed to next batch
  │   └── Type check fail → fixer agent fixes errors (max 2 attempts)
  └── If type check still fails after 2 attempts → rollback batch (git checkout)
```

### Step 6.4: Post-Fix Validation

After ALL fixes applied:
```
Orchestrator runs simultaneously:
├── Type check: tsc --noEmit for each detected tsconfig.json
├── Lint: re-run linter on fixed files
├── Tests: run affected tests
└── git diff --stat (confirm only intended files changed)
```

**Gate criteria**:
- Type check: 0 errors (all packages/configs)
- Lint: no new errors
- Tests: no NEW failures (pre-existing failures OK)
- No unintended file changes

**If gate fails**: rollback all fixes (`git stash`), mark as ESCALATE, skip to Phase 8.

**Output**: `review-report/phase-6-fix-results.md`

```markdown
# Phase 6: Auto-Fix Results

## Summary
- Total issues: {N}
- Fixed: {N}
- Failed: {N}
- Escalated: {N}

## Fix Log
- [FIXED] Fix #1: P0 — {description} — verified by {command}
- [FIXED] Fix #2: P1 — {description} — verified by {command}
- [FAILED] Fix #5: P4 — {description} — reason: {why}
- [ESCALATE] Fix #7: P6 — {description} — needs human: {reason}

## Post-Fix Validation
- Type check: 0 errors ({N} tsconfig files)
- Lint: 0 new errors
- Tests: {N} pass (no new failures)
- Files changed: {list}
```

---

## Phase 7: Re-Review (delta-only, ~2min)

**Trigger**: Phase 6 fixed at least 1 issue. Skip if all ESCALATED/FAILED.

### Scope: Impact-Based Delta

Only re-review files that were:
1. **Directly modified** in Phase 6
2. **Import** the modified files (1-level deep)
3. **Imported by** the modified files (reverse deps, 1-level deep)

```
Orchestrator:
  git diff --name-only HEAD~1..HEAD → modified files
  For each modified file: find importers via grep
  Union = re-review scope
```

### Re-Review Strategy

**NOT a full 3-critic re-run.** Instead, a single focused re-reviewer agent:

```
You are RE-REVIEWER. You are verifying that fixes from Phase 6 are correct
and did not introduce new problems.

FOR EACH fixed file:
1. Read the FULL file from disk
2. Read the original critic finding (from critic-*.md)
3. Verify the fix actually addresses the issue (not just suppresses it)
4. Check for NEW issues introduced by the fix:
   - Type safety: any `as any`, `@ts-ignore` added?
   - Logic: did the fix change behavior beyond the issue?
   - Imports: any new circular dependencies?
   - Style: does the fix match surrounding code patterns?

FOR EACH imported/importing file (impact zone):
1. Quick scan for breakage (type errors, missing props, changed APIs)

CROSS-FILE INTEGRATION RE-CHECK:
1. Theme consistency still intact after fixes
2. Import paths still valid
3. Router references still correct
4. Data flow not broken by fixes

OUTPUT FORMAT:
- [VERIFIED] Fix #{N}: correctly addresses {issue}, no side effects
- [REGRESSION] Fix #{N}: introduced new issue — {description}
- [INCOMPLETE] Fix #{N}: partially addresses {issue}, still needs {what}

Score: X/10 (10 = all fixes clean, 0 = fixes made things worse)

Write to: review-report/phase-7-re-review.md
```

### Regression Handling

If re-review finds regressions:
```
REGRESSION found → Orchestrator decides:
  ├── Minor (typo, missing import): auto-fix inline (1 attempt)
  ├── Medium (logic error): revert that specific fix + ESCALATE
  └── Major (multiple files broken): revert ALL Phase 6 + BLOCK
```

**Max re-review loops: 1.** If Phase 7 finds issues, fix them once. Do NOT re-review the re-review fixes. That way lies infinite loops.

**Output**: `review-report/phase-7-re-review.md`

---

## Phase 8: Final Verdict & Commit

### Score Recalculation

```
Original scores from Phase 4: Security={S}, Architecture={A}, UX-Perf={U}

Fix bonus per issue:
  [FIXED]     → +0.3 to relevant critic score (capped at 10)
  [VERIFIED]  → no additional change (already counted in FIXED)
  [REGRESSION]→ -0.5 from relevant critic score
  [FAILED]    → no change (original deduction stays)
  [ESCALATE]  → no change (original deduction stays)
  [INCOMPLETE]→ +0.1 to relevant critic score

Recalculated: Security={S'}, Architecture={A'}, UX-Perf={U'}
Final Score = (S' × 3 + A' × 2 + U' × 1) / 6
```

### Final Verdict

| Score | Verdict | Action |
|-------|---------|--------|
| 8.0+ | **APPROVE** | Auto-commit + push |
| 6.0-7.9 + all P0 fixed | **CONDITIONAL APPROVE** | Commit with TODO comments for remaining |
| 6.0-7.9 + P0 unfixed | **BLOCK** | P0 unfixed = cannot ship |
| < 6.0 | **BLOCK** | Escalate to human review |

### Commit Strategy

**On APPROVE or CONDITIONAL APPROVE**:
```
git add {all fixed files}
git commit -m "fix(review): resolve {N} issues from code review

Phase 6 auto-fix: {N} fixed, {N} failed, {N} escalated
Phase 7 re-review: {N} verified, {N} regressions
Final score: {X.X}/10 ({original} → {final})

Issues fixed:
- {P0}: {description}
- {P1}: {description}
...

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"

git push origin {branch}
```

**On BLOCK**:
- Do NOT commit
- Write `review-report/escalation.md` with:
  - What was tried
  - What failed and why
  - Recommended manual fix approach
  - Estimated effort (S/M/L)

### Output: Final Report

Generate: `review-report/final-verdict.md`

```markdown
# Final Code Review Report

## Pipeline: v3.0 (Universal)
## Date: {date}
## Project: {auto-detected project name}
## Commit Range: {base}..{head}

## Final Verdict: {APPROVE|CONDITIONAL_APPROVE|BLOCK}
## Final Score: {X.X}/10 (was {Y.Y} before auto-fix)

### Score Progression
| Critic | Phase 4 | Phase 6 Bonus | Phase 7 Adj | Final |
|--------|---------|---------------|-------------|-------|
| Security (x3) | {X} | +{N} | {adj} | {X'} |
| Architecture (x2) | {X} | +{N} | {adj} | {X'} |
| UX-Perf (x1) | {X} | +{N} | {adj} | {X'} |

### Phase Summary
| Phase | Status | Duration |
|-------|--------|----------|
| 0. Project Detection | {detected framework, tools, tokens} | {Ns} |
| 1. Static Gate | {PASS/FAIL} | {Ns} |
| 2. Visual Gate | {PASS/FAIL/SKIP} | {Ns} |
| 3. Risk Classification | {Ship/Show/Ask} (score:{N}, {N} files, modifiers:{+N}) | {Ns} |
| 4. 3-Critic Party | {scores} | {Ns} |
| 5. Initial Verdict | {verdict} ({score}) | — |
| 6. Auto-Fix | {N} fixed / {N} total | {Ns} |
| 7. Re-Review | {N} verified / {N} regressions | {Ns} |
| 8. Final Verdict | **{verdict}** (**{score}**) | — |

### Issues Resolved
{table of all issues with status: FIXED/FAILED/ESCALATED}

### Remaining Issues (if CONDITIONAL_APPROVE)
{list of unfixed non-P0 issues as TODO}

### Escalation Items (if any)
{items needing human attention with recommended approach}
```

---

## Orchestrator Flow (v3.0 Universal)

```
Step 0: Project Auto-Detection
  Detect: build tools, tsconfig files, package manager, monorepo structure,
          frontend framework, entry/layout/router files, design tokens,
          architecture docs, CI/CD config, test runner
  Output: review-report/phase-0-detection.md
  If detection fails on critical items: warn but continue with best-effort

Step 0.5: Setup
  mkdir -p review-report/screenshots
  Identify changed files: git diff --name-only {base}
  If no changes: "Nothing to review" → EXIT

Step 1: Phase 1 — Static Gate (parallel)
  Run type check + linter + tests + bundle check simultaneously
  Use auto-detected tools from Step 0
  Any FAIL → report + EXIT (don't waste time on deeper review)

Step 2: Phase 2 — Visual & E2E Gate (if UI changed)
  Phase 2A: Run existing Playwright specs (packages/e2e/ or tests/) → phase-2a-static.md
  Phase 2B: 소크라테스 Dynamic E2E — TeamCreate 4 agents (Playwright MCP --headless)
    Pre-flight: detect routes, auth pre-check, assign routes to agents
    Agent A (Functional): CRUD, forms, navigation — checklist items 3,5,10
    Agent B (Visual): screenshots, design tokens, responsive — items 1,2,11
    Agent C (Edge/Security): empty states, auth bypass, console errors — items 8,11,12
    Agent D (Regression): sidebar sweep, shared components, theme — items 1,2,3
    Aggregation: merge 4 reports, de-duplicate, score → phase-2b-socrates.md
  Critical E2E fail or Security bug → report + EXIT

Step 3: Phase 3 — Risk Classification
  Classify all changed files using universal patterns → compute risk score
  Apply bulk change modifiers (+20 for >10 files, +40 for >30 files)
  Apply always-HIGH overrides (entry, layout, router, config files)
  If score < 10 AND Phase 1+2 pass → AUTO-APPROVE (Ship)

Step 4: Phase 4 — AI 3-Critic Party (parallel)
  Launch 3 background agents (Security, Architecture, UX-Perf)
  Each reads phase-0-detection.md for project context
  Critic-Architecture runs CROSS-FILE INTEGRATION CHECKS
  Critic-UX-Perf uses auto-detected design tokens
  Wait for all 3 → cross-talk round → collect scores

Step 5: Phase 5 — Initial Verdict
  Calculate weighted score → determine verdict
  Generate review-report/verdict.md
  If APPROVE (>=8.0): → Step 9 (skip fix)
  If BLOCK (<6.0): → Step 9 (escalate, no auto-fix)
  If CHANGES_REQUESTED (6.0-7.9): → Step 6

Step 6: Phase 6 — Auto-Fix
  Parse verdict.md → extract issues → prioritize (P0 first)
  Batch by file → select strategy (sequential/parallel/worktree)
  Launch fixer agent(s) → each fix: read → edit → verify
  Post-fix validation: type check + lint + tests
  Generate review-report/phase-6-fix-results.md
  If 0 fixes succeeded: → Step 9 (BLOCK)

Step 7: Phase 7 — Re-Review (delta-only)
  Identify impact zone (modified + importers + imported-by)
  Launch re-reviewer agent on delta scope only
  Check: fixes correct? new issues? regressions? integration intact?
  If regressions: minor=inline fix, medium=revert+escalate, major=revert all+BLOCK
  Generate review-report/phase-7-re-review.md

Step 8: Phase 8 — Final Verdict
  Recalculate scores with fix bonuses
  Determine final verdict (APPROVE / CONDITIONAL_APPROVE / BLOCK)
  If APPROVE/CONDITIONAL: auto-commit + push
  If BLOCK: write escalation.md
  Generate review-report/final-verdict.md

Step 9: Cleanup
  If PR URL given: post final verdict as PR comment (gh pr comment)
  Remove stale worktrees if any
  Report to user: score progression, what was fixed, what remains
```

---

## Playwright Configuration

### E2E Test Structure
```
tests/
├── e2e/
│   ├── critical-flows/
│   │   ├── auth.spec.ts           # Login/logout/session
│   │   ├── navigation.spec.ts     # Core navigation flows
│   │   ├── crud.spec.ts           # Primary CRUD operations
│   │   └── interaction.spec.ts    # Button/form/dropdown interactions
│   ├── visual-regression/
│   │   ├── pages.spec.ts          # Screenshot each page
│   │   └── components.spec.ts     # Screenshot key components
│   └── accessibility/
│       └── a11y-audit.spec.ts     # axe-core per page
```

### Viewport Config
```typescript
const viewports = {
  desktop: { width: 1280, height: 800 },
  mobile: { width: 390, height: 844 },  // iPhone 14 Pro
}
```

### VRT Threshold
```typescript
expect(page).toHaveScreenshot({
  maxDiffPixelRatio: 0.05,  // 5% pixel difference threshold
  animations: 'disabled',
  mask: [page.locator('.dynamic-timestamp')],  // Mask dynamic content
})
```

---

## Defense & Timeouts

| Mechanism | Value | Action |
|-----------|-------|--------|
| Step 0 detection timeout | 30sec | Use best-effort defaults, warn |
| Phase 1 timeout | 2min | FAIL phase, report what passed |
| Phase 2A timeout | 3min | Skip remaining static specs, report partial |
| Phase 2B total timeout | 12min | Force-collect partial agent reports, aggregate |
| Phase 2B per-agent timeout | 8min | SendMessage warning → 30s → shutdown agent |
| Phase 2B page navigation | 30sec | Skip page, mark TIMEOUT, continue next |
| Phase 2B team creation fail | 10sec | Fallback: orchestrator runs Phase 2B solo |
| Phase 4 critic timeout | 5min each | Accept partial review |
| Cross-talk timeout | 2min | Skip cross-talk, use individual scores |
| Phase 6 fixer timeout | 3min per fix | Mark as FAILED, move to next |
| Phase 6 total timeout | 10min | Stop fixing, proceed with partial results |
| Phase 6 type-check gate | 2 attempts | Rollback batch on 2nd failure |
| Phase 7 re-review timeout | 3min | Accept partial re-review |
| Phase 7 regression loop | 1 max | NO re-reviewing the re-review. Ever. |
| Max fix rounds | 1 | Phase 6→7 runs once. No Phase 6→7→6→7 loop |
| Total pipeline timeout | 35min | Force final verdict with available data |

---

## Conventional Comments Reference

| Label | Meaning | Blocking? |
|-------|---------|-----------|
| `issue:` | Must fix before merge | YES |
| `suggestion:` | Would improve code, author decides | NO |
| `nitpick:` | Trivial preference, ignore freely | NO |
| `question:` | Need clarification | MAYBE |
| `thought:` | Sharing an idea | NO |
| `praise:` | Excellent work | NO |

---

## Core Rules

### Review Rules (Phase 1-5)
1. **Risk-first**: Classify files before reviewing. HIGH risk gets 3x attention.
2. **Conventional Comments**: ALL feedback uses label: format. No unlabeled comments.
3. **Evidence-based**: Every issue: cites file:line and explains WHY it's a problem.
4. **Security x 3**: Security score weighted 3x in final calculation.
5. **No style nitpicks**: Linter handles formatting. Critics focus on logic/security/architecture.
6. **Phase gates are mandatory**: Do NOT skip Phase 1. Phase 2 skippable only if no UI changes.
7. **Critics read FROM FILE**: Never from message memory. Always Read tool.
8. **Zero findings = re-analyze**: If a critic finds nothing, they must look harder.
9. **Cross-talk is mandatory**: Critics must read each other's reports before final score.
10. **Ship / Show / Ask**: Low-risk changes with passing gates can auto-approve.
11. **Bulk changes get extra scrutiny**: >10 files = integration risk. >30 files = maximum depth.
12. **Integration checks are mandatory**: Cross-file consistency checked on EVERY review.

### Fix Rules (Phase 6-8)
13. **Reviewer != Fixer**: The critic agents NEVER fix code. Separate fixer agents do the fixing. Same entity reviewing and fixing = blind spots.
14. **Fix only what's reported**: Fixer agents fix ONLY the issues from verdict.md. No "while I'm here" refactoring. No bonus improvements.
15. **Type check after every batch**: Each batch of fixes must pass type check before proceeding to the next batch. Cascading type errors = immediate stop.
16. **Max 2 attempts per fix**: If a fix fails twice, mark ESCALATE and move on. Do not brute-force.
17. **No infinite loops**: Phase 6→7 runs exactly ONCE. No 6→7→6→7 cycles. One fix round, one re-review, done.
18. **Rollback on failure**: If post-fix validation fails after 2 attempts, `git stash` ALL fixes and BLOCK. Broken fixes are worse than no fixes.
19. **Delta-only re-review**: Phase 7 reviews ONLY modified files + 1-level import graph. Not the whole codebase again.
20. **P0 must fix**: If P0 issues remain unfixed after Phase 6, verdict = BLOCK regardless of score. P0 = ship-blocker.
21. **Commit message traces pipeline**: Fix commits must reference the review (Phase 4 scores, which issues fixed).
22. **Human escalation is OK**: ESCALATE is a valid outcome. Not every issue can be auto-fixed. Flag it clearly and move on.
23. **Project-agnostic**: All checks use auto-detected paths and tools. NEVER hardcode project-specific paths or tokens.

ARGUMENTS: $ARGUMENTS
