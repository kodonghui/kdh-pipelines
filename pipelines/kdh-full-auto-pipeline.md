---
name: 'kdh-full-auto-pipeline'
description: 'Universal Full Pipeline v9.4 — EARS + Contract Stage + Wiring Stories + Integration Gate. Auto-discovers workflows, real BMAD agent personas, party mode per step, user gates. Usage: /kdh-full-auto-pipeline [planning|story-ID|parallel ID1 ID2...|swarm epic-N]'
---

# Universal Full Pipeline v9.4

## Mode Selection

- `planning` or no args: Planning pipeline — BMAD full-cycle, 9 stages, real agent party mode
- Story ID (e.g. `3-1`): Single story dev — 6 phases with party mode per phase
- `parallel story-ID1 story-ID2 ...`: Parallel story dev — Git Worktrees, max 3 simultaneous
- `swarm epic-N`: Swarm auto-epic — all stories as tasks, 3 self-organizing agent teams

---

## Step 0 (ALL Modes): Project Auto-Scan

Run this BEFORE any other step. Results are cached in `project-context.yaml` at project root.

```
1. Read package.json → detect:
   - Package manager: check for bun.lockb (bun), pnpm-lock.yaml (pnpm), yarn.lock (yarn), else npm
   - Project name, version, scripts (dev, build, test, lint)

2. Find ALL tsconfig.json files:
   - glob("**/tsconfig.json", ignore node_modules)
   - If monorepo: find the root tsconfig AND each package tsconfig
   - Build tsc command list: ["npx tsc --noEmit -p {path}" for each tsconfig]
   - If zero found: tsc_enabled = false

3. Detect monorepo structure:
   - turbo.json → Turborepo
   - pnpm-workspace.yaml → pnpm workspace
   - lerna.json → Lerna
   - workspaces in package.json → npm/yarn workspaces
   - None found → single-package project

4. Find test runner config:
   - vitest.config.* → "npx vitest run"
   - jest.config.* or jest in package.json → "npx jest"
   - "bun:test" in files → "bun test"
   - playwright.config.* → playwright_enabled = true
   - cypress.config.* → cypress_enabled = true
   - None found → test_enabled = false

5. Detect BMAD:
   - Check if _bmad/ directory exists → bmad_enabled = true/false
   - If true: locate workflow dirs, agent files, templates
   - If false: use simplified workflow (see "Non-BMAD Workflow" section)

6b. Detect Hono RPC capability (v9.4):
   - Check for 'hono' in package.json dependencies (any package in monorepo)
   - If Hono found AND monorepo with shared types package: hono_rpc_eligible = true
   - Save to project-context.yaml:
     hono:
       detected: true/false
       rpc_eligible: true/false
       server_package: "{path}" | null

6. Detect UI framework:
   - Check for: React (react-dom), Vue, Svelte, Angular, Next.js, Nuxt, Remix, Astro
   - Find dev server command from package.json scripts
   - Check for Playwright config → vrt_enabled = true/false
   - Check for Tailwind/CSS framework config

7. Detect architecture docs (any of these):
   - _bmad-output/planning-artifacts/architecture.md
   - docs/architecture.md, docs/ARCHITECTURE.md
   - ARCHITECTURE.md at root
   - Any file matching **/architecture*.md
   - Store path or null

8. Detect existing feature spec (any of these):
   - _bmad-output/planning-artifacts/*feature-spec*
   - docs/*feature-spec*, docs/*features*
   - Any file matching **/*feature-spec*.md
   - Store path or null

9. Detect existing PRD (any of these):
   - _bmad-output/planning-artifacts/prd.md
   - docs/prd.md, docs/PRD.md
   - Any file matching **/prd*.md
   - Store path or null

10. Save results to project-context.yaml
```

If `project-context.yaml` already exists and is < 1 hour old, skip re-scan (use cached).

---

## BMAD Auto-Discovery Protocol

For each planning stage, steps are discovered dynamically — NEVER hardcoded.

```
1. Read the workflow directory path for the stage
2. glob("{dir}/steps/*.md") OR glob("{dir}/steps-c/*.md") as configured per stage
3. Filter out files matching *-continue* or *-01b-*
4. Sort by filename (natural sort: step-01, step-02, step-02b, step-02c, step-03...)
5. For each discovered step file: execute party mode
```

If a steps/ directory is empty or missing → SKIP stage with warning, never fail.

---

## BMAD Agent Roster

ALL agents are spawned with their **real BMAD names** and **full persona files loaded**.

| Spawn Name | Persona File | Expertise |
|-----------|-------------|-----------|
| `winston` | `_bmad/bmm/agents/architect.md` | Distributed systems, cloud infra, API design, scalable patterns |
| `quinn` | `_bmad/bmm/agents/qa.md` | Test automation, API testing, E2E, coverage analysis |
| `john` | `_bmad/bmm/agents/pm.md` | PRD, requirements discovery, stakeholder alignment |
| `sally` | `_bmad/bmm/agents/ux-designer.md` | User research, interaction design, UI patterns |
| `bob` | `_bmad/bmm/agents/sm.md` | Scrum master, sprint planning, delivery risk |
| `dev` | `_bmad/bmm/agents/dev.md` | Implementation, code quality, debugging |
| `analyst` | `_bmad/bmm/agents/analyst.md` | Analysis, research synthesis |
| `tech-writer` | `_bmad/bmm/agents/tech-writer/tech-writer.md` | Documentation, technical writing |

### Agent Spawn Template

Every agent MUST be spawned with this structure:

```
You are {NAME} in team "{team_name}". Role: {Writer|Critic}.

## Your Persona
Read and fully embody: _bmad/bmm/agents/{file}.md
Load the persona file with the Read tool BEFORE doing anything else.

## Your Expertise
{expertise from roster above}

## Scoring Rubric
Read: _bmad-output/planning-artifacts/critic-rubric.md
6 dimensions, 7/10 pass threshold, any dimension <3 = auto-fail.

## References
- project-context.yaml
- All context-snapshots from prior stages
- {stage-specific references}
```

