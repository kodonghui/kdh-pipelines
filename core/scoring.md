# Scoring System

Grade definitions, scoring rubric, and pass thresholds for all KDH pipelines.

---

## Step Grades

Every step in a pipeline is assigned a grade that determines its review intensity and retry limits.

| Grade | Label | Max Retries | Review Mode | When to Use |
|-------|-------|-------------|-------------|-------------|
| **A** | Critical | 3 | Full Party Mode + Devil's Advocate (2 cycles minimum) | Core decisions, architecture patterns, functional/nonfunctional requirements |
| **B** | Important | 2 | Full Party Mode (1 cycle minimum + cross-talk) | Most content steps, design, research, validation |
| **C** | Setup | 1 | Writer Solo (no review) | Init, complete, routine validation, boilerplate |

### Grade A — Critical Steps

- 3 retries maximum before escalation to Orchestrator
- **2 full review cycles minimum**, regardless of scores
- Cycle 1: Normal party mode (Writer → Critics → Cross-talk → Fix → Verify)
- Cycle 2: Devil's Advocate mode (1 designated critic MUST find >= 3 real issues)
- Pass threshold: average score >= **8.0**
- If Devil's Advocate finds 0 issues: flagged as suspicious, Orchestrator reviews directly

### Grade B — Important Steps

- 2 retries maximum before escalation
- **1 full review cycle minimum** with cross-talk verified
- All critic party-logs must contain `## Cross-talk` section
- Pass threshold: average score >= **7.5**

### Grade C — Setup Steps

- 1 retry maximum
- **Writer Solo** — no critic review needed
- Writer executes the step alone
- No party-logs generated
- Pass threshold: average score >= **7.0** (self-assessed or Orchestrator spot-check)
- Saves agent resources on routine steps (init, complete, file setup)

---

## Scoring Dimensions

Every critic evaluates the Writer's output across **6 dimensions**, each scored 1-10.

| # | Dimension | What It Measures |
|---|-----------|-----------------|
| 1 | **Completeness** | Does the output cover all required elements? Are there gaps or missing sections? |
| 2 | **Accuracy** | Is the content factually correct? Are technical claims verifiable? |
| 3 | **Coherence** | Does the output flow logically? Are sections internally consistent? |
| 4 | **Depth** | Is the analysis sufficiently detailed? Does it go beyond surface-level? |
| 5 | **Actionability** | Can the output be directly used for the next step? Are there clear next actions? |
| 6 | **Alignment** | Does the output match the project's goals, architecture, and user needs? |

### Scoring Scale

| Score | Meaning |
|-------|---------|
| 9-10 | Exceptional — exceeds expectations, production-ready |
| 7-8 | Good — meets requirements with minor improvements possible |
| 5-6 | Adequate — meets minimum bar but needs improvement |
| 3-4 | Below standard — significant gaps, requires rewrite |
| 1-2 | Unacceptable — fundamental problems, start over |

---

## Pass Thresholds

| Grade | Required Average | Calculation |
|-------|-----------------|-------------|
| A | >= **8.0** | Mean of all critics' overall scores |
| B | >= **7.5** | Mean of all critics' overall scores |
| C | >= **7.0** | Self-assessed or Orchestrator spot-check |

### Auto-Fail Rule

**Any single dimension scored < 3 = automatic failure**, regardless of average.

This prevents a high average from masking a critical weakness. For example:
- Scores of [9, 9, 9, 9, 2, 9] average 7.83 — would pass Grade B threshold
- But the dimension scored 2 triggers auto-fail
- Writer must specifically address the failed dimension before re-review

---

## Score Variance Check

Detects artificially uniform scoring that suggests critics are not reviewing independently.

### How It Works

1. After all critics submit their scores, calculate the **standard deviation** (stdev)
2. If stdev < **0.5**: flag as **"Suspiciously High Agreement"**
3. Resolution: at least 1 critic must independently re-score **without** seeing other critics' scores
4. Replace that critic's original score with the re-scored value
5. Recalculate average and stdev

### Why This Matters

Production failure case: all 4 critics scored exactly 9.00 on the same step. This unanimity indicates anchoring bias (later critics matching earlier scores) rather than genuine independent assessment. The variance check forces at least one dissenting voice.

### Thresholds

| Stdev | Status |
|-------|--------|
| >= 1.0 | Healthy — genuine disagreement exists |
| 0.5 - 1.0 | Acceptable — some convergence but within normal range |
| < 0.5 | **Suspicious** — trigger re-scoring protocol |

---

## Devil's Advocate Protocol

Required for all **Grade A** steps during Cycle 2.

### Purpose

Prevent rubber-stamp approval where all critics agree on first pass. One critic is designated to actively challenge the output.

### Rules

1. Orchestrator designates 1 critic as Devil's Advocate for Cycle 2
2. The Devil's Advocate **MUST find >= 3 issues** (real issues, not nitpicks)
3. Issues must be substantive: logic gaps, missing edge cases, incorrect assumptions, unclear requirements
4. The Devil's Advocate documents findings in their party-log under `## Devil's Advocate Review`
5. Writer addresses all Devil's Advocate issues in the fixes log
6. Other critics verify the fixes in their re-review

### Failure Modes

| Scenario | Action |
|----------|--------|
| Devil's Advocate finds >= 3 issues | Normal — Writer fixes, all critics re-verify |
| Devil's Advocate finds 1-2 issues | Acceptable — but Orchestrator notes the low count |
| Devil's Advocate finds 0 issues | **Suspicious** — Orchestrator reviews the output directly |

---

## Retry Flow

When a step fails to meet its threshold:

```
1. Score average < threshold
2. Check retry count vs grade_max
3. If retries remaining:
   a. Orchestrator notifies Writer of failure reason
   b. Writer reads ALL critic feedback from party-logs
   c. Writer rewrites from scratch (not just patching)
   d. Full party mode runs again (step 1 of protocol)
4. If retries exhausted (retry >= grade_max):
   a. ESCALATE to Orchestrator
   b. Orchestrator reviews directly and makes final decision
   c. Options: force-pass with noted issues, rewrite with different Writer, or skip with warning
```

---

## Score Reporting Format

Critics report scores in this format:

```markdown
## Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Completeness | 8 | All sections covered |
| Accuracy | 7 | Minor factual issue in section 3 |
| Coherence | 9 | Excellent flow |
| Depth | 7 | Could expand on edge cases |
| Actionability | 8 | Clear next steps |
| Alignment | 9 | Matches architecture doc |

**Overall: 8.0/10**
```

The overall score is the mean of all 6 dimensions. Critics may also provide a qualitative summary alongside the numerical scores.
