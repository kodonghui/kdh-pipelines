---
name: kdh-frustration-evolve
description: "짜증 로그 분석 후 재발 방지 룰과 memory 갱신."
---

# kdh-frustration-evolve

CEO 짜증 로그를 분석해서 Claude 행동을 진화시키는 스킬.
24시간 루프 또는 수동 실행.

## 데이터 소스

`_bmad-output/frustration-logs/*.jsonl` — think-level hook이 자동 기록.

각 줄 형식:
```json
{"ts":"2026-04-15T12:34:56Z","keywords":["시발"],"message":"시발 이거 왜 안돼","session_id":"...","cwd":"...","todayCount":3,"total":15}
```

## 실행 절차

### Step 1: 로그 수집

1. `_bmad-output/frustration-logs/` 전체 JSONL 읽기
2. 최근 7일 로그만 필터 (오래된 건 패턴이 바뀌었을 수 있음)
3. 로그 0건이면 "짜증 없음 — 잘하고 있다" 보고 후 종료

### Step 2: 패턴 분석

각 로그의 `message`를 분석해서 다음을 추출:

1. **짜증 원인 분류** (택1):
   - `wrong-answer` — 잘못된 답변/할루시네이션
   - `slow` — 너무 느리거나 장황
   - `not-listening` — 지시를 무시하거나 반복 실수
   - `asking-too-much` — 불필요한 확인 질문
   - `broken` — 뭔가 안 됨 (빌드 실패, 훅 차단 등)
   - `ux-friction` — 도구/세션 문제
   - `other`

2. **빈도 집계**: 원인별 횟수, 시간대별 분포
3. **반복 패턴**: 같은 원인이 3회+ 반복되면 하이라이트

### Step 3: 개선안 생성

패턴별 구체 개선안:

- `not-listening` 3회+ → CLAUDE.md에 해당 규칙 강화 제안
- `asking-too-much` 3회+ → "묻지 말고 실행" 류 피드백 메모리 확인, 없으면 생성 제안
- `wrong-answer` 3회+ → 관련 스킬/에이전트 프롬프트 개선 제안
- `slow` 3회+ → 응답 간결화 규칙 제안
- `broken` 3회+ → 훅/설정 점검 제안

### Step 4: 보고서 작성

`_bmad-output/frustration-logs/evolve-report-{date}.md` 저장:

```markdown
# Frustration Evolve Report — {date}

## 기간: {start} ~ {end}
## 총 짜증 횟수: {N}회

## 원인 분류
| 원인 | 횟수 | 비율 | 대표 메시지 |
|------|------|------|------------|
| not-listening | 5 | 33% | "아오 이거 하지 말라 했잖아" |
| ... | ... | ... | ... |

## 반복 패턴 (3회+ 하이라이트)
1. **not-listening**: ...
2. ...

## 개선안
1. CLAUDE.md 규칙 추가: "..."
2. 피드백 메모리 생성: "..."
3. ...

## 실행 여부
[ ] CEO 승인 후 적용 (자동 적용 금지)
```

### Step 5: 대기

- 수동 실행 시: 보고서 출력 후 종료
- 루프 모드 시: 24시간 후 재실행 (ScheduleWakeup 1200s × 반복)

## 사용법

```
/kdh-frustration-evolve          # 수동 1회 실행
/loop /kdh-frustration-evolve    # 24시간 루프
```

## 규칙

- 개선안은 **제안만** — 자동 적용 절대 금지
- CEO가 "적용해" 하면 그때 CLAUDE.md/메모리 수정
- 로그 원문은 수정/삭제 금지 (감사 추적용)
- 7일 이전 로그는 분석에서 제외하되 파일은 유지