PROHIBITION: Never spawn agents as `critic-a`, `critic-b`, `critic-c` or any generic name.

---

## Model Strategy

**ALL agents = opus. No exceptions.** Agent tool fixes model at spawn time, so per-step mixing is not possible. All agents in all stages are spawned with `model: opus`.

### Step Grades (retry limits only)

| Grade | Max Retries | When |
|-------|-------------|------|
| **A** (critical) | 3 | Core decisions, functional/nonfunctional reqs, architecture patterns |
| **B** (important) | 2 | Most content steps |
| **C** (setup) | 1 | init, complete, routine validation |

**Grade C = Writer Solo.** Grade C steps (init, complete) skip party mode entirely. Writer executes alone, no critic review needed. This saves agent resources on routine steps.

---

## Party Mode Protocol (per step)

**Applies to Grade A and B steps only.** Grade C steps use Writer Solo (see above).

Supports variable team sizes (3-5 critics).

```
1. Writer: Read step file with Read tool → write section → save to output doc
2. Writer: SendMessage [Review Request] to ALL critics BY REAL NAME
   Include: file path, line range, step file path
3. Critics (parallel): Read FROM FILE → review → write to party-logs/{stage}-{step}-{name}.md
4. Critics: Cross-talk with relevant peers (1 round):
   - 3 critics: 3 pairs (all)
   - 4 critics: 4 relevant pairs (adjacent expertise, skip 2 least-related)
   - 5 critics: 5 relevant pairs (adjacent expertise, skip 5 least-related)
   Cross-talk MUST happen. Each critic SendMessage to assigned peer(s) with top disagreement/concern.
   Peer responds. Both update their party-logs with cross-talk section before scoring.
5. Critics: SendMessage [Feedback] to Writer BY NAME — "{N} issues. Priority: [top 3]"
6. Writer: Read ALL critic logs FROM FILE → apply fixes → write party-logs/{stage}-{step}-fixes.md
7. Writer: SendMessage [Fixes Applied] to ALL critics BY NAME
8. Critics (parallel): Re-read FROM FILE → verify → SendMessage [Verified] score X/10
9. Calculate average + enforce thresholds:
   - Grade A: avg >= 8.0 required (was 7.0)
   - Grade B: avg >= 7.5 required (was 7.0)
   - Avg >= threshold: proceed to Minimum Cycle Check (step 11)
   - Avg < threshold AND retry < grade_max: Writer rewrites from step 1
   - Retry >= grade_max: ESCALATE to Orchestrator
10. Score Variance Check (v9.1):
   - Calculate standard deviation of all critic scores
   - If stdev < 0.5 (was 0.3): Orchestrator flags "Suspiciously High Agreement"
   - At least 1 critic MUST independently re-score without seeing others' scores
11. Minimum Cycle Check (v9.2 — MANDATORY):
   - Grade A: MINIMUM 2 full cycles required regardless of scores
     - Cycle 1: steps 1-8 above (normal review)
     - Cycle 2: Devil's Advocate mode — 1 designated critic MUST find ≥ 3 issues
     - If Devil's Advocate finds 0 issues: suspicious, Orchestrator reviews directly
   - Grade B: MINIMUM 1 full cycle + cross-talk verified
   - Only after minimum cycles met AND avg >= threshold → PASS
12. Orchestrator Step Completion Checklist (v9.2 — BLOCKING):
   Before accepting [Step Complete], Orchestrator MUST verify ALL:
   - [ ] party-logs/{stage}-{step}-{critic1}.md EXISTS (file, not message)
   - [ ] party-logs/{stage}-{step}-{critic2}.md EXISTS
   - [ ] party-logs/{stage}-{step}-{critic3}.md EXISTS
   - [ ] party-logs/{stage}-{step}-{critic4}.md EXISTS (if 4 critics)
   - [ ] party-logs/{stage}-{step}-fixes.md EXISTS
   - [ ] Each critic log contains "## Cross-talk" section
   - [ ] Score stdev >= 0.5
   - [ ] Grade A: 2nd cycle completed with Devil's Advocate
   - [ ] Context snapshot saved
   ANY item unchecked → REJECT [Step Complete], do NOT proceed
```

Party-log naming: `party-logs/{stage}-{step}-{agent-name}.md`

### Party-log Verification (v9.1)

Orchestrator validates ALL critic logs + fixes.md exist before accepting [Step Complete]:
```
1. For each critic in team: check file exists at party-logs/{stage}-{step}-{critic-name}.md
2. Check fixes log exists: party-logs/{stage}-{step}-fixes.md
3. If ANY file missing → REJECT [Step Complete], request missing critic to write their log
4. Only accept [Step Complete] when ALL files verified
```

---

## User Gate Protocol

16 steps across the pipeline pause for user (사장님) input on non-technical decisions.

### Gate Flow
```
1. Writer drafts options (A/B/C format with pros/cons)
2. Writer sends "[GATE] {step_name}" to team-lead (Orchestrator)
3. Orchestrator presents to user:
   - Summary of what was written
   - Options with pros/cons
   - Clear question: "어떻게 할까요? A/B/C 또는 수정사항?"
4. User responds
5. Orchestrator sends user decision to Writer
6. Writer incorporates decision into document
7. Normal party mode continues (Critics review the gate-resolved content)
```

### Gate Inventory

