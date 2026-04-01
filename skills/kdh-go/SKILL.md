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

5.8 통합 상태 확인 (v12):
   sprint-status.yaml에서 integration_state 확인:
   - integration_state: fail →
     "스토리 간 충돌이 발견됐어요. 수정이 필요합니다."
     → /kdh-sprint {N} (통합 이슈 해결)
   - integration_state: warning →
     정상 진행 (E2E에서 추가 확인)

5.7 E2E 상태 확인 (v11):
   sprint-status.yaml에서 현재 Sprint의 e2e_result 확인:
   - Sprint 완료(stories 전부 completed) + e2e_result: null →
     "Sprint {N}이 완료됐는데 E2E 테스트를 안 돌렸어요."
     → /kdh-e2e 강제 호출
   - e2e_result: fail →
     "Sprint {N} E2E에서 버그가 발견됐어요."
     → 버그 목록 보여주고 /kdh-sprint {N} (E2E 버그 수정)
```

## ★★★ 절대 규칙 — 이것을 어기면 CEO가 전체 삭제함 ★★★

```
이 규칙은 CEO가 3번 코드 전체 삭제 후 직접 지시한 것이다.
"선언"이 아니라 "실행 흐름 자체"에 박혀있다. 건너뛸 수 없다.

1. 감독(이 세션)은 packages/*/src/ 에 Write/Edit 절대 금지.
   - .ts, .tsx, .css, .json 등 모든 구현 파일
   - "간단한 수정", "한 줄 고치기", "import 정리" 포함 — 전부 금지
   - 깨진 빌드 수정도 직접 안 함 → 팀 에이전트가 함

2. 코딩이 필요하면 반드시 이 순서 (v15 "한 팀 = 한 스토리"):
   TeamCreate("sprint-{N}")
   → 스토리마다 4명 팀 에이전트 소환:
     dev-{story} (빌더), winston-{story}, quinn-{story}, john-{story}
     전부 team_name: "sprint-{N}" 필수. 서브에이전트 금지.
   → dev가 빌드 (커밋 안 함)
   → 오케스트레이터가 winston/quinn/john에게 SendMessage로 리뷰 지시
   → critics끼리 cross-talk (SendMessage)
   → PASS → 오케스트레이터 커밋
   → CONDITIONAL → dev에게 수정 지시 → 재리뷰
   → 4명 전원 shutdown → 다음 스토리
   이 순서를 건너뛰면 안 됨. 별도 reviewer 에이전트 없음.

3. 코드 리뷰 시 Codex CLI 세컨드 오피니언 필수 (tmux 실시간):
   # Codex 창 열기 (CEO가 실시간으로 봄)
   CODEX_PANE=$(tmux split-window -h -P -F '#{pane_id}' "bash")
   tmux select-pane -t $CODEX_PANE -T "codex-reviewer"
   # Codex한테 리뷰 보내기
   tmux send-keys -t $CODEX_PANE 'npx @openai/codex exec - --json \
     --sandbox read-only -o {output}.md -C /home/ubuntu/corthex-v3 \
     <<'"'"'PROMPT'"'"'
   [리뷰 프롬프트]
   PROMPT' C-m
   # 완료 대기 → 결과 읽기 → Codex 창 닫기
   GPT-5.4 fresh session. CEO가 Codex 작업 과정을 tmux에서 실시간 확인.
   Codex 실패 시 → Claude Agent fallback (kdh-integration 참조)

4. 리뷰는 3명 팀 에이전트 파티 모드 필수 (winston, quinn, john):
   Finding-First + CoT(Evidence Collection) + 4-point scale (영어 프롬프트)
   각 finding에 Expected/Actual/Impact/Fix 포함 → dev가 읽고 바로 수정
   PASS: 평균 ≥ 3.0/4 AND CRITICAL findings 0건

5. UI 스토리는 반드시 Subframe + CEO 디자인 시스템:
   Subframe 프로젝트: fe1d14ed3033
   디자인 기준: Linear 다크 미니멀 + Genesis 프리미엄 + 한국 기업 세련됨
   색상 테마: CEO가 정한 테마 (벚꽃, Toss 라이트/다크, 라벤더 등)
   Subframe MCP로 디자인 → React 코드 내보내기 → 빌더가 적용
   UI 스토리에서 Subframe 안 쓰면 = 자동 FAIL
   참고: memory/feedback_design_taste.md, memory/reference_subframe_project.md

6. 감독이 할 수 있는 것:
   ✅ Read, Grep, Glob (파일 읽기)
   ✅ Bash (tsc, bun test, git, curl 등)
   ✅ sprint-status.yaml, pipeline-state.yaml 수정
   ✅ party-logs/, _bmad-output/ 파일 작성
   ✅ TeamCreate, Agent, TaskCreate, SendMessage
   ✅ GATE 질문 (사장님에게)

이 규칙의 이유: CEO가 3번 전체 삭제. 감독이 직접 코딩하면
코드 품질이 파이프라인을 무시하고 떨어짐. 팀 에이전트는
fresh context로 실행되어 편향 없이 작업함.
```

## Phase 1: Execute

상태 판단 결과에 따라 적절한 스킬 호출:

```
Action Map:
  NEED_PLANNING      → /kdh-plan {stage}
  NEED_CONTRACTS     → /kdh-plan stage-6.5
  NEED_SPRINT_PLAN   → /kdh-plan stage-7
  SPRINT_IN_PROGRESS → 아래 "Sprint 실행 흐름" 참조
  NEED_E2E           → /kdh-e2e
  NEED_GATE          → /kdh-gate {type}
  NEXT_SPRINT        → 아래 "Sprint 실행 흐름" 참조
  PHASE_COMPLETE     → 보고 + 대기
```

### Sprint 실행 흐름 → kdh-sprint 위임

```
★★★ kdh-go는 자체 Sprint 흐름을 실행하지 않는다 ★★★
★★★ 반드시 kdh-sprint 스킬의 흐름을 따른다 ★★★

SPRINT_IN_PROGRESS 또는 NEXT_SPRINT 상태면:
  → /kdh-sprint {N} 호출 (이 스킬이 전부 관리)

kdh-sprint가 관리하는 것:
  1. TeamCreate
  2. 스토리별: Build(커밋 안 함) → Review(3명 파티) → PASS 후 커밋
  3. Batch 통합 리뷰
  4. tsc + test + E2E
  5. Sprint 완료 보고

kdh-go가 직접 Builder/Reviewer를 소환하면 안 된다.
kdh-go는 상태 판단 + kdh-sprint 호출만 한다.
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
