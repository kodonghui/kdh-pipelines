---
name: kdh-help
description: "뭐해야하지? v3 — 프로젝트 상태 + BMAD 카탈로그 결합 라우터. bmad-help 자동 호출 → Sprint/plan/session 컨텍스트 얹어서 명령어 추천."
---

# KDH Help v3 — "뭐해야하지?"

프로젝트 상태를 읽고 자동으로 다음 할 일을 판단합니다.

## When to Use

- `/kdh-help` — 지금 뭐 해야 하는지 모를 때
- "뭐해야하지?", "다음 뭐야?", "현황 알려줘", "어떤 명령어 써야해?"
- 새 세션 시작할 때 상태 파악용

> v3 변경 (2026-04-21): **Phase 0 에서 `bmad-help` 자동 호출**. kdh-help = BMAD 카탈로그 라우팅 + 프로젝트 컨텍스트 풍부화 통합 라우터.
> v2 변경 (2026-04-08): Planning 감지 축소, Sprint 블록 해석 강화, plan layer 연동, session→resume 안내.

## Phase 0: BMAD 라우팅 (v3 신규)

```
1. Skill tool 로 bmad-help 호출
   - args: CEO 가 kdh-help 에 넘긴 args 를 그대로 pass-through (args 없으면 빈 문자열)
   - bmad-help 가 _bmad/_config/bmad-help.csv (43 스킬) 기준 매칭
2. bmad-help 결과 캡처 → Phase 1 의 프로젝트 state 와 결합
   - BMAD 추천이 현재 Sprint/plan 과 맞으면 우선순위 ↑
   - 안 맞으면 kdh 스킬 추천 우선
3. Phase 2 최종 제시에서 두 카테고리 함께 출력:
   - "프로젝트 컨텍스트 기반 (kdh-*)": 현재 state 에 가장 잘 맞는 kdh 명령
   - "BMAD 카탈로그 매칭 (bmad-*)": 명령어 자체를 찾을 때 쓸 BMAD 스킬
```

★ **kdh-help 가 이제 1차 관문**. bmad-help 는 그 안에서 호출되는 하위 검색 엔진.

## Phase 1: 상태 자동 감지 (30초)

**전부 읽기만 한다. 아무것도 수정하지 않는다.**

### 1-0. Session 파일 확인 (최우선)
```
1. ~/.claude/session-data/ 에서 최신 *-session.tmp 확인
2. 있으면 → "이전 세션 파일이 있습니다. /resume-session 먼저 실행을 추천합니다."
   - 선택지 A에 /resume-session 배치
3. 없으면 → 다음 단계로
```

### 1-1. pipeline-state.yaml 읽기
```
1. _bmad-output/pipeline-state.yaml 읽기
   - 없으면 → "상태 파일 없음. git log 기반 fallback." → 1-1F로
2. 핵심 필드 추출:
   - current_phase_number, mode, current_stage
   - current_story (활성 스토리)
3. planning.status 확인:
   - complete → Planning 완료. Sprint 감지(1-2)로
   - 그 외 → Planning 미완료. Stage 번호 확인 후 안내:
     - "Planning Stage {N}부터 재개. /kdh-planning-pipeline"
```

**1-1F. Fallback (pipeline-state.yaml 없을 때)**
```
1. 산출물 존재 체크 (간략):
   - epics-and-stories.md 있음 → "Sprint 모드"
   - prd.md 있음, epics 없음 → "Planning Stage 6부터"
   - 아무것도 없음 → "Planning 처음부터. /kdh-planning-pipeline"
2. git log --oneline -5 표시
```

### 1-2. Sprint 상태 (블록 전체 해석)
```
1. pipeline-state.yaml에서 현재 Sprint 블록 찾기:
   - phase_2_sprint_{N} 블록 읽기
2. 스토리별 status 분류:
   - complete 목록
   - in-progress 또는 current_story
   - backlog 목록
3. Sprint 진행률 계산: 완료/전체
4. 미완료 스토리 중 다음 실행 후보:
   - current_story가 있으면 → 그것 먼저
   - 없으면 → backlog 중 의존관계 해소된 첫 번째
```

