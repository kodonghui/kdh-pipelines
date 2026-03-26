---
name: 'kdh-code-review-full-auto'
description: 'Universal full-auto code review + auto-fix pipeline v4.1 + ECC v1.9.0 integration. 8 phases: Static Gate → Visual/E2E → Risk Analysis → 3-Critic Party → Verdict → Auto-Fix → Re-Review → Final. BMAD real agents, cross-talk, score variance check. Works on ANY project. Usage: /kdh-code-review-full-auto [PR-url|commit-range|changed-files]'
---

# Universal Code Review + Auto-Fix Pipeline v4.1

## Input Selection

- PR URL (e.g. `https://github.com/org/repo/pull/123`): `gh pr diff 123`
- Commit range (e.g. `abc123..def456`): `git diff abc123..def456`
- Changed files (e.g. `src/auth.ts src/middleware.ts`): direct list
- No args: `git diff HEAD~1` (last commit)

---

## Phase 0: Project Auto-Scan + Diff Collection

### 0A: Project Auto-Scan

> **Step 0: Project Auto-Scan**: See [core/project-scan.md](../core/project-scan.md)

If `project-context.yaml` already exists and is < 1 hour old, skip re-scan (use cached).

### 0B: Diff Collection

```
1. Determine diff source from args:
   - PR URL → gh pr diff {number} --patch
   - Commit range → git diff {range} --stat --name-status
   - Changed files → git diff HEAD -- {files} --stat --name-status
   - No args → git diff HEAD~1 --stat --name-status

2. Collect changed file list with status:
   - A (added), M (modified), D (deleted), R (renamed)
   - Full file paths, relative to project root

3. Categorize changes:
   | Category | Glob Patterns |
   |----------|--------------|
   | server | **/server/**, **/api/**, **/routes/**, **/middleware/** |
   | frontend | **/*.tsx, **/*.jsx, **/*.vue, **/*.svelte, **/*.css, **/*.scss |
   | shared | **/shared/**, **/types/**, **/utils/** |
   | config | *.json, *.yaml, *.yml, *.toml, *.config.*, Dockerfile, .env* |
   | tests | **/*.test.*, **/*.spec.*, **/__tests__/** |
   | docs | **/*.md, **/docs/** |
   | migrations | **/migrations/**, **/drizzle/**, **/prisma/migrations/** |
   | engine | **/engine/**, **/agent-loop* |

4. Count lines changed per category:
   git diff {source} --stat -- {files_per_category} | tail -1

5. Save to review-report/diff-summary.md:
   - Total files: N
   - Total lines: +X / -Y
   - Per-category breakdown
   - File list with status markers
```

---

## Phase 1: Static Gate

Automated checks. No agents needed. Orchestrator runs directly.

```
1. TypeScript check (if tsc_enabled):
   - Run ALL tsc commands from project-context.yaml
   - Collect errors with file:line:col format
   - GATE: tsc MUST pass. Errors → BLOCKED (skip to Phase 8 with verdict=BLOCKED)

2. Linter check (if configured):
   - ESLint: npx eslint {changed_files} --format json
   - Biome: npx biome check {changed_files} --reporter json
   - Collect warnings and errors separately
   - WARN only (not blocking)

3. Secret scan:
   - grep -rn patterns in changed files:
     - /[A-Za-z0-9_-]{20,}/ adjacent to KEY|SECRET|TOKEN|PASSWORD|API_KEY
     - /sk-[a-zA-Z0-9]{20,}/ (OpenAI keys)
     - /ghp_[a-zA-Z0-9]{36}/ (GitHub PAT)
     - /AKIA[0-9A-Z]{16}/ (AWS access key)
     - Hardcoded .env values (process.env.X replaced with literal)
   - CRITICAL if found → force risk_level = CRITICAL

4. Debug artifact scan:
   - grep -rn in changed NON-TEST files:
     - console.log (not console.error/warn/info)
     - debugger
     - // @ts-ignore without explanation comment
     - // @ts-expect-error without explanation comment
     - // eslint-disable without explanation comment
   - WARN with exact locations

5. TODO/FIXME/HACK scan:
   - grep -rn "TODO|FIXME|HACK|XXX|TEMP" in changed files
   - Differentiate: NEW markers (in diff +lines) vs EXISTING (in context)
   - WARN for new markers only

6. Dependency audit (if lockfile changed):
   - Report: critical/high/moderate/low counts
   - CRITICAL/HIGH vulns → force risk_level = HIGH minimum

7. Output: review-report/static-gate.md
   - tsc: PASS/FAIL (with error list if FAIL)
   - lint: N warnings, M errors
   - secrets: PASS/FOUND (with file:line if found)
   - debug: N artifacts found (locations)
   - todos: N new markers
   - audit: critical/high/moderate/low counts
   - GATE RESULT: PASS / BLOCKED
```

