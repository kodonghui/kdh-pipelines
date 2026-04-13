---
name: kdh-ecc-12h
description: "12시간 학습+진화 v3 — observations.jsonl 기반 패턴 추출 + 진화 + 건강 체크. instinct-cli.py fallback 포함."
tags: [learning, evolution, maintenance, analysis]
---

# KDH ECC 12시간 학습+진화 v3

12시간마다 실행하는 ECC 핵심 루틴. instinct → 스킬 자동 진화.
단순 명령어 나열이 아닌 **오케스트레이터** — Phase 간 데이터 전달 + 조건 분기.

> v3 변경 (2026-04-13): Phase 1 입력 소스를 observations.jsonl로 전환, Phase 3 instinct-cli.py fallback 추가, Phase 5 비용 추정을 observations 기반으로 전환, Report 형식 업데이트.

## 실행 흐름 (6 Phase)

```
Phase 1: Learn-Eval ─── instinct 파일들 ───→ Phase 2: Plan Retro (조건부)
                                                   │
                                              추가 instinct
                                                   ↓
Phase 3: Evolve ←── Phase 1+2의 instinct ──── skill/cmd/agent 후보
                                                   ↓
Phase 4: Prune ←── evolved 결과 참조 ──── 정리된 instinct
                                                   ↓
Phase 5: Health ─── observations.jsonl + 스킬 목록 ──── 건강 대시보드
                                                   ↓
Phase 6: Report ←── Phase 1~5 결과 ──── 1줄 + 상세 + SKIP 비율
```

### Phase 1: Learn-Eval (패턴 추출 + 평가)

입력: observations.jsonl (최근 12시간) + compliance-violations.jsonl + 세션 JSONL (보조)
출력: instinct 파일들 (confidence 0.3~0.9)
SKIP: observations.jsonl 미존재 AND 새 세션 없으면 → "Phase 1: SKIP"

```
1. 데이터 소스 읽기:
   a. observations.jsonl — 도구 사용 패턴 (최근 12시간)
   b. compliance-violations.jsonl — 위반 패턴
   c. 세션 JSONL (있으면) — 교정/결정 신호 (보조)

2. 패턴 추출:
   a. 반복 패턴: 같은 tool+file 5회+ → "이 파일 자주 수정됨"
   b. 위반 패턴: 같은 규칙 3회+ → "이 규칙 자주 위반"
   c. 워크플로우: Edit→Bash(test)→Edit 반복 → "TDD 패턴"
   d. 교정: 세션 JSONL에서 "아니", "그게 아니라" → "CEO 교정"

3. instinct 저장:
   - 경로: ~/.claude/homunculus/instincts/
   - YAML: {id, trigger, action, confidence, domain, scope, source: "observations"}
   - 기존 instinct에 같은 패턴 → confidence +0.1

4. 품질 자가평가: /learn-eval 실행
```

### Phase 2: Plan Retrospective (계획 회고) — 조건부

입력: _index.yaml의 status:done plans + git log
출력: plan 관련 instinct 추가
SKIP: done plan 3개 미만 → "Phase 2: SKIP (done plans: N, threshold: 3)"

```
1. _bmad-output/kdh-plans/_index.yaml 읽기
2. status: done plan 분석 (최근 30일):
   - 복잡도 vs 실제 규모 비교:
     a. plan 본문에 "복잡도:" 필드 있으면 사용
     b. 없으면 task 개수로 추정 (1~3=S, 4~7=M, 8+=L)
     c. 실제 규모: git log --since {created} --until {done 추정} 커밋 수 (merge 제외, fixup 포함)
     d. S 기대=1~2, M 기대=3~5, L 기대=6+. 기대 대비 2배 이상 → "과소 추정" 패턴 기록
   - analyze 파일 있으면 (*-analyze-*.md): 추천 vs 실제 결과 비교
   - Risk 중 실제 발생한 것 (plan 본문의 Pre-mortem 테이블 대조)
   - plan에서 빠졌던 태스크 (git log에 있으나 plan task에 없는 변경)
3. 패턴 → instinct 후보 저장
4. done plan 30일+ → status: archived 전환
```

