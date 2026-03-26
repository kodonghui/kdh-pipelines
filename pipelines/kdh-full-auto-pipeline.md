---
name: 'kdh-full-auto-pipeline'
description: 'Universal Full Pipeline v9.3 — BMAD-powered full-cycle automation + ECC v1.9.0 integration. Auto-discovers workflows, real BMAD agent personas, party mode per step, user gates. Usage: /kdh-full-auto-pipeline [planning|story-ID|parallel ID1 ID2...|swarm epic-N]'
---

# Universal Full Pipeline v9.3

## Mode Selection

- `planning` or no args: Planning pipeline — BMAD full-cycle, 9 stages, real agent party mode
- Story ID (e.g. `3-1`): Single story dev — 6 phases with party mode per phase
- `parallel story-ID1 story-ID2 ...`: Parallel story dev — Git Worktrees, max 3 simultaneous
- `swarm epic-N`: Swarm auto-epic — all stories as tasks, 3 self-organizing agent teams

---

## Step 0 (ALL Modes): Project Auto-Scan

> **Step 0: Project Auto-Scan**: See [core/project-scan.md](../core/project-scan.md)

If `project-context.yaml` already exists and is < 1 hour old, skip re-scan (use cached).

---

> **ECC Enhancement — search-first**: If project-context.yaml shows missing common patterns or `test_enabled: false`, the `search-first` skill runs automatically to identify existing frameworks before planning begins. See [core/ecc-integration.md §1.1](../core/ecc-integration.md#11-planning-phase--search-first).

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

> **Party Mode Protocol**: See [core/party-mode.md](../core/party-mode.md)

> **Scoring**: See [core/scoring.md](../core/scoring.md)

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
   - Grade A: avg >= 8.0 required
   - Grade B: avg >= 7.5 required
   - Avg >= threshold: proceed to Minimum Cycle Check (step 11)
   - Avg < threshold AND retry < grade_max: Writer rewrites from step 1
   - Retry >= grade_max: ESCALATE to Orchestrator
10. Score Variance Check:
   - Calculate standard deviation of all critic scores
   - If stdev < 0.5: Orchestrator flags "Suspiciously High Agreement"
   - At least 1 critic MUST independently re-score without seeing others' scores
11. Minimum Cycle Check (MANDATORY):
   - Grade A: MINIMUM 2 full cycles required regardless of scores
     - Cycle 1: steps 1-8 above (normal review)
     - Cycle 2: Devil's Advocate mode — 1 designated critic MUST find >= 3 issues
     - If Devil's Advocate finds 0 issues: suspicious, Orchestrator reviews directly
   - Grade B: MINIMUM 1 full cycle + cross-talk verified
   - Only after minimum cycles met AND avg >= threshold → PASS
12. Orchestrator Step Completion Checklist (BLOCKING):
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

### Party-log Verification

Orchestrator validates ALL critic logs + fixes.md exist before accepting [Step Complete]:
```
1. For each critic in team: check file exists at party-logs/{stage}-{step}-{critic-name}.md
2. Check fixes log exists: party-logs/{stage}-{step}-fixes.md
3. If ANY file missing → REJECT [Step Complete], request missing critic to write their log
4. Only accept [Step Complete] when ALL files verified
```

---

## User Gate Protocol

16 steps across the pipeline pause for user input on non-technical decisions.

### Gate Flow
```
1. Writer drafts options (A/B/C format with pros/cons)
2. Writer sends "[GATE] {step_name}" to team-lead (Orchestrator)
3. Orchestrator presents to user:
   - Summary of what was written
   - Options with pros/cons
   - Clear question
4. User responds
5. Orchestrator sends user decision to Writer
6. Writer incorporates decision into document
7. Normal party mode continues (Critics review the gate-resolved content)
```

### Gate Inventory

| # | Stage | Step | Question for User |
|---|-------|------|-------------------|
| 1 | 0 Brief | vision | Project core vision direction? |
| 2 | 0 Brief | users | Target users, user priority? |
| 3 | 0 Brief | metrics | Success criteria to use? |
| 4 | 0 Brief | scope | Which features include/exclude/modify? |
| 5 | 2 PRD | discovery | Which existing features to change/keep? |
| 6 | 2 PRD | vision | PRD vision statement confirmation? |
| 7 | 2 PRD | success | Success metrics realistic? |
| 8 | 2 PRD | journeys | User journey matches expectation? |
| 9 | 2 PRD | innovation | Innovation vs basic feature split? |
| 10 | 2 PRD | scoping | Phase division, priority decisions? |
| 11 | 2 PRD | functional | Each FR include/exclude? |
| 12 | 2 PRD | nonfunctional | NFR numbers confirmed (FPS, response time, memory)? |
| 13 | 4 Arch | decisions | Final tech stack confirmation? |
| 14 | 5 UX | design-system | Design system/theme direction? |
| 15 | 5 UX | design-directions | Design direction selection? |
| 16 | 6 Epics | design-epics | Epic scope confirmed? |

AUTO steps (non-gate) proceed without user input. Orchestrator only notifies user at stage boundaries.

---

## Anti-Patterns (production failures)

1. **Writer calls Skill tool** — Skill auto-completes all steps internally, bypasses critic review. FIX: Writer MUST NEVER use Skill tool. Read step files with Read tool, write manually.
2. **Writer batches steps** — Writes steps 2-6 then sends one review. FIX: Write ONE step → party mode → THEN next step.
3. **Agent spawned with generic name** — `critic-a` or `worker-1` instead of BMAD name. FIX: ALWAYS use real names from BMAD Agent Roster.
4. **Critic skips persona file** — Reviews without reading `_bmad/bmm/agents/*.md`. FIX: First action MUST be Read persona file.
5. **GATE step auto-proceeds** — Writer skips user input on GATE step. FIX: GATE steps MUST send [GATE] to Orchestrator and WAIT.
6. **Shutdown-then-cancel race** — shutdown_request is irreversible. FIX: NEVER send unless 100% committed.
7. **Writer duplicates prior step content** — Writer copies tables that already exist in earlier steps. FIX: Before writing, Writer MUST Read prior steps. If content exists, use cross-reference instead of duplicating.
8. **Score convergence inflation** — All critics give identical scores after fixes. FIX: Orchestrator checks score standard deviation; if stdev < 0.5, triggers independent re-scoring.
9. **Missing party-log files** — Critic reviews sent via message only, no file written. FIX: Orchestrator verifies all party-log files exist before accepting [Step Complete]. Missing file = REJECT.
10. **Single-cycle rubber stamp** — All critics score 8.5+ on first review, no retry triggered. FIX: Grade A requires MINIMUM 2 cycles regardless of scores. Cycle 2 uses Devil's Advocate mode.
11. **Cross-talk skipped** — Critics review independently but never discuss. FIX: Cross-talk is MANDATORY. Each critic log MUST contain "## Cross-talk" section.
12. **Orchestrator skips own checklist** — Rules exist but Orchestrator doesn't follow them. FIX: Step Completion Checklist is BLOCKING — Orchestrator must verify every checkbox before accepting.

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
Step 1: For each Stage (0-8):
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

Input references (root material for brief):
- Read reference docs from preset or `project-context.yaml`
- Existing PRD, architecture, feature-spec (from project-context.yaml)
- `_bmad-output/planning-artifacts/critic-rubric.md` (scoring)

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
2. No sidebar duplication in page components
3. Theme changes require full grep for remnants
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
5. Fix → verify → PASS (avg >= 7)
6. Save: context-snapshots/stories/{story-id}-phase-a.md
```

### Phase B: Develop Story

```
Team: dev(Writer), winston, quinn, john = 4
Reference: _bmad/bmm/workflows/4-implementation/dev-story/checklist.md

1. dev reads story file + DoD checklist
2. dev implements REAL working code (no stubs/mocks/placeholders)
3. Party mode: dev sends [Review Request] with changed files list
   - winston: architecture compliance, engine boundary
   - quinn: code quality, error handling, test hooks
   - john: acceptance criteria satisfaction
4. Fix → verify → PASS
5. Save: context-snapshots/stories/{story-id}-phase-b.md
```

> **ECC Enhancement — tdd-workflow + coding-standards**: dev(Writer) follows the `tdd-workflow` RED→GREEN→REFACTOR cycle. Tests written before implementation. quinn(Critic) enforces 80%+ coverage. All code checked against `coding-standards` (immutability, error handling, input validation). See [core/ecc-integration.md §1.2](../core/ecc-integration.md#12-story-dev--tdd-workflow--coding-standards).

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
3. Party mode: winston sends [Review Request]
   - quinn: security patterns, test coverage, edge cases
   - dev: code conventions, performance, dependencies
   - john: product alignment, scope compliance
4. Fix → verify → PASS
5. Save: context-snapshots/stories/{story-id}-phase-f.md
```

> **ECC Enhancement — santa-method**: After Phase F party mode PASSES, run `santa-method` adversarial verification: 2 context-isolated agents independently review changed files. Both must PASS. MAX_ITERATIONS=2, then ESCALATE. Includes Phantom Success rubric criterion. See [core/ecc-integration.md §1.3](../core/ecc-integration.md#13-code-review--santa-method--security-review).

### Phase transitions

After Phase F passes:
1. Run tsc commands from project-context.yaml (all must pass)
2. If UI files changed → run UI Verification (see section below)
3. **E2E Gate** (if .tsx page files changed):
   - Follow protocol in `core/e2e-gate.md`
   - Identify changed pages → load TCs → Playwright verify CRUD → lint check
   - CRITICAL: Verify DB writes, not just toast messages
   - PASS → continue. FAIL → return to Phase A for fix (max 2 retries)
   - **ECC Enhancement**: `click-path-audit` maps state stores and traces handler chains for Phantom Success detection. `verification-loop` runs 6-phase deterministic gate (Build→Type→Lint→Test→Security→Diff). See [core/ecc-integration.md §1.4](../core/ecc-integration.md#14-e2e-gate--click-path-audit--verification-loop).
4. Verify Story Dev Completion Checklist (all items [x])
5. git commit + push
6. Shutdown team → TeamDelete

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
- PROHIBITION: No success UI (toast, redirect) without a preceding api.post/put/delete or mutation.mutate().
  addToast({ type: 'success' }) without API call = CRITICAL BUG. Document each CRUD handler:
  API endpoint → server route → DB table. See core/ecc-integration.md §6 (Phantom Success Defense).
```

---

## Mode C: Parallel Story Dev

Usage: `/full-auto parallel 9-1 9-2 9-3` (max 3 workers)
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

---

## Mode D: Swarm Auto-Epic

Usage: `/full-auto swarm epic-9`

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
```

ALL items must be [x] before story is accepted.
If any UI check fails → fix → re-run → must pass.

> **ECC Enhancement — continuous-learning**: On story completion, `continuous-learning-v2` observe hook captures patterns as project-scoped instincts. `/learn-eval` extracts reusable knowledge. See [core/ecc-integration.md §1.5](../core/ecc-integration.md#15-post-completion--continuous-learning).

---

## Pipeline Interconnection: UXUI Redesign → Code Review

When UXUI redesign pipeline completes, auto-trigger full code review:

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
18. **Run to completion.** Do NOT stop at intermediate milestones (except GATE steps).
19. **Batch parallelism.** Independent files needing similar changes → split into batches, launch background agents.
20. **Startup cleanup.** Clean stale worktrees/panes/dirs. Shutdown: clean all resources.
21. **ECC enhancements are additive.** ECC skills enhance but never replace BMAD party mode or agent personas. If ECC and BMAD conflict, BMAD takes precedence. santa-method runs AFTER party mode, not instead of it.