> **ECC Enhancement — verification-loop + security-review**: Phase 1 static checks are supplemented by the `verification-loop` 6-phase deterministic verification (Build→Type→Lint→Test→Security→Diff) and the `security-review` skill's 46+ vulnerability patterns (OWASP Top 10). See [core/ecc-integration.md §2.1](../core/ecc-integration.md#21-static-gate--verification-loop--security-review).

---

## Phase 2: Visual/E2E Verification

**Condition**: Run ONLY if changed files include UI files:
- `**/*.tsx`, `**/*.jsx`, `**/*.vue`, `**/*.svelte`
- `**/*.css`, `**/*.scss`, `**/*.less`
- `**/*.html` (in src/ or app/ directories)
- Route/page config files

If no UI files changed → skip with note in review-report, proceed to Phase 3.

```
1. Start dev server:
   - Command from project-context.yaml (dev_command)
   - 60s startup timeout
   - If timeout → WARN, skip E2E, continue to Phase 3

2. Identify changed pages:
   - git diff → filter UI files → map to routes

3. Screenshot ALL changed pages:
   - Playwright navigate to each route
   - Full-page screenshot → review-report/screenshots/{page-name}.png
   - 2min timeout per page → skip page with WARN

4. Full interaction E2E on each changed page:
   a. Every button: click → verify no crash + expected response
   b. Every input: type test data → verify value accepted + validation works
   c. Every form: fill all fields + submit → verify success/error states
   d. Every dropdown/select: open → verify options render → select → verify state
   e. CRUD operations (if applicable): create → read → update → delete
   f. Navigation links: click → verify route change + no 404

   g. **12-Dimension Scenario Sweep** (Grade A/B changed pages only):

      | # | Dimension | Check | Example |
      |---|-----------|-------|---------|
      | 1 | Happy Path | 정상 입력 → 기대 결과? | 유효한 이름으로 부서 생성 |
      | 2 | Error | 잘못된 입력 → 에러 표시? | 빈 이름, 특수문자, 중복 |
      | 3 | Edge | 경계값 정상 작동? | 1글자, 255글자, 0건 목록 |
      | 4 | Abuse | 악의적 입력 방어? | XSS, SQL injection |
      | 5 | Scale | 대량 데이터 성능? | 1000건 목록 |
      | 6 | Concurrent | 동시 요청 안전? | 같은 이름 동시 생성 |
      | 7 | Temporal | 시간 엣지? | 자정, 타임존, 만료 |
      | 8 | State | 상태 전이 올바른가? | 생성→수정→삭제→재생성 |
      | 9 | Integration | 다른 기능 연동? | 부서 삭제 시 소속 직원 |
      | 10 | Data | 데이터 무결성? | null, undefined, NaN |
      | 11 | Permission | 권한 올바른가? | 일반 유저 → admin API |
      | 12 | Environment | 환경별 차이? | 모바일, 다크모드 |

      Grade A: 12차원 전부. Grade B: 1-4, 8-11 (핵심 8개).

5. Console error collection:
   - Capture ALL browser console messages during E2E
   - Filter benign: React DevTools, HMR, favicon 404
   - Remaining errors → list with page context
   - Any unexpected error → WARN

6. Theme consistency check:
   - Verify design tokens match app shell (if design system exists)
   - Check for hardcoded colors outside design tokens

7. Router import check:
   - All lazy-loaded routes in changed files → verify they resolve
   - Dynamic imports → verify target file exists

8. Stop dev server

9. Output: review-report/visual-e2e.md
   - Screenshots: N pages captured
   - E2E: N interactions tested, M failures
   - Console errors: N found (list)
   - Theme: CONSISTENT / N violations
   - Router: PASS / N broken imports
```

