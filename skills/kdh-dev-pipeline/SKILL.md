---
name: 'kdh-dev-pipeline'
description: 'Dev Pipeline — Sprint 실행 (Story Loop + Party Mode + Integration + E2E + Codex). 사장님 명령어: /kdh-dev-pipeline [sprint N|story-ID|계속|parallel ID1 ID2]'
---

# Dev Pipeline

Sprint 실행 파이프라인. 스토리별 개발 + 리뷰 + 테스트 + E2E + Codex + 통합 검증.

## Mode Selection

- **`sprint N`**: Sprint N 실행 — 스토리 루프
- **`계속`**: 밤새 모드 — GATE 자동 통과, 3 stories/session 분할
- **Story ID** (e.g. `3-1`): 단일 스토리 개발
- **`parallel ID1 ID2 ...`**: Git Worktree 병렬 개발 (max 3)

### `계속` 모드 (밤새 자동)

```
1. GATE → 자동 통과 ([AUTO] 표시)
2. FAIL 스토리 → 1회 재시도 → SKIP + 기록
3. ★ Codex FAIL은 자동 진행 금지
4. ★ 3 stories마다 save-session + 새 세션 (v4.0)
```

### Ralph Loop (밤샘 최안정)
```bash
while true; do claude -p "/kdh-dev-pipeline 계속"; sleep 5; done
```

### 보고 형식 (preset gate.language)
```
시작:    "Sprint {N} 이어서 합니다. 스토리 {M}개 남았어요."
스토리:  "스토리 {id} 완료. 리뷰 평균: {X.X}/10. ({N}/{M} 진행)"
Sprint:  "Sprint {N} 끝! 브라우저에서 확인해주세요."
```

---

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

2b. Gemini CLI (병렬 리뷰 필수):
   - `which gemini` → 설치 확인
   - `gemini -p "echo hello"` → 응답 확인
   - 안 되면 → 🚩 BLOCK. 멈춰. CEO 보고.

3. UI Design System (project-context.yaml `ui.components` 기반):
   - IF `ui.components == "shadcn"`:
     → shadcn/ui 사용. MCP 체크 불필요. ✅ 자동 통과.
   - IF `ui.components == "subframe"`:
     → ToolSearch로 subframe 도구 검색 → 미인증이면 🚩 BLOCK
   - IF 비어있으면:
     → ⚠️ WARNING. UI 컴포넌트 라이브러리 미설정.

4. Helper Script:
   - `test -x ~/.claude/scripts/codex-review.sh` → 실행 권한 확인
   - 안 되면 → 🚩 BLOCK.

5. design-references.md:
   - `test -f _bmad-output/design-references.md` → 5개 테마 URL 존재 확인
   - 안 되면 → ⚠️ WARNING (BLOCK 아님)

출력:
  ✅/🚩 Codex CLI: [버전 or FAIL]
  ✅/🚩 Codex 인증: [OK or FAIL]
  ✅/🚩 UI Design System: [shadcn ✅ | subframe 연결됨 | 미설정]
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

파이프라인 시작 후, Step 0 완료 후, 첫 Phase 진입 전에 실행.

```
1. _bmad-output/kdh-plans/_index.yaml 읽기
   - 파일 없으면 → 스킵 (plan 없이 진행 OK)

2. status: active 필터링

3. 현재 작업과 매칭:
   - pipeline: "dev" 또는 "all"인 것만
   - scope: 현재 Sprint/Story와 관련된 것만
     예: sprint 2 실행 중 → scope "sprint-2" 또는 "all" 매칭
     예: story 2-2 실행 중 → scope "story-2-2" 또는 "sprint-2" 매칭

4. 매칭된 plan 본문 읽기 (Read tool)
   - plan이 2개 이상이면 → 전부 읽되, 가장 최신 것 우선

5. plan 맥락을 보유하고 실행 시작:
   - plan은 "맥락 제공자" — SKILL.md의 절차/Phase 순서를 override하지 않음
   - plan에 구체적 구현 지시가 있으면 → Phase A에서 구현 계획에 반영
   - plan에 CEO 결정이 있으면 → 해당 결정 따름 (GATE 자동 통과)

★ plan 읽기는 _index.yaml이 없을 때만 스킵. 있으면 active plan 필수 읽기.
★ plan 내용과 SKILL.md 충돌 시: SKILL.md = 절차, plan = 내용. 영역이 다름.
```

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

**MANDATORY party-log rule (v4.4):**
Critics MUST write their review to a party-log FILE using the Write tool BEFORE sending SendMessage.
Path: `_bmad-output/phase-{N}/party-logs/story-{id}-phase-{phase}-{critic-name}.md`
Include: D1-D6 scores with rationale, referenced file paths from the diff, inline code quotes (`backticks`), verdict.
Minimum: 1500B, 20+ lines, 3+ D-score references, 2+ code quotes.
SendMessage는 party-log 파일 경로만 전달. 리뷰 내용은 파일에.
오케스트레이터가 직접 party-log를 작성하면 = 기만 행위. 절대 금지.

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
| Gemini (second opinion) | Gemini 3.1 Pro | Parallel with Codex, additional perspective |

