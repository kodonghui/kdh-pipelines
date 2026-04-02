---
name: 'kdh-full-auto-pipeline'
description: 'Universal Full Pipeline v10.2 — Planning DA + Traceability Matrix + App Chrome Checklist + UI Existence Check. 사장님 명령어: /kdh-full-auto-pipeline [auto|planning|sprint N|story-ID|parallel ID1 ID2...|swarm epic-N|계속]'
---

# Universal Full Pipeline v10

## Mode Selection

- **no args** 또는 **`auto`**: 상태 자동 감지 → 다음 할 일 판단 → 실행 (kdh-go 흡수)
- **`계속`**: 자동 감지 + GATE 자동 통과 (밤새 모드)
- `planning`: Planning pipeline — BMAD full-cycle, 9 stages, real agent party mode
- `sprint N`: Sprint N 실행 — 스토리 루프 + 리뷰 + Codex + 통합 + E2E
- Story ID (e.g. `3-1`): Single story dev — 6 phases with party mode per phase
- `parallel story-ID1 story-ID2 ...`: Parallel story dev — Git Worktrees, max 3 simultaneous
- `swarm epic-N`: Swarm auto-epic — all stories as tasks, 3 self-organizing agent teams

---

## Mode: Auto (상태 자동 감지 — kdh-go 흡수)

인자 없이 실행하면 프로젝트 상태를 읽고 자동으로 다음 할 일을 판단합니다.

```
Phase 0: State Detection (30s)

1. project-context.yaml 존재하는지?
   - 없음 → planning 모드 (Step 0부터)

2. _bmad-output/planning-artifacts/ 확인:
   - product-brief 없음 → planning 모드 (Stage 0부터)
   - prd.md 없음 → planning 모드 (Stage 2부터)
   - architecture.md 없음 → planning 모드 (Stage 4부터)
   - epics-and-stories.md 없음 → planning 모드 (Stage 6부터)

3. packages/shared/src/contracts/index.ts 확인:
   - 없음 → planning 모드 (Stage 6.5)

4. sprint-status.yaml 확인:
   - 없음 → planning 모드 (Stage 7 Sprint Planning)
   - 있음 → Sprint 상태 읽기

5. 리뷰 상태 확인 (우선):
   - review_state: conditional → 해당 스토리 수정부터
   - review_state: auto-fail → GATE 에스컬레이션
   - review_state: escalated → GATE 에스컬레이션

6. 통합 상태 확인:
   - integration_state: fail → 통합 이슈 해결
   - integration_state: warning → 정상 진행

7. E2E 상태 확인:
   - Sprint 완료 + e2e_result: null → E2E 실행
   - e2e_result: fail → E2E 버그 수정

8. Sprint 상태 분석:
   - 미완료 스토리 있음 → sprint {N} 모드 (이어서)
   - 스프린트 완료 + E2E 안 함 → E2E 실행
   - E2E 완료 + GATE 안 함 → GATE sprint-verify
   - 전부 완료 → 다음 스프린트? → sprint {N+1} 모드
   - 전체 Phase 완료 → "Phase 1 완료!" 보고
```

### `계속` 모드 (밤새 자동)

`/kdh-full-auto-pipeline 계속` 으로 실행 시:
```
1. 모든 GATE → 기본 선택 (A) 자동 통과, [AUTO] 표시
2. 아침에 사장님이 확인하고 변경 가능
3. FAIL 스토리 → 1회 재시도 → SKIP + 기록
4. ESCALATED → sprint-status.yaml에 기록
5. Phase 완료 → 종료 (다음 Phase는 사장님 확인 후)

★ 예외: Codex FAIL은 자동 진행 금지 (계속 모드에서도) ★
```

### Ralph Loop (밤샘 최안정)
```bash
while true; do claude -p "/kdh-full-auto-pipeline 계속"; sleep 5; done
```
매 반복마다 fresh context — 긴 작업에서도 품질 유지.

### 보고 형식 (한국어)

