---
name: resume-session-conductor
description: Resume a kdh-conductor orchestration session. Extends /resume-session with (1) persistent tracking files load (STATUS.md / DECISIONS.md / MASTER-ROADMAP.md), (2) remote server session+artifact SSH load, (3) local-vs-remote divergence detection. Use this instead of /resume-session when working in the kdh-conductor role (orchestrating corthex-v3 server).
---

# Resume Session — Conductor Edition

This is the Conductor-specialized resume-session. Use when the current role is
orchestration (kdh-conductor) rather than solo project work.

It extends the base `/resume-session` with three additional load steps:
1. Persistent tracking files (STATUS / DECISIONS / MASTER-ROADMAP)
2. Remote server session + artifacts via SSH
3. Local-vs-remote state divergence detection

## When to Use

- Starting a Conductor session in `kdh-conductor/` working directory
- After context-limit restart while orchestrating server Claude
- When you need the FULL picture — your own session + server Claude's session
- Whenever plan drift or state divergence is suspected

## Usage

```
/resume-session-conductor                           # loads most recent session + all tracking + remote
/resume-session-conductor 2026-04-20                # loads that date's session + all tracking + remote
/resume-session-conductor <path-to-session-file>    # specific file + all tracking + remote
```

## Process

### Step 1: Find the session file (same as base)

If no argument: latest `~/.claude/session-data/*-session.tmp`.
If date argument: search for matching files.
If path argument: read directly.

### Step 2: Read the entire session file

Read complete file. No summarization yet.

### Step 2.3: Load persistent tracking files (MANDATORY, LOCAL)

**Before anything else**, load the 3 tracking files from `kdh-conductor/` root:

1. **`kdh-conductor/STATUS.md`** — current status snapshot. Truth of "where are we right now".
2. **`kdh-conductor/DECISIONS.md`** — decision ledger. Read **last 20 entries** (most recent). Truth of "why we decided what we decided".
3. **`kdh-conductor/MASTER-ROADMAP.md`** — single source plan. Truth of "what we will do next".

If any file missing: warn "STATUS.md / DECISIONS.md / MASTER-ROADMAP.md missing — N of 3 not found. Session context incomplete."

### Step 2.5: Cross-verify with LOCAL live state

1. **`_bmad-output/pipeline-state.yaml`** — current Sprint, stories, status.
2. **`_bmad-output/phase-*/planning-artifacts/epics-and-stories.md`** — Sprint scope.
3. **`_bmad-output/kdh-plans/_index.yaml`** — active plans.
4. **git log cross-check:** `git log --oneline --since="<session-file-mtime>"`. Missing commits get ⚠️ flag.
5. **BRANCH DIVERGENCE DETECTION (CRITICAL — Phase 3 오보 재발 방지):**

   Run: `for b in $(git branch -r | grep -v HEAD | grep -v "origin/main"); do count=$(git rev-list origin/main..$b --count 2>/dev/null); [ "$count" -gt 0 ] && echo "$b: $count commits ahead of main"; done`

   ANY remote branch with commits ahead of main → **MUST** include in briefing.
   Especially watch `refactor/*`, `feat/*`, `sprint-*`, `ui-rebuild` patterns — these indicate unmerged feature work.

   Failing to report an ahead-of-main branch = phantom audit (Phase 3 정오 사건, 2026-04-20 DECISIONS.md [14:15]).

### Step 2.7: Load REMOTE server session + artifacts (MANDATORY for Conductor)

SSH to corthex-v3 server and pull remote state:

1. **Detect role**: confirm this is Conductor mode (working dir matches `.*kdh-conductor.*` OR CLAUDE.md contains "Conductor" keyword). If not Conductor, skip this step.

2. **Server reachability check**: `ssh -p 8000 -o BatchMode=yes -o ConnectTimeout=5 ubuntu@158.179.165.97 "echo ok"`. If fails, log "⚠️ 서버 SSH unreachable" and proceed with local-only briefing.

