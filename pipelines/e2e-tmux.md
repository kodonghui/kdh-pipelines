---
name: 'e2e-tmux'
description: 'Playwright E2E Full-Auto 24/7 — TMUX Version v2.1. Loop-based automated E2E testing + instant bug fix + deploy. Uses TeamCreate for parallel 4-agent testing with BMAD agent personas. Runs on VPS inside tmux + Claude CLI.'
---

# Playwright E2E Full-Auto 24/7 — TMUX Version v2.1 (Team Agents + BMAD Personas)

Loop-based automated E2E testing + instant bug fix + deploy. Uses **TeamCreate** for parallel 4-agent testing with **BMAD agent personas**. Runs on VPS inside tmux + Claude CLI.

## When to Use

- `/loop 30m /e2e-tmux` — 30-min auto cycles
- `/e2e-tmux` — single execution
- VPS tmux session with Claude CLI
- 3-4x faster than VS version (4 team agents in parallel)

## Prerequisites

- VPS tmux session with Claude CLI
- Playwright MCP with headless chromium in `.mcp.json`
- Live site: `{preset.e2e.base_url}` (from preset or project-context.yaml)
- Login credentials from preset:
  - Admin: `{preset.e2e.admin_login.username}` / `{preset.e2e.admin_login.password}`
  - User: `{preset.e2e.user_login.username}` / `{preset.e2e.user_login.password}`

---

## CRITICAL: Tool Loading (first step every cycle)

Team agents require deferred tools to be loaded first. **Run before each cycle:**

```
ToolSearch("select:TeamCreate,TeamDelete,TaskCreate,TaskList,TaskUpdate,TaskGet,SendMessage")
```

Without this, TeamCreate is unavailable. **Standalone Agent usage is prohibited. Always TeamCreate first.**

---

## CRITICAL: Browser Contention Prevention (TMUX-specific)

4 agents sharing headless Chromium concurrently causes lock conflicts. Staggered spawn required:

```
Staggered spawn order:
  quinn:   immediate (0s)
  winston: +30s
  bob:     +60s
  sally:   +90s  (screenshot-heavy, spawns last)
```

**Per-agent browser rules:**
- Lock failure → wait 15s, retry (max 3)
- `browser_close()` between page groups
- Future: if staggering insufficient, switch to multi-MCP instances

---

## ABSOLUTE: No Phase Skipping

**Every cycle MUST execute Phase 0->1->2->3->4->5->6->7->8 in order.**

### Phase 2 (Playwright 4-Agent test) is the reason this pipeline exists.

- "Already tested in previous cycle, skip" → **prohibited**
- "Bug list already exists, go straight to fix" → **prohibited**
- "Time is short, reduce Phase 2" → **reduce agent count, but never skip to 0**
- Each cycle is **independent**. Previous cycle results are **reference only, not substitutes.**

### Phase Gate: Pre-Phase-4 Verification

Before starting Phase 4 (Bug Fix), orchestrator MUST verify:

```
GATE CHECK (any failure → re-run Phase 2):
  1. cycle-{N}/quinn.md exists + 10+ lines
  2. cycle-{N}/sally.md exists + 10+ lines
  3. cycle-{N}/winston.md exists + 10+ lines
  4. cycle-{N}/bob.md exists + 10+ lines
  5. cycle-{N}/screenshots/ has 1+ files
```

**Exception: Playwright MCP down**
- If browser connection itself is impossible:
- Record reason + error in `cycle-{N}/BROWSER_DOWN.md`
- Switch to API-only fallback mode (curl tests only)
- Agent reports (quinn~bob.md) still required via API/source analysis

### Previous Cycle Reference Principle: Reference OK, Substitute NO

- bob reads prior `merged-bugs.md` for regression testing → OK
- Fixer addresses unfixed bugs from prior cycle → OK
- "Tested in previous cycle, skip Phase 2" → **prohibited**

---

## BMAD Agent Personas

Each agent MUST embody their BMAD persona. First action on spawn = read persona file.

| Agent Name | Role | BMAD Persona | Bug ID Prefix |
|------------|------|-------------|---------------|
| quinn | Functional CRUD | `_bmad/bmm/agents/qa.md` | BUG-Q |
| sally | Visual Design | `_bmad/bmm/agents/ux-designer.md` | BUG-S |
| winston | Edge Security | `_bmad/bmm/agents/architect.md` | BUG-W |
| bob | Regression Navigation | `_bmad/bmm/agents/sm.md` | BUG-B |