```
시작:    "Sprint {N} 이어서 합니다. 스토리 {M}개 남았어요."
스토리:  "스토리 {id} 완료. 리뷰 평균: {X.X}/10. ({N}/{M} 진행)"
Sprint:  "Sprint {N} 끝! {M}개 스토리, 평균 리뷰 {X.X}/10.
          브라우저에서 확인해주세요."
Phase:   "Phase 1 전부 끝났습니다! 기능 5개 완성."
```

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
6 dimensions (D1-D6, /4 scale → /10 conversion). Grade A: ≥8.0/10, Grade B: ≥7.5/10. Any dimension <3 = auto-fail.

## References
- project-context.yaml
- All context-snapshots from prior stages
- {stage-specific references}
```

PROHIBITION: Never spawn agents as `critic-a`, `critic-b`, `critic-c` or any generic name.

---

## Model Strategy

**Grade-differentiated model assignment:**

| Role | Model | Rationale |
|------|-------|-----------|
| Orchestrator (kdh-go, pipeline) | opus | Complex judgment, state management, CEO communication |
| Dev agent (builder) | sonnet | Best coding model, fast, validated in Sprint 0 |
| Critics — Grade A (auth, permissions, payments) | opus | Deep architecture analysis needed |
| Critics — Grade B (CRUD, UI) | sonnet | Fast and sufficient |
| Critics — Grade C (setup) | N/A | Writer Solo, no critics |
| Codex (second opinion) | GPT-5.4 | External model, independent perspective |

**haiku 절대 금지 (CEO 규칙).**

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
4. Critics: Cross-talk with FIXED pairs (1 round, v10.1):
   Story Dev fixed pairs (3 critics: winston, quinn, john):
     - winston ↔ quinn: 보안/아키텍처 vs 테스트/품질
     - quinn ↔ john: 테스트 커버리지 vs 제품 요구사항
     - john ↔ winston: 제품 방향 vs 아키텍처 제약
   Planning (4-5 critics): adjacent expertise pairs as before.
   Cross-talk MUST happen. Each critic SendMessage to assigned peer with top disagreement/concern.
   Peer responds. Both update their party-logs with "## Cross-talk" section before scoring.
   ★ pre-commit hook이 Cross-talk 섹션 존재 + 최소 3줄 내용 검증 (WARNING)
   Critic 프롬프트에 포함할 것:
     "리뷰 후 {peer_name}에게 SendMessage로 가장 큰 의견 차이 1개 공유.
      상대방 응답 받은 후 '## Cross-talk' 섹션에 대화 내용 기록."
5. Critics: SendMessage [Feedback] to Writer BY NAME — "{N} issues. Priority: [top 3]"
6. Writer: Read ALL critic logs FROM FILE → apply fixes → write party-logs/{stage}-{step}-fixes.md
7. Writer: SendMessage [Fixes Applied] to ALL critics BY NAME
8. Critics (parallel): Re-read FROM FILE → verify → SendMessage [Verified] with D1-D6 scores (/4)
9. Orchestrator converts to /10: overall = (3-critic weighted avg / 4) × 10
   Report format: "리뷰 평균: 8.2/10 (D1:3.5 D2:3.0 D3:3.5 D4:3.0 D5:3.5 D6:3.0)"
10. Calculate average + enforce thresholds:
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

### Party-log Naming Standard (v10.1)

Two patterns only. Everything else is wrong.

**Story Dev (Sprint execution):**
```
story-{story-id}-phase-{a|b|c|d|f}-{critic-name}.md     # critic review
story-{story-id}-phase-{X}-fixes.md                      # Writer fixes
story-{story-id}-phase-{X}-devils-advocate.md             # DA cycle
story-{story-id}-codex.md                                 # Codex result
```
Examples: `story-1-1-phase-b-winston.md`, `story-1-1-phase-d-fixes.md`

**Planning (Stages 0-8):**
```
stage-{N}-step-{NN}-{critic-name}.md                     # critic review
stage-{N}-step-{NN}-fixes.md                             # Writer fixes
stage-{N}-step-{NN}-gate-draft.md                        # GATE draft
```
Examples: `stage-0-step-02-winston.md`, `stage-2-step-05-fixes.md`

Pre-commit hook validates these patterns. Non-conforming filenames are ignored by the hook.

### Party-log Verification (v9.1)

Orchestrator validates ALL critic logs + fixes.md exist before accepting [Step Complete]:
```
1. For each critic in team: check file exists using naming standard above
2. Check fixes log exists
3. If ANY file missing → REJECT [Step Complete], request missing critic to write their log
4. Only accept [Step Complete] when ALL files verified
```

---

## User Gate Protocol (v10.1)

19 GATE steps, 분류: **Business** (CEO 대기) vs **Technical** (자동 통과 + 기록).
Business GATE = 제품 방향/의미/사용자 경험. Technical GATE = 기술 결정/수치/세부사항.

### Gate Flow

**Business GATE:**
```
1. Writer drafts options (A/B/C format with pros/cons)
2. Writer sends "[GATE] {step_name}" to team-lead (Orchestrator)
3. Orchestrator presents to user (한국어, 기술 용어 금지):
   - Summary of what was written
   - Options with pros/cons
   - Clear question: "어떻게 할까요? A/B/C 또는 수정사항?"