> **ECC Enhancement — browser-qa + click-path-audit**: Phase 2 is enhanced by `browser-qa` 4-phase protocol (Smoke→Interaction→Visual Regression→Accessibility) and `click-path-audit` for Phantom Success detection (toast without DB write), Sequential Undo, and Dead Path patterns. State store mapping runs before interaction testing. See [core/ecc-integration.md §2.2](../core/ecc-integration.md#22-visual-e2e--browser-qa--click-path-audit).

---

## Phase 3: Risk Analysis

No agents needed. Orchestrator calculates directly from diff data.

```
1. Blast radius calculation:
   For each changed file:
   a. Count importers: grep -rl "from.*{filename}" --include="*.ts" --include="*.tsx" | wc -l
   b. Count importers of importers (depth 2)
   c. Total blast radius = unique files at depth 1 + depth 2

2. Critical path detection:
   | Path Pattern | Risk Factor |
   |-------------|-------------|
   | **/auth/** or **/auth.ts | CRITICAL — authentication |
   | **/middleware/** | CRITICAL — request pipeline |
   | **/engine/** or **/agent-loop** | CRITICAL — core engine |
   | **/migrations/** or **/schema** | CRITICAL — database schema |
   | **/shared/types** | HIGH — shared contracts |
   | **/sanitize** or **/validate** | CRITICAL — security boundary |
   | **/crypto** or **/credential** | CRITICAL — secrets handling |
   | **/routes/** or **/api/** | MEDIUM — API surface |
   | **/pages/** or **/views/** | MEDIUM — UI pages |
   | **/components/** | LOW-MEDIUM — reusable UI |
   | **/*.test.* or **/*.spec.* | LOW — test files |
   | **/*.md or **/docs/** | LOW — documentation |
   | *.config.* or *.json | LOW-MEDIUM — config |

3. Test coverage assessment:
   For each changed non-test file:
   - Check if corresponding test file exists
   - Check if test file was also modified (test updated with code)
   - Score: covered / partial / uncovered

4. Risk scoring:
   | Level | Condition |
   |-------|-----------|
   | LOW | All changes in: docs, tests, config-only (no logic) |
   | MEDIUM | Frontend pages, non-critical API routes, components |
   | HIGH | Shared types, auth adjacent, DB queries, multiple packages |
   | CRITICAL | Auth, middleware, engine, migrations, crypto, sanitizers |

   Escalation rules:
   - ANY CRITICAL file → risk_level = CRITICAL
   - Blast radius > 20 files → risk_level += 1 level
   - No test coverage for changed logic → risk_level += 1 level
   - Secret scan hit in Phase 1 → risk_level = CRITICAL (forced)

5. Output: review-report/risk-analysis.md
```

---

## Phase 4: 3-Critic Party Mode (CORE PHASE)

The heart of the review pipeline. Real BMAD agents perform structured review with cross-talk.

> **Party Mode Protocol**: See [core/party-mode.md](../core/party-mode.md)

> **Scoring**: See [core/scoring.md](../core/scoring.md)

### Team Configuration

```
TeamCreate("code-review-{timestamp}")

| Spawn Name | Persona File | Review Focus |
|-----------|-------------|--------------|
| winston (Writer/Review Lead) | _bmad/bmm/agents/architect.md | Architecture compliance, system design patterns, scalability concerns. |
| quinn (Critic 1: Functional) | _bmad/bmm/agents/qa.md | Test coverage, edge cases, error handling, API contract compliance, race conditions. |
| dev (Critic 2: Security+Code) | _bmad/bmm/agents/dev.md | OWASP top 10, injection, XSS, auth bypass, code quality, performance. |
| john (Critic 3: Product) | _bmad/bmm/agents/pm.md | Scope compliance, product alignment, unnecessary changes, user impact. |
```

### Evaluator Calibration Protocol

평가자(Critic) 에이전트는 기본적으로 관대합니다. 캘리브레이션 없이는 진짜 문제를 발견해도 "별거 아니다"로 넘깁니다.

**캘리브레이션 사이클** (파이프라인 첫 실행 후 1회, 이후 5회 실행마다 1회):

1. 오케스트레이터가 최근 party-log 파일들을 읽음
2. Critic이 PASS했지만 실제로 버그가 있었던 사례 식별 (예: "toast는 OK" 판정했지만 실제 API 호출 누락)
3. 해당 패턴을 Critic 스폰 프롬프트의 "Known False Passes" 섹션에 추가
4. 다음 리뷰에서 해당 패턴에 대한 Critic 판단 재확인

**Known False Passes 누적 위치**: `_qa-e2e/evaluator-calibration.md`

> Anthropic Labs: "Tuning a standalone evaluator to be skeptical turns out to be far more tractable than making a generator critical of its own work."

### Agent Spawn Template

```
You are {NAME} in team "{team_name}". Role: {Writer|Critic}.

## Your Persona
Read and fully embody: _bmad/bmm/agents/{file}.md
Load the persona file with the Read tool BEFORE doing anything else.

## Your Expertise
{expertise from team config above}

## Review Scope
Changed files: {file_list from Phase 0B}
Risk level: {risk_level from Phase 3}
Static gate results: {summary from Phase 1}
Visual/E2E results: {summary from Phase 2, if applicable}

## Scoring Rubric
Read: _bmad-output/planning-artifacts/critic-rubric.md
6 dimensions, 7/10 pass threshold, any dimension <3 = auto-fail.

## References
- project-context.yaml
- review-report/diff-summary.md
- review-report/risk-analysis.md
- Architecture doc (from project-context.yaml, if exists)
- Feature spec (from project-context.yaml, if exists)
```

PROHIBITION: Never spawn agents as `critic-a`, `critic-b`, `critic-c` or any generic name. Always use BMAD roster names.

### Grade Selection (risk-based)

| Risk Level | Review Grade | Min Cycles | Cross-talk | Devil's Advocate |
|-----------|-------------|------------|------------|-----------------|
| CRITICAL | A | 2 | Mandatory | Yes (Cycle 2) |
| HIGH | A | 2 | Mandatory | Yes (Cycle 2) |
| MEDIUM | B | 1 | Mandatory | No |
| LOW | C | 0 | No | No |

Grade C (LOW risk) = Writer Solo. winston reviews alone, no critics spawned.

### Party Mode Protocol

**Applies to Grade A and B reviews only.**

```
1. winston: Read ALL changed files with Read tool (not diff, full files for context)
   - For each file: read surrounding context (imports, exports, callers)
   - Cross-reference with architecture doc
   - Write review document: review-report/party-logs/review-winston.md

2. winston: SendMessage [Review Request] to quinn, dev, john BY REAL NAME

3. Critics (parallel): Each reads ALL changed files independently
   - quinn: focuses on functional correctness, test gaps, error paths
   - dev: focuses on security vectors, code quality, performance
   - john: focuses on product alignment, scope, user impact
   - Each writes: review-report/party-logs/review-{name}.md

4. Cross-talk round (MANDATORY for Grade A and B):
   - quinn <-> dev: "Is this a security issue or a test coverage gap? Both?"
   - dev <-> john: "Architecture concern or legitimate product need?"
   - john <-> quinn: "Scope creep or missing edge case?"
   Both update their party-logs with ## Cross-talk section

5. Critics: SendMessage [Feedback] to winston BY NAME

6. winston: Read ALL critic logs FROM FILE → categorize issues:
   - CRITICAL: must fix before merge (security, data loss, crash)
   - MAJOR: should fix (logic errors, missing validation, bad patterns)
   - MINOR: nice to fix (naming, style, optimization)
   - NIT: optional (formatting, preference)
   Write: review-report/party-logs/review-fixes.md

7. winston: SendMessage [Fixes Applied] to ALL critics BY NAME

8. Critics (parallel): Re-read review-fixes.md FROM FILE → verify
   - SendMessage [Verified] with updated score X/10

9. Score calculation:
   - Grade A: avg >= 8.0 required
   - Grade B: avg >= 7.5 required

10. Score Variance Check:
    - stdev < 0.5 → Orchestrator flags "Suspiciously High Agreement"
    - At least 1 critic MUST independently re-score

11. Minimum Cycle Check (MANDATORY):
    - Grade A: MINIMUM 2 full cycles. Cycle 2 = Devil's Advocate mode.
    - Grade B: MINIMUM 1 full cycle + cross-talk verified.

12. Orchestrator Step Completion Checklist (BLOCKING):
    Before accepting [Review Complete], Orchestrator MUST verify ALL:
    - [ ] review-report/party-logs/review-winston.md EXISTS
    - [ ] review-report/party-logs/review-quinn.md EXISTS
    - [ ] review-report/party-logs/review-dev.md EXISTS
    - [ ] review-report/party-logs/review-john.md EXISTS
    - [ ] review-report/party-logs/review-fixes.md EXISTS
    - [ ] Each critic log contains "## Cross-talk" section
    - [ ] Score stdev >= 0.5 (or re-score completed)
    - [ ] Grade A: 2nd cycle with Devil's Advocate completed
    - [ ] Grade A Devil's Advocate found >= 3 issues
    - [ ] All CRITICAL issues have resolution in fixes.md
    ANY item unchecked → REJECT [Review Complete], do NOT proceed
```

> **ECC Enhancement — santa-method + ai-regression-testing**: After 3-Critic party mode PASSES, `santa-method` runs 2 context-isolated reviewers independently. Both must PASS. Includes Phantom Success rubric criterion. The `ai-regression-testing` skill checks sandbox/production path consistency — the #1 AI regression pattern. MAX_ITERATIONS=2. See [core/ecc-integration.md §2.3](../core/ecc-integration.md#23-party-review--santa-method--ai-regression-testing).

### Party-log File Format

Each critic log MUST follow this structure:

```markdown
# Code Review — {critic_name}

## Reviewer
{name} ({role}) — {persona_file}

## Files Reviewed
- {file_path}: {status} (+X/-Y lines)

## Issues Found

### CRITICAL
1. [{file}:{line}] {description}
   Impact: {what breaks}
   Suggested fix: {concrete fix}

### MAJOR
...

### MINOR
...

### NIT
...

## Cross-talk
### Discussion with {peer_name}
- My concern: {what I raised}
- Their response: {what they said}
- Resolution: {agreed/disagreed/deferred}

## Score
{X}/10

## Rationale
{Why this score — reference rubric dimensions}
```

---

## Phase 5: Verdict

Orchestrator determines outcome based on Phase 4 scores + Phase 3 risk.

```
Verdict matrix:

| Verdict | Condition | Action |
|---------|-----------|--------|
| APPROVED | avg >= 8.0, zero CRITICAL, zero unresolved MAJOR | Proceed to Phase 8 (deploy) |
| APPROVED_WITH_NOTES | avg >= 7.5, zero CRITICAL, MAJOR issues have plan | Proceed to Phase 8, notes tracked |
| CHANGES_REQUESTED | avg >= 7.0, fixable issues found | Proceed to Phase 6 (auto-fix) |
| BLOCKED | avg < 7.0 OR any CRITICAL security issue unresolved | Stop. Manual intervention required. |

Additional BLOCKED conditions (override score):
- Phase 1 secret scan hit + not resolved
- Phase 2 crash on any page
- Auth/middleware logic error found by any critic
- Migration data loss risk identified

Output: review-report/verdict.md
```

If APPROVED or APPROVED_WITH_NOTES → skip to Phase 8.
If CHANGES_REQUESTED → proceed to Phase 6.
If BLOCKED → skip to Phase 8 with BLOCKED report.

---

## Phase 6: Auto-Fix (if CHANGES_REQUESTED)

### Team Configuration

```
TeamCreate("code-review-fixers-{timestamp}")

| Spawn Name | Persona File | Fix Role |
|-----------|-------------|----------|
| dev (Writer/Fixer) | _bmad/bmm/agents/dev.md | Implements minimal, targeted fixes |
| quinn (Verifier 1) | _bmad/bmm/agents/qa.md | Verifies fixes don't break tests |
| winston (Verifier 2) | _bmad/bmm/agents/architect.md | Verifies fixes maintain architecture |
```

### Smart File Limits

| Change Type | Max Files Per Fix | Example |
|------------|------------------|---------|
| Logic | 3 | Bug fix, validation, error handling |
| Style | 10 | CSS/theme/class changes |
| Text | 15 | Copy, labels, translations |
| Mixed | 5 | Logic + style combined |

If a fix requires more files than the limit → mark ESCALATED, skip to next issue.

### Safety Boundaries (NO auto-fix allowed)

```
NEVER auto-fix these — always ESCALATED:
- auth.ts, auth/*.ts — authentication logic
- middleware.ts, middleware/*.ts — request pipeline
- migrations/*.ts, schema.ts — database schema
- package.json, *lock* — dependency changes
- .env*, secrets*, credential* — secrets/config
- engine/agent-loop.ts — core engine
```

### Fix Protocol

```
For each issue from Phase 4 (CRITICAL first, then MAJOR):

1. dev reads the issue description + original file + surrounding context
2. dev applies MINIMAL fix (smallest change that resolves the issue)
3. tsc check after each fix (if tsc_enabled)
   - tsc fails → revert fix, try alternative approach
4. If UI fix → Playwright verify the affected page
5. Party mode lite:
   - dev sends [Fix Applied] to quinn + winston with diff
   - quinn: "Does this break any test? Edge case missed?"
   - winston: "Does this violate architecture? Introduce tech debt?"
   - Both APPROVE → fix accepted
   - Any REJECT → dev tries alternative (max 2 attempts total)
6. After 2 failed attempts → mark ESCALATED
7. Write fix summary to review-report/party-logs/fix-{issue-number}.md
```

### Escalation Protocol

```
ESCALATED issues are tracked persistently:

1. Write to review-report/ESCALATED.md:
   - Issue ID, description, risk level
   - Why auto-fix failed
   - Suggested manual fix approach
   - Files involved

2. ESCALATED.md survives across review cycles
   - New reviews append, never overwrite
   - Each entry timestamped
```

> **ECC Enhancement — build-error-resolver + refactor-cleaner**: The `build-error-resolver` agent is the primary fixer for build/tsc failures (minimal diffs, categorized errors). The `refactor-cleaner` agent runs after to remove dead code introduced during fixes. See [core/ecc-integration.md §2.4](../core/ecc-integration.md#24-auto-fix--build-error-resolver--refactor-cleaner).

---

## Phase 7: Re-Review (if Phase 6 applied fixes)

**This phase is NOT optional.** If Phase 6 changed any files, Phase 7 MUST run.

```
Same team from Phase 4 reviews ONLY the fixed files.

1. Orchestrator provides:
   - List of fixed files
   - Original issues that prompted fixes
   - Fix summaries from Phase 6 party-logs

2. winston reads all fixed files + fix summaries
   - Verify each fix addresses the original issue
   - Check for regression

3. Party mode (same protocol as Phase 4, abbreviated):
   - winston writes re-review: review-report/party-logs/re-review-winston.md
   - Critics review fixed files only (not full codebase)
   - Cross-talk focuses on: "Did this fix introduce new issues?"
   - Score must meet same threshold as Phase 4 grade

4. tsc MUST pass after all fixes

5. Possible outcomes:
   - All fixes verified → proceed to Phase 8
   - Some fixes rejected → mark those ESCALATED → proceed to Phase 8
   - Score below threshold → ONE more fix attempt → then ESCALATED
```

---

## Phase 8: Final Report + Deploy

### 8A: Generate Final Report

```
Output: review-report/final-verdict.md

Structure:
  # Code Review Final Report

  ## Summary
  - Date: {timestamp}
  - Input: {PR URL | commit range | files}
  - Files reviewed: {N}
  - Lines changed: +{X} / -{Y}

  ## Risk Assessment
  - Risk level: {LOW | MEDIUM | HIGH | CRITICAL}
  - Blast radius: {N} direct importers, {M} indirect
  - Critical paths: {list or "none"}

  ## Static Gate
  - tsc: {PASS/FAIL}
  - Lint: {N warnings, M errors}
  - Secrets: {PASS/FOUND}
  - Debug artifacts: {N}
  - New TODOs: {N}

  ## Visual/E2E (if applicable)
  - Pages tested: {N}
  - Interactions: {N tested, M failures}
  - Console errors: {N}
  - Theme consistency: {PASS/N violations}

  ## Review Scores
  - Grade: {A/B/C}
  - Cycles completed: {N}
  - winston (architecture): {X}/10
  - quinn (functional): {X}/10
  - dev (security+code): {X}/10
  - john (product): {X}/10
  - Average: {X.XX}/10
  - Score stdev: {X.XX}

  ## Issues
  | Severity | Found | Fixed | Escalated |
  |----------|-------|-------|-----------|
  | CRITICAL | {N} | {N} | {N} |
  | MAJOR | {N} | {N} | {N} |
  | MINOR | {N} | {N} | {N} |
  | NIT | {N} | {N} | {N} |

  ## Verdict
  {APPROVED | APPROVED_WITH_NOTES | CHANGES_REQUESTED | BLOCKED}

  ## ESCALATED Items (if any)
  {list from ESCALATED.md}

  ## Phase Timeline
  | Phase | Duration | Result |
  |-------|----------|--------|
  | 0: Scan+Diff | {Xs} | {N files, M categories} |
  | 1: Static | {Xs} | {PASS/BLOCKED} |
  | 2: Visual/E2E | {Xs} | {PASS/SKIP/N failures} |
  | 3: Risk | {Xs} | {risk_level} |
  | 4: Party | {Xm} | {avg score} |
  | 5: Verdict | {Xs} | {verdict} |
  | 6: Auto-Fix | {Xm} | {N fixed, M escalated} |
  | 7: Re-Review | {Xm} | {PASS/PARTIAL} |
  | 8: Final | {Xs} | {final verdict} |
  | Total | {Xm} | — |
```

### 8B: Deploy (if APPROVED or APPROVED_WITH_NOTES)

```
1. git add changed files (specific files, not -A)
2. git commit:
   - Message: "fix: code review auto-fixes — {N} issues resolved"
   - Include: list of fixed issues in commit body
3. git push
4. Wait for deploy: gh run list -L 1 --json status,conclusion
   - Poll every 15s, max 5min
5. Post-deploy smoke test (if smoke-test.sh exists)
6. Report to user:
   - Build #N
   - Changes deployed
   - Where to check
```

> **ECC Enhancement — continuous-learning**: On pipeline completion, `continuous-learning-v2` captures review patterns as project-scoped instincts. `/learn-eval` extracts findings (e.g., "this repo's auth routes need extra scrutiny"). See [core/ecc-integration.md §2.5](../core/ecc-integration.md#25-post-completion--continuous-learning).

### 8C: Cleanup

```
1. TeamDelete all teams created during review
2. Archive review-report/:
   - Copy to review-report/archive/{date}-{verdict}/
   - Keep current review-report/ for reference
3. Clean stale resources:
   - tmux panes from E2E
   - Dev server processes
   - Temporary files
```

### Output Directory Structure

```
review-report/
  diff-summary.md              # Phase 0B output
  static-gate.md               # Phase 1 output
  visual-e2e.md                # Phase 2 output (if UI)
  risk-analysis.md             # Phase 3 output
  party-logs/                  # Phase 4 output
    review-winston.md          # Review lead document
    review-quinn.md            # Functional critic log
    review-dev.md              # Security+code critic log
    review-john.md             # Product critic log
    review-fixes.md            # Fix summary from party mode
    re-review-winston.md       # Phase 7 re-review (if applicable)
    fix-{N}.md                 # Phase 6 individual fix logs
  verdict.md                   # Phase 5 output
  ESCALATED.md                 # Persistent escalation tracker
  final-verdict.md             # Phase 8 final report
  screenshots/                 # Phase 2 screenshots (if UI)
    {page-name}.png
  archive/                     # Historical reviews
    {date}-{verdict}/
```

---

## Anti-Patterns (production failures)

1. **Critic uses generic name** — BMAD real names mandatory. Each loads persona file as first action.
2. **Review without reading changed files** — winston MUST Read ALL changed files with Read tool. Diff alone is insufficient.
3. **Single-cycle rubber stamp** — Grade A requires MINIMUM 2 cycles. Cycle 2 uses Devil's Advocate mode.
4. **Score convergence** — stdev < 0.5 triggers independent re-score. Unanimous scores are suspicious.
5. **Cross-talk skipped** — `## Cross-talk` section REQUIRED in every critic log.
6. **Fix without verification** — Even auto-fixes need quinn + winston Party Mode Lite verification.
7. **Risk assessment skipped** — Phase 3 is mandatory even for "small" changes.
8. **Orchestrator skips checklist** — Phase 4 completion checklist is BLOCKING.
9. **ESCALATED items not tracked** — review-report/ESCALATED.md is persistent across reviews.
10. **Deploy before re-review** — Phase 7 is mandatory if Phase 6 applied ANY fixes.
11. **Auto-fix touches auth/migrations** — Safety boundaries are absolute. NEVER auto-fix.
12. **Writer calls Skill tool** — Writer MUST NEVER use Skill tool. Read files with Read tool.

Additional safeguards:
- TeamDelete fails → `rm -rf` team dirs → force cleanup
- Shutdown stall → 30s timeout → `tmux kill-pane` → force cleanup
- Dev server orphan → `lsof -i :{port}` → kill process on cleanup
- Context compaction → PostCompact hook auto-saves

---

## Timeouts

| Phase | Timeout | On Timeout |
|-------|---------|------------|
| Phase 0: Scan+Diff | 1min | Report partial, continue |
| Phase 1: Static Gate | 2min | Report partial results, continue |
| Phase 1: tsc specifically | 90s | WARN, mark tsc_enabled=false, continue |
| Phase 2: Dev server startup | 60s | WARN, skip E2E entirely |
| Phase 2: E2E per page | 2min | Skip page with WARN |
| Phase 2: Total Visual/E2E | 10min | Report what completed, continue |
| Phase 3: Risk Analysis | 1min | Default to risk_level=MEDIUM |
| Phase 4: Party Mode per round | 15min | Fallback to single-reviewer (winston solo) |
| Phase 4: Cross-talk per pair | 3min | Skip pair, note in log |
| Phase 4: Total Party Mode | 30min | Accept current scores as final |
| Phase 5: Verdict | 30s | Auto-calculate from available data |
| Phase 6: Auto-Fix per issue | 3min | Mark issue ESCALATED |
| Phase 6: Total Auto-Fix | 15min | ESCALATE remaining issues |
| Phase 7: Re-Review | 10min | Accept Phase 6 result as-is |
| Phase 8: Deploy wait | 5min | Report deploy status, don't block |
| Phase 8: Smoke test | 2min | WARN, don't block |
| **Total pipeline** | **45min** | Force Phase 8 with whatever data available |

Timeout hierarchy: Phase timeout > per-item timeout. If total pipeline hits 45min, immediately jump to Phase 8.

---

## Core Rules

1. **BMAD real names mandatory.** winston, quinn, dev, john. Each agent Reads their persona file as first action.
2. **Cross-talk mandatory.** Every Grade A/B review cycle. Each critic log MUST contain `## Cross-talk` section.
3. **Party-log files mandatory.** Written to review-report/party-logs/ as .md files. Messages alone are NOT sufficient.
4. **Score variance check.** stdev >= 0.5 required. Below threshold triggers independent re-score.
5. **Risk-based grading.** HIGH/CRITICAL = Grade A. MEDIUM = Grade B. LOW = Grade C (Writer Solo).
6. **tsc before verdict.** Must pass. tsc failure = BLOCKED verdict.
7. **Smart file limits on auto-fix.** Logic:3, Style:10, Text:15, Mixed:5.
8. **No auth/migration auto-fix.** Safety boundaries are absolute.
9. **ESCALATED tracking.** review-report/ESCALATED.md is persistent.
10. **Re-review after fix.** Phase 7 is NOT optional if Phase 6 changed files.
11. **All reads FROM FILE.** Use Read tool. Never rely on message memory.
12. **Phase 3 always runs.** Even for "trivial" changes.
13. **Orchestrator owns transitions.** Agents do NOT self-advance.
14. **Cleanup mandatory.** Phase 8C runs regardless of verdict.
15. **Output quality: specific and concrete.** File paths, line numbers, exact values.
16. **ECC enhancements are additive.** santa-method runs AFTER party mode PASS, not instead of it. verification-loop supplements Phase 1, not replaces it. BMAD takes precedence on any conflict.

---

## Pipeline Interconnection

### Triggered by UXUI Redesign Pipeline

When this pipeline is invoked as part of a UXUI redesign review:

```
Overrides:
  risk_level: HIGH (forced)
  phase_2_scope: ALL pages (not just changed pages)
  grade: A (forced — 2 cycles, Devil's Advocate)

Additional Phase 2 checks:
  1. Theme consistency across ALL pages
  2. WCAG AA baseline
  3. Responsive spot-check (375px, 768px, 1440px)

Output: review-report/uxui-redesign-addendum.md
```

### Triggered by Full-Auto Pipeline (Story Dev Phase F)

When Phase 4 protocol is used for story dev code review:

```
Integration:
  - Phase F of story dev uses THIS pipeline's Phase 4 party mode protocol
  - Story acceptance criteria added to review scope
  - john validates acceptance criteria satisfaction
  - quinn validates test coverage against story requirements

Differences from standalone:
  - Team already exists (reuse from story dev)
  - No separate Phase 0-3 (already done in story context)
  - Verdict feeds into Story Dev Completion Checklist
  - No auto-fix (story dev has its own fix cycle)
```

---

## Non-BMAD Fallback

When `bmad_enabled = false` (no `_bmad/` directory):

```
Phase 4 uses generic reviewer roles instead of BMAD personas:

| Spawn Name | Role | Focus |
|-----------|------|-------|
| lead-reviewer (Writer) | Review Lead | Architecture, system design |
| func-reviewer (Critic 1) | Functional | Tests, edge cases, error handling |
| sec-reviewer (Critic 2) | Security+Code | OWASP, code quality, performance |
| scope-reviewer (Critic 3) | Product | Scope, requirements, user impact |

Same party mode protocol applies (cross-talk, scoring, variance check).
No persona files loaded. Agents rely on role description only.
Scoring rubric: simplified 4-dimension rubric (correctness, security, quality, scope).
```

---

## Defense & Recovery

| Mechanism | Value | Action |
|-----------|-------|--------|
| phase_timeout | per-phase (see Timeouts) | Skip to next phase with partial data |
| party_timeout | 15min per round | Fallback to winston solo review |
| fix_attempts | 2 per issue | 3rd attempt = ESCALATED |
| critic_unresponsive | 3min no response | Ping → 2nd stall → exclude from round |
| dev_server_crash | during Phase 2 | Restart once → skip E2E on 2nd crash |
| tsc_loop | fix causes new tsc error | Max 3 tsc-fix cycles → ESCALATED |
| total_pipeline | 45min | Force Phase 8 report |
| team_cleanup_fail | TeamDelete errors | `rm -rf` team dirs → force cleanup |
| stale_screenshot | > 5min old | Retake → skip on 2nd failure |

### Recovery from interrupted review

```
If pipeline crashes/times out mid-review:
1. Check review-report/ for existing phase outputs
2. Resume from last incomplete phase
3. Reuse cached data (project-context.yaml, diff-summary.md, risk-analysis.md)
4. If Phase 4 party-logs exist → skip to verdict calculation
5. If no party-logs → restart Phase 4
```
