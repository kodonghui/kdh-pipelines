---
name: kdh-ecc-3h
description: "3시간 분석 루틴 v3 — observations.jsonl 기반 분석 + dream + plan audit + lint + report. 수집은 훅이 100% 함."
tags: [maintenance, memory, analysis]
---

# KDH ECC 3시간 분석 루틴 v3

> v3 변경: 수집 로직 제거. observation-collector 훅이 100% 수집.
> 이 스킬은 observations.jsonl + compliance-violations.jsonl을 읽어 분석만 함.
> Lint는 cwd 기반 동적 감지로 프로젝트 독립적.

3시간마다 자동 실행되는 경량 분석 루틴. 5 Phase만 실행.
변경 없으면 Lint만 돌리고 나머지는 SKIP.

비유: 3시간마다 사무실을 한 바퀴 돌면서 문 잠겼는지(tsc), 쓰레기통 비었는지(console.log) 확인하는 야간 경비원.

> v2 변경사항 (2026-04-08): Learn/Prune/Health를 12h(kdh-ecc-12h)로 이관. delta-only 추가. Report 개선.

## 실행 방법

- 자동: CronCreate로 3시간마다 자동 실행 (세션 내)
- 수동: `/kdh-ecc-3h` 입력

## Delta 감지

실행 시작 시 먼저 확인:
```
1. .last-3h-run 타임스탬프 읽기 (없으면 → 전체 실행)
2. git log --since="[.last-3h-run 시각]" --oneline | head -1
3. observations.jsonl에서 .last-3h-run 이후 Edit/Write 이벤트 유무 확인
4. git log 결과 있거나 Edit/Write 이벤트 하나라도 있으면 → has_changes=true (전체 실행)
5. 둘 다 없으면 → has_changes=false (Phase 3 Lint만 실행, 나머지 SKIP)
6. 실행 완료 후 .last-3h-run 타임스탬프 갱신
```

## 실행 흐름 (5 Phase)

### Phase 1: Dream (메모리 정리) — 1분
> delta: has_changes=false이면 SKIP

```
1. MEMORY.md + 모든 토픽 파일 읽기
2. 최근 세션에서 교정/결정/선호 변경 스캔
3. 중복 제거, 오래된 정보 정리
4. MEMORY.md 인덱스 200줄 이하 유지
5. .last-dream 타임스탬프 업데이트
```

Run as background subagent: `/dream`

### Phase 2: Plan Audit (계획 정리) — 10초
> delta: has_changes=false이면 SKIP

```
1. _bmad-output/kdh-plans/_index.yaml 읽기
   - 없으면 스킵
2. TTL 체크:
   - ttl이 오늘 이전인 plan → status: active → done 자동 전환
   - _index.yaml 업데이트
3. Stale 체크:
   - created가 14일 이상 전 + status: active → 경고
   - "Plan {id} 2주 넘음. 아직 유효한지 확인 필요"
4. 보고: "Plans: N active, N done, N expired"
```

### Phase 3: Lint (코드 위생) — 30초
> delta: 항상 실행 (has_changes 무관)

```
1. tsc 체크:
   - cwd에 tsconfig.json 존재 확인
   - 없으면 "tsc:SKIP (no tsconfig)"
   - 있으면 전 패키지 (server, admin, app) 에러 수 기록
2. console.log 잔여 체크 (packages/app + packages/admin)
3. bun.lock 변경 감지:
   - git diff HEAD -- bun.lock | head -1
   - 변경 있으면 "lockfile changed" 경고
4. toast-without-api 린트 (hook 있으면):
   - bash .claude/hooks/toast-without-api-check.sh
5. Biome 린트:
   - cwd에 biome.json 또는 biome.jsonc 존재 확인
   - 없으면 "biome:SKIP (no config)"
   - 있으면 bunx --bun @biomejs/biome check packages/ --reporter=summary 2>&1 | tail -3
   - 에러 수 기록. 0이면 "biome:OK", 있으면 "biome:N errors"
6. Knip dead code 리포트 (has_changes=true일 때만):
   - bunx knip --reporter json 2>/dev/null | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log('unused files:'+d.files?.length+' exports:'+d.exports?.length+' deps:'+d.unlisted?.length)" 2>/dev/null || echo "knip:SKIP"
   - 결과 기록 (숫자만 — 자동 삭제 절대 금지, 보고만)
```

### Phase 4: Update Log + Codesight 갱신 — 20초
> delta: has_changes=false이면 SKIP

```
1. 오늘 날짜 파일: _bmad-output/update-log/YYYY-MM-DD.md
2. 없으면 새로 생성, 있으면 append
3. 데이터 소스 2개 병합:
   a. git log --since="[.last-3h-run 시각]" --oneline
   b. observations.jsonl에서 최근 3시간 도구 사용 요약:
      - Edit/Write 대상 파일 Top 10
      - Bash 명령어 중 빌드/테스트 실행 횟수
      - Party Mode 관련 이벤트 (TeamCreate, SendMessage) 건수
4. 카테고리 자동 분류:
   - Bug Fixes: fix 커밋
   - Features: feat 커밋
   - Infrastructure: chore/ci 커밋
   - Review: party-log 관련 이벤트
5. Codesight 갱신 (has_changes=true + .codesight/ 존재할 때만):
   - npx codesight --wiki 2>/dev/null && echo "codesight:UPDATED" || echo "codesight:SKIP"
   - 코드 변경 후 에이전트들이 최신 구조 파악할 수 있게 위키 최신화
```

### Phase 5: Report (1줄 요약 + 12h 감시) — 5초

출력 형식:
```
[ECC-3H] Dream:OK|SKIP Plan:N active|SKIP Lint:tsc(S/A/P) log(N) lock(OK|CHG) Log:OK|SKIP Obs:{N}events Comp:{N}violations 12h:OK|15h-WARN|24h-CRIT
```

Obs 계산:
```
- observations.jsonl 총 줄 수 카운트
- 파일 미존재 → "NO-DATA"
```

Comp 계산:
```
- compliance-violations.jsonl에서 .last-3h-run 이후 항목 건수
- 파일 미존재 → "NO-DATA"
- 0건 → "0"
- 1건 이상 → "{N}!"
```

12h 감시 로직:
```
1. .last-12h-run 타임스탬프 읽기
2. 경과 시간 계산:
   - 15시간 미만 → "12h:OK"
   - 15~24시간 → "12h:15h-WARN" (경고)
   - 24시간 초과 → "12h:24h-CRIT" (치명)
3. .last-12h-run 없으면 → "12h:UNKNOWN"
```

ecc-3h-log.md 기록:
```
## YYYY-MM-DD HH:MM UTC — Dream:OK|SKIP Plan:OK|SKIP Lint:tsc(S/A/P) log(N) lock(OK) Log:OK|SKIP Obs:{N}events Comp:{N}violations 12h:OK
```

## 12시간 확장 (kdh-ecc-12h)

12시간마다 추가 실행 (별도 스킬):

```
1. /learn-eval — 세션 패턴 추출 + 품질 평가
2. /evolve — 높은 confidence instinct → 스킬/커맨드 진화
3. Prune — 30일 넘은 미승격 instinct 삭제 (3h에서 이관)
4. Health Check — skill-health + cost tracker (3h에서 이관)
5. /skill-health — 전체 스킬 건강 대시보드
6. /context-budget — 컨텍스트 사용량 상세 분석
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