4. User responds
5. Orchestrator sends user decision to Writer
6. Writer incorporates decision into document
7. Normal party mode continues
```

**Technical GATE:**
```
1. Writer drafts decision with rationale
2. Critics review and approve/challenge
3. Orchestrator logs decision to party-logs/{stage}-gate-{step}-auto.md
4. Auto-proceed. CEO can review logged decisions at any time.
```

### Gate Inventory

| # | Stage | Step | Type | Question / Auto-decision |
|---|-------|------|------|--------------------------|
| 1 | 0 Brief | vision | **BIZ** | 제품 비전 방향 맞는지? |
| 2 | 0 Brief | users | **BIZ** | 타겟 사용자 우선순위? |
| 3 | 0 Brief | metrics | TECH | 업계 표준 기반 성공 기준 자동 설정 |
| 4 | 0 Brief | scope | **BIZ** | 기능 넣을지/뺄지/수정 |
| 5 | 2 PRD | discovery | TECH | v1→v2 기능 변환은 기술 판단 |
| 6 | 2 PRD | vision | TECH | Brief에서 이미 결정됨, 문구 자동 반영 |
| 7 | 2 PRD | success | TECH | metrics에서 결정됨, 수치 자동 반영 |
| 8 | 2 PRD | journeys | **BIZ** | 사용자 흐름이 사장님 상상과 일치? |
| 9 | 2 PRD | innovation | TECH | 혁신 vs 기본은 아키텍트 판단 |
| 10 | 2 PRD | scoping | **BIZ** | Phase 나누기, 우선순위 결정 |
| 11 | 2 PRD | functional | TECH | scope에서 큰 방향 결정됨, FR 세부는 기술 |
| 12 | 2 PRD | nonfunctional | TECH | NFR 수치는 기술 벤치마크 기반 |
| 13 | 4 Arch | decisions | TECH | 기술 선택은 에이전트 자율 (CLAUDE.md 규칙) |
| 14 | 5 UX | design-system | TECH | 테마 방향은 design-directions에서 결정 |
| 15 | 5 UX | design-directions | **BIZ** | 디자인 시안 선택 |
| 16 | 6 Epics | design-epics | TECH | Epic 스코프는 scope에서 이미 결정됨 |
| 17 | Sprint Zero | theme-select | TECH | 5개 테마 이미 확정됨 (CEO 선정) |
| 18 | Story Dev | page-design | TECH | Subframe 자동 생성, Sprint End에서 일괄 확인 |
| 19 | Sprint End | visual-verify | **BIZ** | 브라우저에서 전체 화면 확인 — 최종 관문 |

**Summary: 6 Business GATEs** (CEO 대기) + **13 Technical GATEs** (자동 통과).
`계속` 모드: Technical GATE auto-pass + Business GATE도 auto-pass ([AUTO] 표시).
일반 모드: Business GATE만 CEO 대기, Technical GATE는 자동 통과.

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

App Chrome Checklist (v10.2 — Stage 5 완료 전 BLOCKING):
sally MUST define ALL of the following in UX spec. 빠지면 Stage 5 PASS 불가.
```
- [ ] 로그인 페이지 레이아웃
- [ ] App Shell (header + sidebar + content area) 전체 구조
- [ ] 사용자 계정 메뉴 위치 (프로필, 설정, 로그아웃)
- [ ] 로그아웃 버튼 정확한 위치 (어느 컴포넌트의 어디)
- [ ] 전역 로딩 상태 (스피너 or 스켈레톤)
- [ ] 에러 메시지 표시 위치 (토스트 or 인라인 or 배너)
- [ ] 세션 만료 시 UX 흐름 (리다이렉트 → 어디에 메시지?)
- [ ] 빈 상태 (목록에 데이터 없을 때 보여줄 것)
- [ ] 모든 FR에 대응하는 UI 요소 1개 이상 존재
```
Critic 검증: winston은 "FR3에 대응하는 UI 요소가 UX 스펙에 있는가?" 체크. 없으면 auto-FAIL.

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

#### Stage 6.1: Planning DA — User Journey Traceability (v10.2)

```
Pre-condition: Stage 6 complete
Team (3): quinn(DA Writer), winston, john
GATES: none
Grade: A (minimum 3 gaps mandatory)
```

Purpose: Dev Mode의 Devil's Advocate를 Planning에 적용.
모든 FR에 대해 사용자 여정을 처음부터 끝까지 추적하여 빠진 단계를 찾는다.

Planning DA Workflow:
```
1. quinn reads PRD → extract ALL FRs
2. For EACH FR, trace the complete user path:
   a. 사용자가 이 기능을 어떻게 찾는가? → UX 스펙에 UI 요소 있는가?
   b. 사용자가 어떤 페이지에서 시작하는가? → Story에 해당 페이지 있는가?
   c. 사용자가 무엇을 클릭/입력하는가? → UX 스펙에 버튼/폼 정의됐는가?
   d. 시스템이 어떻게 응답하는가? → Architecture에 API 경로 있는가?
   e. 성공 시 어디로 이동하는가? → Story AC에 리다이렉트 정의됐는가?
   f. 실패 시 사용자에게 뭘 보여주는가? → UX 스펙에 에러 표시 위치 있는가?
   g. 로딩 중에 뭘 보여주는가? → UX 스펙에 로딩 상태 정의됐는가?
