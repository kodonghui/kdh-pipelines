# Party Mode Protocol

Shared multi-critic review protocol used by all KDH pipelines. Applies to **Grade A and Grade B steps only**. Grade C steps use Writer Solo (no review).

Supports variable team sizes (3-5 critics).

---

## Protocol Steps

```
1. Writer: Read step file with Read tool → write section → save to output doc
2. Writer: SendMessage [Review Request] to ALL critics BY REAL NAME
   Include: file path, line range, step file path
3. Critics (parallel): Read FROM FILE → review → write to party-logs/{context}-{step}-{name}.md
4. Critics: Cross-talk with relevant peers (1 round):
   - 3 critics: 3 pairs (all-to-all)
   - 4 critics: 4 relevant pairs (adjacent expertise, skip 2 least-related)
   - 5 critics: 5 relevant pairs (adjacent expertise, skip 5 least-related)
   Cross-talk MUST happen. Each critic SendMessage to assigned peer(s) with top disagreement/concern.
   Peer responds. Both update their party-logs with cross-talk section before scoring.
5. Critics: SendMessage [Feedback] to Writer BY NAME — "{N} issues. Priority: [top 3]"
6. Writer: Read ALL critic logs FROM FILE → apply fixes → write party-logs/{context}-{step}-fixes.md
7. Writer: SendMessage [Fixes Applied] to ALL critics BY NAME
8. Critics (parallel): Re-read FROM FILE → verify → SendMessage [Verified] score X/10
9. Calculate average + enforce thresholds:
   - Grade A: avg >= 8.0 required
   - Grade B: avg >= 7.5 required
   - Avg >= threshold: proceed to Minimum Cycle Check (step 11)
   - Avg < threshold AND retry < grade_max: Writer rewrites from step 1
   - Retry >= grade_max: ESCALATE to Orchestrator
10. Score Variance Check:
   - Calculate standard deviation of all critic scores
   - If stdev < 0.5: Orchestrator flags "Suspiciously High Agreement"
   - At least 1 critic MUST independently re-score without seeing others' scores
11. Minimum Cycle Check (MANDATORY):
   - Grade A: MINIMUM 2 full cycles required regardless of scores
     - Cycle 1: steps 1-8 above (normal review)
     - Cycle 2: Devil's Advocate mode — 1 designated critic MUST find >= 3 issues
     - If Devil's Advocate finds 0 issues: suspicious, Orchestrator reviews directly
   - Grade B: MINIMUM 1 full cycle + cross-talk verified
   - Only after minimum cycles met AND avg >= threshold → PASS
12. Orchestrator Step Completion Checklist (BLOCKING):
   Before accepting [Step Complete], Orchestrator MUST verify ALL:
   - [ ] party-logs/{context}-{step}-{critic1}.md EXISTS (file, not message)
   - [ ] party-logs/{context}-{step}-{critic2}.md EXISTS
   - [ ] party-logs/{context}-{step}-{critic3}.md EXISTS
   - [ ] party-logs/{context}-{step}-{critic4}.md EXISTS (if 4+ critics)
   - [ ] party-logs/{context}-{step}-{critic5}.md EXISTS (if 5 critics)
   - [ ] party-logs/{context}-{step}-fixes.md EXISTS
   - [ ] Each critic log contains "## Cross-talk" section
   - [ ] Score stdev >= 0.5
   - [ ] Grade A: 2nd cycle completed with Devil's Advocate
   - [ ] Context snapshot saved
   ANY item unchecked → REJECT [Step Complete], do NOT proceed
```

---

## Cross-talk Rules

Cross-talk is **MANDATORY** for all party mode steps. Critics must discuss disagreements with peers before finalizing scores.

### Pairings by Team Size

| Team Size | Pairs | Rule |
|-----------|-------|------|
| 3 critics | 3 pairs | All-to-all: every critic talks to every other critic |
| 4 critics | 4 pairs | Adjacent expertise pairs. Skip the 2 least-related pairings |
| 5 critics | 5 pairs | Adjacent expertise pairs. Skip the 5 least-related pairings |

### Cross-talk Execution

1. Each critic identifies their top disagreement or concern from the Writer's output
2. Critic sends `SendMessage` to their assigned peer(s) with the concern
3. Peer responds with their perspective
4. Both critics update their party-log files with a `## Cross-talk` section documenting:
   - Who they talked to
   - What was discussed
   - Whether they changed their assessment