3. **Server latest session file**:
   ```
   ssh -p 8000 ubuntu@158.179.165.97 'ls -t ~/.claude/session-data/*.tmp 2>/dev/null | head -1'
   ssh -p 8000 ubuntu@158.179.165.97 'cat <path>'
   ```
   Read full content.

4. **Server tracking files** (if they exist):
   ```
   ssh -p 8000 ubuntu@158.179.165.97 'for f in ~/corthex-v3/STATUS.md ~/corthex-v3/DECISIONS.md ~/corthex-v3/MASTER-ROADMAP.md; do [ -f "$f" ] && echo "=== $f ===" && cat "$f"; done'
   ```

5. **Server update-log last 3 days**:
   ```
   ssh -p 8000 ubuntu@158.179.165.97 'ls -t ~/corthex-v3/_bmad-output/update-log/*.md 2>/dev/null | head -3 | xargs -I{} sh -c "echo === {} === && cat {}"'
   ```

6. **Server pipeline-state.yaml**:
   ```
   ssh -p 8000 ubuntu@158.179.165.97 'cat ~/corthex-v3/_bmad-output/pipeline-state.yaml'
   ```

7. **Server _index.yaml (active plans)**:
   ```
   ssh -p 8000 ubuntu@158.179.165.97 'cat ~/corthex-v3/_bmad-output/kdh-plans/_index.yaml'
   ```

