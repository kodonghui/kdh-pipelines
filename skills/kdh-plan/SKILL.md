---
name: kdh-plan
description: "Planning Pipeline — BMAD Stage 0~8 기획 전담. Party mode + GATE steps + Context snapshots."
---

# KDH Plan — Planning Pipeline

BMAD 워크플로우 기반 기획 전담 스킬.
Stage 0(Product Brief) ~ Stage 8(Sprint Zero)까지 순차 실행.

## When to Use

- `/kdh-plan` — 기획 파이프라인 전체 실행
- `/kdh-plan {stage}` — 특정 스테이지만 (예: `/kdh-plan stage-2`)
- `/kdh-go`에서 기획 미완료 시 자동 호출됨

## Pattern: Pipeline (순차)

```
revfactory/harness 패턴: Pipeline (A → B → C → D)
기존 kdh-full-auto-pipeline Mode A를 추출
Party mode 유지 (Grade A/B steps)
GATE steps 유지 (사장님 확인)
```

---

## Step 0: Project Auto-Scan

기획 시작 전 프로젝트 구조 파악. `project-context.yaml`에 캐시.

```
1. package.json → 패키지 매니저, 스크립트, 의존성
2. tsconfig.json 목록 → tsc 명령어 빌드
3. 모노레포 구조 감지 (Turborepo, pnpm workspace 등)
4. 테스트 러너 감지 (vitest, jest, bun test)
5. BMAD 디렉토리 감지 (_bmad/ 존재 여부)
6. Hono RPC 감지 (server + shared 패키지)
7. UI 프레임워크 감지 (React, Tailwind, Subframe)
8. 기존 기획 문서 감지 (PRD, architecture, feature-spec)
9. 결과 저장: project-context.yaml
```

1시간 이내 캐시 있으면 재스캔 건너뜀.

---

## Planning Stages

### Stage 0: Product Brief
```
Dir: _bmad/bmm/workflows/1-analysis/create-product-brief/steps/
Output: _bmad-output/planning-artifacts/product-brief-{project}-{date}.md
Team: analyst(Writer), john, sally, bob, winston
GATES: vision, users, metrics, scope
```

### Stage 1: Technical Research
```
Dir: _bmad/bmm/workflows/1-analysis/research/technical-steps/
Output: _bmad-output/planning-artifacts/technical-research-{date}.md
Team: dev(Writer), winston, quinn, john
GATES: none
```

### Stage 2: PRD Create
```
Dir: _bmad/bmm/workflows/2-plan-workflows/create-prd/steps-c/
Output: _bmad-output/planning-artifacts/prd.md
Team: john(Writer), winston, quinn, sally, bob
Skip: step-01b-continue.md
GATES: discovery, vision, success, journeys, innovation, scoping, functional, nonfunctional
```

### Stage 3: PRD Validate (병렬화 가능)
```
Dir: _bmad/bmm/workflows/2-plan-workflows/create-prd/steps-v/
Output: _bmad-output/planning-artifacts/prd-validation-report.md
Team: analyst(Writer), john, winston, quinn
GATES: none
```

### Stage 4: Architecture (최중요)
```
Dir: _bmad/bmm/workflows/3-design-build/design-architecture-solution/steps/
Output: _bmad-output/planning-artifacts/architecture.md
Team: winston(Writer), dev, quinn, john, bob
GATES: decisions
```

### Stage 5: UX Design
```
Dir: _bmad/bmm/workflows/3-design-build/plan-ux-design/steps/
Output: _bmad-output/planning-artifacts/ux-design.md
Team: sally(Writer), john, winston, quinn
GATES: design-system, design-directions
Subframe MCP 사용: 디자인 프로토타입
```

### Stage 6: Epics & Stories
```
Dir: _bmad/bmm/workflows/2-plan-workflows/create-epics-and-stories/steps/
Output: _bmad-output/planning-artifacts/epics-and-stories.md
Team: bob(Writer), john, winston, dev, quinn
GATES: design-epics
```

### Stage 6.5: API Contract Definition
```
기존 pipeline에 없던 v9.4 신규 단계.
Output: packages/shared/src/contracts/*.ts + api-contracts.md
Team: winston(Writer), dev, quinn, john
목적: 백-프론트 타입 계약 정의 (v2 실패 방지)
```

### Stage 7: Sprint Planning
```
Output: _bmad-output/implementation-artifacts/sprint-status.yaml
Team: bob(Writer), dev, winston
```