| Fixer Name | Role | BMAD Persona |
|------------|------|-------------|
| dev | Server bugs | `_bmad/bmm/agents/dev.md` |
| quinn | Frontend bugs | `_bmad/bmm/agents/qa.md` |
| sally | Design bugs | `_bmad/bmm/agents/ux-designer.md` |

---

## Cycle Structure (30min target)

### Phase 0: Pre-flight (30s)

```
1. curl GET {BASE_URL}/health → site alive?
   - DOWN → log "SITE DOWN" → skip cycle
2. POST {BASE_URL}/api/auth/admin/login → get JWT token
   - FAIL → log "LOGIN FAILED" → skip cycle
3. gh run list -L 1 → last deploy status
   - FAILED → log warning, continue
4. Read _qa-e2e/playwright-e2e/cycle-report.md → previous cycle results
   - Unresolved bugs from last cycle = priority targets
5. Determine cycle number: ls cycle-* dirs → N = max + 1
6. mkdir -p _qa-e2e/playwright-e2e/cycle-{N}/screenshots
7. Delete old cycles: cycle-(N-3) and older → rm -rf
   - Keep only most recent 3 cycles (storage management)
   - cycle-report.md is never deleted (cumulative log)
8. Test Data Setup:
   - POST /api/admin/companies with body {"name": "E2E-TEMP-{N}"}
   - Store response companyId as E2E_COMPANY_ID
   - All CRUD tests use E2E_COMPANY_ID exclusively
9. Read reference files:
   - Read _qa-e2e/playwright-e2e/known-behaviors.md → KB-{NNN} list
   - Read _qa-e2e/playwright-e2e/ESCALATED.md → ESC-{NNN} list
   - Read _qa-e2e/playwright-e2e/stability-state.md → clean_cycles count
   - Check git log --oneline -5 → any new commits since last cycle?
10. Login credentials check:
    - Admin: POST /api/auth/admin/login → store ADMIN_TOKEN
    - User: POST /api/auth/login → store USER_TOKEN
    - If user login fails → log warning, skip user pages (admin-only mode)
11. Theme detection (run once per cycle):
    - Read theme CSS files → extract [data-theme] blocks
    - Identify current active theme from layout data-theme attribute
    - Store in cycle context: ACTIVE_THEME, THEME_TOKENS
    - Write theme snapshot to cycle-{N}/theme-tokens.md
```

### Phase 1: API Smoke Test (1min)

```
Using curl with admin token + E2E_COMPANY_ID query param, hit ALL endpoints.

Pages and endpoints are loaded from project-context.yaml.

For each:
  - 200/201 → OK
  - 500 → CRITICAL bug (record error message)
  - 404 → HIGH bug (route not mounted)
  - 401/403 → Check if auth issue
```

---

### Phase 2: Parallel E2E Sweep — 4 Team Agents (5min)

**This Phase is the TMUX version's core. TeamCreate → TaskCreate → Agent(team_name) order required.**

#### Step 2.0: Team creation

```
TeamCreate(team_name: "e2e-cycle-{N}")
```

#### Step 2.1: Shared file creation

```
Write → _qa-e2e/playwright-e2e/cycle-{N}/blockers.md  (empty)
Write → _qa-e2e/playwright-e2e/cycle-{N}/bugs.md      (Phase 1 results included)

bugs.md standard format:
| Bug ID | Agent | Page | Severity | Description | Screenshot |
|--------|-------|------|----------|-------------|------------|

Bug ID format: BUG-{FIRST_LETTER}{NNN} (e.g., BUG-Q001, BUG-S003, BUG-W002, BUG-B005)
  - Q = quinn, S = sally, W = winston, B = bob
- Agents check existing entries before writing → skip duplicates
```

#### Step 2.2: Create 4 tasks

```
TaskCreate (4 parallel):
  TaskCreate(subject: "quinn: Functional CRUD", description: "...")
  TaskCreate(subject: "sally: Visual Design", description: "...")
  TaskCreate(subject: "winston: Edge Security", description: "...")
  TaskCreate(subject: "bob: Regression Navigation", description: "...")
```