**haiku 절대 금지 (CEO 규칙).**

### Step Grades (retry limits only)

| Grade | Max Retries | When |
|-------|-------------|------|
| **A** (critical) | 3 | Core decisions, functional/nonfunctional reqs, architecture patterns |
| **B** (important) | 2 | Most content steps |
| **C** (setup) | 1 | init, complete, routine validation |

**Grade C = Writer Solo.** Grade C steps (init, complete) skip party mode entirely. Writer executes alone, no critic review needed. This saves agent resources on routine steps.

---

---
## Story Dev Pipeline

### Key Change (C안 — v11.0)
OLD: 7 phases (A→B→C→D→E→F→Codex), browser verification per story.
NEW: 4 phases (A→B→D→Codex). Browser verification → bug-fix pipeline at Sprint End.

### Phase 책임 이관표
| 삭제된 Phase | 원래 역할 | 이관 위치 |
|-------------|----------|----------|
| Phase C (simplify) | 코드 간소화 | Phase B 리뷰에서 흡수 (Sprint 1: 기여 0) |
| Phase E (browser E2E) | Playwright + browser-use | /kdh-bug-fix-pipeline (Sprint End) |
| Phase F (code review) | 최종 코드 리뷰 | Phase B 리뷰에서 흡수 (Sprint 1: 추가 발견 0건) |

### Orchestrator Flow

```
Step 0: Project Auto-Scan → load project-context.yaml
Step 1: TeamCreate("{project}-story-{id}")
Step 2: Spawn base team: dev(Writer), winston, quinn, john (4 agents, bypassPermissions)
Step 3: Execute Phase A → B → D → Codex
  - Between phases: save context-snapshot, team continues (no recreation)
  - Phase D: team rotation (quinn Writer, dev+winston critics)
Step 4: bun test + tsc → Verify completion checklist → commit + push
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

   === REFERENCE CODE SEARCH (v10.9 — CEO 지시 2026-04-05) ===
   1d. dev searches for reference implementations BEFORE writing new code:
     i.   gh search repos "{story 핵심 기술 키워드}" --sort=stars --limit=5
     ii.  gh search code "{핵심 패턴/함수명}" --limit=10
     iii. npm/PyPI에서 관련 라이브러리 확인 (검증된 라이브러리가 80%+ 해결하면 직접 구현 대신 사용)
     iv.  참고 코드 발견 시 → party-log에 "## Reference Code" 섹션 기록 (URL + 채택/기각 사유)
     v.   검색 결과 0건이어도 기록 ("searched: {query}, result: none" — 검색했다는 증거)
     ★ "먼저 찾아보고, 있으면 검토" — 새로 짜는 건 검색 후 판단
     ★ 기각 시 사유 필수 (예: "라이선스 비호환", "의존성 과다", "우리 패턴과 불일치")
     Source routing (ref: kdh-research v3):
     - Library/framework topics → Context7 MCP first, WebSearch second
     - Code implementation patterns → GitHub search first (`gh search repos`)
     - General best practices → WebSearch first
     - Each source evaluated with 3-question credibility (type, recency, evidence)

   === UI STORY GATE (v11 — 오케스트레이터 주도) ===
   1c. Check: does this story create or modify UI pages? (*.tsx in features/)
       If YES → UI Design Gate:
         i.   오케스트레이터: 프로젝트 UI 컴포넌트 라이브러리(shadcn/ui 등)로 페이지 레이아웃 작성
         ii.  오케스트레이터: ui-design.md 저장 (party-logs/story-{id}-ui-design.md)
         iii. 오케스트레이터: [GATE page-design] → CEO 디자인 승인
         iv.  dev 에이전트: 승인된 레이아웃 위에 비즈니스 로직 구현 (API 연결, 폼 검증)
       If NO → skip to step 2

2. dev implements REAL working code (no stubs/mocks/placeholders)
   2b. UI stories: apply active theme from themes.ts, use consistent layout from ui-design.md reference
3. Party mode: dev sends [Review Request] with changed files list
   - winston: architecture compliance, contract compliance, 전체 코드베이스 패턴 일관성 (타입, API 호출 방식, 미들웨어)
   - quinn: code quality, error handling, test hooks
   - john: acceptance criteria 충족, 사용자 경험 갭, 제품 수준 품질 (에러 메시지, 상태 유실, UX 흐름)
   - sally: (UI stories only) design matches approved ui-design.md layout
   Critics MUST write to FILE first: party-logs/story-{id}-phase-b-{critic-name}.md (v4.4 필수)
   Then SendMessage with file path only. 리뷰 내용은 파일에.
   Critics include D1-D6 scores with rationale per dimension, diff file paths, inline code quotes
4. Fix → verify → PASS
5. Save: context-snapshots/stories/{story-id}-phase-b.md
```

