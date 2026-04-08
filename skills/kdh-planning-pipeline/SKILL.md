---
name: 'kdh-planning-pipeline'
description: 'Planning Pipeline — BMAD 9 Stages (Brief→PRD→Arch→UX→Epics→Contracts→Sprint Planning). Stage-Batch Party Mode + GATE Protocol. 사장님 명령어: /kdh-planning-pipeline [auto|계속]'
---

# Universal Full Pipeline v10

## Mode Selection

- **no args** 또는 **`auto`**: 상태 자동 감지 → 다음 할 일 판단 → 실행 (kdh-go 흡수)

## Phase Directory Convention (v10.8)

`_bmad-output/`는 Phase별로 폴더를 분리한다. 나중에 버그 추적 시 해당 Phase 문서를 바로 찾기 위함.

```
_bmad-output/
├── phase-1/                        # Phase 1 archive (complete)
│   ├── planning-artifacts/         # PRD, architecture, epics, etc.
│   ├── party-logs/                 # Phase 1 party logs
│   ├── compliance/                 # Phase 1 compliance YAMLs
│   ├── context-snapshots/          # Phase 1 snapshots
│   ├── implementation-artifacts/   # Sprint status, story guides
│   ├── e2e-screenshots/           # Phase 1 E2E screenshots
│   └── pipeline-audit/            # Phase 1 audit logs
├── phase-{N}/                      # Active phase (same structure)
│   ├── planning-artifacts/
│   ├── party-logs/
│   ├── compliance/
│   ├── context-snapshots/
│   │   ├── planning/
│   │   └── stories/
│   ├── implementation-artifacts/
│   └── e2e-screenshots/
├── bug-fix/                        # Bug fix pipeline (cross-phase)
├── critic-rubric.md                # Shared — all phases use same rubric
├── design-references.md            # Shared design references
├── pipeline-state.yaml             # Global state (current_phase_number here)
├── update-log/                     # Daily logs (cross-phase)
├── daily-briefings/                # Cross-phase
├── ecc-logs/                       # Cross-phase
└── evolve-candidates/              # Cross-phase
```

**경로 규칙:**
- 이 문서의 모든 `_bmad-output/planning-artifacts/` 등의 경로는 `_bmad-output/phase-{N}/planning-artifacts/`로 읽는다
- `N` = `pipeline-state.yaml`의 `current_phase_number` 값
- Phase 완료 시: 해당 폴더 그대로 유지 (archive). 삭제/이동 금지.
- 새 Phase 시작 시: 빈 폴더 구조 자동 생성 (`mkdir -p`)
- bug-fix/, update-log/, ecc-logs/, daily-briefings/ 등은 cross-phase → top level 유지
- critic-rubric.md, design-references.md, v2 참고 문서는 top level (shared)
- 이전 Phase 문서 참조 가능: `_bmad-output/phase-1/planning-artifacts/prd.md` 등

---


## Step -1 (ALL Modes): Tool Readiness Check — 초장 검증

**파이프라인 시작 전 필수 도구 전부 검증. 하나라도 안 되면 즉시 중지. 자동 복구/fallback 없음.**

