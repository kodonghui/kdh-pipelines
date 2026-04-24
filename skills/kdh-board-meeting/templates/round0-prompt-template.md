# Round 0 Prompt Template (BRD-025)

Chairman A uses this template to drive Round 0 before R1 begins.

## Chairman A's actions

### Step 1 — Invoke /kdh-research

Run the deep-research skill on the board topic:

```
/kdh-research {topic}
```

The skill reads `~/.claude/skills/kdh-research/SKILL.md` and executes Step 0~6:
- Source routing (Context7 → GitHub → Web)
- 7 sub-query decomposition
- Round 1 Breadth (7 WebSearch + 5 WebFetch in parallel)
- Round 2 Depth
- Cross-verification
- Analyze-Ready Summary

Save the full report to `rounds/R0/research-summary.md`.

### Step 2 — Supplementary corpus

Collect files that are:
- Referenced in the research but not yet in `sources/`
- Prior kdh board outputs related to the topic
- Relevant spec, code, or docs inside this repository

Copy them into `rounds/R0/corpus-supplement/` (preserve structure where useful).

### Step 3 — EARS skeleton

Write `rounds/R0/EARS-skeleton.md` with a blank 4-column table:

```markdown
# EARS Skeleton — Board {board_id} — Topic {topic}

| Issue / Requirement | A draft | B input | C input | Final (per R5) |
|---------------------|---------|---------|---------|----------------|
| BRD-XXX — {placeholder} |   |   |   |   |
```

Add placeholder rows for anticipated requirements based on research-summary.md insights.

### Step 4 — A-DONE flag

```bash
: > inbox/round-0/A-DONE-R0.flag
```

Use `:` (bash null command) or `touch` to ensure atomic creation with 0-byte content.

### Step 5 — Notify B and C (2-step Enter per conductor CLAUDE.md rule 3-1)

```bash
tmux send-keys -t conductorB:0 'Round 0 artifacts ready. Read:
- rounds/R0/research-summary.md
- rounds/R0/corpus-supplement/
- rounds/R0/EARS-skeleton.md

After reading:
- IF relevant and sufficient: touch inbox/round-0/B-ACK-R0.flag
- IF irrelevant/insufficient: touch inbox/round-0/R0-INVALID.flag + explain in rounds/R0/B-invalid-reason.md'
tmux send-keys -t conductorB:0 Enter

# Same for conductorC with C-ACK-R0.flag
```

**Critical:** The message and `Enter` MUST be separate `tmux send-keys` calls. Combining them swallows the Enter.

## B and C actions

After receiving the tmux message:

1. Read the 3 Round 0 artifacts fully (no summarization — BRD-006 citation requirement).
2. Decide:
   - **Relevant and sufficient** for the topic → `touch inbox/round-0/{B,C}-ACK-R0.flag`
   - **Irrelevant or insufficient** → `touch inbox/round-0/R0-INVALID.flag` AND write reason to `rounds/R0/{B,C}-invalid-reason.md`

`WHEN` `R0-INVALID.flag` exists, `THE SYSTEM SHALL` abort the board. Chairman A must re-run Round 0 with corrected scope or abandon the topic.

### CRITICAL — File-level verification rubric (added 2026-04-20 board `0420-patches-review` R5 meta-lesson)

Before voting APPROVE on any claim that cites a file path + line range:

1. **MUST open the cited file** using Read tool (or equivalent) at the cited offset.
2. **MUST compare the actual file content** to the patch/claim description — do they match byte-for-byte?
3. **MUST spot-check at least one cross-cited integration** — e.g., if a plan claims "install.sh uses symlinks", actually open `install.sh` and verify.

Citation of patch text alone is **insufficient** evidence for APPROVE. Patches can misstate the source they claim to patch. Precedent: 2026-04-20 `0420-patches-review` R0-C voted APPROVE on claim `install.sh creates symlinks` when actual `install.sh:24-31` uses `cp -r`. C retracted to AMEND after R1 forced re-inspection.

This rubric is **additive** to ACK gate — it governs how B/C form their R0 verdicts, not whether they ACK at all.

## Gate check

After all flags are in place:

```bash
~/.claude/scripts/board/round0-validator.py {board_id}
```

PASS requires:
- 3 artifacts exist (research-summary.md, corpus-supplement/, EARS-skeleton.md)
- A-DONE-R0.flag exists
- B-ACK-R0.flag exists
- C-ACK-R0.flag exists
- R0-INVALID.flag does NOT exist

`IF` PASS, `THEN` write `gates/phase-r0-pass.json` and proceed to R1.

## Fallback (MCP failure)

`IF` `/kdh-research` fails (Context7 down, WebSearch rate limited):
1. Chairman A writes `rounds/R0/round0-fallback-reason.md` documenting the failure.
2. A manually collects corpus from existing repo files.
3. ACK gate still applies — B/C verify manual corpus is adequate.

## Example prompt to B/C (for copy-paste by A)

```
Round 0 ready for board {board_id} on topic: {topic}.

Artifacts:
1. rounds/R0/research-summary.md — /kdh-research output (sources, cross-verified claims, confidence levels)
2. rounds/R0/corpus-supplement/ — additional files collected
3. rounds/R0/EARS-skeleton.md — blank deliberation table

Your job:
- Read all 3 artifacts fully.
- IF the corpus+research is relevant and sufficient to deliberate the topic: touch inbox/round-0/{your_role}-ACK-R0.flag
- IF not: touch inbox/round-0/R0-INVALID.flag + write rounds/R0/{your_role}-invalid-reason.md explaining what is missing or wrong.

R1 will not start until both B and C ACK (or until INVALID triggers abort).
```
