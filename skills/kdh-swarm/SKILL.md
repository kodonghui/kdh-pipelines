---
name: kdh-swarm
description: "Swarm auto-epic worker loop."
---

# kdh-swarm

Swarm execution has two supported modes:

- **Mode D: Swarm Auto-Epic** - bounded epic/story execution.
- **Mode O: Overnight Plan-Code Loop** - unattended plan -> coding -> verify cycles with heartbeat, Claude watchdog, deploy fallback, and final bug-fix closure.

## Mode O: Overnight Plan-Code Loop

Use when the CEO asks to keep working while away, especially "plan -> coding -> plan -> coding", "heartbeat", "Claude keep working", or "bug fix / deploy / browser-use sweep after coding".

### Default Queue

Unless the CEO gives another queue, consume work in this order:

1. Active UI migration work under `0421-claude-design-full-migration`.
2. The next active plan that directly unblocks the same UI/API/chat contract.
3. Final bug-fix closure with `$kdh-bug-fix-pipeline` and `$kdh-deploy-verify`.

Do not sweep every active plan by default. If the queue becomes unclear, write a handoff and stop instead of inventing a new epic.

### Preflight

Run before starting the loop:

```bash
cd /home/ubuntu/corthex-v3
git status --short
tmux list-sessions
tmux list-panes -t claude -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command} #{pane_current_path}'
test -f _bmad-output/kdh-plans/_index.yaml
test -f _browser-use-test/run_3provider_sweep.py
mkdir -p _bmad-output/heartbeat _bmad-output/bug-fix _bmad-output/deploy-verify
```

Rules:

- Preserve unrelated dirty files. In this repo, `.last-3h-run` and `.last-12h-run` are expected to be external heartbeat files; do not edit or revert them unless explicitly asked.
- Stop if a shared contract, DB migration, auth flow, or deploy secret is required but unclear.
- Stop if another active agent is editing the same files and the write set cannot be separated.

### Heartbeat

Every loop tick, append a single-line record:

```bash
printf '%s phase=%s task=%s verify=%s claude=%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "$PHASE" "$TASK_ID" "$VERIFY_STATUS" "$CLAUDE_STATUS" \
  >> /home/ubuntu/corthex-v3/_bmad-output/heartbeat/swarm-overnight.log
```

Heartbeat interval:

- Active coding or verification: every 10 minutes.
- Waiting on deploy, browser-use, or another agent: every 5 minutes.
- On blocker or exit: write one final `phase=stopped` or `phase=blocked` line with the blocker.

### Save-Session Cadence

Every 3 hours, send a save-session checkpoint through the same verified tmux-send path:

- If the target is the product Claude session in `/home/ubuntu/corthex-v3`, send `/save-session` and ask it to report the saved session path.
- If the target is a conductor session in `/home/ubuntu/kdh-conductor`, send `$save-session-conductor` and ask it to capture the remote snapshot, sync `conductorA/`, commit, and push conductor tracking files.
- Always send Enter separately, capture after send, and only send one recovery Enter if the text is still sitting in the prompt.
- Record the save checkpoint result in the heartbeat log with `phase=save-session`.

### Claude Watchdog

Target the main Claude session first:

```bash
tmux capture-pane -t claude:0.0 -p -S -120
```

Send reminders and save-session checkpoints with verified Enter behavior:

1. Capture pane before sending.
2. Send the message text.
3. Send `C-m` as a separate tmux command.
4. Wait briefly and capture again.
5. Only send one extra `C-m` if the capture still shows the typed text sitting at the prompt or no visible state change.

Example:

```bash
tmux capture-pane -t claude:0.0 -p -S -80 > /tmp/claude-before.txt
tmux send-keys -t claude:0.0 '작업 계속. kdh-swarm Overnight Mode 기준으로 다음 plan->coding 사이클 진행하고, 전송 여부를 capture-pane으로 확인해.'
tmux send-keys -t claude:0.0 C-m
sleep 3
tmux capture-pane -t claude:0.0 -p -S -80 > /tmp/claude-after.txt
if tail -20 /tmp/claude-after.txt | grep -q '작업 계속. kdh-swarm Overnight Mode'; then
  tmux send-keys -t claude:0.0 C-m
fi
```

3-hour save-session example:

```bash
tmux capture-pane -t claude:0.0 -p -S -80 > /tmp/claude-before-save.txt
tmux send-keys -t claude:0.0 '3시간 체크포인트. /save-session 실행하고 saved path와 현재 작업 상태를 보고해. Enter 전송 여부를 capture-pane으로 확인해.'
tmux send-keys -t claude:0.0 C-m
sleep 3
tmux capture-pane -t claude:0.0 -p -S -80 > /tmp/claude-after-save.txt
if tail -20 /tmp/claude-after-save.txt | grep -q '3시간 체크포인트'; then
  tmux send-keys -t claude:0.0 C-m
fi
```