### Stage 8: Sprint Zero (기반 설정)
```
Output: 프로젝트 기반 코드 (DB 스키마, 라우터 뼈대 등)
Team: dev(Writer), winston, quinn
GATE: theme-select (테마 색상 선택)
```

---

## Party Mode Protocol (per Step)

**Grade A/B steps에만 적용. Grade C(init, complete)는 Writer 단독.**

```
1. Writer: step 파일 Read → 섹션 작성 → 출력 문서에 저장
2. Writer → Critics (전원): [Review Request] + 파일 경로
3. Critics (병렬): 파일에서 읽고 리뷰 → party-logs/{stage}-{step}-{name}.md
4. Critics: Cross-talk (1라운드) — 핵심 이견 교환
5. Critics → Writer: 피드백 + 우선순위 이슈
6. Writer: 피드백 반영 → party-logs/{stage}-{step}-fixes.md
7. Writer → Critics: [Fixes Applied]
8. Critics (병렬): 재검토 → 최종 점수
9. 점수 판정:
   - Grade A: avg >= 8.0 (최소 2 사이클, Devil's Advocate 포함)
   - Grade B: avg >= 7.5 (최소 1 사이클)
   - 미달 + 재시도 남음 → 다시
   - 재시도 소진 → ESCALATE
10. Orchestrator 체크리스트 (BLOCKING):
   - [ ] 모든 critic party-log 파일 존재
   - [ ] fixes.md 존재
   - [ ] Cross-talk 섹션 존재
   - [ ] Score stdev >= 0.5
   하나라도 미충족 → REJECT
```

## GATE Protocol

기능/방향 관련 결정은 사장님한테 질문.

```
1. Writer가 선택지 초안 (A/B/C)
2. [GATE {step}] → Orchestrator
3. Orchestrator → /kdh-gate 호출 (사장님 질문)
4. 사장님 응답 대기 (무한)
5. 응답 → Writer에게 전달
6. Writer: 결정 반영 후 party mode 계속
```

`계속` 모드: GATE 자동 진행 (기본 선택 A).

## Stage 간 전환

```
1. Stage 완료 → context-snapshots/{stage}-snapshot.md 저장
2. 사장님에게 한국어 요약 보고
3. git commit: "docs(planning): {stage} complete"
4. 다음 Stage: fresh team spawn + 이전 snapshots 읽기
```

---

## BMAD Agent Roster

| Agent | Persona File | 전문 분야 |
|-------|-------------|----------|
| winston | `_bmad/bmm/agents/architect.md` | 분산 시스템, API, 확장성 |
| quinn | `_bmad/bmm/agents/qa.md` | 테스트, QA, 커버리지 |
| john | `_bmad/bmm/agents/pm.md` | 요구사항, 이해관계자 |
| sally | `_bmad/bmm/agents/ux-designer.md` | UX, 인터랙션 디자인 |
| bob | `_bmad/bmm/agents/sm.md` | 스크럼, 스프린트, 리스크 |
| dev | `_bmad/bmm/agents/dev.md` | 구현, 코드 품질 |
| analyst | `_bmad/bmm/agents/analyst.md` | 분석, 리서치 |

**절대 규칙:**
- 에이전트는 반드시 실명(winston, quinn 등)으로 spawn
- critic-a, worker-1 같은 제네릭 이름 금지
- spawn 후 첫 action = persona 파일 Read

---

## Anti-Patterns (금지)

1. Writer가 Skill tool 사용 → 내부적으로 전체 완료됨, critic 무시됨
2. Writer가 step 여러 개 한번에 작성 → 하나씩 쓰고 party mode
3. GATE step 자동 진행 → `계속` 모드 아니면 반드시 사장님 대기
4. 이전 step 내용 복붙 → §{section} 참조 사용
5. 만장일치 점수 → stdev < 0.5면 독립 재점수

---

## Output

```
_bmad-output/
  planning-artifacts/
    product-brief-*.md
    technical-research-*.md
    prd.md
    prd-validation-report.md
    architecture.md
    ux-design.md
    epics-and-stories.md
    api-contracts.md
  context-snapshots/
    stage-{N}-snapshot.md
  party-logs/
    {stage}-{step}-{agent}.md
  implementation-artifacts/
    sprint-status.yaml
packages/shared/src/contracts/
  *.ts (Stage 6.5)
project-context.yaml
```
