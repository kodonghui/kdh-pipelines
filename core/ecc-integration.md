# ECC Integration Protocol — KDH Pipeline Suite v2.0

Version: 2.0
Date: 2026-03-26
ECC Version: 1.9.0

## Purpose

KDH 파이프라인 5개에 ECC v1.9.0의 agent/skill/command를 통합하여 품질을 높이는 프로토콜.
핵심: 코드 리뷰 + 적대적 검증 + 자동 학습 + **Phantom Success 방어**로 "toast만 띄우고 실제 동작 안 하는" 류의 버그 방지.

> **Core Rule**: ECC enhancements are ADDITIVE. They supplement existing BMAD agents, party mode, and scoring systems — never replace them. If ECC and BMAD conflict, BMAD takes precedence.

---

## 1. kdh-full-auto-pipeline v9.4

### 1.1 Planning Phase — search-first

**When**: Stage 1 Technical Research, before technical-overview step
**Skill**: `~/.claude/skills/search-first/SKILL.md`
**Workflow**: Need Analysis -> Parallel Search (npm/PyPI/GitHub) -> Evaluate -> Decide (Adopt/Extend/Build) -> Implement
**Integration**: dev(Writer) invokes the 5-step search-first workflow before writing any net-new code. Prevents reinventing existing solutions.
**Constraint**: Runs WITHIN the existing BMAD step structure, not as a separate step.

### 1.2 Story Dev — tdd-workflow + coding-standards

**When**: Phase B (Develop Story), Phase D (Test)
**Skills**:
- `~/.claude/skills/tdd-workflow/SKILL.md` — RED->GREEN->REFACTOR cycle, 80%+ coverage
- `~/.claude/skills/coding-standards/SKILL.md` — Immutability, error handling, input validation, no hardcoded secrets
**Integration**: dev(Writer) follows TDD cycle. quinn(Critic) enforces 80%+ coverage gate using tdd-guide agent checklist.
**Constraint**: Tests run with the project's `test_command` from project-context.yaml. TDD does not replace the BMAD DoD checklist.

**Phantom Success Prevention (Layer 1)**:
Writer prompt includes mandatory API Wiring Checklist:
- Every onClick/onSubmit with success feedback MUST have a preceding api.post/put/delete or mutation.mutate()
- addToast({ type: 'success' }) without API call = CRITICAL BUG
- Document for each CRUD handler: API endpoint -> server route -> DB table

### 1.3 Code Review — santa-method + security-review

**When**: After Phase F party mode PASSES
**Skills**:
- `~/.claude/skills/santa-method/SKILL.md` — 2-agent adversarial verification
- `~/.claude/skills/security-review/SKILL.md` — 46+ vulnerability checks, OWASP Top 10
**Architecture**:
1. Phase F party mode with BMAD agents (winston/quinn/dev/john) -> PASS
2. Santa Method spawns 2 context-isolated review agents
3. Both agents evaluate changed files against the code rubric independently
4. Both must PASS for the story to proceed
5. MAX_ITERATIONS: 2 (then ESCALATE to human)
**Cost**: ~40% increase on Phase F review time (2 additional agents)
**Constraint**: Santa method runs AFTER party mode, not instead of it. Party mode catches broad issues; santa catches bias-shared blind spots.

**Phantom Success Rubric Criterion**:
```
For every handler showing success feedback (toast, redirect, banner):
  PASS: Handler calls api.post/put/delete or mutation.mutate() BEFORE success UI
  FAIL: Handler shows success without any API call in the execution path
For every useMutation:
  PASS: mutationFn calls api.* with a real endpoint
  FAIL: mutationFn is missing, no-op, or endpoint doesn't exist in server routes
```

### 1.4 E2E Gate — click-path-audit + verification-loop

**When**: Between Phase F and commit (after Phase transitions step 2)
**Skills**:
- `~/.claude/skills/click-path-audit/SKILL.md` — State store mapping + handler chain tracing
- `~/.claude/skills/verification-loop/SKILL.md` — 6-phase deterministic gate