#### Step 2.3: Spawn 4 team agents (staggered)

**Important: All Agent calls MUST include team_name. Omitting it creates a subagent that cannot communicate with the team.**
**Important: Staggered spawn to prevent browser contention (quinn→winston→bob→sally, 30s intervals).**

#### quinn — Functional (CRUD + Buttons)

```
FIRST ACTION: Read and embody: _bmad/bmm/agents/qa.md as your persona.

Assigned pages: from project-context.yaml (admin pages + user app pages)

Pre-check:
  - Read known-behaviors.md → skip KB items
  - Read ESCALATED.md → skip ESC items
  - Read cycle-{N}/bugs.md → don't re-report existing BUG IDs

Browser rules:
  - Lock failure → wait 15s, retry (max 3)
  - browser_close() between page groups

Tasks:
  - Login via Playwright MCP
  - Click EVERY button on assigned pages
  - Dead button (no response) = BUG
  - Try CRUD: create → read → update → delete on each page
  - ALL CRUD operations use E2E_COMPANY_ID only (not default data)
  - Form validation: empty submit, test data
  - DO NOT manually delete test data (Phase 8 cleans up entire E2E company)
  - Check blockers.md before each page (skip if blocked)
  - Record all bugs to cycle-{N}/bugs.md using BUG-Q{NNN} format
  - Write summary to cycle-{N}/quinn.md
  - TaskUpdate(status: "completed") when done
```

#### sally — Visual + Design

```
FIRST ACTION: Read and embody: _bmad/bmm/agents/ux-designer.md as your persona.

Assigned pages: ALL pages (screenshot sweep)

Pre-check:
  - Read known-behaviors.md, ESCALATED.md, bugs.md
  - Read cycle-{N}/theme-tokens.md → load ACTIVE_THEME + THEME_TOKENS

Tasks:
  - Login via Playwright MCP
  - Navigate each page → browser_take_screenshot
  - Check design tokens (dynamic — from THEME_TOKENS):
    - Verify backgrounds, sidebar colors match THEME_TOKENS
    - Grep for Tailwind color defaults NOT in THEME_TOKENS = BUG
    - Font: verify matches THEME_TOKENS.font-family
  - Check responsive: desktop + mobile (390x844) → screenshot both
  - Empty state: correct message displayed?
  - Record all bugs using BUG-S{NNN} format
  - Write summary to cycle-{N}/sally.md
  - TaskUpdate(status: "completed") when done
```

#### winston — Edge + Security

```
FIRST ACTION: Read and embody: _bmad/bmm/agents/architect.md as your persona.

Assigned pages: ALL pages + unauthenticated access

Tasks:
  - Visit each page WITHOUT token → should redirect to login
  - Login, then collect console errors on every page
  - Try XSS: <script>alert(1)</script> in text fields
  - Empty required fields → submit → should show validation
  - Rapid click: double-click delete button → should not double-delete
  - CRITICAL bugs → immediately write to blockers.md
  - Record all bugs using BUG-W{NNN} format
  - Write summary to cycle-{N}/winston.md
  - TaskUpdate(status: "completed") when done
```

#### bob — Regression + Navigation

```
FIRST ACTION: Read and embody: _bmad/bmm/agents/sm.md as your persona.

Assigned pages: sidebar full sweep (all apps) + previous cycle's fixed pages

Tasks:
  - Login via Playwright MCP
  - Click EVERY sidebar link → page loads correctly?
  - Previous cycle bugs → re-test each one (regression check)
  - Theme consistency: 5+ pages, verify colors match THEME_TOKENS
  - Shared components: sidebar, layout, toast, modal
  - Session persistence: navigate 10 pages → still logged in?
  - Record all bugs using BUG-B{NNN} format
  - Write summary to cycle-{N}/bob.md
  - TaskUpdate(status: "completed") when done
```

#### Step 2.4: Wait + Collect

```
Wait method: periodic TaskList check or automatic SendMessage reception
  - Per-agent timeout: 5min
  - On timeout → SendMessage(to: "{agent-name}", message: "TIMEOUT — wrap up now")
  - 30s additional wait → collect partial results
```

#### Step 2.5: Aggregate

