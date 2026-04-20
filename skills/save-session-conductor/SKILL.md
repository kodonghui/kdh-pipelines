---
description: Save a kdh-conductor orchestration session. Extends /save-session with (1) local tracking file capture (STATUS.md / DECISIONS.md / MASTER-ROADMAP.md), (2) remote server state snapshot via SSH, (3) auto-commit + auto-push to kdh-conductor repo. Use this instead of /save-session when working in the kdh-conductor role.
---

# Save Session — Conductor Edition

This is the Conductor-specialized save-session. Use when the current role is
orchestration (kdh-conductor) rather than solo project work.

Extends base `/save-session` with:
1. Capture of local tracking files state
2. Snapshot of remote server state via SSH
3. Auto-commit and auto-push to kdh-conductor repo (so work persists across machines)

## When to Use

- End of a Conductor work session before closing Claude Code
- Before context-limit restart (save first, then resume-session-conductor in fresh session)
- After any major Conductor decision / plan change
- Periodic checkpoint if session is running long

## Usage

```
/save-session-conductor                     # saves with auto-generated topic
/save-session-conductor "phase 3 audit"     # saves with custom topic
```

## Process

### Step 1: Gather local context (same as base save-session)

- Read all files modified during this session (`git status`, `git diff`)
- Review conversation: what was discussed, attempted, decided
- Note errors + resolutions
- Check build/test status if relevant

### Step 2: Verify local tracking files are current

Before saving session, ensure these reflect this session's activity:

1. **`kdh-conductor/STATUS.md`** — must reflect current state as of NOW
2. **`kdh-conductor/DECISIONS.md`** — last entry timestamp within last 30 min? If session had decisions and DECISIONS.md is stale, CEO alerted: "DECISIONS.md last update > 30 min ago but session had decisions X, Y, Z. Update before saving session?"
3. **`kdh-conductor/MASTER-ROADMAP.md`** — if Sprint boundary crossed or plan changed, MASTER-ROADMAP.md updated?

If any gaps detected, WARN and pause for CEO confirmation. Do not silently save stale state.

### Step 3: Capture remote server snapshot

SSH to corthex-v3 and capture server state at THIS moment:

```bash
ssh -p 8000 -o BatchMode=yes -o ConnectTimeout=5 ubuntu@158.179.165.97 'cat << EOF_STATE
=== Server State Snapshot ===
Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Branch: $(cd ~/corthex-v3 && git branch --show-current)
HEAD: $(cd ~/corthex-v3 && git log -1 --format="%H %s")
Uncommitted: $(cd ~/corthex-v3 && git status --short | wc -l) files
Active tmux: $(tmux has-session -t claude 2>/dev/null && echo "claude session live" || echo "claude session dead")
Pipeline state: $(cat ~/corthex-v3/_bmad-output/pipeline-state.yaml 2>/dev/null | head -5)
Last update-log: $(ls -t ~/corthex-v3/_bmad-output/update-log/*.md 2>/dev/null | head -1)
EOF_STATE'
```

Include this snapshot verbatim in the session file's "Remote Server State" section.

If SSH fails: write "⚠️ Server unreachable at save time — local-only snapshot" and continue.

### Step 4: Write the session file

Path: `~/.claude/session-data/YYYY-MM-DD-<short-id>-session.tmp`

Use the base save-session format (all sections), PLUS add:

**New section: `Tracking Files Snapshot`**
```
## Tracking Files Snapshot (Conductor)

STATUS.md mtime: <timestamp>
STATUS.md active projects: <P0 / P1 / P2 summary>
DECISIONS.md last 5 entries: <list>
MASTER-ROADMAP.md current sprint: <N>, progress: <X%>
```

**New section: `Remote Server Snapshot`**
```
## Remote Server Snapshot (corthex-v3 @ save time)

<output of Step 3 SSH command>
```

### Step 4b: Write update log (base behavior + conductor extras)

`_bmad-output/update-log/YYYY-MM-DD.md` — append session summary.
Additional conductor-specific categories: Orchestration, Remote-Dispatch, Agent-Coordination.

### Step 4c: Sync tracking files to conductorA/

```bash
cp kdh-conductor/STATUS.md kdh-conductor/conductorA/STATUS.md
cp kdh-conductor/DECISIONS.md kdh-conductor/conductorA/DECISIONS.md
cp kdh-conductor/MASTER-ROADMAP.md kdh-conductor/conductorA/MASTER-ROADMAP.md
```

(conductorA is CEO's quick-access mirror. Always keep in sync.)

### Step 5: AUTO-COMMIT + AUTO-PUSH to kdh-conductor repo (CEO 지시 2026-04-20)

```bash
cd /mnt/c/Users/USER/Desktop/고동희/kdh-conductor

# Stage only the files conductor should commit — not auto-save files, not phase artifacts
git add STATUS.md DECISIONS.md MASTER-ROADMAP.md conductorA/ .claude/session-data/ 2>/dev/null

# Check if anything to commit
if git diff --cached --quiet; then
    echo "No changes to commit."
else
    # Build commit message
    COMMIT_MSG="chore: save-session-conductor $(date +%Y-%m-%d-%H%M) — $(echo \"$TOPIC\" | head -c 60)"
    git commit -m "$COMMIT_MSG" 2>&1 | tail -5
    git push origin main 2>&1 | tail -5
fi
```

CEO laptops (multiple) stay in sync via git push. Resume on any laptop → git pull → /resume-session-conductor.

If push fails (conflict / network): report error, do NOT force-push. Save session file locally; CEO handles manually.

### Step 6: Show summary to CEO

```
Session saved to <local path>
Tracking files synced to conductorA/
Remote snapshot captured (server: <branch>, tmux: <live/dead>)
Auto-push to kdh-conductor: <pushed / skipped / failed>

━━━ Sprint 현황 ━━━
Sprint <N>: <완료>/<전체>. 남은 것: <list>

━━━ 다음 세션 추천 시작점 ━━━
<next step from session file>

━━━ 서버 상태 ━━━
Branch: <name>, HEAD: <shortSHA>, Tmux: <live/dead>

Accurate? Anything to correct?
```

Wait for CEO confirmation.

---

## Token Cost Note

Conductor save adds ~5-10k tokens vs base save (SSH + tracking-file reads + commit ops).
Accepted by CEO (DECISIONS.md [14:30], [14:45]).

---

## Relationship to Base Skill

- `/save-session` — base skill. Saves local only, no push, no server snapshot.
- `/save-session-conductor` — this skill. Full Conductor workflow with remote snapshot + auto-push.
- Server Claude uses `/save-session` (base), not this one.

---

## Edge Cases

**Uncommitted changes in kdh-conductor repo**: git add only the tracking files. Don't auto-commit arbitrary changes. User must manually commit other files.

**Merge conflict on git push**: Abort push, report conflict, leave session file locally. CEO resolves.

**Not in kdh-conductor working directory**: Refuse. "save-session-conductor must run from kdh-conductor/ dir. Use /save-session for other projects."

**Push requires auth that fails**: Session still saved locally. Warn CEO to verify SSH keys or PAT.

**No network for SSH snapshot**: Proceed without remote snapshot. Mark section as "(unavailable)".

---

## Installation

Via kdh-pipelines install.sh or manual symlink from `kdh-pipelines/skills/save-session-conductor/` to `~/.claude/skills/save-session-conductor/`.
