# KDH Playwright E2E Full-Auto 24/7 — TMUX Version v2.0 (Team Agents)

Loop-based automated E2E testing + instant bug fix + deploy. Uses **TeamCreate** for parallel 4-agent testing. Runs on Oracle VPS inside tmux + Claude CLI.

## When to Use

- `/loop 30m /kdh-playwright-e2e-full-auto-24-7-tmux` — 30분마다 자동 사이클
- `/kdh-playwright-e2e-full-auto-24-7-tmux` — 단발 실행
- Oracle VPS tmux 세션에서 Claude CLI로 실행
- VS 버전보다 3-4배 빠름 (4개 팀 에이전트 병렬)

## Prerequisites

- Oracle VPS tmux session with Claude CLI
- Playwright MCP with headless chromium in `.mcp.json`
- Live site: https://corthex-hq.com
- Admin: admin / admin1234

---

## CRITICAL: Tool Loading (매 사이클 첫 단계)

팀 에이전트를 쓰려면 deferred tools를 먼저 로드해야 한다. **사이클 시작 전 반드시 실행:**

```
ToolSearch("select:TeamCreate,TeamDelete,TaskCreate,TaskList,TaskUpdate,TaskGet,SendMessage")
```

이걸 안 하면 TeamCreate를 못 쓰고, 습관적으로 Agent(run_in_background)로 빠진다. **절대 Agent 단독 사용 금지. 반드시 TeamCreate 먼저.**

---

## CRITICAL: Browser Contention Prevention (TMUX-specific)

4개 에이전트가 동시에 headless Chromium을 쓰면 lock 충돌이 발생한다. 반드시 스태거드 스폰:

```
Staggered spawn order:
  Agent A: 즉시 (0s)
  Agent C: +30s
  Agent D: +60s
  Agent B: +90s  (스크린샷 많으므로 마지막)
```

**각 에이전트 브라우저 규칙:**
- Lock failure 시 15초 대기 후 재시도 (max 3회)
- 페이지 그룹 전환 시 `browser_close()` 호출 후 새로 열기
- Future: staggering으로 부족하면 multi-MCP 인스턴스 전환

---

## ABSOLUTE: Phase 건너뛰기 금지

**매 사이클은 반드시 Phase 0->1->2->3->4->5->6->7->8 순서대로 전부 실행한다.**

### Phase 2 (Playwright 4-Agent 테스트)는 이 스킬의 존재 이유다.

- "이전 사이클에서 이미 테스트했으니까 건너뛴다" -> **절대 금지**
- "버그 목록이 이미 있으니까 바로 수정한다" -> **절대 금지**
- "시간이 부족하니까 Phase 2를 줄인다" -> **에이전트 수를 줄여도 되지만 0으로 건너뛰기는 금지**
- 매 사이클은 **독립적**이다. 이전 사이클 결과는 **참고만** 하고, **대체하지 않는다.**

### Phase 게이트: Phase 4 진입 전 필수 검증

Phase 4(Bug Fix)를 시작하기 전에 오케스트레이터가 반드시 확인:

```
GATE CHECK (하나라도 실패 -> Phase 2로 돌아가서 재실행):
  1. cycle-{N}/agent-A.md 존재 + 10줄 이상
  2. cycle-{N}/agent-B.md 존재 + 10줄 이상
  3. cycle-{N}/agent-C.md 존재 + 10줄 이상
  4. cycle-{N}/agent-D.md 존재 + 10줄 이상
  5. cycle-{N}/screenshots/ 안에 파일 1개 이상
```

**예외: Playwright MCP 다운 시**
- 브라우저 접속 자체가 불가능한 경우에 한해
- `cycle-{N}/BROWSER_DOWN.md`에 사유 + 에러 메시지 기록
- API-only fallback 모드로 전환 (curl 테스트만)
- 이 경우에도 agent-A~D.md는 API/소스코드 분석 결과로 작성해야 함

### 이전 사이클 참고 원칙: 참고 O, 대체 X