```
Orchestrator directly:
  - Read cycle-{N}/bugs.md
  - Read cycle-{N}/blockers.md
  - Final dedup: same page + same symptom = merge
  - Severity classification: Critical / Major / Minor
  - Write → cycle-{N}/merged-bugs.md
```

#### Step 2.6: Cross-talk Round (1min)

After all 4 agents complete:

```
1. Orchestrator sends merged-bugs.md to ALL agents via SendMessage

2. Each agent reviews bugs found by others in their domain:
   - quinn reviews sally's visual bugs: "Is this a real UX issue?"
   - sally reviews winston's security findings: "Does the fix break the design?"
   - winston reviews bob's regression bugs: "Is this an architecture issue?"
   - bob reviews quinn's CRUD bugs: "Did this work in the previous cycle?"

3. Each agent appends "## Cross-talk Review" to cycle-{N}/{name}.md

4. Orchestrator collects updated reports:
   - If any bug disputed by 2+ agents → mark DISPUTED in merged-bugs.md
   - Disputed bugs are NOT auto-fixed (deferred to human review)
```

---

### Phase 3: Code Analysis + Cross-Check (30s)

```
Static analysis (no browser needed):

1. Route-API Mismatch Detection:
   - Parse router config → extract all routes
   - For each page file: grep api calls
   - Cross-reference with server routes
   - Mismatch = BUG

2. Cross-Check:
   - Read cycle-{N}/theme-tokens.md → load THEME_TOKENS
   - Grep for color classes NOT in THEME_TOKENS → should match active theme
   - Check for stale icon library references (if project uses specific icon set)
   - Check middleware presence in routes
   - Check migration safety patterns
```

---

### Phase 4: Parallel Bug Fix — 3 Fixer Agents (5min)

**Only if bugs found in Phase 2+3. No bugs → skip to Phase 6.**

#### Step 4.0: ESCALATED update

```
- Read ESCALATED.md
- Bugs with 2+ failed fix attempts → add to ESCALATED.md
- cycles_re_reported >= 3 → add WARNING to cycle report
```

#### Step 4.1: Fixer team creation

```
TeamCreate(team_name: "e2e-fixers-{N}")
TaskCreate (3 tasks): dev (server), quinn (frontend), sally (design)
```

#### Step 4.2: Spawn 3 fixer agents

```
Agent(name: "dev", team_name: "e2e-fixers-{N}", ...)
Agent(name: "quinn", team_name: "e2e-fixers-{N}", ...)
Agent(name: "sally", team_name: "e2e-fixers-{N}", ...)
```

**Fixer role assignment:**

| Fixer | Scope | Handles |
|-------|-------|---------|
| dev — Server | server source | 500 errors, 404 routes, auth issues |
| quinn — Frontend | frontend source (logic) | Console errors, dead buttons, empty pages |
| sally — Design | frontend source (CSS only) | Theme token violations, layout, icon replacements |

**Per-Fixer rules:**
- **Declare Change Type first** — before any fix:
  - Logic (server/frontend logic): max 3 files
  - Style (CSS/theme): max 10 files
  - Text/i18n: max 15 files
  - Mixed: max 5 files
- Read file → apply fix → tsc check
- tsc fail → revert → alternative approach (max 2 attempts)
- 2 failures → mark ESCALATED
- TaskUpdate(status: "completed") when done

#### Step 4.3: Merge + Verify

```
After all Fixers complete, orchestrator:
  1. Check each Fixer result
  2. Run tsc for ALL packages
  3. Type error → revert that Fixer's changes
```

#### Step 4.4: Fixer team cleanup

```
SendMessage shutdown_request to each fixer
TeamDelete (e2e-fixers-{N})
```

---

### Phase 5: Simplify (1min)

```
If any files were modified in Phase 4:
  Run /simplify logic on changed files only:
  - Code reuse: existing utils that could replace new code?
  - Code quality: redundant state, copy-paste?
  - Efficiency: unnecessary work?
  Fix any issues found.
```

### Phase 6: Deploy + Post-Deploy Verification (3min)

