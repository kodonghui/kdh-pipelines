---
name: kdh-review
description: "Story Reviewer (Evaluator) — 별도 에이전트가 BMAD party mode로 코드 리뷰. Generator ≠ Evaluator."
---

# KDH Review — Story Reviewer (Evaluator)

구현 완료된 스토리를 **별도 에이전트**로 리뷰하는 Evaluator 전용 스킬.
**구현한 에이전트와 리뷰하는 에이전트는 반드시 다르다 (자기 편향 제거).**

## When to Use

- `/kdh-review {story-id}` — 스토리 1개 리뷰 (예: `/kdh-review 1-1`)
- `/kdh-sprint`에서 build 완료 후 자동 호출됨

## Pattern: Producer-Reviewer (Reviewer Side)

```
Anthropic 3-Agent 패턴: Generator ≠ Evaluator (자기 편향 방지)
GSD 적용: Fresh context — 구현 과정 모름, 코드만 보고 판단
revfactory/harness 패턴: Producer-Reviewer
Superpowers 적용: Verification Before Completion
CEO 명령: Party mode 절대 생략 금지
```

---

## Review Team (BMAD Agents)

| Agent | Persona File | 리뷰 관점 |
|-------|-------------|-----------|
| **winston** | `_bmad/bmm/agents/architect.md` | 아키텍처, API 설계, 확장성 |
| **quinn** | `_bmad/bmm/agents/qa.md` | 테스트 커버리지, 엣지 케이스, 보안 |
| **john** | `_bmad/bmm/agents/pm.md` | 요구사항 충족, 사용자 관점 |

3명이 독립적으로 리뷰 → 교차 토론 → 최종 점수.

---

## Phase 0: Review Load (30s)

```
1. git log -1 --format="%H %s" → 마지막 커밋 (build 결과)
2. git diff HEAD~1 → 변경된 파일 목록
3. Read sprint-status.yaml → 스토리 스펙
4. Read epics-and-stories.md → acceptance criteria
5. Read packages/shared/src/contracts/*.ts → 계약 타입
6. Read _bmad-output/planning-artifacts/critic-rubric.md → 채점 기준
```

## Phase 1: Automated Checks (1min)

자동 검증 — 사람 판단 불필요한 것들.

```
1. tsc 체크:
   bunx tsc --noEmit -p packages/server/tsconfig.json
   bunx tsc --noEmit -p packages/admin/tsconfig.json
   bunx tsc --noEmit -p packages/shared/tsconfig.json
   → 에러 있으면 즉시 FAIL (리뷰 불필요)

2. 테스트 실행:
   bun test
   → FAIL 있으면 즉시 FAIL

3. Contract Compliance 자동 스캔:
   변경된 .ts/.tsx 파일에서 검색:
   - "interface " + PascalCase + " {" → 인라인 타입 의심
   - "type " + PascalCase + " = {" → 로컬 타입 의심
   - contracts/에 이미 같은 이름 있으면 → 중복 = FAIL
   - @corthex/shared import 없는 파일에서 API 타입 사용 → FAIL

4. 파일 크기 체크:
   - 800줄 초과 파일 → WARNING
   - 50줄 초과 함수 → WARNING
```

## Phase 2: Party Mode Review (5min)

**BMAD 에이전트 3명이 독립 리뷰.**

```
Step 1: Spawn 3 review agents (parallel)
  Each agent receives:
  - Persona file path (MUST read first)
  - Changed files list (git diff HEAD~1)
  - Story spec + acceptance criteria
  - Contract types
  - Critic rubric

Step 2: Independent Review
  Each agent writes: party-logs/{sprint}-{story}-{agent-name}.md

  Review Template:
  ---
  ## {Agent Name} Review: Story {story-id}
  
  ### Checklist
  - [ ] Acceptance criteria 충족
  - [ ] Contract types import (인라인 없음)
  - [ ] 테스트 존재 + 의미있는 커버리지
  - [ ] 에러 핸들링
  - [ ] 보안 (입력 검증, SQL injection, XSS)
  - [ ] 코드 품질 (가독성, 함수 크기, 중복)
  - [ ] {agent-specific checks}

  ### Issues Found
  - [CRITICAL] ...
  - [HIGH] ...
  - [MEDIUM] ...
  - [LOW] ...

  ### Score: X/10
  ---

  Agent-specific checks:
  - winston: API 설계 일관성, DB 쿼리 효율, 확장성
  - quinn: 엣지 케이스, 에러 시나리오, 테스트 품질
  - john: 유저 스토리 완전성, UX 관점, 요구사항 누락

Step 3: Cross-talk (1 round)
  Each agent reads other 2 agents' logs.
  Top disagreement/concern을 peer에게 전달.
  Each agent updates their log with ## Cross-talk 섹션.

Step 4: Final Scoring
  Each agent sends final score to orchestrator.
```

