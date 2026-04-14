---
description: Load the most recent session file from <project>/.claude/sessions/ (프로젝트 폴더 내부) and resume work with full context. 현재 cwd 기준으로 자동 스코프 — Conductor/Study/Work 세션이 절대 서로의 기록을 로드하지 않는다.
---

# Resume Session Command

Load the last saved session state and orient fully before doing any work.
This command is the counterpart to `/save-session`.

## When to Use

- Starting a new session to continue work from a previous day
- After starting a fresh session due to context limits
- When handing off a session file from another source (just provide the file path)
- Any time you have a session file and want Claude to fully absorb it before proceeding

## Usage

```
/resume-session                                                          # current project의 최신 세션 로드
/resume-session 2024-01-15                                               # current project에서 해당 날짜 최신
/resume-session <project>/.claude/sessions/2024-01-15-abc123de-session.tmp  # 정확한 경로로 로드
```

## Process

### Step 0: Determine session root (프로젝트 로컬)

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SESSIONS_DIR="$ROOT/.claude/sessions"
```

- 프로젝트 루트 = git toplevel, 없으면 현재 cwd
- 이후 모든 검색은 `$SESSIONS_DIR` 안에서만 수행한다.

### Step 1: Find the session file

If no argument provided:

1. Check `$SESSIONS_DIR`
2. Pick the most recently modified `*-session.tmp` file **in that folder only**
3. If the folder does not exist or has no matching files, tell the user:
   ```
   이 프로젝트($ROOT)에는 저장된 세션이 없습니다.
   경로: $SESSIONS_DIR
   다른 프로젝트 세션을 로드하려면 전체 경로를 명시하세요.
   이번이 첫 세션이면 작업 끝에 /save-session 으로 저장하면 됩니다.
   ```
   Then stop. **절대 다른 프로젝트 폴더나 `~/.claude/session-data/`로 fallback하지 않는다.**

If an argument is provided:

- 날짜(`YYYY-MM-DD`) 형식이면 `$SESSIONS_DIR`에서 해당 날짜 파일 검색 (레거시 `YYYY-MM-DD-session.tmp` + 현재 `YYYY-MM-DD-<shortid>-session.tmp` 둘 다)
- 파일 경로면 그대로 읽기 (명시적이면 신뢰, 단 프로젝트 루트가 다르면 Step 경고에서 안내)
- 없으면 명확히 보고하고 정지

### Step 2: Read the entire session file

Read the complete file. Do not summarize yet.

### Step 2.5: Cross-verify with live state

세션 파일을 읽은 후, 반드시 다음을 교차 검증한다:

1. **pipeline-state.yaml 읽기** — 현재 Sprint, 완료/미완료 스토리 확인
2. **epics-and-stories.md에서 현재 Sprint 스토리 목록 확인** — 세션 파일에 누락된 스토리가 있는지 대조
3. **세션 파일에 없는 스토리가 발견되면** → ⚠️ 표시하고 보고에 포함
4. **_index.yaml 읽기** — status: active인 plan 목록 확인

5. **git log 교차 검증** — 세션 파일 수정 시각 이후의 커밋 확인:
   - 세션 파일의 mtime을 기준으로 `git log --oneline --since="<mtime>"` 실행
   - 세션 파일에 없는 커밋이 있으면 → 브리핑에 "세션 이후 N건 커밋 발생" + 커밋 목록 표시
   - 병렬 세션(tmux)이 작업한 내용을 누락하지 않기 위함
   - 0건이면 "없음" 표시

이 단계는 세션 파일의 정보가 오래되었거나 불완전한 경우를 방지한다.
세션 파일과 live state가 충돌하면, live state를 신뢰한다.

### Step 3: Confirm understanding

Respond with a structured briefing in this exact format:

```
SESSION LOADED: [actual resolved path to the file]
PREVIOUS SESSION: [Previous 필드 값 또는 "(없음 — 옛 형식 파일)"]
COMMITS SINCE SAVE: [N건 커밋 목록 또는 "없음"]
════════════════════════════════════════════════

PROJECT: [project name / topic from file]

WHAT WE'RE BUILDING:
[2-3 sentence summary in your own words]

CURRENT STATE:
✅ Working: [count] items confirmed
🔄 In Progress: [list files that are in progress]
🗒️ Not Started (Sprint {N} 잔여):
  - Story X-Y: [제목]
  - Story X-Z: [제목]
  [축약 금지. 전부 나열. pipeline-state.yaml + epics-and-stories.md 교차 확인 결과.]
  [세션 파일에 없었으나 live state에서 발견된 스토리는 ⚠️ 표시]

EXECUTION ORDER (CEO 결정 기준):
  1. [다음 할 것] ← 여기부터
  2. [그 다음]
  3. ...
  [세션 파일의 "Exact Next Step" + "Decisions Made" + "Sprint & Pipeline Snapshot"의
   실행 순서를 합쳐서 표시. CEO가 순서를 바꾼 것이 있으면 명시.]

