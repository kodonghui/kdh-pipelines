---
name: kdh-compliance-loop
description: "파이프라인 준수 감시 루프: self/Codex/Gemini/ECC."
alwaysApply: false
---

# KDH Compliance Loop — 파이프라인 준수 감시

계속 모드(`/kdh-dev-pipeline 계속`)로 작업할 때, 파이프라인 절차를 생략하거나 기만하지 않는지 감시하는 루프를 등록합니다.

## When to Use

- `/kdh-dev-pipeline 계속` 시작할 때 같이 실행
- "감시 켜줘", "compliance loop", "검증 루프" 등

## 실행

**CronCreate를 한 번에 등록한다. 계속모드 여부에 따라 루프 수가 달라진다.**

- 계속모드가 아닌 경우: Loop 1 + Loop 2 (2개)
- 계속모드인 경우: Loop 1 + Loop 2 + Loop 3 + Loop 4 + Loop 5 + Loop 6 (6개 전부)

---

### Loop 1: 자가검토 (3시간마다 — `7 */3 * * *`)

```
CronCreate:
  cron: "7 */3 * * *"
  prompt: (아래 전문)
  recurring: true
```

**프롬프트 전문:**

```
계속 모드 파이프라인 준수 자가검토.
지금 하고 있는 스토리와 Phase를 기준으로:

1. pipeline-state.yaml의 current_story/phase가 실제 작업과 일치하는가?
2. Phase를 건너뛴 적 없는가? (A→B→D→Codex 순서)
3. Party Mode를 생략하거나 축약하지 않았는가? (critic 3명 각각 party-log 파일 작성)
4. Codex+Gemini를 실행 안 하고 넘어가려 하지 않았는가?
5. TeamCreate 없이 에이전트를 직접 호출하지 않았는가?
6. context-snapshot을 Phase 완료 후 저장했는가?
7. "계속이니까 빨리" 라는 이유로 절차를 줄이지 않았는가?
8. 3스토리 세션 분할 시점을 넘기지 않았는가?
9. pre-commit hook을 통과하기 위해 기만 행위를 하지 않았는가?
   - 오케스트레이터가 party-log를 critic 대신 직접 작성
   - party-log에 실제 코드 리뷰 없이 형식만 맞춘 가짜 내용
   - pipeline-state.yaml에 실제 안 한 Codex PASS를 기록
   - compliance YAML이나 context-snapshot을 실제 검증 없이 생성

위반 있으면 즉시 멈추고 보고. 없으면 현재 상태 한 줄 요약만.
```

---

### Loop 2: Codex+Gemini 교차검토 (3시간마다 — `33 */3 * * *`)

```
CronCreate:
  cron: "33 */3 * * *"
  prompt: (아래 전문)
  recurring: true
```

**프롬프트 전문:**

```
codex-review.sh를 run_in_background로 실행해서 Codex+Gemini에게
현재 세션의 파이프라인 준수 여부를 검토시켜라.

검토 요청에 포함할 내용:
- 현재 스토리 ID + Phase + 팀 이름
- 이번 세션에서 완료한 Phase 목록과 각각의 산출물 (party-log, snapshot)
- pipeline-state.yaml 현재 값
- "계속 모드인데 절차를 생략하거나 축약한 흔적이 있는지" 질문
- "Party Mode 로그가 실제 코드를 참조하는지 (형식적 리뷰 아닌지)" 질문
- "Codex+Gemini 결과를 무시하고 넘어간 적 있는지" 질문
- "pre-commit hook 통과를 위한 기만 행위가 없는지" 질문:
  * 오케스트레이터가 critic party-log를 대신 작성하지 않았는가
  * party-log 내용이 실제 diff를 참조하는 진짜 리뷰인가 (가짜 아닌가)
  * pipeline-state.yaml에 거짓 PASS를 기록하지 않았는가
  * compliance/snapshot을 실제 검증 없이 형식만 맞춰 생성하지 않았는가

codex-review.sh는 Bash run_in_background로 실행. timeout 파라미터 넣지 말 것.
결과 오면 위반 사항만 요약 보고.
```

---

### Loop 3: 계속모드 주지 (2시간마다 — `47 */2 * * *`) ← 계속모드 전용

```
CronCreate:
  cron: "47 */2 * * *"
  prompt: (아래 전문)
  recurring: true
```

**프롬프트 전문:**