## Phase 3: Score Evaluation

```
1. 평균 점수 계산: (winston + quinn + john) / 3
2. 판정:
   - avg >= 7.5 → PASS
   - avg >= 6.0, < 7.5 → CONDITIONAL (수정 후 재리뷰)
   - avg < 6.0 → FAIL (재구현 필요)
   - 개별 점수 < 3.0 → 자동 FAIL (평균 무관)

3. Score Variance 체크:
   - 3명 점수 표준편차 < 0.5 → "의심스러운 합의" 경고
   - 1명이 독립 재점수 (다른 점수 안 보고)

4. Verification Before Completion (Superpowers):
   PASS 판정 시에도 아래 증거 필수:
   - [ ] tsc 0 errors (Phase 1 결과)
   - [ ] Tests all GREEN (Phase 1 결과)  
   - [ ] Contract compliance PASS (Phase 1 결과)
   - [ ] 3개 party-log 파일 존재
   - [ ] 각 로그에 Cross-talk 섹션 존재
   - [ ] 최소 1개 이상 이슈 발견됨 (이슈 0 = 의심)
   증거 하나라도 없으면 → PASS 취소, 재검증
```

## Phase 4: Result Action

```
PASS:
  1. party-logs에 PASS 기록
  2. sprint-status.yaml → reviewed: true, review_score: {avg}
  3. 다음 스토리로 진행 (kdh-sprint에게 알림)

CONDITIONAL:
  1. 이슈 목록을 파일로 저장: party-logs/{sprint}-{story}-fixes-needed.md
  2. /kdh-build에게 수정 요청 (새 에이전트 spawn)
  3. 수정 완료 후 → /kdh-review 재실행 (또 새 에이전트)
  4. 재리뷰는 최대 2회. 3회 CONDITIONAL → ESCALATE (사장님 판단)

FAIL:
  1. 상세 이유 기록: party-logs/{sprint}-{story}-FAIL.md
  2. sprint-status.yaml → status: failed, fail_reason: {summary}
  3. /kdh-sprint에게 FAIL 알림 → 스토리 재구현 결정
```

---

## Contract Compliance Detail

**인라인 타입 = 자동 FAIL. 이유: v2에서 29개 통합 버그 발생.**

```
Scan pattern:
  1. 변경된 파일에서 type/interface 선언 추출
  2. packages/shared/src/contracts/에서 같은 이름 검색
  3. 매칭되면 → "Contract에 이미 있는 타입을 로컬에서 재정의" = FAIL
  4. 매칭 안 되면 → "Contract에 없는 타입" = WARNING (추가 필요할 수 있음)
  
Exception:
  - React component props (XxxProps) → 로컬 정의 허용
  - Internal utility types → 로컬 정의 허용
  - API request/response types → 반드시 contract에서 import
```

---

## Fresh Context 규칙

```
- Review 에이전트는 Build 에이전트와 다른 에이전트다
- 구현 과정을 모른다 — 코드와 스펙만 보고 판단
- 이전 스토리 리뷰 기억 없다 — 매번 새로 시작
- 상태 전달은 오직 파일로 (party-logs, sprint-status.yaml)
```

---

## Anti-Patterns (금지 사항)

1. **자기 리뷰 금지** — build한 에이전트가 review하면 안 됨
2. **party mode 스킵 금지** — CEO 명시적 명령. 절대 생략 불가.
3. **증거 없이 PASS 금지** — tsc, test, party-log 전부 있어야 PASS
4. **점수 조작 금지** — 표준편차 < 0.5면 독립 재점수
5. **Critic이 persona 안 읽고 리뷰 금지** — 첫 action = Read persona file

---

## Output

```
party-logs/
  {sprint}-{story}-winston.md    ← 아키텍처 리뷰
  {sprint}-{story}-quinn.md      ← QA 리뷰
  {sprint}-{story}-john.md       ← 제품 리뷰
  {sprint}-{story}-fixes-needed.md  ← (CONDITIONAL일 때)
  {sprint}-{story}-FAIL.md          ← (FAIL일 때)
sprint-status.yaml               ← reviewed: true/false, review_score
```
