---
name: 'kdh-bug-fix-pipeline'
description: 'Bug Fix Pipeline v1.0 — browser-use 중심 E2E 버그 탐색 + 수정 + 검증 루프. 사장님 명령어: /kdh-bug-fix-pipeline [auto|계속|scan|fix BUG-XXX|verify|deploy]'
---

# Bug Fix Pipeline v1.0

## Purpose

**기능 개발 = kdh-full-auto-pipeline (6 Phase)**
**버그 수정 = kdh-bug-fix-pipeline (4 Phase) ← 이 파일**

browser-use AI가 실제로 사이트를 클릭하면서 버그를 찾고, 수정하고, 다시 확인하는 루프.
Playwright는 회귀 테스트 고정용. browser-use는 탐색/발견/검증용.
0 bugs가 될 때까지 루프를 돌림.

---

## Phase Directory Convention

bug-fix 파이프라인은 cross-phase (특정 Phase에 속하지 않음).
모든 bug-fix 출력물은 `_bmad-output/bug-fix/` 하위에 저장.
party-logs도 `_bmad-output/bug-fix/party-logs/`에 저장 (Phase 폴더가 아님).

```
_bmad-output/bug-fix/
├── bug-fix-state.yaml
├── bug-fix-rubric.md
├── party-logs/                 # bugfix-{id}-quinn.md, bugfix-{id}-winston.md
├── e2e-screenshots/            # sweep/verify GIF + screenshots
├── sweep-{timestamp}-raw.txt   # sweep 결과
├── sweep-{timestamp}.json      # sweep JSON
└── verify-{id}-{timestamp}.txt # verify 결과
```

---

## Mode Selection

- **no args** 또는 **`auto`**: bug-fix-state.yaml 읽고 이어서. 없으면 Phase 1(SCAN)부터.
- **`계속`**: 밤새 모드 — Phase 4 GATE 자동 통과, 나머지 필수.
- **`scan`**: Phase 1만 실행 (전수 탐색만 하고 멈춤).
- **`fix BUG-XXX`**: 특정 버그만 수정 (Phase 2의 해당 버그만).
- **`verify`**: Phase 3만 실행 (전체 회귀 검증만).
- **`deploy`**: Phase 4만 실행 (배포 + CEO 확인).

### `계속` 모드 (밤새 자동)

```
1. Phase 4 GATE → 자동 통과 ([AUTO] 표시)
2. 아침에 CEO가 bug-fix-state.yaml 보고 확인
3. 외부 루프 5회 초과 → 종료 + 남은 버그 목록 저장
★ Codex FAIL은 자동 진행 금지 (계속 모드에서도)
```

### Ralph Loop (밤샘 최안정)
```bash
while true; do claude -p "/kdh-bug-fix-pipeline 계속"; sleep 5; done
```

### 보고 형식 (한국어)

```
시작:    "사이트 탐색 시작합니다."
탐색:    "버그 {N}개 발견! 심각 {N}, 보통 {N}, 경미 {N}."
수정중:  "BUG-{id} 수정 중... ({N}/{M} 진행)"
수정완료: "버그 {N}개 전부 수정. 전체 검증 시작합니다."
검증:    "전체 검증 완료. 새 버그 {N}개 추가 발견." 또는 "깨끗합니다!"
배포:    "프로덕션 배포 완료. 브라우저에서 확인해주세요."
```

---

## Step -1: Tool Readiness Check

**파이프라인 시작 전 필수 도구 전부 검증. 하나라도 안 되면 즉시 중지.**