WHAT NOT TO RETRY:
[list every failed approach with its reason — this is critical]

OPEN QUESTIONS / BLOCKERS:
[list any blockers or unanswered questions]

ACTIVE PLANS:
[_index.yaml에서 status: active인 plan 목록. 없으면 "없음"]

NEXT STEP:
[exact next step if defined in the file]
[if not defined: "No next step defined — recommend reviewing 'What Has NOT Been Tried Yet' together before starting"]

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

### Step 4: Wait for the user

Do NOT start working automatically. Do NOT touch any files. Wait for the user to say what to do next.

If the next step is clearly defined in the session file and the user says "continue" or "yes" or similar — proceed with that exact next step.

If no next step is defined — ask the user where to start, and optionally suggest an approach from the "What Has NOT Been Tried Yet" section.

---

## Edge Cases

**Multiple sessions for the same date** (`2024-01-15-session.tmp`, `2024-01-15-abc123de-session.tmp`):
Load the most recently modified matching file for that date, regardless of whether it uses the legacy no-id format or the current short-id format.

**Session file references files that no longer exist:**
Note this during the briefing — "⚠️ `path/to/file.ts` referenced in session but not found on disk."

**Session file is from more than 7 days ago:**
Note the gap — "⚠️ This session is from N days ago (threshold: 7 days). Things may have changed." — then proceed normally.

**User provides a file path directly (e.g., forwarded from a teammate):**
Read it and follow the same briefing process — the format is the same regardless of source.

**Session file is empty or malformed:**
Report: "Session file found but appears empty or unreadable. You may need to create a new one with /save-session."

**Session file has no `Previous:` field (pre-v2.1 files):**
Display "(없음 — 옛 형식 파일)" in the PREVIOUS SESSION line. Do not treat as an error.

**No git repository in working directory:**
Skip git log cross-verification. Display "COMMITS SINCE SAVE: (git repo 아님 — 생략)" in briefing.

**Zero commits since session save:**
Display "COMMITS SINCE SAVE: 없음" — this is the normal case for single-session workflows.

**프로젝트 루트 불일치 (명시 경로 로드 시):**
사장님이 전체 경로를 주었는데 파일의 소속 프로젝트 루트가 현재 `$ROOT`와 다르면, 로드는 진행하되 브리핑 상단에 경고:
"⚠️ 이 세션 파일은 `<file-project>` 기록입니다. 현재 cwd는 `$ROOT`. 의도한 게 맞는지 확인하세요."

**레거시 파일 (`~/.claude/session-data/` 홈 직속):**
프로젝트 로컬 도입 이전 파일들은 홈에 남아 있을 수 있다. 기본 `/resume-session`은 이들을 무시한다. 필요하면 전체 경로로 명시 로드하거나, 해당 프로젝트 폴더의 `.claude/sessions/`로 수동 이동.

---

## Example Output

```
SESSION LOADED: /Users/you/.claude/session-data/2024-01-15-abc123de-session.tmp
PREVIOUS SESSION: /Users/you/.claude/session-data/2024-01-14-setup-session.tmp
COMMITS SINCE SAVE: 없음
════════════════════════════════════════════════

PROJECT: my-app — JWT Authentication

WHAT WE'RE BUILDING:
User authentication with JWT tokens stored in httpOnly cookies.
Register and login endpoints are partially done. Route protection
via middleware hasn't been started yet.

CURRENT STATE:
✅ Working: 3 items (register endpoint, JWT generation, password hashing)
🔄 In Progress: app/api/auth/login/route.ts (token works, cookie not set yet)
🗒️ Not Started: middleware.ts, app/login/page.tsx

WHAT NOT TO RETRY:
❌ Next-Auth — conflicts with custom Prisma adapter, threw adapter error on every request
❌ localStorage for JWT — causes SSR hydration mismatch, incompatible with Next.js

OPEN QUESTIONS / BLOCKERS:
- Does cookies().set() work inside a Route Handler or only Server Actions?

NEXT STEP:
In app/api/auth/login/route.ts — set the JWT as an httpOnly cookie using
cookies().set('token', jwt, { httpOnly: true, secure: true, sameSite: 'strict' })
then test with Postman for a Set-Cookie header in the response.

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

---

## Notes

- Never modify the session file when loading it — it's a read-only historical record
- The briefing format is fixed — do not skip sections even if they are empty
- "What Not To Retry" must always be shown, even if it just says "None" — it's too important to miss
- After resuming, the user may want to run `/save-session` again at the end of the new session to create a new dated file
- 세션 기록은 `<project>/.claude/sessions/`에 프로젝트 로컬로 저장된다. cwd가 자동 스코프이므로 Conductor/Study/Work가 서로의 기록을 건드릴 수 없고, 프로젝트 폴더를 다른 컴퓨터로 옮기면 세션도 함께 이동한다.
