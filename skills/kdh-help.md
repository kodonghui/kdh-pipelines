---
name: kdh-help
description: "뭐해야하지? — 프로젝트 상태 읽고 다음 할 일 제안. 세션/메모리/스프린트/블로커 전부 분석."
---

# KDH Help — "뭐해야하지?"

사장님이 "뭐해야하지?" 할 때 쓰는 도우미.
프로젝트 전체 상태를 읽고, 현재 상황 보고 + 다음 할 일 선택지 제시.

## When to Use

- `/kdh-help` — 지금 뭐 해야 하는지 모를 때
- "뭐해야하지?", "다음 뭐야?", "현황 알려줘"
- 새 세션 시작할 때 상태 파악용

## Pattern

```
Phase 1: 상태 수집 (읽기만 — 변경 없음)
Phase 2: 상태 보고 (한국어, 기술용어 금지)
Phase 3: 선택지 제시 (A/B/C)
```

---

## Phase 1: 상태 수집 (30초)

**전부 읽기만 한다. 아무것도 수정하지 않는다.**

```
1. 최근 세션 파일 (최신 3개):
   ls -t ~/.claude/session-data/*-session.tmp | head -3
   → 각각 읽어서 "Exact Next Step" + "Blockers" 섹션 추출

2. 메모리:
   Read ~/.claude/projects/-home-ubuntu-corthex-v3/memory/MEMORY.md
   → 각 메모리 파일의 핵심 1줄 요약

3. Sprint 상태:
   Read _bmad-output/implementation-artifacts/sprint-status.yaml
   → 현재 Sprint, 완료/미완료 스토리 수, review_state, e2e_result

4. 기획 산출물:
   ls _bmad-output/planning-artifacts/
   → PRD, architecture, epics-and-stories 존재 여부

5. CLAUDE.md:
   Read CLAUDE.md → Scope, Dev Rules 확인

6. 플랜 파일:
   Read ~/.claude/plans/*.md (있으면)
   → 현재 진행 중인 계획

7. Git 상태:
   git log --oneline -5 → 최근 커밋
   git status → 미커밋 변경사항

8. 서버 상태:
   curl -s http://localhost:3000/api/health → 서버 살아있나?
   curl -s https://corthex-hq.com/api/health → 프로덕션 살아있나?

9. 미해결 이슈:
   - 이전 세션의 Blockers 수집
   - sprint-status.yaml에서 review_state: conditional/auto-fail/escalated
   - ESCALATED.md 확인
```

## Phase 2: 상태 보고 (한국어, 기술용어 금지)

```
══════════════════════════════════════
  CORTHEX v3 — 현재 상태
══════════════════════════════════════

📍 지금 위치: {Phase 1 / Phase 1.5 / Phase 2 기획 중}

✅ 된 것:
  - {완료된 항목들 — 쉬운 말로}

🔧 해야 할 것:
  - {미완료 항목들 — 우선순위순}

🚫 막힌 것:
  - {블로커들 — 있으면}

📊 숫자:
  - 스토리: {완료}/{전체}
  - 테스트: {통과 수}
  - 리뷰 평균: {점수}
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
3. 플랜 파일의 다음 Step 실행
4. Sprint 미완료 스토리 → /kdh-go
5. E2E 미실행 → /kdh-e2e
6. Phase 완료 → 다음 Phase 기획
7. 아무것도 없으면 → "다 했어요! 뭐 하고 싶으세요?"
```

### 선택 후 실행

```
사장님이 A/B/C 선택하면:
  → 해당 스킬 호출 (예: /kdh-go, /kdh-e2e, /kdh-plan 등)
  → 또는 직접 작업 시작

사장님이 D 선택하면:
  → "뭐 하고 싶으세요?" 대기
```

---

## 사용 가능한 KDH 명령어 (사장님용 설명)

| 명령어 | 뭐 하는 건지 |
|--------|------------|
| `/kdh-go` | 다음 할 일 알아서 해 (낮에) |
| `/kdh-go 계속` | 밤새 자동으로 돌려 (자기 전에) |
| `/kdh-help` | 지금 뭐 해야 하는지 알려줘 (이거) |
| `/kdh-research 주제` | 뭔가 조사해줘 |
| `/save-session` | 지금까지 한 거 저장 |
| `/resume-session` | 저번에 하던 거 이어하기 |

### 내부 명령어 (자동으로 호출됨 — 사장님이 직접 안 쳐도 됨)

| 명령어 | 역할 |
|--------|------|
| `/kdh-plan` | 기획 (PRD, 설계, 스토리 만들기) |
| `/kdh-sprint N` | 스프린트 실행 |
| `/kdh-build 스토리` | 스토리 1개 만들기 |
| `/kdh-review 스토리` | 스토리 1개 검토하기 |
| `/kdh-e2e` | 브라우저 전수검사 |
| `/kdh-gate` | 사장님 확인 필요한 포인트 |
| `/kdh-ecc-3h` | 3시간 자동 유지보수 |
| `/kdh-ecc-12h` | 12시간 학습+진화 |

---

## Rules

1. **한국어만** — 기술 용어 절대 금지
2. **읽기만** — Phase 1에서 아무것도 수정하지 않음
3. **짧게** — 보고서는 화면 한 페이지 이내
4. **선택지는 3개** — 4개 이상 금지 (D는 "다른 거"로 고정)
5. **추천 표시** — 가장 좋은 옵션에 (추천) 붙이기