- Agent D가 이전 `merged-bugs.md` 읽고 회귀 테스트 -> OK
- Fixer가 이전 사이클 미수정 버그를 이번에 수정 -> OK
- "이전 사이클에서 테스트했으니 Phase 2 건너뜀" -> **절대 금지**

---

## Cycle Structure (30min target)

### Phase 0: Pre-flight (30s)

```
1. curl GET https://corthex-hq.com -> site alive?
   - DOWN -> log "SITE DOWN" -> skip cycle
2. POST /api/auth/admin/login -> get JWT token
   - FAIL -> log "LOGIN FAILED" -> skip cycle
3. gh run list -L 1 -> last deploy status
   - FAILED -> log warning, continue
4. Read _qa-e2e/playwright-e2e/cycle-report.md -> previous cycle results
   - Unresolved bugs from last cycle = priority targets
5. Determine cycle number: ls cycle-* dirs -> N = max + 1
6. mkdir -p _qa-e2e/playwright-e2e/cycle-{N}/screenshots
7. 오래된 사이클 삭제: cycle-(N-3) 이하 폴더 전부 rm -rf
   - 최근 3사이클만 유지 (용량 관리)
   - cycle-report.md는 삭제하지 않음 (누적 로그)
8. Test Data Setup:
   - POST /api/admin/companies with body {"name": "E2E-TEMP-{N}"}
   - Store response companyId as E2E_COMPANY_ID
   - All CRUD tests in this cycle use E2E_COMPANY_ID exclusively
9. Read reference files:
   - Read _qa-e2e/playwright-e2e/known-behaviors.md -> KB-{NNN} list
   - Read _qa-e2e/playwright-e2e/ESCALATED.md -> ESC-{NNN} list
   - Read _qa-e2e/playwright-e2e/stability-state.md -> clean_cycles count, last_bug_cycle
   - Check git log --oneline -5 -> any new commits since last cycle?
```

### Phase 1: API Smoke Test (1min)

```
Using curl with admin token + E2E_COMPANY_ID query param, hit ALL endpoints:

TOKEN = (Phase 0에서 획득)
COMPANYID = E2E_COMPANY_ID (Phase 0 step 8에서 생성)
BASE = "https://corthex-hq.com/api/admin"

Admin endpoints (~25):
  companies, users?companyId, employees?companyId, departments?companyId,
  agents?companyId, tools?companyId, costs/summary?companyId,
  costs/by-agent?companyId, costs/by-model?companyId, costs/daily?companyId,
  budget?companyId, credentials?companyId, api-keys?companyId,
  report-lines?companyId, org-chart?companyId, org-templates?companyId,
  soul-templates?companyId, monitoring?companyId, audit-logs?companyId,
  tool-invocations?companyId, mcp-servers?companyId

For each:
  - 200/201 -> OK
  - 500 -> CRITICAL bug (record error message)
  - 404 -> HIGH bug (route not mounted)
  - 401/403 -> Check if auth issue
```

---

### Phase 2: Parallel E2E Sweep — 4 Team Agents (5min)

**이 Phase가 TMUX 버전의 핵심. 반드시 TeamCreate -> TaskCreate -> Agent(team_name) 순서.**

#### Step 2.0: 팀 생성

```
도구 호출: TeamCreate(team_name: "e2e-cycle-{N}")
```

#### Step 2.1: 공유 파일 생성

```
Write -> _qa-e2e/playwright-e2e/cycle-{N}/blockers.md  (빈 파일)
Write -> _qa-e2e/playwright-e2e/cycle-{N}/bugs.md      (Phase 1 결과 포함)

bugs.md 표준 형식:
| Bug ID | Agent | Page | Severity | Description | Screenshot |
|--------|-------|------|----------|-------------|------------|
| BUG-A001 | A | /companies | Major | Create button 500 error | companies-A001.png |

- Bug ID 규칙: BUG-{AGENT}{NNN} (예: BUG-A001, BUG-B003, BUG-C002, BUG-D005)
- 에이전트는 bugs.md에 쓰기 전 기존 항목 확인 -> 중복이면 skip
```