```
1. browser-use 환경:
   - source /home/ubuntu/browser-use-env/bin/activate
   - python3.11 -c "from browser_use import Agent" → 임포트 확인
   - python3.11 -c "from browser_use.llm.anthropic.chat import ChatAnthropic" → LLM 확인
   - 안 되면 → 🚩 BLOCK. CEO 보고. 자동 설치 시도 금지.

2. Playwright:
   - cd packages/admin && bunx playwright --version → 설치 확인
   - 안 되면 → 🚩 BLOCK.

3. Codex CLI:
   - which codex → 설치 확인
   - codex exec "echo hello" → 인증 확인
   - 안 되면 → 🚩 BLOCK.

4. Dev 서버:
   - curl -sf http://localhost:3000 → 응답 확인
   - 안 떠있으면 → 자동 시작:
     tmux new-session -d -s corthex-server \
       "cd /home/ubuntu/corthex-v3/packages/server && NODE_ENV=production PORT=3000 bun run src/index.ts 2>/tmp/corthex-server.log"
   - 60초 대기 후 재확인
   - 안 되면 → 🚩 BLOCK.

5. OAuth CLI 토큰 (별도 API key 사용 금지 — CEO 규칙):
   - python3.11 -c "import json; t=json.load(open('/home/ubuntu/.claude/.credentials.json'))['claudeAiOauth']['accessToken']; print('OK' if len(t)>10 else 'EMPTY')"
   - 만료 확인: expiresAt > 현재 시각
   - 안 되면 → 🚩 BLOCK. "claude" 명령어 한 번 실행하면 토큰 갱신됨.
   - ★ ANTHROPIC_API_KEY 환경변수 사용 금지. OAuth 토큰만 사용.

출력:
  ✅/🚩 browser-use: [OK or FAIL]
  ✅/🚩 Playwright: [version or FAIL]
  ✅/🚩 Codex CLI: [version or FAIL]
  ✅/🚩 Dev 서버: [OK or FAIL]
  ✅/🚩 OAuth 토큰: [OK or FAIL or EXPIRED]

판정:
  → 🚩 0개 → Phase 1 진행
  → 🚩 1개라도 → 즉시 중지. CEO 보고.
```

---

## Step 0: Project Auto-Scan

kdh-full-auto-pipeline의 Step 0과 동일. project-context.yaml 재사용.
1시간 이내 캐시가 있으면 스킵.

---

## Phase 1: SCAN — browser-use 전수 탐색

```
팀 구성: 없음 (오케스트레이터 직접 실행)

Step 1: Playwright 기존 smoke 실행
  cd packages/admin && bunx playwright test e2e/smoke.spec.ts
  → FAIL 목록 = 확실한 버그
  → 결과 기록

Step 2: browser-use 전수 탐색
  source /home/ubuntu/browser-use-env/bin/activate
  cd /home/ubuntu/corthex-v3
  python3.11 _browser-use-test/sweep.py --url http://localhost:3000
  
  ★ timeout 없음 — 탐색이 끝날 때까지 기다림
  ★ 한 페이지에 기능이 여러 개 있을 수 있으므로 시간 제한 두지 않음
  ★ stall 감지: 5분간 아무 action이 없으면 → 현재 페이지 탐색 종료, 다음 페이지로

Step 3: 서버 로그 분석
  tail -1000 /tmp/corthex-server.log | grep -E "(Error|500|FATAL|throw)"
  → 최근 에러 패턴 추출
  → 각 에러를 버그로 등록

Step 4: 3개 소스 종합 → bug-fix-state.yaml 생성
  Playwright 실패 + browser-use 발견 + 서버 로그 에러 = 전체 버그 목록
  
  _bmad-output/bug-fix/bug-fix-state.yaml:
  
  project: corthex-v3
  pipeline: bug-fix
  version: v1.0
  last_updated: "{timestamp}"
  outer_loop_count: 0
  max_outer_loops: 5
  
  scan:
    status: complete
    timestamp: "{timestamp}"
    sources:
      playwright_failures: {N}
      browser_use_bugs: {N}
      server_log_errors: {N}
  
  bugs:
    - id: BUG-001
      type: ui
      severity: major
      page: /dashboard
      theme: toss-dark
      description: "흰 배경 + 남색 텍스트 = 눈아픔"
      root_cause: null
      status: discovered
      fix_attempts: 0
      max_attempts: 3
      playwright_test: null
      screenshot: null
      source: browser-use
      repro:
        - "로그인"
        - "대시보드 이동"
        - "테마 → 토스다크"
    - id: BUG-002
      ...

Step 5: CEO 보고 (정보 전달 — GATE 아님)
  "사이트 탐색 완료.
   
   버그 {N}개 발견:
   - 심각: {N}개
   - 보통: {N}개
   - 경미: {N}개
   
   수정 시작합니다."
  
  feature-request 항목이 있으면:
  "이 {N}건은 버그가 아니라 새 기능입니다:
   1. {description}
   2. {description}
   Phase 2(kdh-full-auto-pipeline planning)에서 다뤄야 해요."

★ bugs가 0이면 → "깨끗합니다! 버그 없어요." → 종료.
```