### UI Component + Theme Workflow (conditional on project-context.yaml)

```
IF ui.components == "shadcn":

  shadcn/ui Setup (Sprint 0 또는 Phase 3 Sprint 1):
    1. npx shadcn@latest init (Tailwind CSS + CSS variables 설정)
    2. npx shadcn@latest add button card dialog input ... (필요한 컴포넌트 설치)
    3. 컴포넌트는 src/components/ui/ 에 copy-paste (코드 소유)
    4. import 경로: @/components/ui/button (tsconfig paths alias)

  UI Story Flow (오케스트레이터 주도):
    1. 오케스트레이터: shadcn/ui + Tailwind로 페이지 레이아웃 작성
    2. 오케스트레이터: ui-design.md 저장 → CEO에게 GATE (디자인 확인)
    3. 오케스트레이터: {admin_package_path}/src/features/{page}.tsx 작성
       - @/components/ui/* shadcn 컴포넌트 사용
       - CSS variable 기반 테마 토큰 사용 (--primary, --background 등)
       - 5개 테마 전환: body 클래스 변경으로 구현
    4. dev 에이전트: 비즈니스 로직 추가 (API 연결, 폼 검증, 라우팅)

  Theme System:
    - CSS 변수 기반 테마 전환 (:root + .theme-{name} 클래스)
    - Semantic tokens: --primary, --background, --foreground, --border, --accent
    - 새 테마 추가 = CSS 변수 세트 1개 추가
    - tweakcn.com 으로 초기 테마 생성 가능

  Storybook (Phase 3):
    - Phase 3 Sprint 1: 핵심 15개 컴포넌트 story 작성 (재진입 트리거)
    - Phase 3 전체: Storybook 전체 도입
    - ★ 재진입 조건: Phase 3 Sprint 1 시작 시 필수. 미루기 금지.

  Sprint Zero GATE #17 (theme-select):
    - Sprint Zero 완료 후 CSS 변수 기반 후보 테마 5개 준비
    - CEO에게 dev 서버 또는 HTML 파일로 보여주기
    - CEO가 기본 테마 선택 → defaultTheme 설정

ELSE:
  Use project's component library. Theme system from project preset.
```

### Phase D: Test + QA (v10.1 — Phase E 통합)

```
Team: quinn(Writer), dev(Critic), winston(Critic), john(Critic) = 4. UI stories: +sally(Critic) = 5
Reference: TEA risk-based test strategy + QA acceptance checklist

Phase D = 기존 Phase D (테스트 작성) + Phase E (QA 검증) 통합.
quinn이 Writer로 테스트 작성과 AC 검증을 한 Phase에서 수행.
sally (UI stories only): 상호작용 흐름 자연스러움, 접근성, UX 시나리오 커버리지. john=요구사항 충족, sally=UX 품질 (비중복).

오케스트레이터 MUST (v11.0):
  1. quinn을 Writer로 Agent 소환
  2. dev, winston, john을 Critic으로 Agent 소환 (3명 전부)
  3. quinn 작업 완료 후 SendMessage [Review Request]를 3명에게 전송
  4. Critic 3명의 로그 파일 존재 확인 후에만 PASS
  ★ pre-commit hook이 phase-d-winston.md, phase-d-quinn.md 검증
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
   - john: acceptance criteria met? user value delivered? 제품 수준 검증
   Critics MUST write to FILE first: party-logs/story-{id}-phase-d-{critic-name}.md (v4.4 필수)
   Then SendMessage with file path only. 리뷰 내용은 파일에.
   Critics include D1-D6 scores with rationale per dimension, diff file paths, inline code quotes
6. Fix → verify → PASS
7. Run all tests — must pass
8. Save: context-snapshots/stories/{story-id}-phase-d.md
```

### Cross-Model Verification (Codex + Gemini)

```
Phase D PASS 후 실행. 에이전트 소환 불필요 — 오케스트레이터 직접 실행.
codex-review.sh가 Codex(GPT-5.4) + Gemini(3.1 Pro) 병렬 실행.

1. 스토리 diff 준비:
   git diff HEAD~1 -- packages/ > /tmp/story-diff.patch

2. Cross-Model 실행:
   bash ~/.claude/scripts/codex-review.sh /tmp/story-diff.patch \
     "이 코드를 리뷰해라. 버그, 보안 문제, 타입 오류를 찾아라."

3. 판정:
   - 하나라도 PASS → Phase transitions 진행 (두 결과 합산)
   - 둘 다 FAIL → CEO 보고, 자동 스킵 금지
   - FAIL 이슈 발견 → 이슈 수정 → 재실행 (max 1회)
   - 맥락상 불필요한 지적 → 사유 기록 후 스킵 OK

★ 둘 다 FAIL = 자동 진행 금지 (계속 모드에서도)
★ Codex(GPT-5.4) + Gemini(3.1 Pro) 병렬 실행 — CEO 승인 2026-04-10
```

### Phase transition party-log verification (v4.4)