```
1. Codex CLI:
   - `which codex` → 설치 확인
   - `codex --version` → 버전 확인
   - 안 되면 → 🚩 BLOCK. 멈춰. CEO 보고. 설치 시도 하지 마.

2. Codex 인증:
   - `codex exec "echo hello"` → 실제 응답 확인
   - 안 되면 → 🚩 BLOCK. 멈춰. CEO 보고. 자동 로그인 하지 마.

3. Subframe MCP (IF project-context.yaml ui.components == 'subframe'):
   - ★ ui.components가 subframe일 때만 체크. 아니면 스킵.
   - ToolSearch로 subframe 도구 검색
   - `mcp__plugin_subframe_subframe__authenticate`만 보이면 = 미인증 → 🚩 BLOCK
   - `mcp__plugin_subframe_subframe__design_page` 등 실제 도구가 보여야 = ✅
   - 안 되면 → 🚩 BLOCK. 멈춰. CEO에게 "Subframe 브라우저 인증 필요" 보고.
   - ★ "지금 Stage에서 안 쓰니까 WARNING만" 같은 예외 없음. 초장에 안 되면 멈춤.

4. Helper Script:
   - `test -x ~/.claude/scripts/codex-review.sh` → 실행 권한 확인
   - 안 되면 → 🚩 BLOCK.

5. design-references.md:
   - `test -f _bmad-output/design-references.md` → 5개 테마 URL 존재 확인
   - 안 되면 → ⚠️ WARNING (BLOCK 아님)

출력:
  ✅/🚩 Codex CLI: [버전 or FAIL]
  ✅/🚩 Codex 인증: [OK or FAIL]
  ✅/🚩 Subframe MCP: [연결됨 or 미인증]
  ✅/🚩 Helper script: [OK or FAIL]
  ✅/⚠️ Design references: [OK or MISSING]

판정:
  → 🚩 0개 → Step 0 진행
  → 🚩 1개라도 → **즉시 중지. 파이프라인 시작하지 않음.**
     CEO에게 뭐가 안 되는지 보고 → 문제 해결될 때까지 대기.
     자동 설치/자동 로그인/자동 복구 시도 금지.
     "나중에 쓰니까 지금은 넘어가자" 금지.
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

## Step 0.5: Read Active Plans

파이프라인 시작 후, Step 0 완료 후, 첫 Stage 진입 전에 실행.

```
1. _bmad-output/kdh-plans/_index.yaml 읽기
   - 파일 없으면 → 스킵 (plan 없이 진행 OK)

2. status: active 필터링

3. 현재 작업과 매칭:
   - pipeline: "planning" 또는 "all"인 것만
   - scope: 현재 Stage/Phase와 관련된 것만

4. 매칭된 plan 본문 읽기 (Read tool)

5. plan 맥락을 보유하고 실행 시작:
   - plan은 "맥락 제공자" — SKILL.md의 절차/Stage 순서를 override하지 않음
   - plan에 CEO 결정이 있으면 → 해당 결정 따름 (GATE 자동 통과)

★ plan 읽기는 _index.yaml이 없을 때만 스킵. 있으면 active plan 필수 읽기.
★ plan 내용과 SKILL.md 충돌 시: SKILL.md = 절차, plan = 내용. 영역이 다름.
```

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
| Critics — Grade A (Planning) | opus | winston(Arch) + quinn(QA) + john(PM), 3명 병렬. DA = fresh instance (기존 3명 겸임 금지) |
| Critics — Grade B (Planning) | sonnet | winston + quinn + john, 3명. 일괄 리뷰 |
| Critics — Grade A (Sprint Dev) | opus | 기존 유지 (3명) |
| Critics — Grade B (Sprint Dev) | sonnet | 기존 유지 (3명) |
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

## Party Mode Protocol v10.4 (Stage-Batch)

**v10.4 변경 (CEO 승인 2026-04-03):** 기존 "step당 party mode"에서 "stage 일괄 작성 + 일괄 리뷰"로 전환.
근거: Stage 0~2 회고 결과, step당 7~12회 agent spawn이 오케스트레이터 병목 유발. Stage 2에서 일괄 처리가 품질+속도 모두 우수했음.

### Grade C Steps: Writer Solo (변경 없음)
init, complete 등 Grade C steps는 오케스트레이터가 직접 처리.

### Planning Stage 실행 흐름 (v10.4)

```
Phase A: Stage Worker가 전체 steps 작성 (spawn 1회)
  - BMAD step file 순서대로 읽고 → output doc에 APPEND
  - frontmatter stepsCompleted 매 step 업데이트
  - GATE steps 도달 시: [GATE] 마크 → 오케스트레이터가 CEO에게 전달
  - 완료 후 SendMessage [Stage Draft Complete]

