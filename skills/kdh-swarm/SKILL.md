---
name: kdh-swarm
description: "Swarm auto-epic worker loop."
---

# Mode D: Swarm Auto-Epic

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
