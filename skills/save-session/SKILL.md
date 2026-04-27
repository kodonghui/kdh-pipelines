---
name: save-session
description: "Base session save와 update log 작성."
---

# Save Session Command

Capture everything that happened in this session — what was built, what worked, what failed, what's left — and write it to a dated file so the next session can pick up exactly where this one left off.

## When to Use

- End of a work session before closing Claude Code
- Before hitting context limits (run this first, then start a fresh session)
- After solving a complex problem you want to remember
- Any time you need to hand off context to a future session

## Process

### Step 1: Gather context

Before writing the file, collect:

- Read all files modified during this session (use git diff or recall from conversation)
- Review what was discussed, attempted, and decided
- Note any errors encountered and how they were resolved (or not)
- Check current test/build status if relevant

### Step 2: Create the sessions folder if it doesn't exist

Create the canonical sessions folder in the user's Claude home directory:

```bash
mkdir -p ~/.claude/session-data
```

### Step 3: Write the session file

Create `~/.claude/session-data/YYYY-MM-DD-<short-id>-session.tmp`, using today's actual date and a short-id that satisfies the rules enforced by `SESSION_FILENAME_REGEX` in `session-manager.js`:

- Compatibility characters: letters `a-z` / `A-Z`, digits `0-9`, hyphens `-`, underscores `_`
- Compatibility minimum length: 1 character
- Recommended style for new files: lowercase letters, digits, and hyphens with 8+ characters to avoid collisions

Valid examples: `abc123de`, `a1b2c3d4`, `frontend-worktree-1`, `ChezMoi_2`
Avoid for new files: `A`, `test_id1`, `ABC123de`

Full valid filename example: `2024-01-15-abc123de-session.tmp`

The legacy filename `YYYY-MM-DD-session.tmp` is still valid, but new session files should prefer the short-id form to avoid same-day collisions.

**Previous 필드 작성 규칙:**
1. `~/.claude/session-data/`에서 현재 저장 중인 파일을 제외하고 가장 최근 수정 파일 선택
2. 같은 날짜 파일이 여러 개면 가장 최근 것
3. 파일을 찾을 수 없으면 `(첫 세션)`
4. 파일이 존재하지만 경로가 불확실하면 `(경로 불명)`

### Step 4: Populate the file with all sections below

Write every section honestly. Do not skip sections — write "Nothing yet" or "N/A" if a section genuinely has no content. An incomplete file is worse than an honest empty section.

### Step 4b: Write update log

After saving the session file, also update the daily update log:

1. Check if `_bmad-output/update-log/YYYY-MM-DD.md` exists (use today's date)
2. If not, create it with header: `# Update Log — YYYY-MM-DD`
3. Append a new section with the current session's activities:

```markdown
## Session: [time] — [1-line topic]

### Changes
- [category]: [what changed]
- [category]: [what changed]

### Decisions
- [decision made]

### Next
- [what's next]
```

Categories: Features, Bug Fixes, Infrastructure, Planning, Pipeline, Memory, Discussion

This mirrors what `/kdh-ecc-3h` Phase 6 does, but runs at session save time so no work is lost between maintenance cycles.

### Step 4c: Sprint Snapshot 교차 검증

Sprint & Pipeline Snapshot 섹션 작성 후, source of truth와 대조한다.
Source of truth = `pipeline-state.yaml` (스토리 status) + `epics-and-stories.md` (스토리 ID/제목).

1. `pipeline-state.yaml` 읽기 → 현재 Sprint 스토리 목록 + status 추출
2. `epics-and-stories.md`에서 해당 Sprint 스토리 ID + 제목 확인
3. 세션 파일의 Sprint & Pipeline Snapshot 섹션과 대조:
   - 빠진 스토리 없는지
   - status(complete/backlog/in-progress)가 일치하는지
   - 스토리 수가 맞는지
4. 불일치 발견 시:
   - **자동 수정하지 않는다**
   - CEO에게 경고: "Sprint Snapshot과 pipeline-state.yaml 불일치 N건: [구체 내역]"
   - CEO 확인 후 수정
5. 불일치 0건이면 그대로 진행

### Step 5: Show the file + Sprint Summary to the user

After writing, display the full contents AND a sprint summary footer:

```
Session saved to [actual resolved path to the session file]

━━━ Sprint 잔여 현황 ━━━
Sprint {N}: {완료}/{전체} 완료. 남은 것: {Story ID: 제목} 전부 나열 (축약 금지)

━━━ 다음 세션 추천 시작점 ━━━
1. {다음 할 스토리/작업} (이유 한 줄)
2. {그 다음}
3. ...

Does this look accurate? Anything to correct or add before we close?
```

Wait for confirmation. Make edits if requested.

---

## Session File Format

```markdown
# Session: YYYY-MM-DD

**Started:** [approximate time if known]
**Last Updated:** [current time]
**Project:** [project name or path]
**Topic:** [one-line summary of what this session was about]
**Previous:** [이전 세션 파일 경로 또는 "(첫 세션)"]

---

## What We Are Building

[1-3 paragraphs describing the feature, bug fix, or task. Include enough
context that someone with zero memory of this session can understand the goal.
Include: what it does, why it's needed, how it fits into the larger system.]

---

## What WORKED (with evidence)

[List only things that are confirmed working. For each item include WHY you
know it works — test passed, ran in browser, Postman returned 200, etc.
Without evidence, move it to "Not Tried Yet" instead.]

- **[thing that works]** — confirmed by: [specific evidence]
- **[thing that works]** — confirmed by: [specific evidence]

If nothing is confirmed working yet: "Nothing confirmed working yet — all approaches still in progress or untested."

---

## What Did NOT Work (and why)

[This is the most important section. List every approach tried that failed.
For each failure write the EXACT reason so the next session doesn't retry it.
Be specific: "threw X error because Y" is useful. "didn't work" is not.]

- **[approach tried]** — failed because: [exact reason / error message]
- **[approach tried]** — failed because: [exact reason / error message]

If nothing failed: "No failed approaches yet."

---

## What Has NOT Been Tried Yet

[기술적으로 아직 시도하지 않은 접근법만 기재.
구현 대안, 디버깅 가설, 검증 실험 등 "다음에 뭘 시도할지" 판단용.
Sprint 스토리 순서/백로그는 Sprint & Pipeline Snapshot에서 담당 — 여기에 중복 기재 금지.
Be specific enough that the next session knows exactly what to try.]

- [approach / idea]
- [approach / idea]

If nothing is queued: "No untried approaches — next work is defined in Sprint Snapshot."

---

## Current State of Files

[Every file touched this session. Be precise about what state each file is in.]

| File              | Status         | Notes                      |
| ----------------- | -------------- | -------------------------- |
| `path/to/file.ts` | ✅ Complete    | [what it does]             |
| `path/to/file.ts` | 🔄 In Progress | [what's done, what's left] |
| `path/to/file.ts` | ❌ Broken      | [what's wrong]             |
| `path/to/file.ts` | 🗒️ Not Started | [planned but not touched]  |

If no files were touched: "No files modified this session."

---

## Sprint & Pipeline Snapshot

[pipeline-state.yaml (source of truth) + epics-and-stories.md에서 자동 추출. 수작업 금지.
이 섹션의 목적: 다음 세션이 "남은 스토리가 뭔지" 즉시 파악하는 것.
"나머지 N개" 같은 축약 절대 금지. 스토리 ID + 제목 전부 나열.
Step 4c에서 pipeline-state.yaml과 교차 검증됨.]

현재 Sprint: Sprint {N}
Sprint 전체 스토리 ({완료}/{전체}):
  ✅ Story X-1: [제목]
  ✅ Story X-2: [제목]
  🗒️ Story X-3: [제목]
  🗒️ Story X-4: [제목]
  ... [전부 나열. 하나도 빠뜨리지 않는다.]

실행 순서 (CEO 결정 반영):
  1. Story X-1 ✅
  2. Story X-2 ✅
  3. Story X-3 ← 다음
  4. [특별 삽입 작업 있으면 여기에: 예) "Agent SDK Migration (CEO 결정: X-3 다음, X-4 전에)"]
  5. Story X-4
  ... [CEO가 순서를 바꿨으면 그 이유도 기재]

파이프라인 상태:
- hook version: {v4.x}
- 강제 사항: [party mode, codex 등 현재 적용 중인 것]
- 활성 plan: [_index.yaml에서 status: active 목록. 없으면 "없음"]

다음 Sprint 미리보기 (해당 시):
- Sprint {N+1}: [스토리 목록 간략히]

---

## Decisions Made

[Architecture choices, tradeoffs accepted, approaches chosen and why.
These prevent the next session from relitigating settled decisions.
★ 순서가 있는 결정은 반드시 전후 관계를 포함한다.
"A를 B 다음에, C 전에 한다" 같은 순서 정보가 핵심.]

- **[decision]** — reason: [why] | order: [X 다음, Y 전에] (순서 관련 시)

If no significant decisions: "No major decisions made this session."

---

## Context (맥락)

[이 세션의 배경과 흐름을 이해하는 데 필요한 맥락.
다음 세션에서 "왜 이런 상태인지" 이해할 수 있도록 충분히 상세하게.
단순 사실 나열이 아니라, 의사결정의 흐름과 이유를 포함.]

- **프로젝트 전체 맥락:** [어떤 프로젝트의 어느 단계인지]
- **이 세션의 맥락:** [어떤 작업을 하다가 어떤 문제가 발생했고, 어떤 결정을 했는지]
- **파이프라인/프로세스 맥락:** [어떤 파이프라인을 돌리고 있는지, 어떤 버전인지, 어떤 규칙이 적용 중인지]
- **CEO 지시사항:** [이번 세션에서 CEO가 내린 결정이나 피드백. 순서 변경·우선순위 지정 포함.]
- **감정/분위기 맥락:** [CEO가 화났는지, 급한지, 신중한지 — 다음 세션 톤 설정에 중요]
- **잔여 작업 전체 목록:** [Sprint 내 아직 안 한 스토리 전부. 축약 금지. Sprint & Pipeline Snapshot과 일관되게.]

If this is a fresh project with no prior context: "First session — no prior context."

---

## Blockers & Open Questions

[Anything unresolved that the next session needs to address or investigate.
Questions that came up but weren't answered. External dependencies waiting on.]

- [blocker / open question]

If none: "No active blockers."

---

## Exact Next Step

[If known: The single most important thing to do when resuming. Be precise
enough that resuming requires zero thinking about where to start.]

[If not known: "Next step not determined — review 'What Has NOT Been Tried Yet'
and 'Blockers' sections to decide on direction before starting."]

---

## Environment & Setup Notes

[Only fill this if relevant — commands needed to run the project, env vars
required, services that need to be running, etc. Skip if standard setup.]

[If none: omit this section entirely.]
```

---

## Example Output

```markdown
# Session: 2024-01-15

**Started:** ~2pm
**Last Updated:** 5:30pm
**Project:** my-app
**Topic:** Building JWT authentication with httpOnly cookies

---

## What We Are Building

User authentication system for the Next.js app. Users register with email/password,
receive a JWT stored in an httpOnly cookie (not localStorage), and protected routes
check for a valid token via middleware. The goal is session persistence across browser
refreshes without exposing the token to JavaScript.

---

## What WORKED (with evidence)

- **`/api/auth/register` endpoint** — confirmed by: Postman POST returns 200 with user
  object, row visible in Supabase dashboard, bcrypt hash stored correctly
- **JWT generation in `lib/auth.ts`** — confirmed by: unit test passes
  (`npm test -- auth.test.ts`), decoded token at jwt.io shows correct payload
- **Password hashing** — confirmed by: `bcrypt.compare()` returns true in test

---

## What Did NOT Work (and why)

- **Next-Auth library** — failed because: conflicts with our custom Prisma adapter,
  threw "Cannot use adapter with credentials provider in this configuration" on every
  request. Not worth debugging — too opinionated for our setup.
- **Storing JWT in localStorage** — failed because: SSR renders happen before
  localStorage is available, caused React hydration mismatch error on every page load.
  This approach is fundamentally incompatible with Next.js SSR.

---

## What Has NOT Been Tried Yet

- Store JWT as httpOnly cookie in the login route response (most likely solution)
- Use `cookies()` from `next/headers` to read token in server components
- Write middleware.ts to protect routes by checking cookie existence

---

## Current State of Files

| File                             | Status         | Notes                                           |
| -------------------------------- | -------------- | ----------------------------------------------- |
| `app/api/auth/register/route.ts` | ✅ Complete    | Works, tested                                   |
| `app/api/auth/login/route.ts`    | 🔄 In Progress | Token generates but not setting cookie yet      |
| `lib/auth.ts`                    | ✅ Complete    | JWT helpers, all tested                         |
| `middleware.ts`                  | 🗒️ Not Started | Route protection, needs cookie read logic first |
| `app/login/page.tsx`             | 🗒️ Not Started | UI not started                                  |

---

## Decisions Made

- **httpOnly cookie over localStorage** — reason: prevents XSS token theft, works with SSR
- **Custom auth over Next-Auth** — reason: Next-Auth conflicts with our Prisma setup, not worth the fight

---

## Blockers & Open Questions

- Does `cookies().set()` work inside a Route Handler or only in Server Actions? Need to verify.

---

## Exact Next Step

In `app/api/auth/login/route.ts`, after generating the JWT, set it as an httpOnly
cookie using `cookies().set('token', jwt, { httpOnly: true, secure: true, sameSite: 'strict' })`.
Then test with Postman — the response should include a `Set-Cookie` header.
```

---

## Notes

- Each session gets its own file — never append to a previous session's file
- The "What Did NOT Work" section is the most critical — future sessions will blindly retry failed approaches without it
- If the user asks to save mid-session (not just at the end), save what's known so far and mark in-progress items clearly
- The file is meant to be read by Claude at the start of the next session via `/resume-session`
- Use the canonical global session store: `~/.claude/session-data/`
- Prefer the short-id filename form (`YYYY-MM-DD-<short-id>-session.tmp`) for any new session file