#### Step 2.2: 태스크 4개 생성

```
도구 호출 (4개 병렬):
  TaskCreate(subject: "Agent A: Functional CRUD", description: "...")
  TaskCreate(subject: "Agent B: Visual Design", description: "...")
  TaskCreate(subject: "Agent C: Edge Security", description: "...")
  TaskCreate(subject: "Agent D: Regression Navigation", description: "...")
```

#### Step 2.3: 팀 에이전트 4개 스폰 (스태거드)

**중요: 모든 Agent 호출에 team_name 필수. 빠뜨리면 서브에이전트가 되어 팀 통신 불가.**
**중요: 브라우저 경합 방지를 위해 스태거드 스폰 (A->C->D->B, 30초 간격).**

```
도구 호출 (4개 — 30초 간격으로 순차):

[즉시] Agent(
  name: "agent-A",
  team_name: "e2e-cycle-{N}",
  description: "Functional CRUD testing",
  mode: "bypassPermissions",
  prompt: "[Agent A 프롬프트 — 아래 참조]"
)

[+30s] Agent(
  name: "agent-C",
  team_name: "e2e-cycle-{N}",
  description: "Edge security testing",
  mode: "bypassPermissions",
  prompt: "[Agent C 프롬프트 — 아래 참조]"
)

[+60s] Agent(
  name: "agent-D",
  team_name: "e2e-cycle-{N}",
  description: "Regression navigation testing",
  mode: "bypassPermissions",
  prompt: "[Agent D 프롬프트 — 아래 참조]"
)

[+90s] Agent(
  name: "agent-B",
  team_name: "e2e-cycle-{N}",
  description: "Visual design testing",
  mode: "bypassPermissions",
  prompt: "[Agent B 프롬프트 — 아래 참조]"
)
```

#### Agent A — Functional (CRUD + Buttons)

```
Assigned pages: companies, employees, departments, agents, tools,
                credentials, api-keys, onboarding, settings, users,
                report-lines, workflows

Pre-check:
  - Read _qa-e2e/playwright-e2e/known-behaviors.md -> skip KB-{NNN} items
  - Read _qa-e2e/playwright-e2e/ESCALATED.md -> skip ESC-{NNN} items
  - Read cycle-{N}/bugs.md -> don't re-report existing BUG IDs

Browser rules:
  - Lock failure -> wait 15s, retry (max 3)
  - browser_close() between page groups

Tasks:
  - Login via Playwright MCP -> admin / admin1234
  - Click EVERY button on assigned pages
  - Dead button (no response) = BUG
  - Try CRUD: create -> read -> update -> delete on each page
  - ALL CRUD operations use E2E_COMPANY_ID only (not default company)
  - Form validation: empty submit, Korean test data ("테스트팀", "김테스트")
  - DO NOT manually delete test data (Phase 8 cleans up entire E2E company)
  - Check blockers.md before each page (skip if blocked)
  - Record all bugs to cycle-{N}/bugs.md using BUG-A{NNN} format
  - Write summary to cycle-{N}/agent-A.md
  - TaskUpdate(status: "completed") when done
```

#### Agent B — Visual + Design

```
Assigned pages: ALL 21 admin pages (screenshot sweep)

Pre-check:
  - Read _qa-e2e/playwright-e2e/known-behaviors.md -> skip KB-{NNN} items
  - Read _qa-e2e/playwright-e2e/ESCALATED.md -> skip ESC-{NNN} items
  - Read cycle-{N}/bugs.md -> don't re-report existing BUG IDs

Browser rules:
  - Lock failure -> wait 15s, retry (max 3)
  - browser_close() between page groups (every 5 pages)

Tasks:
  - Login via Playwright MCP
  - Navigate each page -> browser_take_screenshot
  - Check design tokens (Natural Organic):
    - bg: cream #faf8f5, sidebar: olive dark #283618
    - bg-blue-* anywhere = BUG (should be olive/cream)
    - Material Symbols text ("check_circle", "more_vert") = BUG (should be Lucide)
    - Font not Inter = BUG
  - Check responsive: browser_resize(390, 844) -> screenshot
  - Empty state: correct message displayed?
  - Record all bugs to cycle-{N}/bugs.md using BUG-B{NNN} format
  - Write summary to cycle-{N}/agent-B.md
  - TaskUpdate(status: "completed") when done
```

