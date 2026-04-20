---
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

### Step 3: Confirm understanding (briefing)

Respond with this expanded briefing format:

```
SESSION LOADED: <local session file path>
PREVIOUS SESSION: <Previous field or "(없음)">
COMMITS SINCE SAVE (local): <list or "없음">
════════════════════════════════════════════════

📋 TRACKING FILES (from kdh-conductor/)
STATUS.md: <summary of current active projects P0/P1/P2>
DECISIONS.md: <last 3 entries tagged with timestamp>
MASTER-ROADMAP.md: <current sprint number + its progress>

════════════════════════════════════════════════

🖥️  REMOTE SERVER STATE (corthex-v3)
Server session: <path + topic + last-updated>
Server branch: <current branch + HEAD SHA>
Server tmux: <active command or "idle">
Server pipeline: <current sprint + story>

════════════════════════════════════════════════

🚨 DIVERGENCE ALERTS (if any)
- <alert 1 with recommended action>
- <alert 2>

If none: "Local and remote state consistent."

════════════════════════════════════════════════

PROJECT: <project name from session>

WHAT WE'RE BUILDING:
<2-3 sentence summary>

CURRENT STATE:
✅ Working: <count> items confirmed
🔄 In Progress: <files>
🗒️ Not Started: <stories — full list, no truncation>

EXECUTION ORDER:
1. <next> ← here
2. <then>
...

WHAT NOT TO RETRY:
<failed approaches + reasons>

ACTIVE PLANS:
<from _index.yaml status: active>

NEXT STEP:
<exact next step>

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

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