8. **Server tmux capture** (what's currently running):
   ```
   ssh -p 8000 ubuntu@158.179.165.97 'tmux capture-pane -t claude -p -S -50 2>/dev/null || echo "tmux session not active"'
   ```

9. **Server git status**:
   ```
   ssh -p 8000 ubuntu@158.179.165.97 'cd ~/corthex-v3 && git status --short && git log --oneline -5 && git branch -a'
   ```

### Step 2.9: Divergence Detection

Compare local vs remote state. Flag any of these:

- **Branch divergence**: server git has commits local doesn't know about (or vice versa)
- **Pipeline-state divergence**: local pipeline-state.yaml says Sprint X, server says Sprint Y
- **Unmerged feature branch**: any remote branch ahead of main (especially refactor/app-ui-rebuild)
- **Stale session**: local session > 12 hours old while server actively working (tmux active)
- **Active server task**: server tmux shows active command but no corresponding local record

Build a "🚨 divergence alerts" subsection in the briefing if ANY detected.

### Step 3: Confirm understanding (briefing — CEO 친화 한국어 형식)

Respond with this briefing format. **목표: 비개발자 CEO 가 한 번 읽고 현재 상태 + 결정 사항 + 다음 행동 직관 파악.**

원칙:
- 영어 헤더 → 한국어 + emoji 1 개씩 (식별용)
- 기술 용어 등장 시 즉시 풀이 (예: "commit (변경 단위 한 묶음)")
- SHA 해시 = 첫 8 자 + 한국어 의미 (예: "Topic 5 잠김 무결 9417e9ef")
- 비유 사용 권장: 회사 / 직원 / 명함 / 잠김 / 도장
- CEO 결정 항목 = 별 섹션으로 강조
- "현재 → 다음" 축 (kdh-report §2 1번 철학)
- 응답 최대 80 줄 (사장님 한 화면에 들어오게)

```
═══════════════════════════════════════════════
📌 지금 어디까지 왔나
═══════════════════════════════════════════════

[프로젝트] <kdh-conductor — 한 줄 요약>

[방금 끝낸 일] (직전 세션 마무리 작업, 기술 용어 풀이 동반)
- <항목 1, 한국어 평문>
- <항목 2>

[회사 직원 (스킬) 명부] (skill-maturity.yaml R-NOV-02 기준)
정상 N명 / 보류 N명 / 신입 N명 / 별칭 N명 = 총 N

═══════════════════════════════════════════════
🛠️ 진행 중인 작업 (호출 시 즉시 재개 가능)
═══════════════════════════════════════════════

1. <작업 이름> (P0 / P1 / P2)
   현재 = <한 줄>
   대기 = <CEO 결재 / 외부 의존 / 시간>
   다음 가능 = <한 줄>

2. ...

[잠김 (도장 찍은) 작업]
- Topic 5 ... (sha 9417e9ef 무결 보존)
- Topic 3 ... (sha 5bd487ef 무결 보존)

═══════════════════════════════════════════════
🖥️ 서버 (corthex-v3, 원격) 상태
═══════════════════════════════════════════════

브랜치 = <name>
마지막 commit = <한국어 풀이>
서버 터미널 (tmux) = <멈춤 / 실행 중>
실행 중인 일 = <없음 / 한 줄 설명>

═══════════════════════════════════════════════
⚠️ 충돌 / 주의사항
═══════════════════════════════════════════════

[로컬 ↔ 서버 일치 여부]
- 일치 시 = "충돌 X"
- 불일치 시 = "<한국어 평문 + 권장 조치>"

[브랜치 별 상태]
- main 외 브랜치 중 main 보다 앞선 commit 있는 브랜치 list (있을 시만)

═══════════════════════════════════════════════
🚦 사장님이 지금 결정할 것
═══════════════════════════════════════════════

(있으면 1, 2, 3 으로 명시 + 보고서 path. 없으면 "결정 대기 사항 X.")
1. <결재 대기 항목 1>
2. <결재 대기 항목 2>

═══════════════════════════════════════════════
📞 사장님 답변 예시
═══════════════════════════════════════════════

"<예시 명령 1>" — <한 줄 효과>
"<예시 명령 2>" — <한 줄 효과>
"<예시 명령 3>" — <한 줄 효과>
"오늘 그만" — /save-session-conductor 후 종료

═══════════════════════════════════════════════
다음 명령 대기.
═══════════════════════════════════════════════
```

**briefing 작성 시 자가 검증 (응답 직전):**
- [ ] 영어 헤더 0 개 (한국어 + emoji 만)
- [ ] 기술 용어 첫 등장 시 한국어 풀이 동반
- [ ] SHA 해시 풀길이 노출 0 (첫 8 자 + 의미 만)
- [ ] CEO 결정 항목 = 별 섹션 (🚦) 으로 분리 강조
- [ ] 응답 본문 80 줄 이하
- [ ] "박았다 / 봉인 / 직진" 표현 0 개 (메모리 룰 준수, 단 publish artifact 정식 인용 시 예외)
- [ ] 사장님 답변 예시 3~5 개 (선택지 형태)

### Step 4: Wait for user

Do NOT start work automatically. Wait for instruction.

---

## Token Cost Note

This skill costs 15-25k tokens on startup (SSH × 8-10 calls + file reads ~20 KB).
That cost is ACCEPTED by CEO (2026-04-20 DECISIONS.md [14:30]) because:
- Prevents Phase 3 style phantom reporting
- Auto-detects local-remote divergence
- Surfaces unmerged feature branches before plan commitments

Do not skip steps to save tokens. The cost is the price of reliable orchestration.

---

## Edge Cases

**SSH unreachable** (Oracle maintenance, network down): Log "⚠️ 서버 SSH unreachable at <timestamp>" and proceed with local-only briefing. Mark all remote sections as "(unavailable)".

**Tracking files missing**: Report which are missing. Proceed but with warning "This session cannot fully orient — recreate tracking files via CLAUDE.md protocol."

**Session file from >7 days ago**: Warn about staleness + run extra git log spanning the gap.

**Server working directory differs from expected**: Adapt SSH paths accordingly.

**tmux session not named "claude"**: Try common alternatives (claude-server, corthex, server).

---

## Relationship to Base Skill

- `/resume-session` — base skill (kdh-pipelines/skills/resume-session/). Reads local only.
- `/resume-session-conductor` — this skill. Extends with tracking files + remote SSH.
- Server Claude should use `/resume-session` (base), not this one (servers don't SSH to themselves).
- Conductor should use `/resume-session-conductor` exclusively.

---

## Installation

Via kdh-pipelines install.sh or manual symlink from `kdh-pipelines/skills/resume-session-conductor/` to `~/.claude/skills/resume-session-conductor/`.