```
If any files were modified:
  1. git add {specific changed files only}
  2. git commit -m "fix(e2e-cycle-{N}): {bug summary}

     Bugs fixed: {count}
     - P{X}: {description}
     ..."
  3. git push origin main
  4. Wait for deploy:
     - Poll: gh run list -L 1 (20s intervals, max 6 checks = 2min)
  5. Post-deploy verification:
     - Run smoke test if available
     - All endpoints 200 OK → PASS
  6. Record deploy result

If no files modified:
  Skip deploy.
```

### Phase 7: Working State Update + Context Snapshot (30s)

```
Update working state:
  - Last cycle: #{N} at {time}
  - Bugs fixed/remaining/total

Save context snapshot to _qa-e2e/playwright-e2e/context-snapshots/cycle-{N}.md:
  - Cycle number + timestamp
  - Bugs found / fixed / remaining (with BUG IDs)
  - Page health scores
  - ESCALATED changes
  - Files modified
  - Deploy result
  - Theme used this cycle
```

### Phase 8: Report + Cleanup (30s)

```
0. Test Data Cleanup:
   - DELETE /api/admin/companies/{E2E_COMPANY_ID}
   - Verify 200 response (cascade delete)
   - If fails → log warning, continue

1. Calculate Page Health Scores (see below)

2. Append to _qa-e2e/playwright-e2e/cycle-report.md:

## Cycle #{N} — {timestamp}
- API: {passed}/{total} OK
- Pages loaded: {N}/{total}
- Console errors: {N}
- Dead buttons: {N}
- Bugs found: {N} (P0:{n} P1:{n} P2:{n} P3:{n})
- Bugs fixed: {N}
- Bugs remaining: {N}
- Bugs escalated: {N}
- Bugs disputed (cross-talk): {N}
- Files modified: {list}
- Deploy: {success|failed|skipped|timeout}
- Smoke test: {pass|fail|skipped}
- Test company cleanup: {success|failed}
- Theme: {ACTIVE_THEME}
- Page health: {pages_degrading} degrading, {pages_escalated} auto-escalated

3. Update stability-state.md:
   - 0 bugs → increment clean_cycles
   - bugs found → reset clean_cycles to 0

4. E2E team cleanup:
   SendMessage shutdown_request to each agent
   TeamDelete (e2e-cycle-{N})
```

---

## Page Health Score System

Each page gets a health score (0-10) calculated per cycle:

```
Base score: 10

Deductions:
  - Console error: -1 per error (max -4)
  - Dead button: -2 per button (max -6)
  - 500 API response: -10 (instant 0)
  - Missing content (empty page): -5
  - Design token violation: -1 per violation (max -3)
  - Failed form submission: -2

Minimum score: 0
```

Tracked in: `_qa-e2e/playwright-e2e/page-health.md`

Trend indicators: `^` improving, `->` stable, `v` degrading, `-` no data.

**Auto-escalation rule:** Pages with score < 5 for 3 consecutive cycles are auto-added to `ESCALATED.md` with reason "PAGE_HEALTH_CRITICAL".

---

## Auto-Stabilization Protocol

After Phase 8, check stabilization conditions:

```
Read stability-state.md:
  - clean_cycles: consecutive 0-bug cycles
  - last_bug_cycle: last cycle with bugs
  - mode: "ACTIVE" | "STABLE_WATCH"

ENTER STABLE_WATCH when ALL true:
  - clean_cycles >= 3
  - No new git commits since last cycle
  - No manual request for full cycle

STABLE_WATCH mode:
  - bob only (regression + navigation sweep)
  - 2h interval instead of 30m
  - No fixer agents spawned
  - Reduced scope: sidebar sweep + previous bug re-check only

EXIT STABLE_WATCH (return to ACTIVE) when ANY true:
  - bob finds a new bug
  - New git commit detected
  - Manual request from user
```

---

## Safety Limits

- **Smart file limits per fixer (by change type):**
  - Logic: max 3 files
  - Style: max 10 files
  - Text/i18n: max 15 files
  - Mixed: max 5 files
  - Fixer MUST declare change type before starting
- No deleting files
- No changing package.json
- No modifying migrations or auth middleware
- tsc must pass before commit
- If deploy fails → next cycle detects and warns

## Timeouts

