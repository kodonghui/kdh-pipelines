---
name: kdh-sprint
description: "Sprint Orchestrator — 스프린트 전체를 관리. 스토리별 build→review 사이클 + 의존성 + E2E 검증."
---

# KDH Sprint v11 — Sprint Orchestrator

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

## Phase -1: 팀 부트스트랩 (v13 — 필수, 30초)

이 Phase는 선택이 아닙니다. TeamCreate 없이 Phase 0 진행 금지.

```
1. TeamCreate("sprint-{N}")
   → ~/.claude/teams/sprint-{N}/ 디렉토리 생성됨
   → tmux에 팀 공간 생성 (사장님 눈에 보임)

2. 팀 존재 확인:
   ls ~/.claude/teams/sprint-{N}/config.json → 존재해야 함
   없으면 → 중단. "TeamCreate 실패. 진행 불가." 보고.

3. pipeline-state.yaml 업데이트:
   sprint_{N}.team_created: true
   sprint_{N}.team_name: "sprint-{N}"

4. 이 시점부터 감독의 역할 (절대 규칙):
   ✅ 파일 읽기 (sprint-status.yaml, 계약서, 스키마 등)
   ✅ 스토리를 팀 에이전트에게 위임 (Agent 도구로 소환)
   ✅ 진행 상황 모니터링 (TaskList, TaskGet)
   ✅ Bash 실행 (tsc, bun test, git 등)
   ❌ packages/*/src/ 직접 수정 금지 (Hook이 차단)
```

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

  Step 2: Build (Generator) — 커밋 안 함
    - Agent spawn: /kdh-build {story-id}
    - mode: bypassPermissions (자동 실행)
    - 완료 대기 (타임아웃: 30min)
    - 결과 확인: sprint-status.yaml → status: built? (completed 아님!)
    - ★ 빌더는 git commit 안 함. 코드만 작성.

  Step 3: Review (Evaluator) — 빌드 직후, 커밋 전
    - Agent spawn: /kdh-review {story-id}
    - mode: bypassPermissions
    - 완료 대기 (타임아웃: 15min)
    - 결과 확인: sprint-status.yaml → review_state?

  Step 3.5: 커밋 (리뷰 PASS 후에만 — 오케스트레이터가 직접)
    ★★★ 이 단계가 없으면 커밋 금지 ★★★
    리뷰 PASS 확인 후:
    - git add {빌더가 변경한 파일들}
    - git commit: "feat({epic}): {story-id} — {title}
      - TDD: {N} tests, reviewed by winston/quinn/john
      - Review avg: {X.X}/10"
    - sprint-status.yaml: status → completed (built → completed로 변경)
    - git push origin main

  Step 4: Result Processing (HARD ENFORCEMENT)
    PASS:
      → Step 3.5 커밋 실행
      → sprint-status.yaml: review_state: passed, status: completed
      → 다음 스토리 진행

    CONDITIONAL (BLOCKING LOOP — 미해결 시 다음 스토리 진행 금지):
      a. sprint-status.yaml: review_state: conditional
      b. party-logs/{sprint}-{story}-fixes-needed.md 생성됨
      c. 이 스토리 resolve 될 때까지 sprint 일시정지
      d. /kdh-build {story-id} fix-mode spawn (fixes-needed.md 읽고 해당 이슈만 수정)
      e. /kdh-review {story-id} --re-review spawn (새 에이전트, D1-D6 재채점)
      f. 결과: PASS → 진행. 여전히 CONDITIONAL → review_attempt++
      g. review_attempt >= 3 → review_state: escalated → /kdh-gate review-escalation
      h. CRITICAL: 이 스토리 미해결 시 다음 스토리 진행 절대 금지

    FAIL:
      → sprint-status.yaml: review_state: failed
      → /kdh-gate 호출 (사장님 판단)

    AUTO-FAIL:
      → sprint-status.yaml: review_state: auto-fail
      → /kdh-gate auto-fail 즉시 호출

  Step 5: Unblock
    - 이 스토리에 의존하던 스토리들 → blocked 해제
    - 다음 배치에 포함

  Step 5.5: Batch Integration Review (v12)
    IF batch_completed_count >= 3 OR last_batch_in_sprint:
      Agent spawn: /kdh-integration batch
      입력: 이번 Batch의 스토리 ID 목록
      결과:
        PASS → 다음 Batch
        WARNING → 기록 후 진행
        FAIL → 해당 스토리 CONDITIONAL 되돌림