### 1-3. Plan Layer 연동
```
1. _bmad-output/kdh-plans/_index.yaml 읽기
   - 없으면 → SKIP
2. status: active plan 필터:
   - pipeline이 현재 mode(dev/planning/bug-fix)와 매칭
   - scope가 현재 Sprint/story와 매칭
3. 매칭되는 active plan → "진행중 계획" 섹션에 표시
   - plan 제목 + id만 (본문은 안 읽음)
```

### 1-3.5. 4cmd 아티팩트 감지
```
1. _bmad-output/kdh-plans/ 에서 최근 24시간 아티팩트 확인 (mtime 기준):
   - *-research-*.md → "research 완료"
   - *-analyze-*.md → "analyze 완료"
     - "CEO 선택: 대기중" 포함 → "CEO 선택 대기"
     - "CEO 선택: [A-Z]" 포함 → "CEO 선택 완료"
2. 판단:
   - research만 있으면 → "→ /kdh-analyze 추천"
   - analyze(CEO 선택 대기) → "→ 선택지 확인 필요"
   - analyze(CEO 선택 완료) → "→ /kdh-plan 추천"
3. 24시간 이내 아티팩트 없으면 → SKIP
```

### 1-3.6. ECC 상태 감지
```
1. .last-3h-run 타임스탬프 읽기
   - 없으면 → "ECC-3h: 미설정"
   - 4시간 이내 → "ECC-3h: OK"
   - 4시간+ → "ECC-3h: 지연"
2. .last-12h-run 타임스탬프 읽기
   - 없으면 → "ECC-12h: 미설정"
   - 15시간 미만 → "ECC-12h: OK"
   - 15~24시간 → "ECC-12h: 경고"
   - 24시간+ → "ECC-12h: 치명"
```

### 1-4. 기타 감지
```
1. 리뷰/통합 상태:
   - review_state: conditional → 해당 스토리 수정 필요
   - integration_state: fail → 통합 이슈 해결
2. 버그 상태:
   - bug-fix-state.yaml 존재 + current_phase != complete → "/kdh-bug-fix-pipeline 이어서"
3. 최근 커밋: git log --oneline -3
```

## Phase 2: 상태 보고 (한국어)

```
══════════════════════════════════════
  CORTHEX v3 — 현재 상태
══════════════════════════════════════

지금 위치: Phase {N} / Sprint {N} / {mode}

된 것:
  - 스토리 {완료수}/{전체}: {완료 목록}

해야 할 것:
  - {미완료 스토리 — 번호+제목, 우선순위순}
  - {active plan 있으면: "계획 진행중: {plan 제목}"}

사고 체인:
  - {4cmd 상태: "research 완료 → analyze 추천" 등, 없으면 생략}

시스템:
  - ECC: {3h 상태} / {12h 상태}

막힌 것:
  - {블로커들 — 없으면 "없음"}

숫자:
  - 스토리: {완료}/{전체} ({진행률}%)
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

### 선택지 결정 로직 (우선순위)

```
1. 블로커 해결 (tsc 실패, 통합 에러 등)
2. session.tmp 존재 → /resume-session
3. 4cmd 체인 진행중 → 다음 단계 안내
   - research 완료 → "/kdh-analyze [주제]"
   - analyze CEO선택 대기 → 선택지 표시
   - analyze 완료 → "/kdh-plan [주제]"
4. Sprint 미완료 스토리 → /kdh-dev-pipeline sprint {N}
   - current_story 있으면 그것 먼저
   - 없으면 backlog 중 의존 해소된 첫 번째
4. Active plan 실행 → 해당 plan의 다음 단계
5. Planning 미완료 → /kdh-planning-pipeline
6. 버그 발견 → /kdh-bug-fix-pipeline
7. Phase 완료 → 다음 Phase 기획
8. 아무것도 없으면 → "다 했어요!"
```

## 사용 가능한 KDH 명령어 (사장님용)

| 명령어 | 뭐 하는 건지 |
|--------|------------|
| `/kdh-planning-pipeline` | 기획 (PRD, 설계, 스토리) |
| `/kdh-dev-pipeline` | 개발 (코드 짜기) |
| `/kdh-dev-pipeline 계속` | 밤새 자동으로 |
| `/kdh-bug-fix-pipeline` | 버그 찾고 고치기 |
| `/kdh-help` | 지금 뭐 해야 하는지 (이거) |
| `/kdh-discuss 주제` | 같이 논의하기 |
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
6. **라우터 역할** — 실행 판단은 CEO가 함. help는 안내만.