Never spam blind `C-m C-m`. The second Enter is a recovery path only after capture evidence shows the prompt was not submitted.

### Plan -> Coding Cycle

Loop until the queue is empty or blocked:

1. **Plan** - read the active plan, current repo state, and relevant source files. Record the exact slice, write set, acceptance criteria, and rollback path.
2. **Code** - implement the smallest bounded slice. Preserve real API/auth/chat/SSE/routing contracts. Do not introduce mock-only UI.
3. **Verify** - run targeted tests for the touched surface, package typecheck when relevant, `git diff --check`, and browser evidence for UI changes.
4. **Commit** - commit only the completed slice. Avoid CI-burning docs/report-only pushes unless needed.
5. **Deploy decision** - if the work affects production, deploy or verify deployment.
6. **Next plan** - if verification is green, choose the next queue item. If evidence contradicts the plan, stop and re-plan.

### Deploy Fallback

Preferred path:

```bash
git push origin main
bash scripts/monitor-deploy.sh main
```

If GitHub Actions is blocked by billing, spending limits, or non-code infrastructure failure, do not keep rerunning CI. Switch to manual deploy:

```bash
cd /home/ubuntu/corthex-v3-deploy
git fetch origin main
git reset --hard origin/main
bash /home/ubuntu/corthex-v3/scripts/deploy.sh
systemctl status corthex-v3 --no-pager
curl -sf https://corthex-hq.com/api/health
```

Manual deploy rules:

- Use the repo deploy script as the source of truth.
- Confirm `.env` exists in `/home/ubuntu/corthex-v3-deploy` before deploy.
- If DB migration fails, stop immediately and write the blocker.
- Do not rollback automatically. Prepare the rollback command and ask CEO before running it.

### Final Bug-Fix Closure

After coding queue completion:

1. Invoke `$kdh-bug-fix-pipeline`.
2. Run production or local smoke depending on deploy availability.
3. Run 3-provider browser-use sweep:

```bash
cd /home/ubuntu/corthex-v3
source /home/ubuntu/browser-use-env/bin/activate
python3.11 _browser-use-test/run_3provider_sweep.py \
  --url https://corthex-hq.com/admin \
  --providers openai,gemini,claude
```

4. Run direct browser/Playwright checks for changed app/admin routes, including `/app/hub`, `/app/chat`, and mobile viewport when UI changed.
5. Convert findings to EARS/BARS bug specs under `_bmad-output/bug-fix/`.
6. Write a Batch Fix Plan, fix BARS 5/4 first, then independent BARS 3/2 batches.
7. Re-verify each fixed bug with targeted tests and browser evidence.

### Stop Conditions

Stop and write a handoff if any of these happen:

- The next task requires a product decision not present in the plan.
- Backend, DB, Neon, auth, or shared token changes are needed outside the chosen slice.
- Tests become flaky in a way that cannot be reproduced or isolated.
- CI/deploy is blocked and manual deploy also fails.
- The browser-use provider credentials or Claude MCP session are unavailable.

## Mode D: Swarm Auto-Epic

Usage: `/kdh-dev-pipeline swarm epic-9`

```
Step 0: Project Auto-Scan → load project-context.yaml
Step 1: Read sprint status → find all stories in epic → analyze dependencies
Step 2: TaskCreate for each story (status=pending, blockedBy=dependencies)
Step 3: Spawn 3 story teams (Git Worktrees, self-organizing):
  - Each team: dev, winston, quinn, john
  - Each follows Phase A→F flow
Step 4: Monitor:
  - On [Phase Complete]: verify artifacts
  - On [Shared File]: coordinate merge
  - On [ESCALATE]: intervene
  - On [All Tasks Done]: proceed to merge
  - Timeout: 30min per story
Step 5: Shutdown all teams → sequential merge (dependency order) → tsc → commit per story
Step 6: git push → deploy → generate epic completion report

Contract & Wiring in Swarm (v9.4):
- Contract files (shared/src/contracts/): stories touching these are serialized (never parallel)
- Wiring Story (N-W): blockedBy = [parent story N.M] in task dependencies
```

### Swarm Worker Loop

```
Loop until no tasks remain:
1. TaskList → find first task: status=pending, owner=null, blockedBy all completed
   - No available task + others in_progress → wait 30s → retry
   - No tasks at all → "[All Tasks Done]"
2. TaskUpdate: status=in_progress, owner="{team_name}"
3. Execute Phase A → F (full party mode per phase)
4. Run tsc + UI verification (if applicable)
5. TaskUpdate: status=completed → report summary
6. Go to step 1
```
