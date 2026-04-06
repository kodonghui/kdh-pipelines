---
name: kdh-ecc-3h
description: "3시간 자동 유지보수 — dream + learn + prune + health + lint. 세션 중 크론으로 자동 실행되거나 수동 호출 가능."
tags: [maintenance, learning, memory, automated]
---

# KDH ECC 3시간 유지보수

3시간마다 자동 실행되는 유지보수 루틴. dream(메모리 정리) + learn(패턴 학습) + prune(쓰레기 청소) + health(건강 체크) + lint(코드 위생)를 한번에 돌림.

비유: 사무실 청소 + 일지 정리 + 서류 정돈을 3시간마다 자동으로 해주는 비서.

## 실행 방법

- 자동: CronCreate로 3시간마다 자동 실행 (세션 내)
- 수동: `/kdh-ecc-3h` 입력

## 실행 흐름 (총 ~2분)

### Phase 1: Dream (메모리 정리) — 1분

```
1. MEMORY.md + 모든 토픽 파일 읽기
2. 최근 세션에서 교정/결정/선호 변경 스캔
3. 중복 제거, 오래된 정보 정리
4. MEMORY.md 인덱스 200줄 이하 유지
5. .last-dream 타임스탬프 업데이트
```

Run as background subagent: `/dream`

### Phase 2: Learn (패턴 추출) — 30초

```
1. instinct-status 확인 — 현재 instinct 목록
2. 최근 세션에서 새 패턴 감지
3. confidence 0.7+ instinct → evolve 후보 표시
```

Run: check `~/.claude/homunculus/projects/` for new observations, summarize.

### Phase 3: Prune (쓰레기 청소) — 10초

```
1. 30일 넘은 미승격 instinct 삭제
2. 빈 메모리 파일 삭제
3. 오래된 세션 파일 정리 (최근 10개만 유지)
```

Run: `/prune` logic

### Phase 3.5: Plan Audit (계획 정리) — 10초

```
1. _bmad-output/kdh-plans/_index.yaml 읽기
   - 없으면 스킵
2. TTL 체크:
   - ttl이 오늘 이전인 plan → status: active → done 자동 전환
   - _index.yaml 업데이트
3. Stale 체크:
   - created가 14일 이상 전 + status: active → ⚠️ 경고
   - "Plan {id} 2주 넘음. 아직 유효한지 확인 필요"
4. 보고: "Plans: N active, N done, N expired"
```

### Phase 4: Health Check (건강 체크) — 20초

```
1. skill-health: 하락하는 스킬 있으면 경고
2. context-budget 요약: 현재 토큰 사용량
3. cost-tracker 요약: 세션 비용 누계
```

Read `~/.claude/metrics/costs.jsonl` tail, `~/.claude/state/skill-runs.jsonl` tail, summarize.

### Phase 5: Lint (코드 위생) — 10초

```
1. toast-without-api 린트 (성공 토스트 + API 미호출 감지)
2. console.log 잔여 체크 (packages/app + packages/admin)
```

Run: `bash .claude/hooks/toast-without-api-check.sh`

### Phase 6: Update Log (업데이트 로그) — 15초

```
1. 오늘 날짜 파일 확인: _bmad-output/update-log/YYYY-MM-DD.md
2. 없으면 새로 생성, 있으면 append
3. 이번 세션에서 한 작업을 카테고리별로 기록:
   - Bug Fixes, Features, Infrastructure, Memory, Discussion 등
4. 커밋 로그(git log --since="today")에서 자동 추출 + 세션 컨텍스트 반영
```

Run: Read today's `_bmad-output/update-log/$(date +%Y-%m-%d).md`, append new entries from this session. Create if not exists.

### Phase 7: Report (1줄 요약) — 5초

출력 형식:
```
[KDH-ECC-3H] Dream: OK | Learn: N instincts | Prune: N deleted | Plans: N active | Health: OK | Lint: N issues
```

## 12시간 확장 (kdh-ecc-12h)

12시간마다 추가 실행:

```
1. /learn-eval — 세션 패턴 추출 + 품질 평가
2. /evolve — 높은 confidence instinct → 스킬/커맨드 진화
3. /skill-health — 전체 스킬 건강 대시보드
4. /context-budget — 컨텍스트 사용량 상세 분석
```

## 주 1회 확장 (일요일 자정 KST)

Remote trigger로 자동 실행 (trig_017oqLsrT4yeiRsAZwuGj7fu):

```
1. 보안 스캔 — .claude/ 시크릿/취약점
2. 하니스 감사 — hooks/settings 검토
3. 스킬 품질 감사 — 전체 스킬 stocktake
4. 규칙 추출 — 새 규칙 후보 식별
```

## CronCreate 설정 예시

```
# 세션 시작 시 실행:
CronCreate(cron: "7 */3 * * *", prompt: "/kdh-ecc-3h")
CronCreate(cron: "37 */12 * * *", prompt: "12시간 확장 유지보수: /learn-eval 후 /evolve 후 /skill-health")
```