Phase B: 병렬 독립 리뷰 (spawn 3회, 한 메시지로 동시)
  - winston(Arch, opus): 아키텍처 정합성, 스키마 정확성, 일관성
  - quinn(QA, opus for A / sonnet for B): 테스트 가능성, 보안, 에지 케이스, EARS 준수
  - john(PM, opus for A / sonnet for B): 제품 요구사항 커버리지, AC 추적, 사용자 가치
  - 각자 party-log 작성 (D1-D6 scoring, 전문 영역 집중)
  - ★ 리뷰 중 서로 대화 없음 (독립성 보장 = 편향 방지)
  - 각 critic은 자기 전문 영역만 집중, 전체를 다 보지 않음

Phase C: 상호 검증 — Cross-Validation (spawn 추가 없음)
  - 각 critic이 다른 2명의 party-log 파일을 Read tool로 읽기
  - 자신의 party-log에 "## Cross-Validation" 섹션 추가:
    - 동의하는 발견 1개 (구체적 근거 + 라인 참조)
    - 반박하는 발견 1개 (구체적 근거 + 대안)
  - ★ 파일 기반 — SendMessage 불필요, 오케스트레이터 중계 불필요

Phase D: 오케스트레이터 후처리 (spawn 0)
  - 3개 party-log 읽기 → 이슈 우선순위 정리
  - Score 계산: avg >= threshold?
  - FAIL: fixes 목록 작성 → Stage Worker에게 전달 (SendMessage)
    → Stage Worker fixes 적용 → Phase B 반복 (max retries: Grade A=2, Grade B=1)
  - PASS: Phase E로 (Grade A) 또는 Phase F로 (Grade B)
  ★ Planning Grade A 1-cycle 예외: Cycle 1 avg ≥ 8.0 PASS 시, Cycle 2 스킵하고 Phase E(DA)로 바로 진행 가능.
    단, compliance YAML에 `single_cycle_pass: true` + `ceo_approved: [날짜]` 기록 필수.
    Sprint Dev에는 적용 안 됨 — Sprint Dev Grade A는 무조건 2 cycles.

Phase E: DA — Grade A만 (spawn 1회, ★ FRESH INSTANCE 필수)
  - ★ 기존 3명(winston/quinn/john) 중 아무도 아닌 완전히 새로운 에이전트
  - ★ 이전 리뷰 결과 접근 금지 (party-log 읽기 금지)
  - PRD EARS 요구사항 + DoD 기준으로만 검증
  - ≥3 이슈 필수 (0 이슈 = suspicious, 오케스트레이터 직접 리뷰)
  - DA fixes → Stage Worker 적용

Phase F: 최종 검증 + 커밋 (spawn 0)
  오케스트레이터 직접 파일 확인 (Grep + Read):
  - [ ] 모든 steps의 content가 output doc에 존재
  - [ ] frontmatter stepsCompleted 완전
  - [ ] 3개 party-log 존재 (winston, quinn, john)
  - [ ] 각 party-log에 ## Cross-Validation 섹션 존재
  - [ ] Grade A: DA 파일 존재 (≥3 이슈)
  - [ ] fixes.md 존재
  - [ ] avg >= threshold (A: 8.0, B: 7.5)
  - [ ] GATE decisions 기록됨
  - [ ] Context snapshot 저장됨
  - [ ] Compliance YAML 작성됨
  - [ ] Compliance YAML: DA 관련 필드 존재 (DA 파일 or `da_skipped: true` + `da_skip_reason`)
  - [ ] Compliance YAML: Stage trajectory 기록됨 (`fixes_rounds`, `critic_agreement_rate`, `da_unique_issues`, `bias_flag`)
  - [ ] 연속 Stage 위반 체크: 직전 Stage에 violation 있었으면 + 이번 Stage도 violation → CEO 보고 필수
  Stage commit message format: `docs(planning): Stage N complete — avg X.XX, fixes N rounds, agreement N/3`
  → 모든 체크 통과 → git commit → 다음 Stage
  → 하나라도 실패 → REJECT (조건부 PASS 금지)