#### Agent C — Edge + Security

```
Assigned pages: ALL admin pages + unauthenticated access

Pre-check:
  - Read _qa-e2e/playwright-e2e/known-behaviors.md -> skip KB-{NNN} items
  - Read _qa-e2e/playwright-e2e/ESCALATED.md -> skip ESC-{NNN} items
  - Read cycle-{N}/bugs.md -> don't re-report existing BUG IDs

Browser rules:
  - Lock failure -> wait 15s, retry (max 3)
  - browser_close() between page groups

Tasks:
  - Visit each page WITHOUT token -> should redirect to /admin/login
  - Login, then collect console errors on every page
  - Try XSS: <script>alert(1)</script> in text fields
  - Empty required fields -> submit -> should show validation
  - Rapid click: double-click delete button -> should not double-delete
  - CRITICAL bugs -> immediately write to blockers.md
  - Record all bugs to cycle-{N}/bugs.md using BUG-C{NNN} format
  - Write summary to cycle-{N}/agent-C.md
  - TaskUpdate(status: "completed") when done
```

#### Agent D — Regression + Navigation

```
Assigned pages: sidebar full sweep + previous cycle's fixed pages

Pre-check:
  - Read _qa-e2e/playwright-e2e/known-behaviors.md -> skip KB-{NNN} items
  - Read _qa-e2e/playwright-e2e/ESCALATED.md -> skip ESC-{NNN} items
  - Read cycle-{N}/bugs.md -> don't re-report existing BUG IDs

Browser rules:
  - Lock failure -> wait 15s, retry (max 3)
  - browser_close() between page groups

Tasks:
  - Login via Playwright MCP
  - Click EVERY sidebar link -> page loads correctly?
  - Previous cycle bugs -> re-test each one (regression check)
  - Theme consistency: 5+ pages, verify olive palette
  - Shared components: sidebar, layout, toast, modal
  - Session persistence: navigate 10 pages -> still logged in?
  - Record all bugs to cycle-{N}/bugs.md using BUG-D{NNN} format
  - Write summary to cycle-{N}/agent-D.md
  - TaskUpdate(status: "completed") when done
```

#### Step 2.4: 대기 + 수집

```
대기 방법: TaskList 주기적 확인 또는 SendMessage 자동 수신
  - 각 에이전트 timeout: 5분
  - 타임아웃 시 -> SendMessage(to: "agent-X", message: "TIMEOUT — wrap up now")
  - 30초 추가 대기 -> 부분 결과 수집
```

#### Step 2.5: 집계

```
오케스트레이터가 직접:
  - Read cycle-{N}/bugs.md (이미 표준 형식 + BUG ID로 관리됨)
  - Read cycle-{N}/blockers.md
  - 중복 최종 확인: 같은 페이지 + 같은 증상 = merge (BUG ID 중 나중 것 제거)
  - 심각도 분류: Critical / Major / Minor
  - Write -> cycle-{N}/merged-bugs.md
```

---

### Phase 3: React Code Analysis + Cross-Check (30s)

```
Static analysis (no browser needed):

1. Route-API Mismatch Detection:
   - Parse App.tsx -> extract all <Route path="...">
   - For each page file: grep api.get/post/put/delete calls
   - Cross-reference with server routes (index.ts app.route lines)
   - Mismatch = BUG

2. Cross-Check (from cross-check.sh logic):
   - Grep for remaining bg-blue- in admin pages -> should be olive
   - Grep for Material Symbols text -> should be Lucide
   - Check tenantMiddleware presence in admin routes
   - Check migration IF NOT EXISTS
```

---