| # | Stage | Step | Question for User |
|---|-------|------|-------------------|
| 1 | 0 Brief | vision | v2 핵심 비전 방향 맞는지? |
| 2 | 0 Brief | users | 타겟 사용자, CEO vs Admin 우선순위? |
| 3 | 0 Brief | metrics | 성공 기준 뭘로 잡을지? |
| 4 | 0 Brief | scope | 4개 기능 각각 넣을지/뺄지/수정 |
| 5 | 2 PRD | discovery | v1 기능 중 v2에서 바꿀 것/유지할 것 |
| 6 | 2 PRD | vision | PRD 비전 문구 확인 |
| 7 | 2 PRD | success | 성공 기준 수치 현실적인지 |
| 8 | 2 PRD | journeys | 유저 저니가 상상하는 흐름과 일치? |
| 9 | 2 PRD | innovation | 혁신 vs 기본 기능 구분 |
| 10 | 2 PRD | scoping | Phase 나누기, 우선순위 결정 |
| 11 | 2 PRD | functional | FR 하나하나 넣을지/뺄지 |
| 12 | 2 PRD | nonfunctional | NFR 수치 확인 (FPS, 응답시간, 메모리) |
| 13 | 4 Arch | decisions | 기술 선택 최종 확인 |
| 14 | 5 UX | design-system | 디자인 시스템/테마 방향 |
| 15 | 5 UX | design-directions | 디자인 시안 선택 |
| 16 | 6 Epics | design-epics | Epic 스코프 확정 |

AUTO steps (non-gate) proceed without user input. Orchestrator only notifies user at stage boundaries.

---

## Anti-Patterns (v9.1 — production failures)