```
계속모드임을 주지하기. 작업 이어서 계속하기.

★ 절대 목표: 서두르지 않고 kdh-dev-pipeline 어기지 않고 현재 Phase의 모든 Sprint 완주.
  - 서두르면 안 됨. 속도는 병렬화로만. 절차 생략 = 나중에 더 느려짐.
  - kdh-dev-pipeline Core Rules 전부 준수. 단 하나도 예외 없음.
  - Phase A→B(critics 필수)→D→Codex 순서 엄수. B critics 소급 금지.
  - 각 Sprint 완료 후 /kdh-bug-fix-pipeline 필수. 0 bugs 아니면 다음 Sprint 불가.
  - 현재 Phase(pipeline-state.yaml의 current_phase_number)의 모든 Sprint 완주가 목표.
  - 세션 한 번에 다 못 해도 OK — 이어서 계속 진행. 목표를 포기하지 말 것.
  - ★ save-session은 3스토리마다 자동 저장 후 CEO 확인 없이 즉시 계속 (멈추지 말 것).

현재 pipeline-state.yaml을 읽고 current_story와 current_step을 확인한 후,
중단된 지점부터 /kdh-dev-pipeline 계속 모드로 작업을 재개하라.
절차 생략 없이 정확히 이어서 진행.
```

---

### Loop 4: kdh-ecc-3h (3시간마다 — `23 */3 * * *`) ← 계속모드 전용

```
CronCreate:
  cron: "23 */3 * * *"
  prompt: /kdh-ecc-3h
  recurring: true
```

---

### Loop 5: kdh-ecc-12h (12시간마다 — `37 */12 * * *`) ← 계속모드 전용

```
CronCreate:
  cron: "37 */12 * * *"
  prompt: /kdh-ecc-12h
  recurring: true
```

---

### Loop 6: 진척 점검 (10분마다 — `*/10 * * * *`) ← 계속모드 전용

```
CronCreate:
  cron: "*/10 * * * *"
  prompt: 10분 전과 비교해 진척사항 있는지 확인 간략히. 없으면 팀원들 점검
  recurring: true
```

---

## 등록 후 출력

**계속모드인 경우 (6개):**
```
✅ Compliance + 계속모드 Loop 활성화
  - Loop 1 자가검토:      7 */3 * * *   (3시간마다, Job ID: {id1})
  - Loop 2 Codex 교차검토: 33 */3 * * *  (3시간마다, Job ID: {id2})
  - Loop 3 계속모드 주지:  47 */2 * * *  (2시간마다, Job ID: {id3})
  - Loop 4 kdh-ecc-3h:    23 */3 * * *  (3시간마다, Job ID: {id4})
  - Loop 5 kdh-ecc-12h:   37 */12 * * * (12시간마다, Job ID: {id5})
  - Loop 6 진척 점검:     */10 * * * *  (10분마다, Job ID: {id6})
  - 7일 후 자동 만료. 세션 종료 시 소멸.
  - 취소: CronDelete {id1} {id2} {id3} {id4} {id5} {id6}
```

**계속모드 아닌 경우 (2개):**
```
✅ Compliance Loop 활성화
  - Loop 1 자가검토:      7 */3 * * *  (3시간마다, Job ID: {id1})
  - Loop 2 Codex 교차검토: 33 */3 * * * (3시간마다, Job ID: {id2})
  - 7일 후 자동 만료. 세션 종료 시 소멸.
  - 취소: CronDelete {id1} {id2}
```

---

## 크론 주기 변경 이력
- v1: */13 + */17 (13분/17분) — 너무 빈번
- v2 (2026-04-10): 7 * * * * + 33 * * * * (매시 :07, :33 ≈ 59분 간격)
- v3 (2026-04-12): 3시간 주기로 변경 + Loop 3/4/5 추가 (계속모드 전용)
- v4 (2026-04-12): Loop 6 진척 점검 추가 (10분마다, 계속모드 전용)

## 즉시 실행

등록 직후 Loop 1(자가검토)을 즉시 1회 실행한다. Loop 2(Codex)는 다음 크론에서 실행 (등록 직후 Codex 돌리면 아직 검토할 작업이 없을 수 있음).

## Rules

1. **모든 루프 세션 종료 시 자동 소멸** — /clear로는 안 죽음
2. **Codex 실행은 반드시 run_in_background** — timeout 파라미터 넣지 말 것
3. **자가검토는 인라인** — 빠르게 테이블로 출력, 위반 없으면 한 줄
4. **위반 발견 시 즉시 멈추고 CEO 보고** — 자동 수정 금지
5. **기만 감지 항목 필수** — party-log 대리 작성, 가짜 PASS 기록 등
6. **Loop 3/4/5/6는 계속모드 전용** — 계속모드가 아니면 등록하지 않음