---

## Phase 2: FIX+VERIFY 루프

```
팀 구성:
  TeamCreate("{project}-bugfix-{date}")
  - dev (Writer, sonnet) — 코드 수정 + 테스트 작성
  - quinn (Critic, sonnet) — QA/테스트 관점 리뷰
  - winston (Critic, sonnet) — 아키텍처/코드품질 관점 리뷰

Grade: B (threshold ≥ 7.5/10, 1 cycle)
Model: 전부 sonnet (haiku 금지)
Rubric: _bmad-output/bug-fix/bug-fix-rubric.md

처리 순서: severity critical → major → minor

각 버그마다:
━━━━━━━━━━━━━━━━

Step 2a: DIAGNOSE (오케스트레이터 직접)
  - bug-fix-state.yaml에서 버그 정보 읽기
  - 관련 파일 찾기: Grep으로 page/컴포넌트/라우트 키워드 검색
  - 서버 로그에서 관련 에러 추출 (500, stack trace)
  - 근본 원인 1줄 특정
  - bug-fix-state.yaml에 root_cause 추가
  - status: discovered → diagnosing

Step 2b: FIX (dev 에이전트)
  오케스트레이터 → dev SendMessage:
  "BUG-{id} 수정해라.
   증상: {description}
   페이지: {page}
   원인: {root_cause}
   관련 파일: {files}
   
   규칙:
   - 최소 변경. 버그만 고침. 리팩토링 금지.
   - tsc --noEmit 통과 필수.
   - 수정 후 [Fix Complete] 보내라."
  
  dev가 코드 수정 + tsc 확인
  status: diagnosing → fixing

Step 2c: REGRESSION TEST (dev 에이전트, 이어서)
  dev가 Playwright 회귀 테스트 작성:
  → packages/admin/e2e/bugfix/bug-{id}.spec.ts
  → 이 버그의 repro 시나리오를 Playwright 코드로 고정
  → 테스트 실행해서 PASS 확인
  dev → [Fix Complete] SendMessage

Step 2d: VERIFY (오케스트레이터 직접)
  1. Playwright 회귀 테스트 실행:
     cd packages/admin && bunx playwright test e2e/bugfix/bug-{id}.spec.ts
  
  2. browser-use 재확인:
     source /home/ubuntu/browser-use-env/bin/activate
     python3.11 _browser-use-test/verify-bug.py \
       --bug-id BUG-{id} \
       --description "{description}" \
       --repro "{repro_steps}"
  
  3. 판정:
     - Playwright PASS + browser-use PASS → Step 2e
     - 하나라도 FAIL → dev에게 "아직 안 고쳐짐" SendMessage → Step 2b (재수정)
     - fix_attempts >= max_attempts(3) → ESCALATE (CEO 보고)
  
  ★ timeout 없음 — browser-use가 끝날 때까지 기다림

Step 2e: REVIEW (Party Mode — 2 critics, Grade B)
  dev → [Review Request] SendMessage to quinn, winston BY NAME
  
  quinn 리뷰 영역:
    - D1 재현성: Playwright 테스트가 버그를 잡는가?
    - D3 회귀방지: 테스트 커버리지 충분한가?
    - D4 부작용: 다른 기능 깨뜨리지 않았는가?
  
  winston 리뷰 영역:
    - D2 근본원인: 증상만 고쳤는지 근본 원인 고쳤는지
    - D5 코드품질: 핵 수정이 아닌가?
    - D6 테마호환: 5개 테마에서 다 되는가?
  
  각자 party-log 작성:
    _bmad-output/party-logs/bugfix-{id}-quinn.md
    _bmad-output/party-logs/bugfix-{id}-winston.md
  
  Cross-talk (필수):
    quinn이 winston 로그 Read → Cross-talk 섹션 추가
    winston이 quinn 로그 Read → Cross-talk 섹션 추가
  
  Score 계산:
    avg >= 7.5 → PASS
    avg < 7.5 → fixes → dev 재수정 → 재리뷰 (max 1 retry)
    Any D < 2 (= 5.0/10) → auto-FAIL

Step 2f: 상태 업데이트
  bug-fix-state.yaml:
    status: fixing → fixed
    fix_commit: (아직 커밋 전 — Phase 4에서 커밋)
    playwright_test: e2e/bugfix/bug-{id}.spec.ts
    party_logs:
      - bugfix-{id}-quinn.md
      - bugfix-{id}-winston.md
  
  다음 버그로 이동.

모든 버그 수정 완료 → Phase 3.
```