```

### Spawn 수 비교

| Grade | v10.3 (per-step) | v10.4 (per-stage) | 감소 |
|-------|-----------------|-------------------|------|
| C | 0 | 0 | — |
| B (6 steps) | 6×7=42 | 1+3+1=5 | 88% |
| A (4 steps) | 4×12=48 | 1+3+3+1+1=9 | 81% |

### 절대 규칙 (v10.4 추가)

37. **조건부 PASS 금지.** avg < threshold = FAIL. "다음 Stage에서 해결" 미루기 금지. 해당 Stage에서 해결 or ESCALATE.
38. **DA는 반드시 fresh instance.** 기존 critic(winston/quinn/john) 겸임 금지. 이전 리뷰 맥락 0인 새 에이전트만. (출처: Metaswarm adversarial reviewer invariant). DA 미실행 시 compliance YAML에 `da_skipped: true` + `da_skip_reason` 필수 기록. 미기록 = Rule 위반.
39. **Cross-Validation은 독립 리뷰 후.** 리뷰 중 대화(cross-talk) 금지. 독립 리뷰 완료 → 파일 기반 상호 검증.
40. **Critic 전문 영역 집중.** "전체를 리뷰하라"가 아니라 각자 담당 영역만. winston=아키텍처, quinn=QA/보안, john=제품/요구사항.

### GATE Steps (변경 없음)
Business GATE: 오케스트레이터가 CEO에게 preset gate.language로 질문 → CEO 응답 대기.
Technical GATE: 자동 통과 + 기록.

### 기존 Party Mode Protocol (v10.3, Sprint Dev용)
Sprint Dev(Story 단위) 실행 시에는 기존 per-step 프로토콜 유지.
Planning(Stage 단위)만 v10.4 적용.

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
3. Orchestrator presents to user (preset gate.language, 기술 용어 금지):
   - Summary of what was written
   - Options with pros/cons
   - Clear question: "어떻게 할까요? A/B/C 또는 수정사항?"
   - Format: 번호 목차 필수 (I. II. III. 또는 1. 2. 3.), 비유/은유 최소화, 직접 설명. Stage 완료 보고도 동일 형식.
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

## Anti-Patterns (v9.1 — production failures)

1. **Writer calls Skill tool** — Skill auto-completes all steps internally, bypasses critic review. FIX: Writer MUST NEVER use Skill tool. Read step files with Read tool, write manually.
2. **Writer batches steps** — Writes steps 2-6 then sends one review. FIX: Write ONE step → party mode → THEN next step.
3. **Agent spawned with generic name** — `critic-a` or `worker-1` instead of BMAD name. FIX: ALWAYS use real names from BMAD Agent Roster.
4. **Critic skips persona file** — Reviews without reading `_bmad/bmm/agents/*.md`. FIX: First action MUST be Read persona file.
5. **GATE step auto-proceeds** — Writer skips user input on GATE step. FIX: GATE steps MUST send [GATE] to Orchestrator and WAIT.
6. **Shutdown-then-cancel race** — shutdown_request is irreversible. FIX: NEVER send unless 100% committed.
7. **Writer duplicates prior step content** (v9.1) — Writer copies risk/requirement tables that already exist in earlier steps. FIX: Before writing, Writer MUST Read prior steps' sections on the same topic. If content exists, use `§{section_name} 참조` cross-reference instead of duplicating. (Incident: Step 06/08 risk tables had 6 duplicate entries.)
8. **Score convergence inflation** (v9.1) — All critics give identical scores after fixes (e.g., unanimous 9.00). FIX: Orchestrator checks score standard deviation; if stdev < 0.3, triggers independent re-scoring warning. Additionally: if all 3 critics' scores increase by ≥1.0 in the same direction after fixes, Orchestrator flags potential self-enhancement bias (ref: PoLL study — models favor own output by 10-25%). Phase D records `bias_flag: true/false` in compliance YAML. (Incident: Step 08 all 4 critics scored exactly 9.00.)
9. **Missing party-log files** (v9.1) — Critic reviews sent via message only, no file written. FIX: Orchestrator verifies all `party-logs/{stage}-{step}-{critic-name}.md` files exist before accepting [Step Complete]. Missing file = REJECT. (Incident: Step 02-05 had only winston's logs.)
10. **Single-cycle rubber stamp** (v9.2) — All critics score 8.5+ on first review, no retry triggered, issues slip through. FIX: Grade A requires MINIMUM 2 cycles regardless of scores. Cycle 2 uses Devil's Advocate mode (1 critic MUST find ≥ 3 issues). (Incident: Stage 2 Step 06-10 all passed with 9.0+ on first cycle, zero retries across 5 steps.)
11. **Cross-talk skipped** (v9.2) — Critics review independently but never discuss with each other. FIX: Cross-talk is MANDATORY. Each critic log MUST contain "## Cross-talk" section documenting peer discussion. Orchestrator rejects logs without this section. (Incident: Stage 0-3 had zero cross-talk across all steps.)
12. **Orchestrator skips own checklist** (v9.2) — Rules exist but Orchestrator doesn't follow them. FIX: Step Completion Checklist (v9.2) is BLOCKING — Orchestrator must verify every checkbox before accepting. Pre-commit hook validates party-log file completeness. (Incident: Stage 2 Step 02-05 accepted with only 1/4 critic logs.)
13. **Inline API type duplication** (v9.4) — Frontend defines response types locally instead of importing from shared contracts. Causes silent type drift when backend changes shape. FIX: Phase F winston checks contract compliance. Inline types matching contract shapes = auto-FAIL. (Incident: 29 integration bugs from 167 stories, all type mismatches.)
14. **Missing wiring** (v9.4) — Story creates store/endpoint but never connects to consumer. Feature works in unit tests but unreachable at runtime. FIX: Wiring stories auto-generated in Stage 6. Integration verification in Phase D TEA. (Incident: ws-store created but connect() never called from Layout.)
15. **Consecutive 1-cycle exceptions** (v10.5) — Two or more consecutive Grade A stages using single_cycle_pass. Indicates systemic pressure to rush rather than isolated efficiency. FIX: If Stage N used 1-cycle pass, Stage N+1 MUST run full 2 cycles regardless of scores. Orchestrator checks prior stage compliance YAML before allowing 1-cycle. Reference: Phase D line 331 exception rule — this anti-pattern adds a consecutive-use guard, not a repeal. (Incident: Phase 2 Stage 5 + Stage 6 both used 1-cycle, avg 8.17/8.07 — barely passing.)
16. **DA skip without compliance record** (v10.5) — DA skipped but compliance YAML missing `da_skipped: true` and `da_skip_reason`. Without record, the skip is invisible to future audits. FIX: Phase F checklist verifies compliance YAML contains DA fields when no DA file exists. Missing DA record = REJECT. (Incident: Phase 2 Stage 6.5 DA skipped, zero compliance record written.)

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
- IF 프로젝트에 v2 audit 파일이 있으면 참조 (예: `_bmad-output/planning-artifacts/v2-*-audit.md`)
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

Source routing guidance (ref: kdh-research v3):
- Library/framework topics → Context7 MCP first, WebSearch second
- Code implementation patterns → GitHub search first (`gh search repos`)
- General best practices → WebSearch first
- Each source evaluated with 3-question credibility (type, recency, evidence)
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

## Pipeline Interconnection (v10.5)

### Planning → Dev (Sprint 시작 신호)
Stage 8 Sprint Planning 완료 후:
1. sprint-status.yaml 생성 → `_bmad-output/phase-{N}/planning-artifacts/`
2. pipeline-state.yaml에 `mode: sprint` 설정
3. Dev 파이프라인이 pipeline-state.yaml 읽고 Sprint 시작

★ Planning이 dev를 직접 호출하지 않음 — pipeline-state.yaml이 신호.

### Bugfix → Planning (requirements 에스컬레이션 수신)
bug-fix-state.yaml에서 `escalation: planning-pipeline` + `escalation_status: pending` 발견 시:
1. CEO 확인 후 해당 Stage(주로 Stage 2 PRD 또는 Stage 4 Architecture) 재검토
2. 수정된 산출물 → Dev에 영향 스토리 재개발 신호

참조: `_bmad-output/pipeline-protocol.md`