| Phase | Timeout | On timeout |
|-------|---------|------------|
| Pre-flight | 30s | Skip cycle |
| API smoke test | 2min | Report partial, continue |
| Per agent (Phase 2) | 5min | SendMessage "TIMEOUT" → 30s → collect partial |
| Cross-talk (Step 2.6) | 1min | Collect available reviews, continue |
| Per fixer (Phase 4) | 3min | Skip bug, mark ESCALATED |
| Deploy wait (Phase 6) | 2min | Record timeout, skip smoke test |
| Total cycle | 25min | Force report with partial results |

## Output

```
_qa-e2e/playwright-e2e/
  cycle-report.md          ← cumulative report (appended each cycle)
  ESCALATED.md             ← persistent list of bugs that failed 2+ fix attempts
  known-behaviors.md       ← KB-{NNN} items: known non-bugs (not to be re-reported)
  stability-state.md       ← clean_cycles, last_bug_cycle, mode (ACTIVE/STABLE_WATCH)
  page-health.md           ← page health scores tracked across cycles
  context-snapshots/
    cycle-{N}.md           ← full context snapshot per cycle
  cycle-{N}/
    quinn.md               ← Functional CRUD results (BMAD: qa)
    sally.md               ← Visual design results (BMAD: ux-designer)
    winston.md             ← Edge security results (BMAD: architect)
    bob.md                 ← Regression navigation results (BMAD: sm)
    theme-tokens.md        ← Active theme + token values for this cycle
    blockers.md            ← Site-wide blockers (shared between agents)
    bugs.md                ← Shared bug list with BUG-{Q|S|W|B}{NNN} IDs
    merged-bugs.md         ← Aggregated + de-duplicated bugs
    fix-results.md         ← Fixer agent results
    screenshots/
      {page}-{bug-id}.png  ← Bug evidence
```

## Fallback

If TeamCreate fails (connection issue, resource limit):
  → Auto-fallback to VS version (sequential single-agent mode)
  → Log: "TeamCreate failed, running in single-agent mode"
  → Continue cycle without interruption

## Rules

1. **TeamCreate mandatory** — Standalone Agent usage prohibited. Always TeamCreate → Agent(team_name).
2. **ToolSearch first** — Load deferred tools (TeamCreate, TaskCreate, SendMessage) before each cycle.
3. **team_name parameter** — Omitting team_name on Agent spawn creates a subagent. Team communication impossible.
4. **Never stop on single failure** — record and continue.
5. **Screenshot on bugs** — visual evidence is mandatory.
6. **Console errors are bugs** — no exceptions.
7. **Dead buttons are bugs** — clickable element that does nothing = BUG.
8. **Test data isolation** — all CRUD in E2E_COMPANY_ID only. Phase 8 deletes the company.
9. **Type-check before commit** — tsc must pass or no deploy.
10. **Smart file limits** — Fixer declares change type, limit applied per type.
11. **Don't touch auth/middleware** — too risky for auto-fix.
12. **Theme compliance** — grep for colors not in THEME_TOKENS = immediate fix.
13. **Report every cycle** — even if 0 bugs found.
14. **TeamDelete after each phase** — Fixer team after Phase 4, E2E team in Phase 8.
15. **No Phase skipping** — Phase 0→8 in order. "Previous cycle results as substitute" prohibited.
16. **Phase gate** — Before Phase 4: verify quinn~bob.md (4 files) + screenshots (1+). Fail → re-run Phase 2.
17. **Reference OK, substitute NO** — Previous cycle results for reference only. Cannot replace current Playwright tests.
18. **Auto-delete old cycles** — Phase 0 keeps only most recent 3 cycles. cycle-report.md preserved.
19. **Known Behaviors check** — All agents check known-behaviors.md KB items. Do not report as bugs.
20. **ESCALATED tracking** — 2 fix failures → ESCALATED.md. cycles_re_reported >= 3 → WARNING.
21. **Auto-Stabilization** — 3 consecutive clean cycles + no new commits → STABLE_WATCH mode. Exit on new bug/commit/manual request.
22. **BMAD Persona mandatory** — All agents read and embody persona file on spawn. No operation without persona.
23. **Cross-talk mandatory** — Phase 2 completion → Step 2.6 cross-talk round. Inter-agent bug cross-verification.
24. **Page Health tracking** — Update page-health.md every cycle. score < 5 for 3 cycles → auto-escalate.