### Phase 3: Evolve (진화)

입력: Phase 1+2의 instinct + 기존 전체
출력: skill/command/agent 후보 (staging)
SKIP: instinct 총 3개 미만 → "Phase 3: SKIP (instinct count: N, min: 3)"

```
1. instinct-cli.py 존재 확인:
   a. 있으면 → /evolve 실행 (기존)
   b. 없으면 → Claude 직접 클러스터링 (fallback):
      - ~/.claude/homunculus/instincts/ Glob
      - confidence 0.7+ 필터
      - trigger 기반 유사도 그룹핑
      - 3+ 관련 instinct → 진화 후보 보고
      - ~/.claude/homunculus/evolved/ staging
      - 동희님에게 "이 패턴을 스킬로 만들까요?" 보고

★ 자동 생성 금지. 보고만. 동희님 승인 후에만 진화.
```

### Phase 4: Prune (정리) — Evolve 후!

입력: 전체 instinct + Phase 3 evolved 결과
출력: 정리된 instinct 목록
SKIP: instinct 없으면 → "Phase 4: SKIP (no instincts)"

```
1. 30일 넘은 미승격 instinct 삭제 (evolved된 것은 보존)
2. 빈 메모리 파일 삭제
3. 오래된 세션 파일 정리 (최근 10개 유지)
```

Run: `/prune`
순서 근거: Prune을 Evolve 전에 하면 아직 클러스터링 안 된 후보가 삭제될 위험.

### Phase 5: Health (건강 체크)

입력: observations.jsonl + 스킬 목록
출력: 건강 대시보드
SKIP: observations.jsonl 미존재 → "Phase 5: SKIP (missing: observations.jsonl)"

```
1. 비용 추정:
   a. observations.jsonl 최근 12시간 이벤트 집계:
      Read {n}회, Edit {n}회, Write {n}회, Bash {n}회, Agent {n}회
   b. 추정 토큰: Read ~500, Edit ~800, Write ~1000, Bash ~300, Agent ~5000
   c. 총 추정 = Σ(이벤트 × 토큰)
   d. costs.jsonl 있으면 → 실제 비용 우선 사용

2. 스킬 건강:
   - wc -l 기반 간이 체크 (200줄 초과 = 경고)

3. 컨텍스트 예산:
   - 스킬 파일 크기 합산 → 토큰 추정

4. .last-12h-run 타임스탬프 업데이트
```

### Phase 6: Report (보고)

입력: Phase 1~5 결과
출력: 1줄 요약 + Phase별 상세
SKIP: 없음 (항상 실행)

1줄 요약:
```
[ECC-12H] Learn:N instincts(obs)|SKIP Retro:N plans|SKIP Evolve:N candidates|SKIP Prune:N deleted|SKIP Health:~{N}k tok|SKIP Comp:{N}violations
```

상세:
```
Phase별 결과:
| Phase | 상태 | 결과 | SKIP 사유 |
|-------|------|------|----------|

SKIP 비율: N/6 (80%+ = 경고)
실행 시간: ~Nm
```

SKIP 비율 경고:
- 5/6 이상 SKIP → "WARNING: 대부분 Phase가 SKIP. 세션 활동 또는 참조 파일 점검 필요."

## 3h v3와의 역할 분담

| 역할 | 3h v3 | 12h v3 |
|------|-------|--------|
| 메모리 | Dream (정리) | Learn-Eval (observations→instinct) |
| Plan | Audit (TTL/Stale) | Retrospective (예상vs실제) |
| 코드 | Lint (동적 감지) | — |
| 진화 | — | Evolve (cli.py or Claude fallback) + Prune |
| 건강 | — | Health (observations 기반 비용 추정) |
| 로그 | Update Log (git+observations) | — |
| 감시 | 12h 실행 여부 + compliance | — |
| 데이터 | observations.jsonl 읽기 | observations.jsonl + instincts 읽기 |

3h가 .last-12h-run을 감시: 15h 미실행=경고, 24h=치명.

## CronCreate

```
CronCreate(cron: "37 */12 * * *", prompt: "/kdh-ecc-12h")
```
