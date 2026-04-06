---
name: kdh-help
description: "뭐해야하지? — 프로젝트 상태 읽고 다음 할 일 자동 감지 + 선택지 제시. planning/dev/bug-fix 중 뭘 해야 하는지 판단."
---

# KDH Help — "뭐해야하지?"

프로젝트 상태를 읽고 자동으로 다음 할 일을 판단합니다.
planning이 필요하면 `/kdh-planning-pipeline`, dev가 필요하면 `/kdh-dev-pipeline`, 버그면 `/kdh-bug-fix-pipeline`을 안내합니다.

## When to Use

- `/kdh-help` — 지금 뭐 해야 하는지 모를 때
- "뭐해야하지?", "다음 뭐야?", "현황 알려줘"
- 새 세션 시작할 때 상태 파악용

## Phase 1: 상태 자동 감지 (30초)

**전부 읽기만 한다. 아무것도 수정하지 않는다.**

```
1. pipeline-state.yaml 읽기:
   - current_phase_number, mode, current_stage, current_step
   - current_story (활성 스토리 있는지)

2. Planning 완료 여부:
   - project-context.yaml 없음 → "planning부터 시작"
   - product-brief 없음 → "/kdh-planning-pipeline (Stage 0부터)"
   - prd.md 없음 → "/kdh-planning-pipeline (Stage 2부터)"
   - architecture.md 없음 → "/kdh-planning-pipeline (Stage 4부터)"
   - epics-and-stories.md 없음 → "/kdh-planning-pipeline (Stage 6부터)"
   - contracts/index.ts 없음 → "/kdh-planning-pipeline (Stage 6.5)"
   - sprint-status 없음 → "/kdh-planning-pipeline (Stage 7)"

3. Sprint 상태:
   - 미완료 스토리 있음 → "/kdh-dev-pipeline sprint {N}"
   - 스프린트 완료 + E2E 안 함 → "/kdh-dev-pipeline (E2E 실행)"
   - 전부 완료 → 다음 스프린트 or Phase 완료

4. 리뷰/통합 상태:
   - review_state: conditional → 해당 스토리 수정
   - integration_state: fail → 통합 이슈 해결

5. 버그 상태:
   - bug-fix-state.yaml 존재 + current_phase != complete → "/kdh-bug-fix-pipeline 이어서"

6. 최근 세션 + 메모리 + git log 확인
```

## Phase 2: 상태 보고 (한국어)

```
══════════════════════════════════════
  CORTHEX v3 — 현재 상태
══════════════════════════════════════

📍 지금 위치: {Phase N / Planning / Sprint N}

✅ 된 것:
  - {완료된 항목들}

🔧 해야 할 것:
  - {미완료 항목들 — 우선순위순}

🚫 막힌 것:
  - {블로커들}

📊 숫자:
  - 스토리: {완료}/{전체}
  - 테스트: {통과 수}
  - 마지막 커밋: {시간 전}

══════════════════════════════════════
```

## Phase 3: 선택지 제시

```
다음에 뭐 할까요?

A. {가장 추천하는 다음 단계} (추천)
   └── {왜 이걸 먼저 해야 하는지 한 줄}

B. {두 번째 옵션}
   └── {설명}

C. {세 번째 옵션}
   └── {설명}

D. 다른 거 하고 싶어 (직접 말해주세요)
```

### 선택지 결정 로직

```
우선순위:
1. 블로커 해결 (막힌 거 먼저)
2. 이전 세션의 "Exact Next Step" 이어하기
3. Sprint 미완료 스토리 → /kdh-dev-pipeline
4. Planning 미완료 → /kdh-planning-pipeline
5. 버그 발견 → /kdh-bug-fix-pipeline
6. Phase 완료 → 다음 Phase 기획
7. 아무것도 없으면 → "다 했어요!"
```

## 사용 가능한 KDH 명령어 (사장님용)

| 명령어 | 뭐 하는 건지 |
|--------|------------|
| `/kdh-planning-pipeline` | 기획 (PRD, 설계, 스토리) |
| `/kdh-dev-pipeline` | 개발 (코드 짜기) |
| `/kdh-dev-pipeline 계속` | 밤새 자동으로 |
| `/kdh-bug-fix-pipeline` | 버그 찾고 고치기 |
| `/kdh-help` | 지금 뭐 해야 하는지 (이거) |
| `/kdh-research 주제` | 뭔가 조사해줘 |
| `/kdh-analyze 주제` | 깊이 분석해줘 |
| `/kdh-plan 작업` | 실행 계획 세워줘 |
| `/save-session` | 지금까지 한 거 저장 |
| `/resume-session` | 저번에 하던 거 이어하기 |

## Rules

1. **한국어만** — 기술 용어 절대 금지
2. **읽기만** — Phase 1에서 아무것도 수정하지 않음
3. **짧게** — 보고서는 화면 한 페이지 이내
4. **선택지는 3개** — D는 "다른 거"로 고정
5. **추천 표시** — 가장 좋은 옵션에 (추천) 붙이기