### Phase 4: Parallel Bug Fix — 3 Fixer Agents (5min)

**Only if bugs found in Phase 2+3. 버그 없으면 Phase 6으로 건너뜀.**

#### Step 4.0: ESCALATED 업데이트

```
이전 사이클에서 ESCALATED 마킹된 버그 확인:
  - Read _qa-e2e/playwright-e2e/ESCALATED.md
  - merged-bugs.md에서 2회 실패한 버그 -> ESCALATED.md에 추가:
    | ESC-{NNN} | {date} | {description} | {page} | cycles_re_reported: 0 |
  - cycles_re_reported >= 3인 항목 -> cycle-report에 WARNING 추가
```

#### Step 4.1: 픽서 팀 생성

```
도구 호출: TeamCreate(team_name: "e2e-fixers-{N}")
도구 호출 (3개):
  TaskCreate(subject: "Fixer A: Server bugs", description: "...")
  TaskCreate(subject: "Fixer B: Frontend bugs", description: "...")
  TaskCreate(subject: "Fixer C: Design/UX bugs", description: "...")
```

#### Step 4.2: 픽서 에이전트 3개 스폰

```
Agent(name: "fixer-A", team_name: "e2e-fixers-{N}", description: "Fix server bugs", mode: "bypassPermissions", prompt: "...")
Agent(name: "fixer-B", team_name: "e2e-fixers-{N}", description: "Fix frontend bugs", mode: "bypassPermissions", prompt: "...")
Agent(name: "fixer-C", team_name: "e2e-fixers-{N}", description: "Fix design bugs", mode: "bypassPermissions", prompt: "...")
```

**Fixer 역할 분담:**

| Fixer | Scope | 담당 |
|-------|-------|------|
| A — Server | `packages/server/src/**` | 500 errors, 404 routes, auth issues |
| B — Frontend | `packages/admin/src/**` (logic) | Console errors, dead buttons, empty pages |
| C — Design | `packages/admin/src/**` (CSS only) | Blue->olive, layout, icon replacements |

**각 Fixer 규칙:**
- **Change Type 선언 필수** — 수정 시작 전 타입 선언:
  - Logic (서버/프론트 로직): max 3 files
  - Style (CSS/테마): max 10 files
  - Text/i18n (텍스트/번역): max 15 files
  - Mixed (여러 타입): max 5 files
- Read file -> apply fix -> tsc check
- tsc fail -> revert -> 다른 방법 (max 2 attempts)
- 2회 실패 -> mark ESCALATED
- TaskUpdate(status: "completed") when done

#### Step 4.3: 머지 + 검증

```
모든 Fixer 완료 후 오케스트레이터가:
  1. 각 Fixer 결과 확인 (cycle-{N}/fix-results.md)
  2. bunx tsc --noEmit -p packages/server/tsconfig.json
  3. bunx tsc --noEmit -p packages/admin/tsconfig.json
  4. Type error 발생 시 -> 해당 Fixer 변경분 revert
```

#### Step 4.4: 픽서 팀 정리

```
각 Fixer에게: SendMessage(to: "fixer-X", message: {type: "shutdown_request"})
도구 호출: TeamDelete  (e2e-fixers-{N} 정리)
```

---

### Phase 5: Simplify (1min)

```
If any files were modified in Phase 4:
  Run /simplify logic on changed files only:
  - Code reuse: existing utils that could replace new code?
  - Code quality: redundant state, copy-paste?
  - Efficiency: unnecessary work?
  Fix any issues found.
```

### Phase 6: Deploy + Post-Deploy Verification (3min)

```
If any files were modified:
  1. git add {specific changed files only}
  2. git commit -m "fix(e2e-cycle-{N}): {bug summary}

     Bugs fixed: {count}
     - P{X}: {description}
     ...

     Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
  3. git push origin main
  4. Wait for deploy:
     - Poll: gh run list -L 1 (20초 intervals, max 6 checks = 2분)
     - SUCCESS -> continue to verification
     - FAILED -> record in cycle report, skip verification
     - TIMEOUT (6 checks) -> record "deploy timeout" in cycle report
  5. Post-deploy verification:
     - Run: bash .claude/hooks/smoke-test.sh
     - All endpoints 200 OK -> record PASS in cycle report
     - Any failure -> record FAIL + failing endpoints in cycle report
  6. Record deploy result: {success|failed|skipped|timeout} + smoke-test {pass|fail}

If no files modified:
  Skip deploy.
```