오케스트레이터는 Phase 전환 전에 반드시:
1. 해당 Phase의 모든 critic party-log 파일 존재 확인 (Glob)
2. 각 파일이 1500B 이상인지 확인
3. 파일이 없거나 크기 부족 → critic에게 재작성 요청
4. 오케스트레이터가 직접 party-log를 작성하면 = 기만 행위. 절대 금지.

### Phase transitions

After Codex PASS:
1. bun test (해당 패키지 — run ALL relevant test suites)
2. Run ALL tsc commands from project-context.yaml (all must pass — cross-package)
2b. Integration check: for each new/modified API endpoint, verify frontend imports contract type (not inline)
3. Verify Story Dev Completion Checklist (all items [x])
4. git commit + push
5. Shutdown team → TeamDelete

### Sprint End (모든 스토리 완료 후)

```
Step 1: 자동 검증
  - bun test 전체 (모든 패키지)
  - tsc 전 패키지 (cross-package)

Step 2: Codex 일괄 리뷰
  - git diff로 Sprint 전체 변경사항 리뷰
  - FAIL → 수정 후 재실행

Step 3: /kdh-bug-fix-pipeline 필수 실행 ★
  - Phase 1 SCAN: Playwright 전체 suite + browser-use AI 전수 탐색
  - Phase 2 FIX: 발견된 버그 수정 루프
  - Phase 3 SWEEP: 전체 회귀 + Codex
  - 0 bugs = PASS → Step 4로
  - bugs 남으면 수정 완료까지 다음 Sprint 진입 금지

Step 4: 5개 테마 스크린샷
  - browser-use 또는 Playwright로 주요 페이지 × 5테마 스크린샷
  - Sprint End 스크린샷은 bugfix 파이프라인이 관리: _bmad-output/bug-fix/e2e-screenshots/

Step 5: CEO GATE #19 (브라우저 확인)
  - "Sprint N 완료! 브라우저에서 확인해주세요."
  - CEO "OK" → 다음 Sprint
  - CEO "여기 이상해" → /kdh-bug-fix-pipeline 재실행
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

Usage: `/kdh-dev-pipeline parallel 9-1 9-2 9-3` (max 3 workers)
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

Usage: `/kdh-dev-pipeline swarm epic-9`

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
Story Dev completion checklist (C안 — v11.0):
  [ ] Phase A: create-story + party review PASS (winston+quinn+john)
  [ ] Phase B: dev-story (real code, no stubs) + party review PASS (winston+quinn+john)
  [ ] Phase D: tests (unit + integration) + QA + party review PASS (winston+quinn+john)
  [ ] Phase D Layer 2: at least 1 integration test with real HTTP request (not mock)
  [ ] Cross-Model: Codex(GPT-5.4)+Gemini(3.1 Pro) review PASS
  [ ] bun test passes
  [ ] tsc passes (cross-package, not just changed package)
  [ ] Contract compliance: all API types imported from shared contracts (no inline overrides)
  [ ] Real functionality (no stub/mock/placeholder)
  [ ] If UI story: ui-design.md 작성 + theme consistency
  [ ] If wiring story: upstream → downstream connected end-to-end
  [ ] Compliance YAML trajectory: fixes_rounds, critic_agreement_rate, da_skipped/da_skip_reason, bias_flag 기록됨
```

ALL items must be [x] before story is accepted.
If any UI check fails → fix → re-run → must pass.

---

## Pipeline Interconnection (v11.0)

### Planning → Dev (입력)
Planning Stage 8 완료 → pipeline-state.yaml `mode: sprint` 감지 → Sprint 시작.
입력 산출물: epics-and-stories.md, architecture.md, api-contracts.md, sprint-status.yaml
경로: `_bmad-output/phase-{N}/planning-artifacts/`