3. Traceability Matrix 작성:
   | FR | UI 요소 (UX) | 시작 페이지 | 클릭 대상 | API 경로 | 성공 이동 | 실패 표시 | 로딩 상태 |
   빈 셀 = GAP → 최소 3개 강제 발견
4. Party mode: quinn sends [Review Request]
   - winston: architecture 경로 누락 체크
   - john: product 관점에서 사용자 경험 빈 곳 체크
5. GAP 발견 시: Stage 5(UX) 또는 Stage 6(Stories) 보완 → Traceability 재검증
6. 모든 셀 채워짐 → PASS
7. Save: context-snapshots/planning/stage-6.1-traceability.md
```

Anti-pattern: "Story 1-2에서 구현 예정" 같은 미래 참조로 빈 셀을 채우는 것은 금지.
해당 Story가 실제로 해당 UI 요소를 만드는 AC를 포함하는지 확인해야 함.

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
| fr-traceability | A |
| final-assessment | A |

FR-to-UI Traceability Matrix (v10.2 — BLOCKING):
```
tech-writer builds a matrix for EVERY FR in the PRD:
| FR | PRD 정의 | UX UI 요소 | Story | Story AC | 구현 경로 |
빈 셀 = BLOCK. Stage 5(UX) 또는 Stage 6(Stories) 보완 필요.