### Phase 7: Working State Update (30s)

```
Update .claude/memory/working-state.md:
  - Last cycle: #{N} at {time}
  - Bugs fixed this cycle: {count}
  - Bugs remaining: {list}
  - Total cycles run: {N}
  - Total bugs fixed: {N}
  - Next cycle priority: {what to focus on}
```

### Phase 8: Report + Cleanup (30s)

```
0. Test Data Cleanup:
   - DELETE /api/admin/companies/{E2E_COMPANY_ID}
   - Verify 200 response (all associated data cascade-deleted)
   - If delete fails -> log warning, continue

1. Append to _qa-e2e/playwright-e2e/cycle-report.md:

## Cycle #{N} — {timestamp}
- API: {passed}/{total} OK
- Pages loaded: {N}/{total}
- Console errors: {N}
- Dead buttons: {N}
- Bugs found: {N} (P0:{n} P1:{n} P2:{n} P3:{n})
- Bugs fixed: {N}
- Bugs remaining: {N}
- Bugs escalated: {N}
- ESCALATED warnings: {list of ESC items with cycles_re_reported >= 3}
- Files modified: {list}
- Deploy: {success|failed|skipped|timeout}
- Smoke test: {pass|fail|skipped}
- Test company: E2E-TEMP-{N} cleanup: {success|failed}

2. Update stability-state.md:
   - If 0 bugs found -> increment clean_cycles
   - If bugs found -> reset clean_cycles to 0, set last_bug_cycle = N
   - Record last_cycle = N, last_timestamp = {now}

3. E2E 에이전트 팀 정리:
   각 에이전트에게: SendMessage(to: "agent-X", message: {type: "shutdown_request"})
   도구 호출: TeamDelete  (e2e-cycle-{N} 정리)
```

---

## Auto-Stabilization Protocol

After Phase 8, check stabilization conditions:

```
Read _qa-e2e/playwright-e2e/stability-state.md:
  - clean_cycles: number of consecutive 0-bug cycles
  - last_bug_cycle: last cycle that found bugs
  - mode: "ACTIVE" | "STABLE_WATCH"

ENTER STABLE_WATCH when ALL true:
  - clean_cycles >= 3
  - No new git commits since last cycle
  - No manual request for full cycle

STABLE_WATCH mode:
  - Agent D only (regression + navigation sweep)
  - 2h interval instead of 30m
  - No fixer agents spawned
  - Reduced scope: sidebar sweep + previous bug re-check only
  - Update stability-state.md: mode = "STABLE_WATCH"

EXIT STABLE_WATCH (return to ACTIVE) when ANY true:
  - Agent D finds a new bug
  - New git commit detected (git log check in Phase 0)
  - Manual request from user
  - Update stability-state.md: mode = "ACTIVE", clean_cycles = 0
```

---

## Safety Limits

- **Smart file limits per fixer (by change type):**
  - Logic (server/frontend logic): max 3 files
  - Style (CSS/theme): max 10 files
  - Text/i18n (text/translation): max 15 files
  - Mixed (multiple types): max 5 files
  - Fixer MUST declare change type before starting
- No deleting files
- No changing package.json
- No modifying migrations or auth middleware
- tsc must pass before commit
- If deploy fails -> next cycle detects and warns

## Timeouts

| Phase | Timeout | On timeout |
|-------|---------|------------|
| Pre-flight | 30s | Skip cycle |
| API smoke test | 2min | Report partial, continue |
| Per agent (Phase 2) | 5min | SendMessage "TIMEOUT" -> 30s -> collect partial |
| Per fixer (Phase 4) | 3min | Skip bug, mark ESCALATED |
| Deploy wait (Phase 6) | 2min | Record timeout, skip smoke test |
| Total cycle | 25min | Force report with partial results |

