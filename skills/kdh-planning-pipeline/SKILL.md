---
name: 'kdh-planning-pipeline'
description: 'Planning Pipeline v11 — BMAD 9 Stages (Brief→PRD→Arch→UX→Epics→Contracts→Sprint Planning). 경량화: 참조 docs/ + 스킬 분리. 사장님 명령어: /kdh-planning-pipeline [auto|계속]'
---

# Planning Pipeline v11 (경량화)

> v11 변경: Phase 2 리팩터링. 979줄 → ~195줄. 참조 문서/스킬 분리.
> 분리된 스킬: /kdh-party-mode, /kdh-gate-protocol, /kdh-project-scan
> 분리된 문서: docs/ 폴더 (agent-roster, model-strategy, directory-convention, stage-review-matrix, ears-format, non-bmad-workflow, research-routing, pipeline-protocol)

<HARD-GATE>
1. Stage 순서 절대 변경 금지 — BMAD 0→1→2→3→4→5→6→6.1→6.5→7→8
2. Grade C 결과물 생략 금지 — party-log만 생략, 결과물은 반드시 생성
3. Phase 폴더 삭제/이동 금지 — archive로 유지
4. haiku 절대 금지 — opus(Grade A) 또는 sonnet(Grade B/C)
5. 조건부 PASS 금지 — avg < threshold = FAIL. "다음 Stage에서 해결" 미루기 금지
6. EARS 100% 강제 — 모든 FR/NFR은 EARS 구문. should/needs to/must = 비EARS
7. Wiring >30% 에스컬레이션 — 과생성 의심
8. 인라인 타입 정의 금지 — shared contracts에서 import
9. FR-to-UI 빈 셀 0개 필수 — Stage 7 Readiness PASS 조건
10. EARS 위반 3개 이상 = auto-fail
11. 미래 참조로 빈 셀 채우기 금지 — 실제 AC 확인 필수
12. planning_active: true 없이 planning-artifacts/ 수정 금지 — Hook 차단
</HARD-GATE>

## Red Flags

| Claude가 이렇게 생각하면 | 실제로는 |
|----------------------|---------|
| "이 Stage는 간단해서 Writer Solo로 해도 돼" | Grade 분류를 확인해. A/B면 party mode 필수 |
| "GATE는 Technical이니 자동 통과" | /kdh-gate-protocol의 인벤토리 확인. Business면 CEO 대기 |
| "Writer가 Skill tool로 한번에 하면 빠름" | Anti-Pattern #1. Writer는 Read tool로 step 읽고 수동 작성 |
| "step 여러개 한번에 쓰고 리뷰" | Anti-Pattern #2. ONE step → party mode → THEN next |
| "critic-a, critic-b로 스폰하면 돼" | Anti-Pattern #3. 반드시 BMAD 이름 (winston, quinn, john...) |
| "비슷한 내용이니 이전 Step에서 복사" | Anti-Pattern #7. 중복 금지, 교차 참조(§) 사용 |
| "점수 높으니 1-cycle로 끝내자" | Anti-Pattern #10/15. Grade A는 최소 2 cycles. 연속 1-cycle 금지 |
| "Party-log는 SendMessage로 보내면 돼" | Anti-Pattern #9. 파일로 Write 필수. 메시지만은 REJECT |
| "DA는 기존 critic이 겸임해도 돼" | fresh instance 필수. 기존 critic 겸임 금지 |
| "EARS 대신 should/must로 써도 의미 같잖아" | -1점/위반. 3개 이상 auto-fail |
| "FR에 대응하는 UI 없어도 나중에 추가하면 돼" | FR-to-UI 빈 셀 = BLOCK. Stage 5/6 보완 필수 |

## ★ v4 최적화 (2026-04-11 Plan v4) — BMAD 8 Stage 수 유지, 속도 최적화

### Stage Review Matrix
BMAD 8 stage 순서는 100% 유지한다. 각 stage의 **리뷰 cycle만** 다음과 같이 분류.

| Stage | BMAD 역할 | Review Mode | Party Mode |
|-------|----------|-------------|------------|
| 0 — Brief | 비전/범위 정의 | Grade A (정식) | ✅ winston+quinn |
| 1 — Research | 기술 조사 | Grade C (Writer Solo) | ❌ 자동 PASS |
| 2 — PRD | 요구사항 정의 | Grade A (정식) | ✅ winston+quinn |
| 3 — Validate | PRD 검증 | Grade C (Writer Solo) | ❌ 자동 PASS |
| 4 — Architecture | 설계 | Grade A (정식) | ✅ winston+quinn |
| 5 — UX | UX 설계 | Grade C (Writer Solo) | ❌ 자동 PASS |
| 6 — Epics | 스토리 분해 | Grade A (정식) | ✅ winston+quinn |
| 7 — Readiness | 최종 검증 | Grade A (정식) | ✅ winston+quinn + Codex+Gemini 병렬 |