1. **Writer calls Skill tool** — Skill auto-completes all steps internally, bypasses critic review. FIX: Writer MUST NEVER use Skill tool. Read step files with Read tool, write manually.
2. **Writer batches steps** — Writes steps 2-6 then sends one review. FIX: Write ONE step → party mode → THEN next step.
3. **Agent spawned with generic name** — `critic-a` or `worker-1` instead of BMAD name. FIX: ALWAYS use real names from BMAD Agent Roster.
4. **Critic skips persona file** — Reviews without reading `_bmad/bmm/agents/*.md`. FIX: First action MUST be Read persona file.
5. **GATE step auto-proceeds** — Writer skips user input on GATE step. FIX: GATE steps MUST send [GATE] to Orchestrator and WAIT.
6. **Shutdown-then-cancel race** — shutdown_request is irreversible. FIX: NEVER send unless 100% committed.
7. **Writer duplicates prior step content** (v9.1) — Writer copies risk/requirement tables that already exist in earlier steps. FIX: Before writing, Writer MUST Read prior steps' sections on the same topic. If content exists, use `§{section_name} 참조` cross-reference instead of duplicating. (Incident: Step 06/08 risk tables had 6 duplicate entries.)
8. **Score convergence inflation** (v9.1) — All critics give identical scores after fixes (e.g., unanimous 9.00). FIX: Orchestrator checks score standard deviation; if stdev < 0.3, triggers independent re-scoring warning. (Incident: Step 08 all 4 critics scored exactly 9.00.)
9. **Missing party-log files** (v9.1) — Critic reviews sent via message only, no file written. FIX: Orchestrator verifies all `party-logs/{stage}-{step}-{critic-name}.md` files exist before accepting [Step Complete]. Missing file = REJECT. (Incident: Step 02-05 had only winston's logs.)
10. **Single-cycle rubber stamp** (v9.2) — All critics score 8.5+ on first review, no retry triggered, issues slip through. FIX: Grade A requires MINIMUM 2 cycles regardless of scores. Cycle 2 uses Devil's Advocate mode (1 critic MUST find ≥ 3 issues). (Incident: Stage 2 Step 06-10 all passed with 9.0+ on first cycle, zero retries across 5 steps.)
11. **Cross-talk skipped** (v9.2) — Critics review independently but never discuss with each other. FIX: Cross-talk is MANDATORY. Each critic log MUST contain "## Cross-talk" section documenting peer discussion. Orchestrator rejects logs without this section. (Incident: Stage 0-3 had zero cross-talk across all steps.)
12. **Orchestrator skips own checklist** (v9.2) — Rules exist but Orchestrator doesn't follow them. FIX: Step Completion Checklist (v9.2) is BLOCKING — Orchestrator must verify every checkbox before accepting. Pre-commit hook validates party-log file completeness. (Incident: Stage 2 Step 02-05 accepted with only 1/4 critic logs.)
13. **Inline API type duplication** (v9.4) — Frontend defines response types locally instead of importing from shared contracts. Causes silent type drift when backend changes shape. FIX: Phase F winston checks contract compliance. Inline types matching contract shapes = auto-FAIL. (Incident: 29 integration bugs from 167 stories, all type mismatches.)
14. **Missing wiring** (v9.4) — Story creates store/endpoint but never connects to consumer. Feature works in unit tests but unreachable at runtime. FIX: Wiring stories auto-generated in Stage 6. Integration verification in Phase D TEA. (Incident: ws-store created but connect() never called from Layout.)

Additional safeguards:
- TeamDelete fails after tmux kill → `rm -rf ~/.claude/teams/{name} ~/.claude/tasks/{name}`, retry
- Shutdown stall → 30s timeout → `tmux kill-pane` → force cleanup
- Context compaction → PostCompact hook auto-saves working-state.md + git commit
- Stale resources → auto-clean stale worktrees + cleanup.sh handles tmux/sessions

---

## Mode A: Planning Pipeline

### Orchestrator Flow

```
Step 0: Project Auto-Scan → load project-context.yaml
Step 1: For each Stage (0-6, 6.5, 7-8):
  a. TeamCreate("{project}-{stage-name}")
  b. Create party-logs/ and context-snapshots/ dirs
  c. Spawn Writer + Critics per Stage Team Config (see below)
     - Writer: embed stage context + refs + FIRST step instruction
     - Critics: embed persona + "WAIT for Writer's [Review Request]"
  d. Step Loop — for each discovered step:
     - If GATE step: Writer drafts → [GATE] → Orchestrator asks user → forward decision
     - Party mode runs (Writer ↔ Critics)
     - On [Step Complete]: validate party-log files exist → ACCEPT or REJECT
     - Timeout: 20min + 2min grace. 3 stalls → SKIP.
  e. git commit: "docs(planning): {stage} complete — {N} steps, party mode"
  f. Shutdown ALL → TeamDelete → next stage with fresh team + all snapshots
Step 2: Final report with all stage summaries
```

### Planning Stages — BMAD Mode (bmad_enabled = true)

#### Stage 0: Product Brief

```
Dir: _bmad/bmm/workflows/1-analysis/create-product-brief/steps/
Output: _bmad-output/planning-artifacts/product-brief-{project}-{date}.md
Team (5): analyst(Writer), john, sally, bob, winston
GATES: vision, users, metrics, scope
```

EARS Requirement Format (v9.4 — MANDATORY for all functional requirements):
All requirements MUST use EARS syntax. Gherkin is reserved for test acceptance criteria only.
EARS 5 Patterns:
  1. Ubiquitous:        THE SYSTEM SHALL [behavior]
  2. Event-driven:      WHEN [trigger], THE SYSTEM SHALL [response]
  3. State-driven:      WHILE [condition], THE SYSTEM SHALL [response]
  4. Unwanted behavior: IF [bad condition], THEN THE SYSTEM SHALL [response]
  5. Optional feature:  WHERE [feature enabled], THE SYSTEM SHALL [response]
Examples:
  - THE SYSTEM SHALL display agent status in real-time on the Hub.
  - WHEN user submits handoff request, THE SYSTEM SHALL validate target agent is active.
  - IF API response exceeds 5 seconds, THEN THE SYSTEM SHALL display timeout warning.
Critic EARS Compliance: requirements using "should/needs to/must" (non-EARS keywords) → -1 per violation, 3+ → auto-fail.

Input references (root material for brief):
- `_bmad-output/planning-artifacts/v2-openclaw-planning-brief.md` (draft, reference only)
- `_bmad-output/planning-artifacts/v2-corthex-v2-audit.md` (accurate numbers)
- `_bmad-output/planning-artifacts/critic-rubric.md` (scoring)
- `_bmad-output/planning-artifacts/v2-vps-prompt.md` (execution context)
- Existing PRD, architecture, v1-feature-spec (from project-context.yaml)

Step grades:
| Step | Grade | GATE |
|------|-------|------|
| init | C | AUTO |
| vision | A | GATE |
| users | B | GATE |
| metrics | B | GATE |
| scope | A | GATE |
| complete | C | AUTO |

#### Stage 1: Technical Research

```
Dir: _bmad/bmm/workflows/1-analysis/research/technical-steps/
Output: _bmad-output/planning-artifacts/technical-research-{date}.md
Team (4): dev(Writer), winston, quinn, john
GATES: none
```

Step grades:
| Step | Grade |
|------|-------|
| init | C |
| technical-overview | B |
| integration-patterns | B |
| architectural-patterns | A |
| implementation-research | B |
| research-synthesis | A |

#### Stage 2: PRD Create

```
Dir: _bmad/bmm/workflows/2-plan-workflows/create-prd/steps-c/
Output: _bmad-output/planning-artifacts/prd.md
Team (5): john(Writer), winston, quinn, sally, bob
Skip: step-01b-continue.md
GATES: discovery, vision, success, journeys, innovation, scoping, functional, nonfunctional
```

EARS Format (v9.4): ALL FR/NFR in EARS syntax. User journeys remain narrative form.
Critic checkpoint: count total FRs → count EARS-formatted FRs → if ratio < 100%, flag.

Step grades:
| Step | Grade | GATE |
|------|-------|------|
| init | C | AUTO |
| discovery | B | GATE |
| vision | B | GATE |
| executive-summary | B | AUTO |
| success | B | GATE |
| journeys | B | GATE |
| domain | B | AUTO |
| innovation | B | GATE |
| project-type | B | AUTO |
| scoping | A | GATE |
| functional | A | GATE |
| nonfunctional | A | GATE |
| polish | B | AUTO |
| complete | C | AUTO |

#### Stage 3: PRD Validate (PARALLELIZED)

```
Dir: _bmad/bmm/workflows/2-plan-workflows/create-prd/steps-v/
Output: _bmad-output/planning-artifacts/prd-validation-report.md
Team (4): analyst(Writer), john, winston, quinn
GATES: none
```

Parallelization:
```
Round 1 (sequential): step-v-01-discovery
Round 2 (4 parallel):  step-v-02, v-02b, v-03, v-04
Round 3 (4 parallel):  step-v-05, v-06, v-07, v-08
Round 4 (3 parallel):  step-v-09, v-10, v-11
Round 5 (sequential): step-v-12, v-13
```

For parallel rounds: spawn separate background agents per step, each runs party mode independently. Orchestrator collects all results before next round.

Step grades: v-01=C, v-02=C, v-02b=B, v-03=C, v-04=B, v-05=B, v-06=B, v-07=A, v-08=B, v-09=B, v-10=A, v-11=A, v-12=B, v-13=C

#### Stage 4: Architecture (MOST CRITICAL — all opus)

```
Dir: _bmad/bmm/workflows/3-solutioning/create-architecture/steps/
Output: _bmad-output/planning-artifacts/architecture.md
Team (5): winston(Writer), dev, quinn, john, bob
Skip: step-01b-continue.md
GATES: decisions
```

Step grades:
| Step | Grade | GATE |
|------|-------|------|
| init | C | AUTO |
| context | B | AUTO |
| starter | B | AUTO |
| decisions | A | GATE |
| patterns | A | AUTO |
| structure | A | AUTO |
| validation | A | AUTO |
| complete | C | AUTO |

#### Stage 5: UX Design

```
Dir: _bmad/bmm/workflows/2-plan-workflows/create-ux-design/steps/
Output: _bmad-output/planning-artifacts/ux-design-specification.md
Team (5): sally(Writer), john, dev, winston, quinn
Skip: step-01b-continue.md
GATES: design-system, design-directions
```

UXUI Rules (injected into Writer prompt):
1. App shell (layout + sidebar) MUST be confirmed FIRST → pages generate content area only
2. No sidebar duplication in page components — Stitch v2 lesson
3. Theme changes require full grep for remnants (v2 428-location incident)
4. Dead buttons prohibited — every UI element must have a function

Step grades:
| Step | Grade | GATE |
|------|-------|------|
| init | C | AUTO |
| discovery | B | AUTO |
| core-experience | B | AUTO |
| emotional-response | C | AUTO |
| inspiration | C | AUTO |
| design-system | A | GATE |
| defining-experience | B | AUTO |
| visual-foundation | A | AUTO |
| design-directions | B | GATE |
| user-journeys | A | AUTO |
| component-strategy | B | AUTO |
| ux-patterns | B | AUTO |
| responsive-a11y | B | AUTO |
| complete | C | AUTO |

#### Stage 6: Epics & Stories

```
Dir: _bmad/bmm/workflows/3-solutioning/create-epics-and-stories/steps/
Output: _bmad-output/planning-artifacts/epics-and-stories.md
Template: _bmad/bmm/workflows/3-solutioning/create-epics-and-stories/templates/epics-template.md
Team (5): bob(Writer), john, winston, dev, quinn
GATES: design-epics
```

Step grades:
| Step | Grade | GATE |
|------|-------|------|
| validate-prereqs | B | AUTO |
| design-epics | A | GATE |
| create-stories | A | AUTO |
| final-validation | B | AUTO |

Wiring Story Auto-Generation (v9.4):
After all stories are created, bob applies wiring detection rules:
- Story creates store/service → add Wiring Story for initialization in layout/app
- Story creates API endpoint → add Wiring Story for frontend hook connection
- Story creates middleware → add Wiring Story for route registration
- Story creates WebSocket channel → add Wiring Story for client subscription
Naming: Story {N}-W (e.g., 15-1 creates ws-store, 15-W wires it to Layout)
Requirements (EARS): WHEN the application starts, THE SYSTEM SHALL initialize {component} and connect to {consumer}.
Scope limit: ONLY cross-package connections. Same-directory imports excluded.
Wiring stories > 30% of total → ESCALATE (over-generation suspected).
quinn check: "Is this wiring story actually necessary or is the connection trivial?"

#### Stage 6.5: API Contract Definition (v9.4 — Integration Defense)

```
Output: _bmad-output/planning-artifacts/api-contracts.md + shared package type files
Team (4): dev(Writer), winston, quinn, john
GATES: none
Pre-condition: Stage 6 complete
```

Purpose: Define ALL API types in shared package BEFORE any story implementation begins.
This prevents the #1 integration bug source: frontend-backend type mismatches.

Contract Stage Workflow:
```
1. dev reads ALL stories from epics-and-stories.md
2. dev reads architecture.md → extract endpoint definitions
3. For each epic, dev extracts:
   a. Every API endpoint (method + path)
   b. Request body shape (from story requirements + architecture)
   c. Response body shape (from acceptance criteria + architecture)
   d. Error response shapes (from IF/THEN EARS requirements)
4. dev writes api-contracts.md with ALL extracted types
5. Party mode: dev sends [Review Request]
   - winston: architecture alignment, naming consistency, no missing endpoints
   - quinn: testability — are types specific enough to generate test fixtures?
   - john: do contracts cover all story acceptance criteria?
6. Fix → verify → PASS (avg >= 8, Grade A)
7. TypeScript type generation:
   - Hono RPC (hono.rpc_eligible = true in project-context.yaml):
     a. Refactor routes to chaining pattern → export route type
     b. Set up hc client in shared package
   - Standard (non-Hono):
     a. Create shared/src/contracts/{epic-name}.ts for each epic
     b. Export Request/Response types → barrel export from index.ts
   - Both paths: tsc --noEmit on shared package → must pass (GATE)
8. Commit: "types(contracts): API contracts for epic N — {count} endpoints"
```

Contract Stage Rules:
- Contract types = SINGLE SOURCE OF TRUTH for API shapes
- Story dev (Phase B): MUST import from contracts, NEVER define inline
- Type change during implementation: update contract FIRST → tsc → then implement
- Brownfield: read existing types.ts → re-export + extend (don't break existing imports)

Contract Stage Skip:
- Epic has ZERO API endpoints (pure frontend refactor, CSS-only, docs-only)
- dev confirms + party mode agrees → skip logged in context-snapshot

Step grades:
| Step | Grade |
|------|-------|
| extract-endpoints | A |
| generate-types | A |
| tsc-verification | C |

#### Stage 7: Readiness Check (PARALLELIZED)

```
Dir: _bmad/bmm/workflows/3-solutioning/check-implementation-readiness/steps/
Output: _bmad-output/planning-artifacts/readiness-report.md
Template: _bmad/bmm/workflows/3-solutioning/check-implementation-readiness/templates/readiness-report-template.md
Team (5): tech-writer(Writer), winston, quinn, john, bob
GATES: none
```

Parallelization:
```
Round 1 (sequential): step-01-document-discovery
Round 2 (4 parallel):  step-02, step-03, step-04, step-05
Round 3 (sequential): step-06-final-assessment
```

Step grades:
| Step | Grade |
|------|-------|
| document-discovery | C |
| prd-analysis | B |
| epic-coverage | B |
| ux-alignment | B |
| epic-quality | A |
| final-assessment | A |

#### Stage 8: Sprint Planning

No party mode. Orchestrator executes automatically using:
- `_bmad/bmm/workflows/4-implementation/sprint-planning/instructions.md`
- Output: `_bmad-output/implementation-artifacts/sprint-status.yaml`
- Commit: `docs(planning): sprint planning complete`

### Planning Stages — Non-BMAD Mode (bmad_enabled = false)

**Stage 0: Project Analysis**
- Read all existing docs from project-context.yaml
- Analyze codebase structure, key modules, dependencies
- Output: `docs/project-analysis.md`

**Stage 1: Requirements & Design**
- Define user journeys, functional requirements, non-functional requirements
- Output: `docs/requirements.md`

**Stage 2: Architecture Review/Creation**
- If architecture doc exists: review and update
- If not: create architecture document
- Output: `docs/architecture.md`

**Stage 3: Epic & Story Breakdown**
- Break work into epics and stories with acceptance criteria
- Output: `docs/epics-and-stories.md`

**Stage 3.5: API Contract Definition**
- Read all stories → extract API endpoints → define types
- If monorepo: types in shared package. If single package: types in src/types/contracts/
- tsc --noEmit must pass
- Output: `docs/api-contracts.md` + generated type files

**Stage 4: Implementation Plan**
- Dependency order, sprint allocation, risk assessment
- Output: `docs/implementation-plan.md`

Non-BMAD stages use 4-agent party mode (1 Writer + 3 Critics with generic roles).

---

## Mode B: Story Dev Pipeline

### Key Change from v8.0
OLD: 1 Worker calls BMAD Skills sequentially, no party mode.
NEW: 6 phases, each with Writer + Critics party mode using BMAD checklists.

### Orchestrator Flow

```
Step 0: Project Auto-Scan → load project-context.yaml
Step 1: TeamCreate("{project}-story-{id}")
Step 2: Spawn base team: dev(Writer), winston, quinn, john (4 agents, bypassPermissions)
Step 3: Execute Phase A → B → C → D → E → F (details below)
  - Between phases: save context-snapshot, team continues (no recreation)
  - Phase C (simplify): Orchestrator runs directly, no team needed
  - Phase D/E: team rotation (different Writer, same members)
Step 4: Verify completion checklist → tsc (if enabled) → commit + push
Step 5: Shutdown ALL → TeamDelete → update sprint status
```

### Phase A: Create Story

```
Team: dev(Writer), winston, quinn, john = 4
Reference: _bmad/bmm/workflows/4-implementation/create-story/checklist.md

1. dev reads story requirements from epics file
2. dev reads create-story checklist and template
3. dev writes story file following template
4. Party mode: dev sends [Review Request] → winston/quinn/john review
   - winston: architecture alignment, file structure
   - quinn: testability, edge cases, acceptance criteria completeness
   - john: product requirements coverage, user value
   EARS + Gherkin (v9.4):
   - Story "Requirements" section: EARS syntax (WHEN/THE SYSTEM SHALL/IF THEN)
   - Story "Acceptance Criteria" section: Gherkin (Given/When/Then)
   - quinn validates: each EARS requirement has a corresponding Gherkin acceptance criterion
5. Fix → verify → PASS (avg >= 7)
6. Save: context-snapshots/stories/{story-id}-phase-a.md
```

### Phase B: Develop Story

```
Team: dev(Writer), winston, quinn, john = 4
Reference: _bmad/bmm/workflows/4-implementation/dev-story/checklist.md

1. dev reads story file + DoD checklist
   1b. dev reads API contracts from shared/src/contracts/ → import ALL types from contracts (NEVER define inline)
       If needed type missing from contracts: STOP → update contract first → tsc → then continue
2. dev implements REAL working code (no stubs/mocks/placeholders)
3. Party mode: dev sends [Review Request] with changed files list
   - winston: architecture compliance, engine boundary (agent-loop.ts untouched)
   - quinn: code quality, error handling, test hooks
   - john: acceptance criteria satisfaction
4. Fix → verify → PASS
5. Save: context-snapshots/stories/{story-id}-phase-b.md
```

### Phase C: Simplify

```
No team needed. Orchestrator runs /simplify directly.
Timeout: 3 minutes. Skip on fail — code-review catches issues.
```

### Phase D: Test (TEA)

```
Team rotation: quinn(Writer), dev, winston = 3
Reference: TEA risk-based test strategy

1. quinn designs test strategy based on story requirements
2. quinn writes tests (unit + integration + E2E as needed)
   EARS-Driven Test Scaffolding (v9.4):
   2b. quinn parses EARS keywords from story requirements → generates test scaffold:
      - THE SYSTEM SHALL → unit test (verify behavior exists)
      - WHEN [trigger] → integration test (trigger event → assert response)
      - WHILE [condition] → state test (set condition → verify continuous behavior)
      - IF [bad condition] → negative test (inject bad state → assert graceful handling)
      - WHERE [feature] → conditional test (enable/disable feature → verify both paths)
   Integration Verification (v9.4):
   2c. For wiring stories: import chain test + initialization test + data flow test
   2d. For stories that CREATE something: at least 1 integration smoke test
3. Party mode: quinn sends [Review Request]
   - dev: implementability, test framework compliance
   - winston: architecture test coverage, boundary tests
4. Fix → verify → PASS
5. Run all tests — must pass
6. Save: context-snapshots/stories/{story-id}-phase-d.md
```

### Phase E: QA

```
Team rotation: quinn(Writer), john, dev = 3

1. quinn runs QA checklist against implemented code
2. quinn verifies ALL acceptance criteria from story file
3. Party mode: quinn sends [Review Request]
   - john: acceptance criteria met? user value delivered?
   - dev: code completeness, no shortcuts
4. Fix → verify → PASS
5. Save: context-snapshots/stories/{story-id}-phase-e.md
```

### Phase F: Code Review

```
Team rotation: winston(Writer), quinn, dev, john = 4
Reference: _bmad/bmm/workflows/4-implementation/code-review/checklist.md

1. winston reads all changed files + code-review checklist
2. winston performs architecture + security + quality review
   CONTRACT COMPLIANCE (v9.4): winston verifies all API types imported from contracts, not defined inline. Inline type = FAIL.
3. Party mode: winston sends [Review Request]
   - quinn: security patterns, test coverage, edge cases
   - dev: code conventions, performance, dependencies
   - john: product alignment, scope compliance
4. Fix → verify → PASS
5. Save: context-snapshots/stories/{story-id}-phase-f.md
```

### Phase transitions

After Phase F passes:
1. Run ALL tsc commands from project-context.yaml (all must pass — cross-package)
1b. Integration check: for each new/modified API endpoint, verify frontend imports contract type (not inline)
2. If UI files changed → run UI Verification (see section below)
3. Verify Story Dev Completion Checklist (all items [x])
4. git commit + push
5. Shutdown team → TeamDelete

### Developer Writer Prompt Template (Phase A/B)

```
You are dev in team "{team_name}". Model: opus. YOLO mode.

## Your Persona
Read and embody: _bmad/bmm/agents/dev.md

## PROHIBITION: NEVER use the Skill tool.
Read BMAD checklist/template files directly with Read tool.

## Role
Implement real, working features. Fix based on critic feedback. No stubs.

## Phase {A|B} Workflow
1. Read step instruction from Orchestrator
2. Read BMAD checklist: {checklist_path}
3. Read references: project-context.yaml, story file, architecture, prior snapshots
4. {Write story file | Implement code}
5. SendMessage [Review Request] to winston, quinn, john BY NAME
6. WAIT for ALL feedback
7. Read ALL critic logs FROM FILE → apply fixes → write fixes.md
8. SendMessage [Fixes Applied] to ALL BY NAME → WAIT for scores
9. Avg >= 7: [Phase Complete] → WAIT for next instruction
10. Avg < 7: rewrite (max 2 retries)

## Rules
- NEVER use Skill tool. Read .md files manually.
- Real working code only. No stubs/mocks.
- All references read FROM FILE, not from message memory.
```

---

## Mode C: Parallel Story Dev

Usage: `/kdh-full-auto-pipeline parallel 9-1 9-2 9-3` (max 3 workers)
Requires: stories are independent (no mutual dependencies, different files)

```
Step 0: Project Auto-Scan → load project-context.yaml
Step 1: Read status/dependency info → verify no cross-dependencies
Step 2: For each story (up to 3), in separate Git Worktrees:
  - TeamCreate("{project}-story-{id}")
  - Spawn team: dev, winston, quinn, john
  - Execute Phase A → F (same as Mode B)
Step 3: Collect all results (timeout: 30min per story)
Step 4: Sequential merge (in dependency order):
  - checkout main → merge --no-ff → tsc → commit or revert
Step 5: git push → wait for deploy → report
```

Worktree rule: workers must NOT touch files outside their story scope. Shared files → ESCALATE to Orchestrator.

Contract & Wiring in Parallel (v9.4):
- Contract conflict: if two parallel stories modify contract types → sequential merge + tsc after each
- Wiring Story: must be in same parallel batch as parent story (never split across workers)

---

## Mode D: Swarm Auto-Epic

Usage: `/kdh-full-auto-pipeline swarm epic-9`

```
Step 0: Project Auto-Scan → load project-context.yaml
Step 1: Read sprint status → find all stories in epic → analyze dependencies
Step 2: TaskCreate for each story (status=pending, blockedBy=dependencies)
Step 3: Spawn 3 story teams (Git Worktrees, self-organizing):
  - Each team: dev, winston, quinn, john
  - Each follows Phase A→F flow
Step 4: Monitor:
  - On [Phase Complete]: verify artifacts
  - On [Shared File]: coordinate merge
  - On [ESCALATE]: intervene
  - On [All Tasks Done]: proceed to merge
  - Timeout: 30min per story
Step 5: Shutdown all teams → sequential merge (dependency order) → tsc → commit per story
Step 6: git push → deploy → generate epic completion report

Contract & Wiring in Swarm (v9.4):
- Contract files (shared/src/contracts/): stories touching these are serialized (never parallel)
- Wiring Story (N-W): blockedBy = [parent story N.M] in task dependencies
```

### Swarm Worker Loop

```
Loop until no tasks remain:
1. TaskList → find first task: status=pending, owner=null, blockedBy all completed
   - No available task + others in_progress → wait 30s → retry
   - No tasks at all → "[All Tasks Done]"
2. TaskUpdate: status=in_progress, owner="{team_name}"
3. Execute Phase A → F (full party mode per phase)
4. Run tsc + UI verification (if applicable)
5. TaskUpdate: status=completed → report summary
6. Go to step 1
```

---

## UI Verification (triggered when UI files changed)

### Detection
UI files changed = any modified/added file matching:
- `**/*.tsx`, `**/*.jsx`, `**/*.vue`, `**/*.svelte`
- `**/*.css`, `**/*.scss`, `**/*.less`
- `**/*.html` (in src/ or app/ directories)
- Route/page config files

### Full Interaction E2E

```
Step 1: Start dev server (dev_command from project-context.yaml, 60s timeout)
Step 2: Identify changed pages (git diff → filter UI → map to routes)
Step 3: Playwright screenshot of ALL changed pages
Step 4: Full interaction E2E on each changed page:
  a. Every button: click → verify no crash + expected response
  b. Every input: type test data → verify value + validation
  c. Every form: fill + submit → verify success/error states
  d. Every dropdown: open → verify options → select → verify
  e. CRUD operations (if applicable): create → read → update → delete
  f. Console errors: capture all, filter benign, fail on unexpected
Step 5: Theme consistency check (design tokens match app shell)
Step 6: Router import check (all lazy-loaded routes resolve)
Step 7: Stop dev server
```

If Playwright not configured → skip automated E2E, still run router + console checks.

---

## Story Dev Completion Checklist

```
Story Dev completion checklist:
  [ ] Phase A: create-story + party review PASS
  [ ] Phase B: dev-story (real code, no stubs) + party review PASS
  [ ] Phase C: simplify completed
  [ ] Phase D: TEA tests written + party review PASS + tests passing
  [ ] Phase E: QA acceptance criteria verified + party review PASS
  [ ] Phase F: code-review + party review PASS
  [ ] tsc passes (if tsc_enabled)
  [ ] If UI story: full interaction E2E passes
  [ ] If UI story: theme consistency verified
  [ ] If UI story: no unexpected console errors
  [ ] All router imports resolve
  [ ] Real functionality (no stub/mock/placeholder)
  [ ] Integration: cross-package imports all resolve
  [ ] Contract compliance: all API types imported from shared contracts (no inline overrides)
  [ ] If wiring story: upstream component → downstream consumer connected end-to-end
  [ ] If story creates API endpoint: frontend hook/query uses contract types
  [ ] Cross-package tsc: ALL tsc commands pass (not just changed package)
```

ALL items must be [x] before story is accepted.
If any UI check fails → fix → re-run → must pass.

---

## Pipeline Interconnection: UXUI Redesign → Code Review

When `/kdh-uxui-redesign-full-auto-pipeline` completes, auto-trigger full code review:

```
Review context:
  type: "uxui-redesign"
  risk_level: HIGH (forced)

Required checks:
  1. Theme consistency across ALL pages
  2. Full interaction E2E on ALL pages (not just changed)
  3. Router integrity (all imports resolve, no 404s)
  4. Accessibility baseline (WCAG AA contrast, keyboard nav, screen reader)
  5. Performance sanity (bundle size, no render-blocking imports)

Output: _qa-e2e/uxui-redesign-review-{date}.md
```

---

## Defense & Timeouts

| Mechanism | Value | Action |
|-----------|-------|--------|
| max_retry (Grade A) | 3 per step | 4th fail → ESCALATE |
| max_retry (Grade B) | 2 per step | 3rd fail → ESCALATE |
| max_retry (Grade C) | 1 per step | 2nd fail → ESCALATE |
| step_timeout | 20min + 2min grace | Reminder → grace → respawn with snapshots |
| party_timeout | 15min per round | Critic unresponsive → fallback to single-worker |
| gate_timeout | none | GATE waits indefinitely for user |
| stall_threshold | 5min no message | Ping → 2nd stall → force-close |
| max_stalls | 3 | SKIP step |
| shutdown_timeout | 30s | → tmux kill-pane → force cleanup |
| /simplify | 3min timeout | Skip on fail |
| ui_dev_server | 60s startup | WARN + continue without E2E |
| ui_e2e_per_page | 2min per page | Skip page with WARN |
| context_window | 1M tokens (Opus 4.6) | No early compaction |
| story_timeout | 30min per story | ESCALATE |

---

## Core Rules

1. **BMAD real names mandatory.** All agents spawned with names from BMAD Agent Roster. Each agent Reads their persona file as first action.
2. **GATE steps pause for user.** Never auto-proceed on GATE steps. Wait indefinitely.
3. **BMAD steps auto-discovered.** glob steps/ directories, filter continue files, sort by filename. Never hardcode step lists.
4. **Independent steps run in parallel.** PRD Validate and Readiness use parallel groups.
5. **Writer NEVER calls Skill tool.** Read step/checklist files manually with Read tool.
6. **One step at a time.** Write ONE step → full party mode → THEN next step.
7. **All reads FROM FILE.** Use Read tool, never message memory.
8. **Output quality: specific and concrete.** File paths, hex colors, exact values. "Vague" = instant FAIL.
9. **Orchestrator embeds first task in spawn.** Never spawn with just "wait".
10. **Stage transition: clean restart.** Verify all steps → commit → shutdown ALL → TeamDelete → fresh team + snapshots.
11. **Pipeline never blocks.** Timeout/fail/escalate always leads to "continue".
12. **tsc MUST pass** before any commit (if tsc_enabled).
13. **Context snapshots after every step/phase.** Save to context-snapshots/. On resume: read ALL snapshots first.
14. **Project Auto-Scan first.** ALWAYS run Step 0. Never assume project structure.
15. **UI verification gate.** UI files changed + verification fails = story NOT complete.
16. **No hardcoded paths.** All paths from project-context.yaml or dynamic discovery.
17. **Scoring rubric mandatory.** Critics use `_bmad-output/planning-artifacts/critic-rubric.md` — 6 dimensions, 7/10 pass, any dim <3 auto-fail.
18. **`계속` = run to completion.** Do NOT stop at intermediate milestones (except GATE steps).
19. **Batch parallelism.** Independent files needing similar changes → split into batches, launch background agents.
20. **Startup cleanup.** Clean stale worktrees/panes/dirs. Shutdown: clean all resources.
21. **EARS for requirements, Gherkin for tests.** All functional requirements use EARS syntax (THE SYSTEM SHALL...). Acceptance criteria use Gherkin (Given/When/Then). Both coexist.
22. **Contract types are single source of truth.** API types defined in Contract Stage (6.5). Story dev imports from contracts, never defines inline. Type changes require contract update FIRST, tsc pass, then implementation.
23. **Wiring stories mandatory for cross-package connections.** If a story creates a component consumed by another package, a wiring story must exist. Skip only for same-directory connections.
24. **Integration gate before story completion.** ALL tsc commands run (cross-package), not just the changed package. Import chains verified. Contract compliance checked.
