---
name: kdh-sprint
description: "Sprint Orchestrator — 스프린트 전체를 관리. 스토리별 build→review 사이클 + 의존성 + E2E 검증."
---

# KDH Sprint — Sprint Orchestrator

스프린트 전체를 관리하는 오케스트레이터.
스토리 의존성 분석 → 병렬 배치 → build/review 사이클 → E2E 검증.

## When to Use

- `/kdh-sprint {N}` — 스프린트 N 실행 (예: `/kdh-sprint 1`)
- `/kdh-go`에서 자동 호출됨 (직접 안 쳐도 됨)

## Pattern: Supervisor + Fan-out/Fan-in

```
revfactory/harness 패턴: Supervisor (동적 배분) + Fan-out/Fan-in (병렬 → 합치기)
Ralph Wiggum 적용: 매 스토리 fresh agent (build → review → terminate → 다음)
GSD 적용: 파일 기반 상태 관리 (sprint-status.yaml)
```

---

## Phase 0: Sprint Load (1min)

```
1. Read sprint-status.yaml → Sprint N 스토리 목록
2. Read epics-and-stories.md → 스토리 상세
3. 각 스토리 상태 확인:
   - pending → 실행 대상
   - completed + reviewed → 건너뛰기
   - completed + NOT reviewed → review만 실행
   - failed → 재실행 대상
4. 의존성 분석:
   - 스토리 간 depends_on 확인
   - 의존하는 스토리가 미완료면 → blocked 표시
5. 실행 순서 결정:
   - 의존성 없는 스토리 → 즉시 실행 가능
   - 의존성 있는 스토리 → 선행 완료 후 실행
```

## Phase 1: Story Execution Loop

**핵심: 스토리마다 fresh agent spawn (Ralph Loop)**

```
for each batch (최대 3 stories parallel):
  
  Step 1: Task 잠금 (경쟁 조건 방지)
    - sprint-status.yaml에서 스토리 status → "in_progress" 변경
    - owner: "agent-{story-id}" 기록
    - git commit: "chore: claim story {story-id}"
    - 다른 에이전트가 같은 스토리 잡는 것 방지

  Step 2: Build (Generator)
    - Agent spawn: /kdh-build {story-id}
    - mode: bypassPermissions (자동 실행)
    - 완료 대기 (타임아웃: 30min)
    - 결과 확인: sprint-status.yaml → status: completed?

  Step 3: Review (Evaluator)
    - Agent spawn: /kdh-review {story-id}
    - mode: bypassPermissions
    - 완료 대기 (타임아웃: 15min)
    - 결과 확인: sprint-status.yaml → reviewed: true?

  Step 4: Result Processing
    - PASS → 다음 스토리로
    - CONDITIONAL → 수정 build spawn → 재 review (최대 2회)
    - FAIL → sprint-status.yaml에 기록, 사장님 판단 필요 시 GATE

  Step 5: Unblock
    - 이 스토리에 의존하던 스토리들 → blocked 해제
    - 다음 배치에 포함
```

## Phase 2: Sprint Wrap-up

```
모든 스토리 완료 후:

1. Sprint 통계:
   - 완료: N개 / 전체: M개
   - 리뷰 평균 점수: X.X/10
   - 실패 → 재실행: N건
   - ESCALATED: N건

2. tsc 전체 체크 (Sprint 레벨):
   bunx tsc --noEmit -p packages/server/tsconfig.json
   bunx tsc --noEmit -p packages/admin/tsconfig.json
   bunx tsc --noEmit -p packages/shared/tsconfig.json
   → 에러 있으면 수정 (스토리 간 충돌 가능)

3. 전체 테스트:
   bun test
   → 실패 있으면 수정

4. /kdh-e2e 호출 → E2E 검증
5. /kdh-gate sprint-verify 호출 → 사장님 브라우저 확인
   - `계속` 모드면 자동 PASS
```

## Phase 3: Progress Update

```
1. sprint-status.yaml 업데이트:
   sprint_N:
     status: completed
     completed_at: {timestamp}
     stories_completed: N
     review_avg_score: X.X
     e2e_result: PASS/FAIL

2. git commit + push:
   "chore(sprint-{N}): complete — {N} stories, avg review {X.X}/10

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## 병렬 실행 규칙

```
- 최대 3개 스토리 동시 실행
- 같은 파일을 수정하는 스토리끼리는 순차 실행
- Wiring 스토리(W-*)는 관련 스토리 전부 완료 후 실행
- Sprint Zero(0-*)는 반드시 순차 (기반 설정이므로)
```

## 경쟁 조건 방지

```
1. 스토리 잡기 전: sprint-status.yaml 읽기 → status 확인
2. status가 이미 in_progress → 건너뛰기
3. status가 pending → "in_progress" + owner 기록 → git commit
4. 다른 에이전트도 같은 파일을 수정했으면 → git pull → 충돌 해결 → 재확인
5. 이중 잠금: sprint-status.yaml 파일 + git commit 이력
```

## 타임아웃

| Phase | 제한 | 초과 시 |
|-------|------|---------|
| Sprint Load | 2min | 파일 경로 확인 |
| Build per story | 30min | 스토리 ESCALATE |
| Review per story | 15min | 기본 PASS (WARNING) |
| tsc 전체 | 5min | 에러 로그 저장 |
| E2E | 10min | 수동 확인 요청 |
| 전체 Sprint | 4h | 진행 상황 저장 후 종료 |

## `계속` 모드

```
/kdh-go 계속으로 실행 시:
- GATE = 자동 진행 (기본 선택)
- FAIL 스토리 = 1회 재시도 후 SKIP (아침에 사장님 확인)
- ESCALATED 목록을 sprint-status.yaml에 기록
- Sprint 끝나면 자동으로 다음 Sprint 시작
```

---

## Output

```
sprint-status.yaml              ← 스프린트 전체 상태
party-logs/{sprint}-*.md         ← 리뷰 로그들
git commits                      ← 스토리별 커밋 + 스프린트 완료 커밋
```