### 규칙
- **Grade A stage:** winston + quinn Party Mode 필수. 결과물 + party-log 2개 생성.
- **Grade C stage:** Writer Solo. **결과물 생성 필수** (Stage 건너뛰기 금지). party-log만 생략.
- **Codex/Gemini 병렬화:** Grade A stage에서 Party Mode와 Codex+Gemini 백그라운드 동시 실행 (순차 → 병렬). codex-review.sh v2 사용.
- **Stage 순서 변경/삭제 절대 금지** — BMAD 방법론 유지.

### Codex 비동기 호출
`bash ~/.claude/scripts/codex-review.sh`는 반드시 `run_in_background: true`로 실행.
맥락 주입은 스크립트가 pipeline-state.yaml에서 자동으로 가져옴.

## Mode Selection

- **no args** 또는 **`auto`**: 상태 자동 감지 → 다음 할 일 판단 → 실행

---

## Step -1: Tool Readiness Check

파이프라인 시작 전 필수 도구 전부 검증. 하나라도 안 되면 즉시 중지.

```
1. Codex CLI: which codex → 안 되면 🚩 BLOCK
2. Codex 인증: codex exec "echo hello" → 안 되면 🚩 BLOCK
3. UI Design System: project-context.yaml ui.components 기반 체크
4. Helper Script: test -x ~/.claude/scripts/codex-review.sh → 안 되면 🚩 BLOCK
5. design-references.md: 5개 테마 URL → 없으면 ⚠️ WARNING

🚩 1개라도 → 즉시 중지. 자동 설치/복구/fallback 금지. CEO에게 보고.
```

## Step 0-pre: Planning Active 상태 설정

```
1. pipeline-state.yaml에 planning_active: true 설정
2. 종료 시 (정상/비정상) planning_active: false
3. 긴급 우회: PLANNING_GUARD_BYPASS=1 (CEO 전용)
★ 이 단계 건너뛰면 planning-artifact-guard.sh Hook이 모든 Edit/Write 차단
```

## Step 0: Project Auto-Scan

> 참조: /kdh-project-scan (독립 스킬로 분리됨)

project-context.yaml 생성. 1시간 이내 캐시 있으면 스킵.

## Step 0.5: Read Active Plans

```
1. _bmad-output/kdh-plans/_index.yaml 읽기 (없으면 스킵)
2. status: active AND (pipeline: "planning" OR "all") 필터링
3. 매칭된 plan 본문 읽기
4. plan = 맥락 제공자. SKILL.md 절차를 override하지 않음.
5. plan에 CEO 결정 있으면 → 해당 GATE 자동 통과
```

## BMAD Auto-Discovery Protocol

```
1. Stage의 workflow directory 경로 읽기
2. glob("{dir}/steps/*.md") → 자연 정렬
3. *-continue*, *-01b-* 필터 제외
4. 각 step에 대해 party mode 실행
steps/ 비어 있으면 → SKIP + warning (fail 아님)
```

---

### ★ 자동 스킬 로드 (분리된 스킬 — 반드시 Read)

<HARD-GATE>
오케스트레이터는 파이프라인 시작 시 Read tool로 반드시 읽어라:
1. Party Mode: Read ~/.claude/skills/kdh-party-mode/SKILL.md
2. GATE Protocol: Read ~/.claude/skills/kdh-gate-protocol/SKILL.md
읽지 않고 해당 절차 실행 = 규칙 위반.
</HARD-GATE>

## Orchestrator Flow

```
Step 0: /kdh-project-scan → project-context.yaml
Step 0.1: ★ Read ~/.claude/skills/kdh-party-mode/SKILL.md (Party Mode 규칙 로드)
Step 0.2: ★ Read ~/.claude/skills/kdh-gate-protocol/SKILL.md (GATE 19개 인벤토리 로드)
Step 1: For each Stage (0→1→2→3→4→5→6→6.1→6.5→7→8):
  a. TeamCreate("{project}-{stage-name}")
  b. party-logs/ + context-snapshots/ dirs 생성
  c. Writer + Critics 스폰 (Stage Team Config)
  d. Step Loop: GATE면 CEO 대기, party mode, party-log 검증
     Timeout: 20min + 2min grace. 3 stalls → SKIP.
  e. git commit: "docs(planning): {stage} complete"
  f. Shutdown ALL → TeamDelete → 다음 stage fresh team
Step 2: 최종 보고 (전 Stage 요약)

> Party Mode 상세: /kdh-party-mode (Planning Mode = Stage-Batch v10.4)
> GATE 상세: /kdh-gate-protocol (19개 인벤토리)
> Grade/Model: docs/stage-review-matrix.md + docs/model-strategy.md
```

---

## Stage별 핵심 (BMAD Mode)