예시:
| FR3 (로그아웃) | ✅ prd.md:615 | ❌ UX에 없음 | ✅ Story 1-3 | ✅ AC 2개 | ❌ 버튼 위치 미정 |
→ ❌ 2개 → Stage 5 보완 필요 → Sprint Planning 진행 불가
```
tech-writer가 matrix 작성 → winston/quinn 검증 → 빈 셀 0개 확인 → PASS.

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
Step 3: Execute Phase A → B → C → D → F (v10.1: Phase E removed, merged into D)
  - Between phases: save context-snapshot, team continues (no recreation)
  - Phase C (simplify): Orchestrator runs directly, no team needed
  - Phase D: team rotation (quinn Writer, dev+winston+john critics)
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
   UI Existence Check (v10.2):
   - quinn MUST verify: "이 스토리가 참조하는 UI 요소(버튼, 페이지, 폼)가 다른 스토리 또는 UX 스펙에 정의되어 있는가?"
   - 예: Story 1-3이 "로그아웃 클릭"을 참조 → 로그아웃 버튼이 어떤 스토리/UX에 정의됐는지 확인
   - 없으면: 이 스토리에 "해당 UI 생성" 태스크 추가 OR 선행 스토리 dependency 명시
   - 빈 참조 = auto-FAIL ("UI element not defined anywhere")
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

   === UI STORY GATE (v10 — 오케스트레이터 주도, dev는 MCP 접근 불가) ===
   1c. Check: does this story create or modify UI pages? (*.tsx in features/)
       If YES → Subframe Design Gate (오케스트레이터가 직접 실행):
         i.   오케스트레이터: Subframe MCP design_page → 페이지 레이아웃 생성
         ii.  오케스트레이터: [GATE page-design] → CEO 디자인 승인
         iii. 오케스트레이터: get_page_info → Subframe 코드 추출
         iv.  오케스트레이터: packages/admin/src/features/{page}.tsx 작성 (Subframe 컴포넌트 사용)
         v.   dev 에이전트: Subframe 코드 위에 비즈니스 로직 구현 (API 연결, 폼 검증)
         ★ dev에게 "Subframe 써라" 지시 금지 — MCP 접근 안 됨
       If NO → skip to step 2

2. dev implements REAL working code (no stubs/mocks/placeholders)
   2b. UI stories: apply active theme from themes.ts, use consistent layout from Subframe reference
3. Party mode: dev sends [Review Request] with changed files list
   - winston: architecture compliance, engine boundary (agent-loop.ts untouched)
   - quinn: code quality, error handling, test hooks
   - john: acceptance criteria satisfaction
   - sally: (UI stories only) design matches approved Subframe layout
4. Fix → verify → PASS
5. Save: context-snapshots/stories/{story-id}-phase-b.md
```

### Subframe + Theme Workflow (v10 — Sprint 0 검증 반영)

```
Subframe Setup (Sprint 0, 1회):
  1. npx @subframe/cli@latest init --auth-token {token} -p {projectId} \
       --dir ./src/ui --alias "@/ui/*" --tailwind --css-path src/index.css --install --sync
  2. 44개 컴포넌트 src/ui/components/에 sync됨
  3. UI는 반드시 Subframe 컴포넌트로 구현 (@/ui/components/* 필수 — 수동 React/Tailwind 금지)

UI Story Flow (오케스트레이터 주도):
  1. 오케스트레이터: Subframe MCP design_page → CEO에게 GATE (디자인 확인)
  2. 오케스트레이터: Subframe MCP get_page_info → 페이지 코드 추출
  3. 오케스트레이터: packages/admin/src/features/{page}.tsx 작성
     - @/ui/components/Button 등 Subframe 컴포넌트 직접 사용
     - 테마는 Subframe 디자인 토큰 사용 (brand-600, neutral-border 등)
     - CEO 5개 테마 전환: CSS 변수 오버라이드로 구현
  4. dev 에이전트: 비즈니스 로직 추가 (API 연결, 폼 검증, 라우팅)
  
  dev 에이전트는 Subframe MCP에 접근 불가 → 오케스트레이터가 직접 처리
  import 경로: @/ui/components/Button (tsconfig paths alias)
  컴포넌트 업데이트: npx @subframe/cli@latest sync Button TextField ...

Theme System:
  - CSS 변수 기반 테마 전환 (5개 테마: 벚꽃, Toss 라이트/다크, 라벤더 등)
  - Subframe 디자인 토큰과 호환
  - 새 테마 추가 = CSS 변수 세트 1개 추가

Sprint Zero GATE #17 (theme-select):
  - Sprint Zero 완료 후 CSS 변수 기반 후보 테마 5개 준비
  - CEO에게 dev 서버 또는 HTML 파일로 보여주기
  - CEO가 기본 테마 선택 → defaultTheme 설정
```

### Phase C: Simplify

```
No team needed. Orchestrator runs /simplify directly.
Timeout: 3 minutes. Skip on fail — code-review catches issues.
```

### Phase D: Test + QA (v10.1 — Phase E 통합)