### Party-log Naming Standard

```
bugfix-{id}-quinn.md      # quinn의 리뷰
bugfix-{id}-winston.md    # winston의 리뷰
bugfix-{id}-fixes.md      # dev의 수정 내역
```

### Agent Spawn Template (Bug Fix)

```
You are {NAME} in team "{team_name}". Role: {Writer|Critic}.

## Your Persona
Read and embody: _bmad/bmm/agents/{file}.md

## Scoring Rubric
Read: _bmad-output/bug-fix/bug-fix-rubric.md
6 dimensions (D1-D6, /4 scale → /10). Grade B: ≥7.5/10. Any D < 2 = auto-FAIL.

## Context
- Bug report: _bmad-output/bug-fix/bug-fix-state.yaml
- Project: project-context.yaml

## Bug Fix Rules
- 최소 변경. 버그만 고침. 리팩토링 금지.
- Playwright 회귀 테스트 필수.
- tsc --noEmit 필수.
- 5개 테마 전부 확인 (D6).
```

---

## Phase 3: SWEEP — 전체 회귀 + Codex

```
팀 구성: 오케스트레이터 직접 (에이전트 최소)

Step 3a: 전체 Playwright suite 실행
  cd packages/admin && bunx playwright test
  → 기존 smoke + 새 bugfix 테스트 전부
  → 1개라도 FAIL → 해당 FAIL을 새 버그로 추가 → Phase 2로

Step 3b: 전체 bun test 실행
  cd packages/server && bun test
  → 기존 unit/integration 테스트
  → FAIL → 새 버그로 추가 → Phase 2로

Step 3c: tsc 전체 검증
  모든 tsconfig.json에 대해 tsc --noEmit
  → FAIL → 수정 필요 (Phase 2로)

Step 3d: browser-use 전수 재탐색
  python3.11 _browser-use-test/sweep.py
  ★ timeout 없음 — 끝까지 탐색
  → 새 버그 발견 → bug-fix-state.yaml에 추가 → Phase 2로 (루프)
  → 0 bugs → Step 3e로

Step 3e: Codex 일괄 리뷰
  전체 변경사항을 Codex에게 리뷰:
  
  git diff main...HEAD > /tmp/bugfix-diff.patch
  codex exec "이 코드 변경을 리뷰해라. 버그 수정 diff다.
  각 변경이:
  1. 근본 원인을 고쳤는가?
  2. 부작용은 없는가?
  3. 회귀 테스트가 충분한가?
  문제 있으면 구체적으로 지적해라.
  $(cat /tmp/bugfix-diff.patch)"
  
  → Codex PASS → Phase 4로
  → Codex FAIL → 이슈 수정 → Step 3e 재실행 (max 1 retry)
  → Codex 실행 불가 (인증/타임아웃) → CEO 보고, 자동 스킵 금지

Step 3f: 5개 테마 스크린샷
  browser-use 또는 Playwright로:
  - 주요 페이지 × 5개 테마 = 스크린샷 매트릭스
  - 저장: _bmad-output/e2e-screenshots/bug-fix/theme-{name}-{page}.png
```

### 외부 루프 메커니즘

```
Phase 3에서 새 버그 발견 → outer_loop_count += 1 → Phase 2로

if outer_loop_count >= max_outer_loops (5):
  → CEO 보고: "5회 루프 후에도 버그 {N}개 남음. 목록:"
  → 남은 버그 목록 제출
  → 강제 종료

if 0 bugs found:
  → Phase 4로
```