| Stage | Dir | Output | Writer | Team | GATES | Key Rule |
|-------|-----|--------|--------|------|-------|----------|
| **0 Brief** | 1-analysis/create-product-brief/steps/ | product-brief-{project}-{date}.md | analyst | +john,sally,bob,winston | vision(BIZ),users(BIZ),metrics(TECH),scope(BIZ) | EARS 필수 (docs/ears-format.md) |
| **1 Research** | 1-analysis/research/technical-steps/ | technical-research-{date}.md | dev | +winston,quinn,john | none | Source routing (docs/research-routing.md) |
| **2 PRD** | 2-plan-workflows/create-prd/steps-c/ | prd.md | john | +winston,quinn,sally,bob | 8개 (discovery~nonfunctional) | EARS 100%. Critic FR 비율 체크 |
| **3 Validate** | 2-plan-workflows/create-prd/steps-v/ | prd-validation-report.md | analyst | +john,winston,quinn | none | 5 Round 병렬화 |
| **4 Arch** | 3-solutioning/create-architecture/steps/ | architecture.md | winston | +dev,quinn,john | decisions(TECH) | ★ MOST CRITICAL — all opus |
| **5 UX** | 2-plan-workflows/create-ux-design/steps/ | ux-design-specification.md | sally | +john,dev,winston,quinn | design-system(TECH),design-directions(BIZ) | App Chrome Checklist (아래) |
| **6 Epics** | 3-solutioning/create-epics-and-stories/steps/ | epics-and-stories.md | bob | +john,winston,dev,quinn | design-epics(TECH) | Wiring Auto-Gen (아래) |
| **6.1 DA** | — | stage-6.1-traceability.md | quinn(DA) | +winston,john | none | 최소 3 gaps 강제. 미래참조 금지 |
| **6.5 Contracts** | — | api-contracts.md + shared types | dev | +winston,quinn,john | tsc GATE | SINGLE SOURCE OF TRUTH |
| **7 Readiness** | check-implementation-readiness/steps/ | readiness-report.md | tech-writer | +winston,quinn,john,bob | none | FR-to-UI Matrix 빈 셀 0 (아래) |
| **8 Sprint** | 4-implementation/sprint-planning/ | sprint-status.yaml | Orchestrator | — | none | No party mode. 자동 실행 |

All Dir paths prefix: `_bmad/bmm/workflows/`. All Output prefix: `_bmad-output/planning-artifacts/`.

### Stage 5 — App Chrome Checklist (BLOCKING)

sally가 UX 스펙에 **반드시** 포함해야 할 항목. 하나라도 빠지면 Stage 5 PASS 불가.
- 로그인 레이아웃, App Shell, 계정 메뉴, 로그아웃 위치, 전역 로딩, 에러 표시, 세션 만료 흐름, 빈 상태, 모든 FR↔UI 매핑

UXUI Rules: (1) App shell 먼저 확정 (2) sidebar 중복 금지 (3) 테마 변경 시 full grep (4) Dead buttons 금지

### Stage 6 — Wiring Story Auto-Generation (v9.4)

store/service → 초기화 Wiring, API endpoint → frontend hook Wiring. Naming: {N}-W. >30% → ESCALATE.

### Stage 6.1 — Traceability Matrix

| FR | UI 요소 | 시작 페이지 | 클릭 대상 | API 경로 | 성공 이동 | 실패 표시 | 로딩 상태 |
빈 셀 = GAP → Stage 5/6 보완. "Story X에서 구현 예정" 미래참조 금지.

### Stage 6.5 — Contract Rules

Contract types = SINGLE SOURCE OF TRUTH. import ONLY, inline 금지. Type 변경 = contract FIRST → tsc → implement.
Hono RPC eligible → chaining + hc client. Standard → shared/src/contracts/{epic}.ts.

### Stage 7 — FR-to-UI Matrix (BLOCKING)

| FR | PRD 정의 | UX UI 요소 | Story | Story AC | 구현 경로 |
빈 셀 = BLOCK → Stage 5/6 보완 → Sprint Planning 불가.

> Non-BMAD 프로젝트: docs/non-bmad-workflow.md 참조

---

## 참조 링크

| 참조 | 위치 |
|------|------|
| Party Mode Protocol | /kdh-party-mode (Stage-Batch v10.4 + Sprint Dev v10.3) |
| GATE Protocol | /kdh-gate-protocol (19개 인벤토리) |
| Project Scan | /kdh-project-scan (project-context.yaml) |
| Stage Review Matrix | docs/stage-review-matrix.md |
| Agent Roster | docs/agent-roster.md |
| Model Strategy | docs/model-strategy.md |
| Directory Convention | docs/directory-convention.md |
| EARS Format | docs/ears-format.md |
| Research Routing | docs/research-routing.md |
| Non-BMAD Workflow | docs/non-bmad-workflow.md |
| Pipeline Protocol | docs/pipeline-protocol.md |
| 리뷰 수용 규칙 | /kdh-party-mode → "6단계 수용 프로세스" |

## 훅 커버리지 메모

다음 규칙은 Phase 1 훅이 자동 강제:
- research-guard: Stage 1에서 gh search 강제
- gateguard: 파일 첫 수정 전 조사 강제
- compliance-checker: 커밋 전 party-log 확인 + main push 차단
- config-protection: 설정 파일 수정 경고
- planning-artifact-guard: planning_active 없이 수정 차단
- quality-gate: Edit 후 타입 체크/린트
- verification-check: 증거 없이 완료 선언 차단