```
Team: quinn(Writer), dev(Critic), winston(Critic), john(Critic) = 4
Reference: TEA risk-based test strategy + QA acceptance checklist

Phase D = 기존 Phase D (테스트 작성) + Phase E (QA 검증) 통합.
quinn이 Writer로 테스트 작성과 AC 검증을 한 Phase에서 수행.

오케스트레이터 MUST (v10.1):
  1. quinn을 Writer로 Agent 소환
  2. dev, winston, john을 Critic으로 Agent 소환 (3명 전부)
  3. quinn 작업 완료 후 SendMessage [Review Request]를 3명에게 전송
  4. Critic 3명의 로그 파일 존재 확인 후에만 PASS
  ★ pre-commit hook이 phase-d-dev.md, phase-d-winston.md, phase-d-john.md 검증
  ★ critic 로그 없으면 커밋 차단됨

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
3. quinn runs QA checklist against implemented code
4. quinn verifies ALL acceptance criteria from story file
5. Party mode: quinn sends [Review Request] to dev, winston, john BY NAME
   - dev: implementability, test framework compliance, code completeness
   - winston: architecture test coverage, boundary tests
   - john: acceptance criteria met? user value delivered?
   Critics write to: party-logs/story-{id}-phase-d-{critic-name}.md (필수)
   Critics include D1-D6 scores with rationale per dimension
6. Fix → verify → PASS
7. Run all tests — must pass
8. Save: context-snapshots/stories/{story-id}-phase-d.md
```

NOTE: Phase E is removed (v10.1). Pipeline order is now: A → B → C → D → F → Codex.

### Phase F: Code Review

```
Team: winston(Writer), quinn(Critic), dev(Critic), john(Critic) = 4
Reference: _bmad/bmm/workflows/4-implementation/code-review/checklist.md

오케스트레이터 MUST (v10.1):
  1. winston을 Writer로 Agent 소환
  2. quinn, dev, john을 Critic으로 Agent 소환 (3명 전부)
  3. winston 작업 완료 후 SendMessage [Review Request]를 3명에게 전송
  4. Critic 3명의 로그 파일 존재 확인 후에만 PASS
  ★ pre-commit hook이 phase-f-quinn.md, phase-f-dev.md, phase-f-john.md 검증
  ★ critic 로그 없으면 커밋 차단됨

1. winston reads all changed files + code-review checklist
2. winston performs architecture + security + quality review
   CONTRACT COMPLIANCE (v9.4): winston verifies all API types imported from contracts, not defined inline. Inline type = FAIL.
3. Party mode: winston sends [Review Request] to quinn, dev, john BY NAME
   - quinn: security patterns, test coverage, edge cases
   - dev: code conventions, performance, dependencies
   - john: product alignment, scope compliance
   Critics write to: party-logs/story-{id}-phase-f-{critic-name}.md (필수)
   Critics include D1-D6 scores with rationale per dimension
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

### Sprint End GATE #19: Visual Verification (v9.5)

```
After ALL stories in a sprint are complete:
1. Start dev servers (backend + frontend)
2. Send [GATE visual-verify] to Orchestrator
3. Orchestrator tells CEO: "Sprint N 완료! 브라우저에서 확인해주세요"
   - CEO's local: git pull → bun install → bun run dev
   - Or: provide URL if VPS port is open