---

## Phase 4: DEPLOY + GATE

```
Step 4a: 최종 확인
  - tsc --noEmit (전체) → PASS 필수
  - git status → 커밋 안 된 변경 없는지

Step 4b: 커밋
  git add [수정 파일들 + 테스트 파일들 + 스크린샷]
  git commit -m "fix: {N}건 버그 수정 — browser-use sweep #{outer_loop_count+1}
  
  Fixed bugs:
  - BUG-001: {description}
  - BUG-002: {description}
  ...
  
  Regression tests added: {M}개
  Themes verified: 5/5"

Step 4c: Push + 배포 대기
  git push origin main
  → GitHub Actions 배포 완료 대기

Step 4d: 프로덕션 확인 (오케스트레이터)
  browser-use로 https://corthex-hq.com 접속:
  python3.11 _browser-use-test/sweep.py --url https://corthex-hq.com
  → 프로덕션에서도 수정 확인
  ★ localhost 통과 + 프로덕션 실패 = 다른 문제 (env/deploy 버그)

Step 4e: GATE — CEO 확인 (필수)
  "버그 {N}개 수정 완료! 프로덕션에서 확인해주세요.
   
   수정 내용:
   - BUG-001: {description} ✅
   - BUG-002: {description} ✅
   ...
   
   https://corthex-hq.com 에서 확인해주세요."
  
  → CEO "OK" → 파이프라인 종료. bug-fix-state.yaml에 gate: approved.
  → CEO "여기 또 이상해" → 새 버그 추가 → Phase 1로 (새 sweep)
  → `계속` 모드: [AUTO] 자동 통과 + 기록
```

---

## State Management: bug-fix-state.yaml

```yaml
# ═══════════════════════════════════════════════════════════
# CORTHEX v3 — Bug Fix Pipeline State v1.0
# 모든 세션은 이 파일을 먼저 읽고 정확히 이 지점부터 이어감.
# ═══════════════════════════════════════════════════════════

project: corthex-v3
pipeline: bug-fix
version: v1.0
last_updated: "2026-04-05T..."
outer_loop_count: 0
max_outer_loops: 5

current_phase: scan  # [scan | fix | sweep | deploy | complete]
team_name: null

scan:
  status: pending  # [pending | in_progress | complete]
  timestamp: null
  sources:
    playwright_failures: 0
    browser_use_bugs: 0
    server_log_errors: 0

bugs:
  # Each bug follows this structure:
  # - id: BUG-001
  #   type: ui | routing | schema | env | logic
  #   severity: critical | major | minor
  #   page: /path
  #   theme: theme-name | null
  #   description: "..."
  #   root_cause: "..." | null
  #   status: discovered | diagnosing | fixing | verifying | fixed | wont-fix | escalated
  #   fix_attempts: 0
  #   max_attempts: 3
  #   playwright_test: path | null
  #   screenshot: path | null
  #   source: playwright | browser-use | server-log | ceo-report
  #   repro: ["step 1", "step 2"]
  #   party_logs: []
  #   codex_result: null

sweep:
  status: pending
  new_bugs_found: 0
  codex:
    status: null  # [pass | fail | blocked]
    result: null

deploy:
  status: pending
  commit: null
  gate: null  # [pending | approved | rejected | auto]
```

### State 업데이트 규칙

- Phase 시작 시: current_phase 업데이트
- 버그 상태 변경 시: 해당 bug의 status 업데이트
- 매 변경 시: last_updated 갱신
- 항상 멀티라인 YAML (인라인 금지)

---

## Defense & Stall Detection

timeout은 사용하지 않음. 대신 stall 감지:

| 메커니즘 | 조건 | 행동 |
|----------|------|------|
| stall_detection | 5분간 browser-use action 없음 | 현재 탐색 종료, 결과 저장 |
| fix_max_attempts | 버그당 3회 수정 시도 | ESCALATE → CEO 보고 |
| outer_loop_max | Phase 3→2 루프 5회 | 강제 종료 + 잔여 버그 보고 |
| codex_retry | Codex FAIL 1회 | 수정 후 재실행 (max 1) |
| review_retry | Party avg < 7.5 | fixes → 재리뷰 (max 1) |
| server_startup | Dev 서버 60초 내 미응답 | 🚩 BLOCK |