**click-path-audit integration**:
1. Map all state stores in changed pages (side-effect map) — MUST complete first
2. Trace every button handler's call chain through the side-effect map
3. Detect: Phantom Success (toast without API call), Sequential Undo (state set then reset), Dead Path (unreachable conditional), Stale Closure, useEffect Interference
4. Report findings with exact file:line references

**verification-loop integration** (pre-commit deterministic gate):
1. Build verification (bun run build / npm run build)
2. Type check (npx tsc --noEmit)
3. Lint check (eslint)
4. Test suite with 80%+ coverage
5. Security scan (grep for hardcoded secrets, console.log)
6. Diff review (what changed, blast radius)

**Constraint**: Does NOT replace core/e2e-gate.md protocol. Supplements it with deeper state-level analysis.

### 1.5 Post-Completion — continuous-learning

**When**: After story commit + push
**Skill**: `~/.claude/skills/continuous-learning-v2/SKILL.md`
**Command**: `/learn-eval`
**Integration**: Automatic via PostToolUse hooks. The continuous-learning-v2 observe hook captures session patterns as project-scoped instincts. The /learn-eval command extracts reusable knowledge for future pipelines.
**Cycle**: observe -> instinct -> dream (3h) -> evolve (12h) -> new skills

---

## 2. kdh-code-review-full-auto v4.1

### 2.1 Static Gate — verification-loop + security-review

**When**: Phase 1 Static Gate
**Skills**:
- `~/.claude/skills/verification-loop/SKILL.md` — extends Phase 1 with 6-phase deterministic verification
- `~/.claude/skills/security-review/SKILL.md` — supplements secret scan with 46+ vulnerability patterns (OWASP Top 10)
**Integration**: The existing Phase 1 checks (tsc, eslint, secret scan, debug artifacts) are supplemented by the full verification-loop and security-review checklists. verification-loop adds build verification and diff review; security-review extends the secret scan to cover injection, XSS, CSRF, auth bypass, and rate limiting.

### 2.2 Visual/E2E — browser-qa + click-path-audit

**When**: Phase 2 Visual/E2E Verification (UI changes only)
**Skills**:
- `~/.claude/skills/browser-qa/SKILL.md` — 4-phase protocol: Smoke Test -> Interaction Test -> Visual Regression -> Accessibility
- `~/.claude/skills/click-path-audit/SKILL.md` — Phantom Success detection via state store mapping
**Integration**:
- browser-qa structures Phase 2 testing with Core Web Vitals (LCP < 2.5s, CLS < 0.1)
- click-path-audit runs state store mapping BEFORE interaction testing
- Detects: Phantom Success, Sequential Undo, Dead Path patterns
- Phase 2 already does screenshots + interaction + console errors; browser-qa adds structured scoring and accessibility baseline checks on top

### 2.3 Party Review — santa-method + ai-regression-testing