4. CEO checks in browser → approves or requests changes
5. If changes needed → create fix stories, repeat
6. If approved → proceed to next sprint
```

### Developer Writer Prompt Template (Phase A/B)

```
You are dev in team "{team_name}". Model: sonnet. YOLO mode.

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
Story Dev completion checklist (v10.1 — Phase E merged into D):
  [ ] Phase A: create-story + party review PASS
  [ ] Phase B: dev-story (real code, no stubs) + party review PASS
  [ ] Phase C: simplify completed
  [ ] Phase D: TEA tests + QA acceptance criteria + party review PASS + tests passing
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
| max_retry (Grade A) | reasonable attempts | Orchestrator judgment → ESCALATE when progress stalls |
| max_retry (Grade B) | reasonable attempts | Orchestrator judgment → ESCALATE when progress stalls |
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
17. **Scoring rubric mandatory.** Critics use `_bmad-output/planning-artifacts/critic-rubric.md` — 6 dimensions (D1-D6, /4 scale → /10 conversion), Grade A: ≥8.0/10, Grade B: ≥7.5/10, any dim <3 auto-fail.
18. **`계속` = run to completion.** Do NOT stop at intermediate milestones (except GATE steps).
19. **Batch parallelism.** Independent files needing similar changes → split into batches, launch background agents.
20. **Startup cleanup.** Clean stale worktrees/panes/dirs. Shutdown: clean all resources.
21. **EARS for requirements, Gherkin for tests.** All functional requirements use EARS syntax (THE SYSTEM SHALL...). Acceptance criteria use Gherkin (Given/When/Then). Both coexist.
22. **Contract types are single source of truth.** API types defined in Contract Stage (6.5). Story dev imports from contracts, never defines inline. Type changes require contract update FIRST, tsc pass, then implementation.
23. **Wiring stories mandatory for cross-package connections.** If a story creates a component consumed by another package, a wiring story must exist. Skip only for same-directory connections.
24. **Integration gate before story completion.** ALL tsc commands run (cross-package), not just the changed package. Import chains verified. Contract compliance checked.
25. **Codex second opinion mandatory (Phase B.5).** After 3-critic party review PASS, run Codex (GPT-5.4) in tmux. 1 run + max 1 re-run. Context-irrelevant findings may be self-skipped (record reason). Codex FAIL blocks commit. See kdh-sprint Phase B.5 for details.
26. **Sprint mode (kdh-sprint absorbed).** `sprint N` argument runs full sprint orchestration: TeamCreate → story loop (build→review→Codex→commit) → batch integration → sprint integration → E2E → GATE. kdh-sprint skill is deprecated; its logic lives here.
27. **Context judgment autonomy.** Orchestrator makes obvious technical decisions autonomously (REST vs RPC, DB structure, code patterns). Only ask CEO about feature meaning/intent/direction. Codex findings clearly irrelevant to project context may be self-skipped with recorded reason.
28. **Batch integration review.** Every 3 completed stories (or last batch in sprint), run kdh-integration batch with Codex. Cross-dependency, middleware consistency, env var sync. PASS until Codex PASS.
29. **Agent prompts include kdh-build rules verbatim.** When spawning dev agents, include kdh-build SKILL.md rules as full text in prompt, never summarized. Missing rules = CEO deletes code.
30. **pipeline-state.yaml은 항상 멀티라인 (v10.1).** 인라인 YAML `{ key: value }` 금지. pre-commit hook이 yq 우선 + sed 폴백으로 파싱하지만, 멀티라인이 가장 안전. 예: `phase_d:\n  status: pass\n  tests: 87` (O), `phase_d: { status: pass, tests: 87 }` (X).
31. **Phase D/F critic 로그 필수 (v10.1).** Phase D: quinn(Writer) + dev/winston/john(Critics) 4개 로그. Phase F: winston(Writer) + quinn/dev/john(Critics) 4개 로그. pre-commit hook이 파일 존재 검증. critic 로그 없으면 커밋 차단.
32. **Cross-talk 고정 쌍 (v10.1).** Story Dev 3인 critic: winston↔quinn, quinn↔john, john↔winston. 각 critic 로그에 `## Cross-talk` 섹션 + 최소 3줄 필수. pre-commit hook이 WARNING 발생.
33. **Planning DA (v10.2).** Stage 6 완료 후 Stage 6.1에서 quinn이 모든 FR의 사용자 여정을 추적. FR→UI요소→Story→AC 각 단계에서 빈 셀 = BLOCK. 최소 3개 갭 강제 발견.
34. **UX App Chrome Checklist (v10.2).** Stage 5 완료 전 sally가 반드시 정의: 로그아웃 버튼 위치, 로딩 상태, 에러 표시 위치, 세션 만료 흐름, 빈 상태, 사용자 계정 메뉴. 빠지면 Stage 5 PASS 불가.
35. **FR-to-UI Traceability Matrix (v10.2).** Stage 7에서 tech-writer가 모든 FR에 대해 PRD→UX→Story→AC 매핑 검증. 빈 셀 = Sprint Planning 진행 불가.
36. **Phase A UI Existence Check (v10.2).** quinn이 스토리의 모든 UI 참조를 검증: "이 버튼/페이지가 다른 스토리 또는 UX 스펙에 정의되어 있는가?" 없으면 auto-FAIL.