5. Cross-talk section must exist in every critic's party-log **before** scoring

---

## Party-log File Naming

All party-logs follow this naming convention:

```
party-logs/{context}-{step}-{agent-name}.md   # Critic logs
party-logs/{context}-{step}-fixes.md           # Writer's fix summary
```

- `{context}` = stage name, phase name, or any pipeline-specific grouping
- `{step}` = step identifier (e.g., `step-02`, `vision`, `patterns`)
- `{agent-name}` = BMAD agent real name (e.g., `winston`, `quinn`, `john`)

Examples:
```
party-logs/prd-discovery-winston.md
party-logs/architecture-decisions-quinn.md
party-logs/architecture-decisions-fixes.md
```

---

## Party-log Verification

Orchestrator validates ALL critic logs + fixes.md exist **before** accepting [Step Complete]:

```
1. For each critic in team: check file exists at party-logs/{context}-{step}-{critic-name}.md
2. Check fixes log exists: party-logs/{context}-{step}-fixes.md
3. If ANY file missing → REJECT [Step Complete], request missing critic to write their log
4. Only accept [Step Complete] when ALL files verified
```

---

## Orchestrator Completion Checklist (BLOCKING)

This checklist is **non-negotiable**. The Orchestrator must verify every item before accepting a step as complete. If any item fails, the step is REJECTED.

| # | Check | Required For |
|---|-------|-------------|
| 1 | All critic party-log files exist on disk | All grades |
| 2 | Fixes party-log file exists on disk | All grades |
| 3 | Each critic log has `## Cross-talk` section | All grades |
| 4 | Score standard deviation >= 0.5 | All grades |
| 5 | 2nd cycle with Devil's Advocate completed | Grade A only |
| 6 | Context snapshot saved | All grades |

---

## Minimum Cycle Check

Prevents single-cycle rubber-stamping where all critics score high on the first pass.

### Grade A Steps
- **MINIMUM 2 full cycles** required regardless of scores
- Cycle 1: Normal review (steps 1-8)
- Cycle 2: Devil's Advocate mode
  - 1 designated critic MUST find >= 3 issues (real issues, not nitpicks)
  - If Devil's Advocate finds 0 issues: flagged as suspicious — Orchestrator reviews directly
- Only after both cycles AND avg >= 8.0 → PASS

### Grade B Steps
- **MINIMUM 1 full cycle** with cross-talk verified
- Cross-talk sections must exist in all critic logs
- Only after cycle complete AND avg >= 7.5 → PASS

---

## Score Variance Check

Detects artificially convergent scoring where critics appear to coordinate scores rather than review independently.

- After all critics submit scores, calculate the **standard deviation**
- If stdev < 0.5: Orchestrator flags **"Suspiciously High Agreement"**
- Resolution: at least 1 critic must independently re-score **without** seeing others' scores
- The re-scored value replaces their original score
- Recalculate average with the new score

This prevents:
- Unanimous identical scores (e.g., all critics scoring exactly 9.0)
- Anchoring bias where later critics match the first critic's score
- Rubber-stamp approval without genuine independent review

---

## Anti-Patterns

These are production-verified failure modes. Every one caused real pipeline failures.

| # | Anti-Pattern | Fix |
|---|-------------|-----|
| 1 | Writer calls Skill tool (bypasses critic review) | Writer MUST NEVER use Skill tool. Read files with Read tool, write manually |
| 2 | Writer batches steps (writes 5 steps, sends 1 review) | Write ONE step → party mode → THEN next step |
| 3 | Critic skips persona file | First action MUST be Read persona file |
| 4 | Critic reviews via message only (no file) | Orchestrator verifies party-log files exist before accepting |
| 5 | Cross-talk skipped entirely | Orchestrator rejects logs without `## Cross-talk` section |
| 6 | Orchestrator skips own checklist | Completion Checklist is BLOCKING — every checkbox must be verified |
| 7 | All critics give identical scores | Score Variance Check catches stdev < 0.5, triggers re-scoring |
| 8 | Grade A passes on first cycle | Minimum Cycle Check requires 2 cycles with Devil's Advocate |
| 9 | Writer duplicates prior step content | Writer must Read prior steps; use cross-reference instead of duplicating |