## Output

```
_qa-e2e/playwright-e2e/
  cycle-report.md          <- cumulative report (appended each cycle)
  ESCALATED.md             <- persistent list of bugs that failed 2+ fix attempts
  known-behaviors.md       <- KB-{NNN} items: known non-bugs (not to be re-reported)
  stability-state.md       <- clean_cycles, last_bug_cycle, mode (ACTIVE/STABLE_WATCH)
  cycle-{N}/
    agent-A.md             <- Functional CRUD results
    agent-B.md             <- Visual design results
    agent-C.md             <- Edge security results
    agent-D.md             <- Regression navigation results
    blockers.md            <- Site-wide blockers (shared between agents)
    bugs.md                <- Shared bug list with BUG-{AGENT}{NNN} IDs (standardized table)
    merged-bugs.md         <- Aggregated + final de-duplicated bugs
    fix-results.md         <- Fixer agent results
    screenshots/
      {page}-{bug-id}.png  <- Bug evidence
```

## Fallback

If TeamCreate fails (connection issue, resource limit):
  -> Auto-fallback to VS version (sequential single-agent mode)
  -> Log: "TeamCreate failed, running in single-agent mode"
  -> Continue cycle without interruption

## Rules

1. **TeamCreate 필수** — Agent 단독 사용 금지. 반드시 TeamCreate -> Agent(team_name) 순서
2. **ToolSearch 선행** — 사이클 시작 시 TeamCreate, TaskCreate, SendMessage 등 deferred tools 먼저 로드
3. **team_name 파라미터** — Agent 스폰 시 team_name 빠뜨리면 서브에이전트가 됨. 팀 통신 불가
4. **Never stop on single failure** — record and continue
5. **Screenshot on bugs** — visual evidence is mandatory
6. **Console errors are bugs** — no exceptions
7. **Dead buttons are bugs** — clickable element that does nothing = BUG
8. **Test data isolation** — all CRUD in E2E_COMPANY_ID only. Phase 8 deletes the company
9. **Type-check before commit** — tsc must pass or no deploy
10. **Smart file limits** — Fixer declares change type, limit applied per type (Logic:3, Style:10, Text:15, Mixed:5)
11. **Don't touch auth/middleware** — too risky for auto-fix
12. **Olive theme only** — any blue (#3b82f6, bg-blue-*) = immediate fix
13. **Report every cycle** — even if 0 bugs found
14. **TeamDelete after each phase** — Fixer 팀은 Phase 4 끝나면 정리, E2E 팀은 Phase 8에서 정리
15. **Phase 건너뛰기 절대 금지** — Phase 0->1->2->3->4->5->6->7->8 전부 순서대로. "이전 사이클 결과로 대체" 금지
16. **Phase 게이트** — Phase 4 시작 전 agent-A~D.md 4개 + screenshots/ 1개 이상 검증. 미충족 시 Phase 2 재실행
17. **참고 O 대체 X** — 이전 사이클 결과는 참고만 (Agent D 회귀테스트 등). 현재 사이클 Playwright 테스트를 대체할 수 없음
18. **오래된 사이클 자동 삭제** — Phase 0에서 최근 3사이클만 유지, 나머지 rm -rf (cycle-report.md는 유지)
19. **Known Behaviors 확인** — 모든 에이전트는 known-behaviors.md의 KB-{NNN} 항목을 버그로 리포트하지 않음
20. **ESCALATED 추적** — 2회 fix 실패 -> ESCALATED.md 등록. cycles_re_reported >= 3 -> cycle-report에 WARNING. 에이전트는 ESC 항목 재리포트 금지
21. **Auto-Stabilization** — 3연속 clean cycle + 새 커밋 없음 -> STABLE_WATCH 모드 (Agent D only, 2h interval). 새 버그/커밋/수동 요청 시 ACTIVE 복귀
