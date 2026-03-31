---
name: kdh-go
description: "원커맨드 — 프로젝트 상태를 자동 판단하고 다음 할 일을 알아서 실행. 사장님이 칠 유일한 명령어."
---

# KDH Go — 원커맨드 자동 실행

프로젝트 상태를 읽고 다음 할 일을 자동으로 판단해서 실행.
**사장님이 알아야 할 명령어는 이것 하나.**

## When to Use

- `/kdh-go` — 다음 할 일 알아서 해 (낮에, 사장님 있을 때)
- `/kdh-go 계속` — GATE 멈춤 없이 밤새 돌려 (자기 전에)

## Pattern: Dispatcher (자동 라우팅)

```
1. 프로젝트 상태 파악
2. 어떤 스킬을 호출할지 자동 결정
3. 실행 → 완료 → 다음 단계 자동 판단 → 반복
```

---

## Phase 0: State Detection (30s)

```
1. project-context.yaml 존재하는지?
   - 없음 → 프로젝트 스캔 필요 → /kdh-plan (Step 0부터)

2. _bmad-output/planning-artifacts/ 확인:
   - product-brief 없음 → /kdh-plan (Stage 0부터)
   - prd.md 없음 → /kdh-plan (Stage 2부터)
   - architecture.md 없음 → /kdh-plan (Stage 4부터)
   - epics-and-stories.md 없음 → /kdh-plan (Stage 6부터)

3. packages/shared/src/contracts/index.ts 확인:
   - 없음 → /kdh-plan (Stage 6.5)

4. sprint-status.yaml 확인:
   - 없음 → /kdh-plan (Stage 7 Sprint Planning)
   - 있음 → Sprint 상태 읽기

5. Sprint 상태 분석:
   - 미완료 스토리 있음 → /kdh-sprint {N} (이어서)
   - 스프린트 완료 + E2E 안 함 → /kdh-e2e
   - E2E 완료 + GATE 안 함 → /kdh-gate sprint-verify
   - 전부 완료 → 다음 스프린트 존재? → /kdh-sprint {N+1}
   - 전체 Phase 완료 → "Phase 1 완료!" 보고

5.5 리뷰 상태 확인 (5번보다 우선):
   sprint-status.yaml 전체 스캔:
   - review_state: conditional 있음 →
     "스토리 {id}가 검토 조건부 통과 상태입니다. 수정이 필요합니다."
     → /kdh-sprint {N} (CONDITIONAL 해결부터)
   - review_state: auto-fail 있음 →
     "스토리 {id}에 심각한 문제가 발견됐습니다. 확인이 필요합니다."
     → /kdh-gate review-escalation
   - review_state: escalated 있음 →
     "스토리 {id}가 에스컬레이션 상태입니다."
     → /kdh-gate review-escalation
   - 전부 passed 또는 null → 5번 정상 진행
```

## Phase 1: Execute

상태 판단 결과에 따라 적절한 스킬 호출:

```
Action Map:
  NEED_PLANNING    → /kdh-plan {stage}
  NEED_CONTRACTS   → /kdh-plan stage-6.5
  NEED_SPRINT_PLAN → /kdh-plan stage-7
  SPRINT_IN_PROGRESS → /kdh-sprint {N}
  NEED_E2E         → /kdh-e2e
  NEED_GATE        → /kdh-gate {type}
  NEXT_SPRINT      → /kdh-sprint {N+1}
  PHASE_COMPLETE   → 보고 + 대기
```

## Phase 2: Loop (계속 모드)

```
/kdh-go 계속 실행 시:
  while (Phase 1 미완료):
    1. State Detection
    2. Execute (GATE 자동 진행 — 기본 선택 A)
    3. 완료 확인
    4. 다음 상태 판단 → 반복

  FAIL 스토리: 1회 재시도 → 여전히 FAIL → SKIP + 기록
  ESCALATED 목록: sprint-status.yaml에 기록
  Phase 완료 시: 최종 보고서 작성 + 종료
```

---

## 사장님 시나리오

### 낮에 (사장님 있을 때)
```
사장님: /kdh-go
→ "Sprint 1 스토리 3개 남아있어요. 이어서 할게요."
→ 스토리 build → review → ... 
→ Sprint 끝: "Sprint 1 끝났어요. 브라우저에서 확인해주세요."
→ [GATE] 사장님 확인 대기
사장님: "ㅇㅋ"
→ "Sprint 2 시작합니다."
→ ...
```

### 밤에 (자러 갈 때)
```
사장님: /kdh-go 계속
→ "밤새 모드로 실행합니다. GATE는 기본 선택으로 자동 진행합니다."
→ Sprint 2, 3, 4, 5... 논스톱
→ (아침에 사장님 확인)
→ 결과 보고서 출력
```

### 아무것도 안 되어있을 때
```
사장님: /kdh-go
→ "아직 기획이 안 되어있어요. 기획부터 시작할게요."
→ /kdh-plan 자동 실행
→ GATE에서 사장님 질문: "이 방향 맞아요? A할까요 B할까요?"
→ ...
```

---

## `계속` 모드 규칙

```
1. 모든 GATE → 기본 선택 (A) 자동 진행
2. GATE 결정에 [AUTO] 표시
3. 아침에 사장님이 확인하고 변경 가능
4. FAIL 스토리 → 1회 재시도 → SKIP
5. ESCALATED → sprint-status.yaml에 기록
6. Phase 완료 → 종료 (다음 Phase는 사장님 확인 후)
```

## Ralph Loop 옵션 (밤샘 최안정)

```bash
# 터미널에서 한 줄 — 매 반복마다 fresh context
while true; do claude -p "$(cat <<'EOF'
/kdh-go 계속
EOF
)"; sleep 5; done
```

컨텍스트 오염 없이 가장 안정적인 밤샘 방법.
각 반복이 독립 세션 → 긴 작업에서도 품질 유지.

---

## 보고 형식

실행 시작/종료 시 사장님에게 한국어 보고:

```
시작:
  "Sprint {N} 이어서 합니다. 스토리 {M}개 남았어요."

스토리 완료:
  "스토리 {id} 완료. 리뷰 평균: {X.X}/10. ({N}/{M} 진행)"

Sprint 완료:
  "Sprint {N} 끝! {M}개 스토리, 평균 리뷰 {X.X}/10.
   - 잘한 것: {최고 차원 한국어명} (평균 {X.X})
   - 개선 필요: {최저 차원 한국어명} (평균 {X.X})
   - 재리뷰: {N}건, 에스컬레이션: {N}건
   브라우저에서 확인해주세요." (GATE)
   
차원 한국어명: D1=구체성, D2=완전성, D3=정확성, D4=실행가능성, D5=일관성, D6=리스크인식

Phase 완료:
  "Phase 1 전부 끝났습니다! 
   기능 5개 완성:
   1. 회원가입/로그인 ✅
   2. 회사 관리 ✅
   3. 부서 관리 ✅
   4. 직원 관리 ✅
   5. AI 에이전트 관리 ✅
   브라우저에서 확인해주세요."
```

---

## Output

이 스킬 자체는 파일을 생성하지 않음.
호출하는 하위 스킬들(plan, sprint, e2e, gate)이 각각 파일 생성.
