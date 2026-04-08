# E2E Gate Protocol — Story-Level Browser Verification

Version: 1.0
Author: KDH Pipeline Team
Date: 2026-03-26

## Purpose

파이프라인의 `dev-story` 완료 후, 코드 리뷰만으로는 잡을 수 없는 **"UI는 성공인데 실제 동작 안 하는"** 버그를 감지한다.

핵심 원칙: **toast가 떴다고 끝이 아니다. DB에 들어갔는지 확인한다.**

---

## When to Run

```
Pipeline Step Order:
  create-story → dev-story → simplify → TEA → QA → code-review → cross-check → smoke-test → [E2E-GATE] → commit
```

- Grade: **B** (important, 2 retries, 1 cycle + cross-talk)
- Trigger: smoke-test PASS 이후
- Timeout: 5 min per story
- Skip condition: Story가 서버 로직만 변경 (페이지 .tsx 수정 없음)

---

## Step 1: Identify Changed Pages

```bash
# git diff에서 수정된 .tsx 페이지 파일 추출
CHANGED_PAGES=$(git diff --name-only HEAD~1 HEAD | grep -E 'packages/(app|admin)/src/pages/.*\.tsx$' | sed 's|packages/||;s|/src/pages/||;s|\.tsx$||')

# 예시 결과:
# admin/onboarding
# app/agents
# app/departments
```

각 변경된 페이지에 대해 Step 2~5 실행.

변경된 페이지가 없으면 (서버/shared만 수정):
- toast-without-api 린트만 실행 (Step 4)
- Playwright 테스트 스킵

---

## Step 2: Load Test Cases

`_qa-e2e/e2e-test-cases-complete.md`에서 해당 페이지의 TC를 추출한다.

```
예: admin/onboarding 변경 시
→ TC-ONBOARD-001 ~ TC-ONBOARD-021 (21개 TC)

우선순위 필터:
1. CRUD TC (Create/Edit/Delete) — 필수 실행
2. Form validation TC — 필수 실행
3. Navigation TC — 선택 (시간 여유 시)
4. Visual TC — 스킵 (별도 E2E 사이클에서)
```

---

## Step 3: Playwright Browser Verification

### 3.1 Login

```
Admin 테스트: 
  browser_navigate → preset e2e.dev_admin_url/login
  browser_fill_form → preset e2e.admin_login 참조
  browser_click → 세션 시작

App 테스트:
  browser_navigate → preset e2e.dev_app_url/login
  browser_fill_form → ceo / {password}
  browser_click → INITIALIZE COMMAND
```

### 3.2 CRUD Verification Pattern

모든 Create TC에 대해:

```
1. Navigate to page
2. Click create button
3. Fill form with test data
4. Submit
5. **CRITICAL**: Verify via API that data exists in DB
   - curl GET /api/{endpoint} → response includes created item
   - NOT just checking toast/UI (the onboarding bug pattern)
6. If API returns empty → FAIL

Test data naming convention:
  - Name: "E2E-{story-id}-{timestamp}"
  - 나중에 cleanup 용이
```

### 3.3 DB Verification Queries

```typescript
// After UI create action, verify via direct API call:
const created = await fetch(`${BASE}/admin/{resource}?companyId=${CID}`, {
  headers: { Authorization: `Bearer ${token}` }
})
const data = await created.json()
const found = data.data?.find(item => item.name.includes('E2E-'))

if (!found) {
  // GATE FAIL: UI showed success but DB has nothing
  report.addFailure({
    tc: 'TC-XXX-NNN',
    type: 'PHANTOM_SUCCESS',  // toast without DB write
    page: '/admin/xxx',
    action: 'create',
    expected: 'Item exists in DB after create',
    actual: 'API returns empty — toast was misleading'
  })
}
```

### 3.4 특수 패턴 감지