★ **timeout 없음** — browser-use가 한 페이지에서 20분 걸려도 정상. 기능이 많으면 시간이 걸림.
★ **stall ≠ timeout** — stall은 "아무것도 안 함"일 때만. 열심히 탐색 중이면 절대 안 끊음.

---

## Core Rules

1. **browser-use = 필수.** Playwright만 PASS해도 browser-use FAIL이면 전체 FAIL. "Playwright 통과했으니 OK" 금지.
2. **매 버그마다 Playwright 회귀 테스트 필수.** 테스트 없이 "고쳤다"는 FAIL.
3. **Phase 3 → Phase 2 루프 최대 5회.** 5회 초과 = CEO 보고 + 강제 종료.
4. **Codex FAIL = 자동 진행 금지.** 수정 후 재실행. 실행 불가 시 CEO 보고. **Codex 미실행 = Phase 4 진입 금지. pipeline-guard.sh가 bug-fix-state.yaml의 codex status 확인. pass 아니면 커밋 차단.**
5. **GATE(Phase 4) = CEO 확인 필수.** 자동 통과 금지 (계속 모드 제외).
6. **bug-fix-state.yaml 항상 멀티라인.** 인라인 YAML 금지.
7. **"새 기능" 분류 버그는 수정 대상 아님.** CEO 보고 → kdh-full-auto-pipeline으로.
8. **5개 테마 전부 확인.** 1개 테마만 확인 = D6 자동 FAIL.
9. **근본 원인 못 찾으면 수정 금지.** "일단 고치기" 금지. 원인 먼저.
10. **localhost + 프로덕션 둘 다 확인.** Phase 4에서 프로덕션도 browser-use 탐색.
11. **haiku 모델 사용 금지.** 전부 sonnet.
12. **party-log 파일 필수.** 파일 없으면 PASS 불가.
13. **Cross-talk 필수.** quinn↔winston 상호 로그 읽기 + Cross-talk 섹션.
14. **timeout 없음.** stall 감지(5분 무활동)만 사용. 시간 제한 두지 않음.
15. **TeamCreate 필수.** Phase 2에서 에이전트 소환 전 TeamCreate.
16. **TeamDelete 필수.** 파이프라인 종료 시 팀 정리.
17. **최소 변경 원칙.** 버그만 고침. 주변 코드 리팩토링/개선 금지.
18. **context-snapshot 저장.** Phase 완료마다 context-snapshots/bug-fix/ 에 저장.
19. **compliance YAML.** Phase 완료마다 _bmad-output/compliance/bugfix-{date}-phase-{N}.yaml 기록.

---

## BMAD Agent Roster (Bug Fix용)

| Spawn Name | Persona File | Role in Bug Fix |
|-----------|-------------|----------------|
| `dev` | `_bmad/bmm/agents/dev.md` | Writer — 코드 수정 + Playwright 테스트 작성 |
| `quinn` | `_bmad/bmm/agents/qa.md` | Critic — 테스트 커버리지, 부작용, 에지케이스 |
| `winston` | `_bmad/bmm/agents/architect.md` | Critic — 근본원인, 코드품질, 아키텍처 영향 |

john(PM)은 버그 수정에서 불필요 — 제품 방향 결정이 없으므로 소환하지 않음.
sally(UX)도 소환하지 않음 — UI 버그는 dev + 5테마 검증으로 충분.

---

## Model Strategy

| Role | Model | Rationale |
|------|-------|-----------|
| Orchestrator | opus | 복합 판단, 상태 관리, CEO 소통 |
| dev (Writer) | sonnet | 코드 수정, 테스트 작성 |
| quinn (Critic) | sonnet | QA 리뷰 |
| winston (Critic) | sonnet | 아키텍처 리뷰 |
| Codex | GPT-5.4 | 외부 모델 교차 검증 |

Grade B only — opus critic 불필요 (버그 수정은 Grade A 판단이 필요 없음).
**haiku 절대 금지 (CEO 규칙).**