```

### v15 스토리 실행 패턴 — "한 팀 = 한 스토리" (벤치마크 기반)

★★★ 별도 reviewer 에이전트 없음. 오케스트레이터가 critics를 직접 관리. ★★★
★★★ 4명 전부 팀 에이전트 (team_name 필수). 서브에이전트 금지. ★★★

각 스토리에 대해:

Phase 0: 팀 에이전트 4명 소환 (전부 team_name: "sprint-{N}")
  dev = Agent(name: "dev-{story-id}", team_name: "sprint-{N}", mode: "bypassPermissions",
              prompt: "kdh-build 스킬 내용 + 스토리 컨텍스트")
  winston = Agent(name: "winston-{story-id}", team_name: "sprint-{N}", mode: "bypassPermissions",
              prompt: "아키텍처 리뷰어. _bmad/bmm/agents/architect.md 페르소나 먼저 읽기.
                       리뷰 지시 올 때까지 대기.")
  quinn = Agent(name: "quinn-{story-id}", team_name: "sprint-{N}", mode: "bypassPermissions",
              prompt: "QA 리뷰어. _bmad/bmm/agents/qa.md 페르소나 먼저 읽기.
                       리뷰 지시 올 때까지 대기.")
  john = Agent(name: "john-{story-id}", team_name: "sprint-{N}", mode: "bypassPermissions",
              prompt: "요구사항 리뷰어. _bmad/bmm/agents/pm.md 페르소나 먼저 읽기.
                       리뷰 지시 올 때까지 대기.")
  → tmux에 4개 창 보임 (CEO 확인 가능)

Phase A: Build (dev 리드)
  오케스트레이터 → SendMessage(to: "dev-{story-id}",
    "스토리 {story-id} 빌드 시작. kdh-build 스킬대로 TDD.
     완료 후 변경 파일 목록 보고. git commit 금지.")
  dev: 파일 읽기 → 테스트 작성(RED) → 구현(GREEN) → tsc → test
  dev 완료 → 오케스트레이터에게 idle 알림 (자동)
  오케스트레이터: sprint-status.yaml 확인 → status: built?

Phase B: Review (winston/quinn/john 병렬 — 오케스트레이터가 지시)
  오케스트레이터 → SendMessage 3명에게 동시 (아래 전문 그대로):

    "스토리 {story-id} 리뷰. 변경 파일: {목록}.

    ## Step 1: Auto-Fail 체크 (먼저 — YES면 즉시 중단)
    - [ ] 하드코딩 시크릿 없음
    - [ ] SQL injection / XSS 없음
    - [ ] tsc 에러 없음
    - [ ] 데이터 손실 위험 없음
    - [ ] 인라인 타입 없음 (@corthex/shared만 사용)
    YES → party-log에 AUTO-FAIL 기록 후 보고.

    ## Step 2: 변경 파일 전부 Read 도구로 읽기

    ## Step 3: D1-D6 채점 (이 테이블 그대로 party-log에)

    | 차원 | 점수 | 가중치 | 가중점수 | 근거 (file:line 필수) |
    |------|------|--------|----------|---------------------|
    | D1 구체성 | /10 | {%} | | {테스트명, 에러코드, 줄번호} |
    | D2 완전성 | /10 | {%} | | {AC 충족, 엣지 케이스} |
    | D3 정확성 | /10 | {%} | | {타입=contract, DB=schema} |
    | D4 실행가능성 | /10 | {%} | | {tsc, test 통과 확인} |
    | D5 일관성 | /10 | {%} | | {contract import, 네이밍} |
    | D6 리스크인식 | /10 | {%} | | {보안, 확장성, 통합} |

    가중치: winston D1=15 D2=15 D3=25 D4=20 D5=15 D6=10
            quinn   D1=10 D2=25 D3=15 D4=10 D5=15 D6=25
            john    D1=20 D2=20 D3=15 D4=15 D5=10 D6=20
    가중 평균 = (D1×w1+...+D6×w6)/100. 계산식 표시.
    D < 3 → AUTO-FAIL.

    ## Step 4: 이슈 목록
    형식: [D{N} {차원명}] [{CRITICAL|HIGH|MEDIUM|LOW}] {설명} — {path}:{line}

    ## Step 5: Cross-talk (의무)
    다른 critic 2명에게 SendMessage: 핵심 이슈 1개.
    받은 후 party-log에 ## Cross-talk 섹션:
    - {이름}이 지적한 {이슈}: {동의/반박 + 이유}

    ## Step 6: party-logs/sprint-{N}-{story-id}-{본인이름}.md 작성
    ## Step 7: 완료 보고"

  각 critic: Auto-fail → 파일 읽기 → D1-D6 채점 → 이슈 → cross-talk → party-log

  오케스트레이터 체크리스트 (BLOCKING):
    [ ] party-logs/sprint-{N}-{story-id}-winston.md 존재
    [ ] party-logs/sprint-{N}-{story-id}-quinn.md 존재
    [ ] party-logs/sprint-{N}-{story-id}-john.md 존재
    [ ] 각 로그에 D1-D6 테이블 6행 존재
    [ ] 각 로그에 Cross-talk 섹션 존재 (placeholder 아님)
    하나라도 없으면 → 해당 critic에게 재작성 요청

  오케스트레이터: 3개 party-log 읽기 → 가중 평균 계산
  점수 분산 체크: stdev < 0.5 → 경고 + 1명 독립 재채점 요청

Phase C: 판정 + 커밋/수정
  PASS (3명 모두 ≥ 7.0 AND 평균 ≥ 7.0):
    → 오케스트레이터 커밋:
      git add {변경 파일}
      git commit: "feat({epic}): {story-id} — {title}
        - TDD: {N} tests, reviewed by winston/quinn/john
        - Review avg: {X.X}/10"
      git push origin main
    → sprint-status.yaml: status → completed, review_state → passed

  CONDITIONAL (평균 < 7.0 OR 1명이라도 < 7.0):
    → party-logs/sprint-{N}-{story-id}-fixes-needed.md 생성
    → 오케스트레이터 → SendMessage(to: "dev-{story-id}",
        "수정 필요. fixes-needed.md 읽고 해당 이슈만 수정.
         수정 완료 후 보고.")
    → dev 수정 → 오케스트레이터에게 보고
    → Phase B 재실행 (critics에게 재리뷰 지시)
    → 최대 2회. 3회 실패 → ESCALATE → /kdh-gate review-escalation
    ★ CONDITIONAL 미해결 시 다음 스토리 진행 절대 금지 ★

  AUTO-FAIL (D < 3 또는 보안/빌드 문제):
    → /kdh-gate auto-fail 즉시 호출

Phase D: Cleanup
  오케스트레이터 → 4명 전원 shutdown_request
  → 다음 스토리로

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

4. /kdh-integration sprint → Sprint 간 통합 리뷰 (v12: E2E 전 필수)
     - PASS → E2E 진행
     - WARNING → E2E에 추가 체크포인트 전달
     - FAIL → 수정 필수 (E2E 진행 불가)

5. /kdh-e2e 호출 → E2E 검증 (v11: HARD BLOCKING — FAIL이면 Sprint 완료 불가)
     - E2E FAIL → P0/P1 버그 수정 필수 → 재실행
     - E2E 스킵 = Sprint FAIL (더 이상 "백로그" 허용 안 됨)
     - E2E PASS 후에만 sprint-verify 진행

5. Sprint Review Summary 생성:
   party-logs/{sprint}-review-summary.md:
   - 스토리별: 3명 리뷰어 D1-D6 점수 + 가중 평균
   - 차원별 Sprint 평균: D1~D6 전체 평균
   - 재리뷰 현황: N건 (어떤 스토리, 몇 회)
   - 에스컬레이션: N건
   - Cross-talk 하이라이트: top 3 합의 이슈

6. /kdh-gate sprint-verify 호출 → 사장님에게 리뷰 요약 + 브라우저 확인
   - `계속` 모드면 자동 PASS
```

## Phase 3: Progress Update

```
1. sprint-status.yaml 업데이트:
   스토리별: review_state, review_attempt, review_scores (D1-D6 per reviewer), review_avg
   sprint_N:
     status: completed
     completed_at: {timestamp}
     stories_completed: N
     review_summary:
       overall_avg: X.X
       dimension_avgs: { d1: X.X, d2: X.X, d3: X.X, d4: X.X, d5: X.X, d6: X.X }
       stories_passed_first_try: N
       stories_needed_re_review: N
       stories_auto_failed: N
       stories_escalated: N
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