**When**: After Phase 4 3-Critic party mode reaches PASS
**Skills**:
- `~/.claude/skills/santa-method/SKILL.md` — 2 context-isolated reviewers, both must PASS
- `~/.claude/skills/ai-regression-testing/SKILL.md` — sandbox/production path consistency check
**Integration**:
- Santa method catches issues that party mode's shared-context critics may miss
- ai-regression-testing specifically checks for the #1 AI regression pattern: production path has a field/feature, sandbox path doesn't
- MAX_ITERATIONS: 2, then ESCALATE
**Includes Phantom Success rubric criterion** (same as [Section 1.3](#13-code-review--santa-method--security-review))

### 2.4 Auto-Fix — build-error-resolver + refactor-cleaner

**When**: Phase 6 Auto-Fix (when CHANGES_REQUESTED verdict)
**Agents**:
- `~/.claude/agents/build-error-resolver.md` — Minimal-diff build/tsc error resolution
- `~/.claude/agents/refactor-cleaner.md` — Dead code cleanup after fixes
**Integration**: build-error-resolver is the primary fixer for build failures. It reads the error, applies the smallest possible change, and runs tsc to verify. refactor-cleaner runs after to remove any dead code introduced during fixes. Both respect the Phase 6 safety boundaries (no auth/migration auto-fix).

### 2.5 Post-Completion — continuous-learning

**When**: After Phase 8 Final Report
**Skill**: `~/.claude/skills/continuous-learning-v2/SKILL.md`
**Integration**: Automatic pattern extraction. Review findings become project-scoped instincts (e.g., "this repo's auth routes need extra scrutiny"). Bug patterns found in review are added to bug-patterns.yaml for injection into future Writer prompts.

---

## 3. kdh-playwright-e2e (tmux + vs shared)

### 3.1 E2E Agents — Socrates Methodology

Each BMAD E2E agent's prompt is supplemented with the corresponding ECC Socrates agent methodology. The BMAD persona defines personality and communication style; the ECC Socrates agent defines testing methodology.

| BMAD Agent | ECC Enhancement | Additional Methodology |
|------------|----------------|----------------------|
| quinn (Functional) | `socrates-functional` agent | Socrates QA: declare expected state BEFORE interaction, verify AFTER. **DB verification**: after every Create action, GET the resource list and verify the item exists. |
| sally (Visual) | `socrates-visual` agent + `design-system` skill (audit mode) | 10-dimension visual audit scoring. AI slop detection. |
| winston (Edge) | `socrates-edge` agent + `security-review` skill checklist | 46+ vulnerability patterns. OWASP Top 10. Console error = BUG. |
| bob (Regression) | `socrates-regression` agent + `click-path-audit` skill | State store mapping. Sequential Undo detection. Phantom Success detection via network request verification. |

**BMAD persona is always loaded FIRST.** ECC methodology is injected as a supplementary section in the agent spawn prompt. Example spawn order: (1) Read `_bmad/bmm/agents/qa.md`, (2) inject socrates-functional checklist, (3) begin testing.

**quinn DB Verification Protocol (Phantom Success Layer 5)**:
```
After every Create/Update/Delete action:
1. browser_network_requests() -> verify POST/PUT/DELETE was sent
2. If no network request -> BUG: PHANTOM_SUCCESS (immediate)
3. API GET the resource -> verify change persists in DB
4. If GET returns old state -> BUG: PHANTOM_SUCCESS_STALE
```

**tmux-specific note**: The staggered spawn (quinn 0s, winston +30s, bob +60s, sally +90s) prevents browser contention. ECC methodology injection does not change the spawn order or timing.

**VS-specific note**: Single-agent sequential mode. The Socrates methodology is embedded in the orchestrator's Phase 2 prompt directly (Step 2.4 in the VS pipeline). No separate agent spawns for ECC.

### 3.2 Fixer Agents — build-error-resolver + ai-regression-testing

**When**: Phase 4 Bug Fix (if bugs found)
**Agents**:
- `~/.claude/agents/build-error-resolver.md` — Specialized for tsc/build failures (minimal diffs)
- `~/.claude/skills/ai-regression-testing/SKILL.md` — Sandbox/production path check after every fix
- `~/.claude/skills/verification-loop/SKILL.md` — 6-phase verification after all fixers complete
**Integration**: After fixers complete (Step 4.3), verification-loop runs as the merge gate. ai-regression-testing checks that every fix in the fixer's changed files doesn't introduce a sandbox/production divergence. build-error-resolver handles tsc errors that fixers may introduce.

### 3.3 Post-Cycle — continuous-learning

**When**: After Phase 8 Report + Cleanup
**Skill**: `~/.claude/skills/continuous-learning-v2/SKILL.md`
**Command**: `/learn-eval` runs automatically
**Integration**: Captures E2E-specific patterns as project-scoped instincts (e.g., "page X consistently fails CRUD tests", "this API endpoint returns 500 under load"). These instincts are injected into future cycle agent prompts, making each cycle smarter than the last.

---

## 4. kdh-uxui-redesign v7.1

### 4.1 Design System Phase — design-system + design-principles + design-masters

**When**: Phase 2 Design System Generation (Step 2-1)
**Skills**:
- `~/.claude/skills/design-system/SKILL.md` — Generate mode + AI slop detection + 10-dimension visual audit
- `~/.claude/skills/design-principles/SKILL.md` — Timeless design rules (Rams, Muller-Brockmann)
- `~/.claude/skills/design-masters/SKILL.md` — Legendary designer pattern references
**Integration**: Advisory inputs to promax, not replacements. promax remains the single source of design decisions. design-system skill provides the 10-dimension scoring framework that party mode critics (sally/winston/quinn) use to evaluate the generated design system. design-principles and design-masters provide reference material for critics to cite during cross-talk.

### 4.2 Implementation Phase — coding-standards + tdd-workflow

**When**: Phase 4 Integration (Step 4-1 Page Rebuild)
**Skills**:
- `~/.claude/skills/coding-standards/SKILL.md` — TypeScript/React patterns (immutability, error handling)
- `~/.claude/skills/tdd-workflow/SKILL.md` — Component tests with RED->GREEN->REFACTOR
**Integration**: Rebuild agents follow coding-standards for all new component code. Component tests written using TDD cycle: write test expecting new design tokens -> rebuild component -> verify test passes. coding-standards enforces no hardcoded colors (aligns with the pipeline's zero-hardcoded-colors rule).

### 4.3 Verification Phase — click-path-audit + browser-qa

**When**: Phase 5 Verification (Step 5-2 E2E Functional)
**Skills**:
- `~/.claude/skills/click-path-audit/SKILL.md` — Map rebuilt pages' state stores, trace all handlers
- `~/.claude/skills/browser-qa/SKILL.md` — 4-phase browser testing protocol
**Integration**: click-path-audit maps state stores first (critical after a full page rebuild where handler wiring may break), then browser-qa structures the testing phases. The Phase 5-2 protocol already requires "every interactive element tested" — browser-qa adds structured scoring per interaction category.

### 4.4 Final Review — synthesis-master + libre commands

**When**: Phase 5 Verification (Step 5-3 Accessibility)
**Agent**: `~/.claude/agents/synthesis-master.md` — Coordinates all LibreUIUX plugins
**Commands**:
- `/libre-ui-critique` — Comprehensive design feedback
- `/libre-a11y-audit` — WCAG 2.1 AA accessibility audit
- `/libre-ui-responsive` — Responsive design check across breakpoints
**Integration**: synthesis-master coordinates but doesn't replace party mode critics (sally/winston/quinn). The party mode critics evaluate the design system holistically; synthesis-master provides plugin-specific deep dives (accessibility compliance, responsive breakpoint coverage, design critique).

---

## 5. Santa Method Integration Detail

### Concept

코드 리뷰 단계에서 2개 독립 에이전트가 **서로 모르는 상태로** 동일 코드를 리뷰.
둘 다 PASS해야 통과. 하나라도 FAIL이면 수정 필요.

### Execution Flow

```
1. Party mode (3 BMAD critics) completes with PASS
2. Orchestrator spawns 2 santa agents (context-isolated):
   - Santa-A: receives ONLY changed files + rubric (no party-log access)
   - Santa-B: receives ONLY changed files + rubric (no party-log access)
   - Neither knows the other exists
3. Both review independently and write to:
   - review-report/party-logs/santa-a.md
   - review-report/party-logs/santa-b.md
4. Orchestrator collects both verdicts:
   - Both PASS -> story proceeds
   - Either FAIL -> Writer fixes -> re-run santa (MAX_ITERATIONS: 2)
   - 2 failures -> ESCALATE to human
5. Santa agents are shut down immediately after verdict
```

### Evaluator Calibration

Santa 에이전트도 캘리브레이션이 필요합니다. Anthropic Labs의 실험에서 확인된 사실:
> "Out of the box, Claude is a poor QA agent. It identified legitimate issues, then talked itself into deciding they weren't a big deal and approved the work anyway."

**캘리브레이션 방법**:
1. Santa 리뷰 로그(`party-logs/santa-a.md`, `santa-b.md`)를 오케스트레이터가 사후 분석
2. PASS했지만 나중에 버그로 밝혀진 사례를 `_qa-e2e/evaluator-calibration.md`에 기록
3. 다음 Santa 실행 시 프롬프트에 "Known False Passes" 섹션 주입
4. 5회 실행마다 캘리브레이션 리뷰 (기존 false pass 목록이 여전히 유효한지 확인)

### Application Conditions

| Story Type | Review Configuration |
|-----------|---------------------|
| All Stories | 3-Critic BMAD party mode + santa-method (2 independent) |
| Grade A (critical) | + security-reviewer agent on both santa reviewers |
| UXUI Changes | + socrates-visual methodology on santa reviewers |
| Grade C (setup) | santa-method SKIPPED (Writer Solo, not worth the cost) |

### Cost Impact

| Phase | Before | After (santa) | Increase |
|-------|--------|---------------|----------|
| Code Review | 3 Critics | 3 Critics + 2 Santa | ~40% |
| Total Pipeline | 1x | ~1.3x | Acceptable for quality |

### Why Needed

온보딩 토스트 버그 = 3 Critics가 놓친 것. 같은 모델이 쓰고 같은 모델이 리뷰하면 같은 blind spot을 공유. Santa는 context-isolated (서로의 평가를 모름)이라 한쪽이 "toast OK" 해도 다른 쪽이 "DB 쓰기 없음" 잡을 확률 높음.

---

## 6. Phantom Success Defense Protocol

6겹 방어 체계로 "UX는 있는데 기능이 없는" 버그를 방지.

| Layer | Defense | Pipeline Phase | Mechanism |
|-------|---------|---------------|-----------|
| 0 | Sprint Contract | Phase A→B 전환 | dev↔quinn 사전 합의: 검증 가능한 완료 조건 + 제외 범위 |
| 1 | Generation Prevention | Writer Prompt (Phase B) | API Wiring Checklist: success UI <- API call 필수 |
| 2 | Static Lint | Pre-commit hook | toast-without-api-check.sh (blocking, exit 2) |
| 3 | Dynamic Verification | E2E Gate | CRUD -> API GET -> DB persistence 확인 |
| 4 | Adversarial Review | Code Review (Phase F) | Santa Method + Phantom Success rubric |
| 5 | Continuous Monitoring | 24/7 E2E Loop | quinn: network request 검증 + API GET 확인 |
| 6 | Learning Loop | Post-completion | bug-patterns.yaml -> agent prompt injection |

### How Each Layer Catches the Onboarding Toast Bug

The onboarding department creation bug (2026-03-26): user clicks "Add Department", fills name, submits. Toast says "Department created successfully!" but no API call was made. Department list remains empty.

1. **L1 (Generation)**: Writer forced to document "Add Dept -> POST /admin/departments -> departments table". If Writer cannot name the endpoint, the handler is flagged as incomplete before code review.
2. **L2 (Static Lint)**: `toast-without-api-check.sh` scans the handler function. Detects `addToast({type:'success'})` without `api.post` in the surrounding 20-line block. Blocks commit with exit code 2.
3. **L3 (Dynamic)**: Playwright clicks Add, fills name, submits -> `curl GET /admin/departments?companyId={id}` -> empty list -> GATE FAIL. The E2E gate catches it because DB state didn't change.
4. **L4 (Adversarial)**: Santa reviewer reads the onClick handler, checks against the Phantom Success rubric -> "success toast without API call in execution path" -> FAIL verdict.
5. **L5 (Monitoring)**: quinn clicks Add in 24/7 E2E loop -> `browser_network_requests()` -> no POST request in network log -> immediate BUG: PHANTOM_SUCCESS filed.
6. **L6 (Learning)**: Pattern `PHANTOM_SUCCESS_TOAST` added to `bug-patterns.yaml` -> injected into all future Writer prompts as a known anti-pattern to avoid.

### Detection Patterns (for Static Lint — Layer 2)

```
Pattern 1: Toast without mutation
  addToast({ type: 'success' }) AND NOT (api.post|api.put|api.delete|mutation.mutate) in scope

Pattern 2: Mutation without endpoint
  useMutation({ mutationFn: async () => { /* empty or no api call */ } })

Pattern 3: Optimistic update without server sync
  queryClient.setQueryData() AND NOT (await api.*) in same function
```

---

## 7. Auto-Learning Loop (All Pipelines)

```
Pipeline Execution
  -> continuous-learning-v2 observe hook (automatic, every tool call)
  -> Instinct generation (PreToolUse/PostToolUse observations)
  -> Pipeline complete -> /learn-eval (automatic pattern extraction)
  -> 3 hours -> /kdh-ecc-3h (dream + prune + lint)
  -> 12 hours -> /kdh-ecc-12h (evolve -> cluster instincts -> new skills)
  -> Next pipeline: evolved skills auto-applied
```

이것이 ECC의 **자기강화 사이클**. 파이프라인을 돌릴수록 Claude가 강해짐.

### Instinct Confidence Levels

| Confidence | Behavior | Example |
|-----------|----------|---------|
| 0.3-0.5 | Suggested only (low confidence) | "Consider checking for null before accessing .data" |
| 0.5-0.8 | Applied with notification | "Auto-adding tsc check before commit (observed 5 times)" |
| 0.8+ | Auto-applied silently | "Always validate companyId param on admin routes" |
| 0.8+ in 2+ projects | Auto-promoted to global scope | "Never auto-fix auth middleware files" |

### Pipeline-Specific Learning Targets

| Pipeline | What Gets Learned | Where Stored |
|----------|------------------|-------------|
| full-auto | Story patterns, code review findings, test strategies | Project instincts |
| code-review | Vulnerability patterns, common review issues per file | Bug-patterns.yaml |
| playwright-e2e | Page health trends, recurring bug locations, flaky tests | E2E instincts |
| uxui-redesign | Design token violations, rebuild patterns, a11y issues | Design instincts |

---

## 8. ECC Skill Quick Reference

All skills and agents referenced in this document, with their paths and the pipelines that use them.

| ECC Component | Type | Path | Used By |
|--------------|------|------|---------|
| search-first | Skill | `~/.claude/skills/search-first/SKILL.md` | full-auto (1.1) |
| tdd-workflow | Skill | `~/.claude/skills/tdd-workflow/SKILL.md` | full-auto (1.2), uxui (4.2) |
| coding-standards | Skill | `~/.claude/skills/coding-standards/SKILL.md` | full-auto (1.2), uxui (4.2) |
| santa-method | Skill | `~/.claude/skills/santa-method/SKILL.md` | full-auto (1.3), code-review (2.3) |
| security-review | Skill | `~/.claude/skills/security-review/SKILL.md` | full-auto (1.3), code-review (2.1), e2e (3.1) |
| click-path-audit | Skill | `~/.claude/skills/click-path-audit/SKILL.md` | full-auto (1.4), code-review (2.2), e2e (3.1), uxui (4.3) |
| verification-loop | Skill | `~/.claude/skills/verification-loop/SKILL.md` | full-auto (1.4), code-review (2.1), e2e (3.2) |
| continuous-learning-v2 | Skill | `~/.claude/skills/continuous-learning-v2/SKILL.md` | ALL pipelines |
| browser-qa | Skill | `~/.claude/skills/browser-qa/SKILL.md` | code-review (2.2), uxui (4.3) |
| ai-regression-testing | Skill | `~/.claude/skills/ai-regression-testing/SKILL.md` | code-review (2.3), e2e (3.2) |
| design-system | Skill | `~/.claude/skills/design-system/SKILL.md` | e2e (3.1), uxui (4.1) |
| design-principles | Skill | `~/.claude/skills/design-principles/SKILL.md` | uxui (4.1) |
| design-masters | Skill | `~/.claude/skills/design-masters/SKILL.md` | uxui (4.1) |
| build-error-resolver | Agent | `~/.claude/agents/build-error-resolver.md` | code-review (2.4), e2e (3.2) |
| refactor-cleaner | Agent | `~/.claude/agents/refactor-cleaner.md` | code-review (2.4) |
| synthesis-master | Agent | `~/.claude/agents/synthesis-master.md` | uxui (4.4) |
| socrates-functional | Agent | `~/.claude/agents/socrates-functional.md` | e2e (3.1) |
| socrates-visual | Agent | `~/.claude/agents/socrates-visual.md` | e2e (3.1) |
| socrates-edge | Agent | `~/.claude/agents/socrates-edge.md` | e2e (3.1) |
| socrates-regression | Agent | `~/.claude/agents/socrates-regression.md` | e2e (3.1) |
| /learn-eval | Command | N/A | ALL pipelines |
| /libre-ui-critique | Command | N/A | uxui (4.4) |
| /libre-a11y-audit | Command | N/A | uxui (4.4) |
| /libre-ui-responsive | Command | N/A | uxui (4.4) |