| Pattern | Detection | Example |
|---------|-----------|---------|
| Phantom Success | toast + no API call | 온보딩 부서 Add |
| Role Mismatch | Create user → login → 403 | CEO gets role:user |
| Schema Drift | Page loads → 500 | Missing column |
| Route Shadow | /resource/action → matches /:id | /sns/accounts |

**Phantom Success 감지 알고리즘:**
```
1. UI action (button click)
2. Check: success toast appeared?
3. If yes → API GET the resource
4. If API returns empty/unchanged → PHANTOM_SUCCESS detected
```

---

## Step 4: Static Lint Checks

변경된 파일에 대해 실행:

```bash
# Toast-Without-API lint
bash .claude/hooks/toast-without-api-check.sh

# Cross-check (hardcoded colors, icons, middleware)
bash .claude/hooks/cross-check.sh
```

---

## Step 5: Gate Judgment

### PASS Criteria (ALL must be true)

```
1. All CRUD TCs: API confirms DB write ✓
2. toast-without-api lint: 0 violations ✓
3. cross-check: 0 violations ✓
4. No 500 errors on changed pages ✓
5. No console errors on changed pages ✓
```

### FAIL Actions

```
GATE FAIL → Story rejected:
  1. Write failure report to _qa-e2e/e2e-gate-failures/{story-id}.md
  2. List exact TCs that failed with evidence
  3. Set story status = "e2e-gate-failed"
  4. Return to dev-story for fix
  5. Max 2 retries → after 2 fails, ESCALATE to human

Failure report format:
  ## E2E Gate Failure: {story-id}
  Date: {timestamp}
  Changed pages: {list}
  
  ### Failed TCs:
  | TC | Type | Expected | Actual |
  |....|......|..........|........|
  
  ### Root Cause Hint:
  - PHANTOM_SUCCESS → check if onClick has api.post/mutate
  - SCHEMA_DRIFT → check if migration ran
  - ROLE_MISMATCH → check auth role mapping
```

---

## Step 6: Cleanup

```
성공 시:
  - E2E 테스트 데이터 삭제 (E2E- prefix 항목)
  - 다음 단계 (commit) 진행

실패 시:
  - 테스트 데이터 유지 (디버깅용)
  - dev-story로 복귀
```

---

## Integration with Preset

`presets/{project}.yaml`에 E2E gate 설정 추가:

```yaml
e2e_gate:
  enabled: true
  admin_url: "preset e2e.dev_admin_url"
  app_url: "preset e2e.dev_app_url"
  api_url: "preset e2e.dev_api_url"
  admin_credentials: "preset e2e.admin_login 참조"
  app_credentials:
    username: "ceo"
    password: "{from-env}"
  test_cases_path: "_qa-e2e/e2e-test-cases-complete.md"
  lint_scripts:
    - ".claude/hooks/toast-without-api-check.sh"
    - ".claude/hooks/cross-check.sh"
  max_retries: 2
  timeout_seconds: 300
```

---

## Performance Budget

| Story Size | Changed Pages | TC Count | Est. Time |
|-----------|--------------|----------|-----------|
| Small (1 page) | 1 | 5-10 | 1-2 min |
| Medium (2-3 pages) | 2-3 | 15-30 | 2-3 min |
| Large (5+ pages) | 5+ | 40-60 | 4-5 min |
| Epic-wide | 10+ | — | Full E2E cycle instead |

---

## Relationship to Full E2E Cycle

```
E2E Gate (per-story)        Full E2E Cycle (periodic)
─────────────────────       ─────────────────────────
Scope: changed pages only   Scope: ALL 49 pages
When: every story commit    When: /loop 30m or manual
Depth: CRUD + lint          Depth: CRUD + visual + security + regression
Time: 1-5 min               Time: 15-25 min
Agents: 0 (orchestrator)    Agents: 4 parallel
Purpose: prevent regressions Purpose: find all bugs
```

E2E Gate는 "문 앞에서 잡는 경비원", Full E2E Cycle은 "건물 전체 순찰".