---

## browser-use Configuration

### sweep.py (전수 탐색)
```
script: _browser-use-test/sweep.py
args: --url http://localhost:3000
model: claude-sonnet-4-20250514
LLM class: browser_use.llm.anthropic.chat.ChatAnthropic
headless: true
max_actions_per_step: 8
generate_gif: true
timeout: NONE
stall: 5분 무활동 시 현재 페이지 종료
```

### verify-bug.py (개별 확인)
```
script: _browser-use-test/verify-bug.py
args: --bug-id BUG-XXX --description "..." --repro "step1;step2"
model: claude-sonnet-4-20250514
headless: true
max_actions_per_step: 5
timeout: NONE
```

### 주의사항
- langchain ChatAnthropic 사용 금지 — `browser_use.llm.anthropic.chat.ChatAnthropic` 사용
- Python 3.10 호환 불가 — 반드시 Python 3.11+
- BrowserConfig 제거됨 — `BrowserProfile` + `BrowserSession` 사용
- venv 경로: `/home/ubuntu/browser-use-env/`
- **API 키: OAuth CLI 토큰 사용** — `~/.claude/.credentials.json`에서 accessToken 읽음. 별도 ANTHROPIC_API_KEY 환경변수 사용 금지 (CEO 규칙)
- OAuth 토큰 만료 시: `claude` 명령어 한 번 실행하면 자동 갱신

---

## Entry / Exit Criteria

### Entry (이 파이프라인을 언제 쓰는가)
- 프로덕션에서 버그 발견 (CEO 보고 또는 모니터링)
- Sprint 완료 후 브라우저 검증 실패
- kdh-full-auto-pipeline Sprint End GATE에서 CEO가 문제 발견
- 정기 탐색 (browser-use sweep 스케줄)
- **Sprint End 자동 연동 (v11.0):** dev pipeline Sprint End Step 3에서 필수 호출. /kdh-bug-fix-pipeline scan으로 시작. 0 bugs = PASS → dev pipeline Sprint End 계속. bugs 있으면 수정 루프 → 0 bugs 될 때까지 다음 Sprint 금지.

### Exit (언제 끝나는가)
- browser-use 전수 탐색: 0 bugs found
- Playwright 전체 suite: 100% PASS
- Codex: PASS
- tsc: PASS
- CEO GATE: approved

하나라도 미충족 → 종료 불가.

---

## Pipeline Interconnection

### kdh-full-auto-pipeline → kdh-bug-fix-pipeline
Sprint End GATE #19에서 CEO가 버그 발견 시:
1. 발견된 버그 목록 작성
2. `/kdh-bug-fix-pipeline` 실행
3. 버그 수정 완료 → kdh-full-auto-pipeline Sprint End GATE 재실행

### kdh-bug-fix-pipeline → kdh-full-auto-pipeline
Phase 1 SCAN에서 "새 기능 필요" 발견 시:
1. feature-request로 분류
2. CEO 보고
3. CEO 승인 → kdh-full-auto-pipeline planning에 포함

---

## Anti-Patterns

1. **"Playwright만 통과했으니 OK"** — browser-use 검증 없이 PASS 처리. FIX: browser-use 검증 필수.
2. **증상만 고치기** — CSS `!important` 남발, setTimeout으로 타이밍 우회. FIX: D2(근본원인) < 2면 auto-FAIL.
3. **회귀 테스트 없이 커밋** — "간단한 수정이라 테스트 불필요". FIX: 모든 버그에 Playwright 테스트 필수.
4. **1개 테마만 확인** — 기본 테마에서만 확인하고 나머지 4개 무시. FIX: D6 체크.
5. **버그를 새 기능으로 "그냥 만들기"** — 없는 기능인데 버그로 분류해서 여기서 구현. FIX: feature-request 분류 후 CEO 보고.
6. **외부 루프 무한** — Phase 3에서 계속 새 버그 발견해서 영원히 안 끝남. FIX: max 5회.
7. **dev 서버 안 띄우고 시작** — browser-use가 접속할 서버가 없음. FIX: Step -1에서 검증.