### Dev → Bugfix (Sprint End)
Sprint 내 모든 스토리 완료 → Sprint End Step 3 → `/kdh-bug-fix-pipeline` 실행.
(Core Rule #40)

### Bugfix → Dev (design 에스컬레이션 수신)
bug-fix-state.yaml에서 `escalation: dev-pipeline` + `escalation_status: pending` 발견 시:
1. CEO 확인 후 해당 Story 재개발 or 설계 검토
2. origin=design인 버그의 root_cause를 참고하여 Story Phase A에서 반영

### 스크린샷 경로 표준
- Story별: `_bmad-output/phase-{N}/e2e-screenshots/story-{id}/`
- Sprint End(bugfix): `_bmad-output/bug-fix/e2e-screenshots/`

참조: `_bmad-output/pipeline-protocol.md`

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
6. **Planning = one stage at a time (v10.4).** Stage Worker writes ALL steps in a stage → batch review → THEN next stage. Sprint Dev = Phase A→B→D→Codex (기존 유지).
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
25. **Codex second opinion mandatory (Phase B.5).** After 2-critic party review PASS (winston+quinn), run Codex (GPT-5.4) in tmux. 1 run + max 1 re-run. Context-irrelevant findings may be self-skipped (record reason). Codex FAIL blocks commit. See kdh-sprint Phase B.5 for details.
26. **Sprint mode (kdh-sprint absorbed).** `sprint N` argument runs full sprint orchestration: TeamCreate → story loop (build→review→Codex→commit) → batch integration → sprint integration → E2E → GATE. kdh-sprint skill is deprecated; its logic lives here.
27. **Context judgment autonomy.** Orchestrator makes obvious technical decisions autonomously (REST vs RPC, DB structure, code patterns). Only ask CEO about feature meaning/intent/direction. Codex findings clearly irrelevant to project context may be self-skipped with recorded reason.
28. **Batch integration review.** Every 3 completed stories (or last batch in sprint), run kdh-integration batch with Codex. Cross-dependency, middleware consistency, env var sync. PASS until Codex PASS.
29. **Agent prompts include kdh-build rules verbatim.** When spawning dev agents, include kdh-build SKILL.md rules as full text in prompt, never summarized. Missing rules = CEO deletes code.
30. **pipeline-state.yaml은 항상 멀티라인 (v10.1).** 인라인 YAML `{ key: value }` 금지. pre-commit hook이 yq 우선 + sed 폴백으로 파싱하지만, 멀티라인이 가장 안전. 예: `phase_d:\n  status: pass\n  tests: 87` (O), `phase_d: { status: pass, tests: 87 }` (X).
31. **Phase D critic 로그 필수 (v11.0).** Phase D: quinn(Writer) + dev/winston(Critics) 3개 로그. pre-commit hook이 파일 존재 검증. critic 로그 없으면 커밋 차단.
33. **Planning DA (v10.2).** Stage 6 완료 후 Stage 6.1에서 quinn이 모든 FR의 사용자 여정을 추적. FR→UI요소→Story→AC 각 단계에서 빈 셀 = BLOCK. 최소 3개 갭 강제 발견.
34. **UX App Chrome Checklist (v10.2).** Stage 5 완료 전 sally가 반드시 정의: 로그아웃 버튼 위치, 로딩 상태, 에러 표시 위치, 세션 만료 흐름, 빈 상태, 사용자 계정 메뉴. 빠지면 Stage 5 PASS 불가.
35. **FR-to-UI Traceability Matrix (v10.2).** Stage 7에서 tech-writer가 모든 FR에 대해 PRD→UX→Story→AC 매핑 검증. 빈 셀 = Sprint Planning 진행 불가.
36. **Phase A UI Existence Check (v10.2).** quinn이 스토리의 모든 UI 참조를 검증: "이 버튼/페이지가 다른 스토리 또는 UX 스펙에 정의되어 있는가?" 없으면 auto-FAIL.
38. **mock-only Phase D = FAIL (v10.6).**
43. **스토리 간 에이전트 재사용 절대 금지 (v11.1).** Story X 완료 → Shutdown ALL → TeamDelete → Story Y에서 TeamCreate + 새 에이전트 소환. SendMessage로 "다음 스토리 해라" 지시 금지 — fresh context 필수. 같은 스토리 내 Phase 전환(A→B→D)은 에이전트 유지 OK.
44. **FAIL 재리뷰 시 fresh agent 필수 (v11.1).** Phase D FAIL → dev 수정 → 재리뷰 시: 기존 critic Shutdown → 새 critic 소환. 기존 에이전트에 SendMessage "다시 봐라" 금지 — 옛날 결과 반복함. 원인: sonnet 에이전트가 긴 히스토리에서 이전 리뷰와 현재 지시를 혼동. Phase D Layer 2 (integration test, 실제 HTTP 요청) 최소 1개 필수. mock만 있으면 FAIL. compliance YAML에 integration_tests_count 기록.
40. **Sprint End = /kdh-bug-fix-pipeline 필수 (v11.0).** Sprint 내 모든 스토리 완료 후 /kdh-bug-fix-pipeline 실행. 0 bugs 아니면 다음 Sprint 진입 금지. Playwright 전체 suite + browser-use 전수 탐색 + Codex batch.
42. **Reference Code Search 필수 (v10.9).** Phase B Step 1d — dev가 코드 짜기 전에 `gh search repos` + `gh search code` + npm 검색 필수. 검증된 라이브러리가 80%+ 해결하면 직접 구현 대신 사용. 검색 결과(채택/기각 사유) party-log에 "## Reference Code" 섹션 기록. 검색 0건이어도 기록 필수.

---

## Integration Review (Story간 + Sprint간 통합 검증)

## Codex 역할 분담 (중요)

- **스토리 레벨 Codex**: kdh-sprint Phase B.5에서 1회 실행 (최대 1회 재실행)
- **배치/스프린트 레벨 Codex**: kdh-integration에서 실행 — 여기서 꼼꼼히 돌림
- 스토리별 Codex에서 놓친 것은 배치/스프린트 Codex가 잡는다.
- 중복 실행 금지 — kdh-integration은 통합 검증에 집중.

---

# KDH Integration v13 — "같이 붙여봤냐?"

Story 단독 리뷰(Level 1)로는 못 잡는 통합 버그를 잡는다.
독립 Claude 에이전트로 second opinion을 받아 blind spot을 보완.

## When to Use

- `/kdh-integration batch` — Batch(3개 스토리) 완료 후 Story 간 통합 리뷰
- `/kdh-integration sprint` — Sprint 완료 후 Sprint 간 회귀 리뷰
- `/kdh-sprint`에서 자동 호출됨 (직접 안 쳐도 됨)

## Pattern

```
Level 2 (Batch): "이 스토리들이 서로 안 깨뜨리나?"
Level 3 (Sprint): "이번 Sprint가 이전 Sprint를 안 깨뜨리나?"

Claude = 1차 분석 (자동 검증 스크립트)
Second Opinion Agent = 2차 의견 (독립 Claude 에이전트, fresh context, 읽기 전용)
Claude = 최종 판정 (Second Opinion + 자체 분석 종합)
```

---

## Prerequisites

```
1. sprint-status.yaml 읽기 가능
2. git history 접근 가능
3. Agent 도구 사용 가능 (Second Opinion 에이전트 소환용)
```

---

## Level 2: Batch Integration Review

```
시점: kdh-sprint Step 5.5에서 호출 (Batch 완료 시)
입력: 이번 Batch의 스토리 ID 목록
범위: git diff {batch-start-commit}..HEAD
```

### Phase 0: Context Load

```
1. 이번 Batch에서 완료된 스토리 목록
2. 각 스토리의 변경 파일 목록 (git diff --name-only per story commit)
3. 파일 간 교차점 찾기:
   - Story A가 수정한 파일을 Story B가 import → "교차 의존성"
   - 같은 파일을 2개 이상 스토리가 수정 → "충돌 위험"
```

### Phase 1: Cross-Impact Analysis

```
1. 공유 컴포넌트 변경 스캔:
   변경된 파일 중 export가 있는 것:
     grep -l "export" {changed_files}
   그 export를 다른 파일이 import하는지:
     grep -rl "from '.*{filename}'" packages/ --include="*.ts" --include="*.tsx"
   import하는 파일이 있고 + export 시그니처가 바뀌었으면 → INTEGRATION-WARNING

2. 미들웨어 체인 일관성:
   {server_package_path}/src/routes/*.ts 파일들의 미들웨어 사용 비교 (from project-context.yaml):
     requireAuth, verifyTeamOwnership 등
   Story A가 미들웨어 추가/변경했는데 다른 라우트에 영향 → WARNING

3. 프론트 라우팅 일관성:
   {admin_package_path}/src/main.tsx의 Route 정의 (from project-context.yaml)
   vs 실제 페이지 컴포넌트의 auth 요구사항
   ProtectedRoute 안의 페이지가 비인증 접근 시도 → WARNING

4. 환경변수 교차 검증:
   이번 Batch에서 새로 추가된 process.env.XXX:
     .env.example에 있는지 확인
     fallback이 localhost면 → WARNING
```

### Phase 1.5: 세컨드 오피니언 — Codex CLI (1차) + Claude Agent (백업)

```
1차: Codex CLI (npx @openai/codex) exec 모드 — GPT-5.4 fresh session, 별도 모델 독립 시각
2차: Codex 실패 시 Claude Agent fallback

인증: ~/.codex/auth.json (device-auth 방식, 이미 완료)
모드: exec (비대화형, TTY 불필요)
세션: 매번 fresh session (편향 방지 — 영속 세션 안 씀)

--- Codex CLI (1차 시도) — tmux 실시간 패턴 (CEO가 봄) ---

1. git diff {batch-start}..HEAD > /tmp/batch-diff.txt

2. Codex tmux 창 열기 + 리뷰 보내기 (Bash 도구):
   # Codex 창 열기 — CEO가 실시간으로 작업 과정을 봄
   CODEX_PANE=$(tmux split-window -h -P -F '#{pane_id}' "bash")
   tmux select-pane -t $CODEX_PANE -T "codex-batch-reviewer"

   # Codex한테 통합 리뷰 보내기
   tmux send-keys -t $CODEX_PANE 'npx @openai/codex exec - --json \
     --sandbox read-only \
     -o _bmad-output/party-logs/{sprint}-batch-{N}-second-opinion.md \
     -C $PROJECT_ROOT <<'"'"'PROMPT'"'"'
   Integration review for batch {N}.
   Read /tmp/batch-diff.txt and analyze for cross-story integration issues.
   Focus: shared component changes, middleware consistency, auth flow,
   env vars, type signature changes.
   DO NOT modify source code — read-only analysis only.
   PROMPT' C-m

3. 완료 대기 (프롬프트 복귀 확인):
   while ! tmux capture-pane -t $CODEX_PANE -p | grep -q '❯'; do sleep 3; done

4. 결과 파일 읽기 (-o 플래그로 자동 저장됨) → Phase 2로 이동

5. Codex 창 닫기: tmux kill-pane -t $CODEX_PANE

--- Codex 실패 시 (인증/타임아웃) ---

★ Claude Agent fallback 금지 (CLAUDE.md 절대 규칙) ★
Codex가 못 돌아가면 → 멈추고 CEO에게 보고. 자동 스킵 금지.
CEO가 '스킵 OK' → sprint-status.yaml에 codex_skipped: true 기록.
CEO 응답 없으면 → 대기.

--- Codex FAIL 판정 시 ---

★ Codex FAIL → 수정 후 Codex 재실행 → PASS까지 반복 ★
★ "범위 밖" 핑계로 무시 금지 ★
1. Codex 지적 사항을 party-logs/{sprint}-batch-{N}-codex-fixes.md에 기록
2. 해당 스토리 dev에게 수정 지시
3. dev 수정 → Codex 재실행 (횟수 제한 없음 — PASS까지)
4. PASS 나올 때까지 끝까지 고친다. ESCALATE 없음.
```

### Phase 2: Dependent Test Re-run

```
1. 이번 Batch에서 변경된 모듈을 import하는 테스트 파일 찾기:
   for each changed_module:
     grep -rl "from '.*{module}'" packages/**/__tests__/ → test_files

2. 해당 테스트만 실행:
   bun test {test_files}

3. RED 있으면:
   → INTEGRATION-FAIL
   → 어떤 스토리 변경이 원인인지 git blame으로 추적
   → party-logs에 기록
```

### Phase 3: Report

```
출력: party-logs/{sprint}-batch-{N}-integration.md

## Batch {N} Integration Report
- Stories reviewed: [story-ids]
- Cross-dependencies found: {N}
- Second opinion issues found: {N}
- Dependent tests: {passed}/{total}
- Integration warnings: {list}
- Result: PASS / WARNING / FAIL

판정:
  PASS → 다음 Batch 진행
  WARNING → 기록 후 진행 (Sprint Review에서 재확인)
  FAIL → 해당 스토리 CONDITIONAL 되돌림, 수정 필요

sprint-status.yaml 업데이트:
  batch_reviews에 결과 추가
```

---

## Level 3: Sprint Integration Review

```
시점: kdh-sprint Phase 1.5에서 호출 (모든 스토리 완료 후, E2E 직전)
입력: 이번 Sprint 전체 + 이전 Sprint 마지막 커밋 해시
범위: git diff {previous-sprint-end}..HEAD
```

### Phase 0: Full Context Load

```
1. 이전 Sprint 마지막 커밋:
   sprint-status.yaml → sprint_{N-1}.completed_commit
   없으면: git log --oneline | grep "chore(sprint-{N-1})" → 해시 추출

2. 이번 Sprint 변경 파일 전체:
   git diff --name-only {prev-end}..HEAD

3. 이전 Sprint 핵심 파일 식별:
   sprint-status.yaml → sprint_{N-1}.stories → 각 스토리의 변경 파일
```

### Phase 1: Regression Analysis

```
1. 직접 수정 감지:
   이번 Sprint가 이전 Sprint의 파일을 직접 수정했는지:
   git diff {prev-end}..HEAD -- {prev-sprint-files}
   → 변경 있으면 → REGRESSION-RISK (해당 파일 집중 분석)

2. 간접 영향 분석:
   이번 Sprint가 수정한 공유 모듈:
     {shared_package_path}/src/ (from project-context.yaml)
     {server_package_path}/src/middleware/ (from project-context.yaml)
     {admin_package_path}/src/lib/ (from project-context.yaml)
     {admin_package_path}/src/components/ (공용 컴포넌트, from project-context.yaml)
   이 모듈을 이전 Sprint 파일이 import하는지:
   → import 있으면 → REGRESSION-WARNING

3. 교차점이 0이면 → 자동 PASS (이전 Sprint에 영향 없음)
```

### Phase 2: Assumption Drift Detection

```
이전 Sprint의 가정 vs 이번 Sprint의 변경:

1. 사용자 타입/역할:
   git diff {prev-end}..HEAD -- "*.ts" | grep -i "userType\|role\|permission"
   새 타입/역할 추가됨 → 기존 ProtectedRoute, 미들웨어에 반영했는지 확인

2. 인증 방식:
   auth.ts, auth-context.tsx 변경 여부
   변경됨 → 모든 인증 의존 페이지/라우트에 영향 분석

3. API envelope 형식:
   { success, data } / { success, error } 형식 일관성
   새 API가 다른 형식 쓰면 → WARNING

4. 라우팅 규칙:
   main.tsx Route 변경 → ProtectedRoute 조건과 일치하는지
```

### Phase 2.5: 세컨드 오피니언 — Sprint (Codex 1차 + Claude Agent 백업)

```
--- Codex CLI (1차 시도) — tmux 실시간 패턴 (CEO가 봄) ---

1. git diff {previous-sprint-end}..HEAD > /tmp/sprint-diff.txt

2. Codex tmux 창 열기 + 리뷰 보내기 (Bash 도구):
   CODEX_PANE=$(tmux split-window -h -P -F '#{pane_id}' "bash")
   tmux select-pane -t $CODEX_PANE -T "codex-sprint-reviewer"

   tmux send-keys -t $CODEX_PANE 'npx @openai/codex exec - --json \
     --sandbox read-only \
     -o _bmad-output/party-logs/{sprint}-sprint-second-opinion.md \
     -C $PROJECT_ROOT <<'"'"'PROMPT'"'"'
   Sprint integration review for sprint {N}.
   Read /tmp/sprint-diff.txt and analyze regressions against previous sprint.
   Focus: shared module changes, auth flow consistency, env vars, API envelope format.
   DO NOT modify source code — read-only analysis only.
   PROMPT' C-m

3. 완료 대기 → 결과 종합 → tmux kill-pane -t $CODEX_PANE

--- Codex 실패 시 (인증/타임아웃) ---

★ Claude Agent fallback 금지 (CLAUDE.md 절대 규칙) ★
Codex가 못 돌아가면 → 멈추고 CEO에게 보고. 자동 스킵 금지.

--- Codex FAIL 판정 시 ---

★ Codex FAIL → 수정 후 Codex 재실행 → PASS까지 반복 ★
1. Codex 지적 사항 기록
2. 해당 스토리 dev에게 수정 지시
3. dev 수정 → Codex 재실행 (횟수 제한 없음 — PASS까지)
4. PASS 나올 때까지 끝까지 고친다. ESCALATE 없음.
```

### Phase 3: Environment & Config Audit

```
1. 이번 Sprint에서 추가된 환경변수:
   git diff {prev-end}..HEAD | grep "process\.env\." | grep "+" → 신규 목록

2. .env.example 교차 검증:
   각 변수가 .env.example에 있는지

3. 프로덕션 fallback 검증:
   fallback이 localhost → FAIL
   fallback이 프로덕션 URL → OK
   fallback 없음 → WARNING
```

### Phase 4: Report

```
출력: party-logs/{sprint}-sprint-integration.md

## Sprint {N} Integration Report
- Previous sprint commit: {hash}
- Files changed this sprint: {N}
- Regression risks: {N} (직접 {N}, 간접 {N})
- Assumption drifts: {N}
- Environment gaps: {N}
- Second opinion issues: {N}
- Result: PASS / WARNING / FAIL

판정:
  PASS → E2E 진행
  WARNING → E2E에 추가 검증 포인트 전달 (integration-risks.md)
  FAIL → 수정 필수 (E2E 진행 불가)

sprint-status.yaml 업데이트:
  integration_state: passed/warning/failed
  integration_report: party-logs/{sprint}-sprint-integration.md
```

---

## Second Opinion 규칙

```
1. Codex CLI (npx codex) — 다른 모델의 독립 시각 제공
2. Codex 실행 실패 → 멈추고 CEO 보고 (Claude Agent fallback 금지 — CLAUDE.md)
3. Codex FAIL 판정 → 수정 후 재실행 → PASS까지 반복 (횟수 제한 없음)
4. 항상 fresh context (이전 대화 맥락 없이)
5. 읽기 전용 (소스 코드 수정 절대 안 함 — 분석만)
6. "범위 밖" 핑계로 Codex 지적 무시 금지
```

## Anti-Patterns

```
1. Second Opinion 에이전트에 코드 수정 시키지 않음 — 읽기 전용만
2. Second Opinion 의견을 무조건 따르지 않음 — Claude가 판단
3. false positive에 과민 반응 안 함 — HIGH만 테스트 재실행
4. 순환 의존성 무한 루프 안 됨 — 최대 1회 재실행, 2회 FAIL → GATE
5. 전체 파일 다 읽으려 안 함 — 교차점만 분석
6. DA(Phase D) 미실행 시 compliance YAML에 `da_skipped: true` + `da_skip_reason` 필수. Story completion checklist에서 검증. 없으면 REJECT. (ref: planning-pipeline Anti-Pattern #16)
7. Self-enhancement bias 플래그 — fixes 후 직전 라운드 대비 3명 critics 점수가 모두 같은 방향으로 ≥1.0 상승 시, 오케스트레이터가 bias 의심 플래그. compliance YAML에 `bias_flag: true/false` 기록. bias_flag=true 시 독립 재채점 경고. (ref: planning-pipeline Anti-Pattern #8, PoLL study)
```

---

## Output

```
party-logs/
  {sprint}-batch-{N}-integration.md           ← Level 2 Batch 리포트
  {sprint}-batch-{N}-second-opinion.md        ← Second Opinion Batch 의견
  {sprint}-sprint-integration.md              ← Level 3 Sprint 리포트
  {sprint}-sprint-second-opinion.md           ← Second Opinion Sprint 리뷰
sprint-status.yaml                            ← integration_state, batch_reviews
```
