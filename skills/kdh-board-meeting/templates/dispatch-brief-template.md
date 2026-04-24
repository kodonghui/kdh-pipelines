# Dispatch Brief Template — R1 ~ R6 (all rounds)

> **PURPOSE:** Every dispatch brief (`dispatch/R{N}.{pass}-{ROLE}-{CLI}-brief.md`) for rounds R1 ~ R6 SHALL be instantiated from this template. Chairman A fills the slots `{...}` before `tmux send-keys` to the target actor.
>
> **WHY A TEMPLATE EXISTS (CEO 2026-04-23):** B (Codex) and C (Gemini) start each dispatch with a **fresh context** — no memory of prior rounds, no memory of BRD rules. Any rule the brief omits is a rule the actor will not follow. Standardizing the brief makes every mandatory rule structurally present in every dispatch.
>
> **Enforcement:** Chairman A MUST NOT skip any `[MANDATORY]` block below. Validator `brief_completeness.py` (v0.6, planned) will fail the round if a `[MANDATORY]` section is missing.

---

## Slot reference (A fills these before sending)

| Slot | Example | Where it comes from |
|---|---|---|
| `{BOARD_ID}` | `0422-board-v2-topic2-trio-harness` | `.board-meta.json.board_id` |
| `{ROUND}` | `R3` | round number (1..6) |
| `{PASS}` | `1` or `2` | BRD-029 |
| `{ROLE}` | `C` / `B` | target actor letter |
| `{CLI}` | `Gemini` / `Codex` | target CLI brand |
| `{ROTATION}` | `[C, A, B]` | `rotation-table.yaml[{ROUND}.{PASS}]` |
| `{SPEAKER_POSITION}` | `first` / `second` / `third` | index in `{ROTATION}` |
| `{TARGET_FILE}` | `rounds/R3/C.md` (pass-1) or `rounds/R3.2/C.md` (pass-2) | BRD-002 |
| `{FLAG_PATH}` | `inbox/R3.1/C-DONE.flag` | BRD-020 |
| `{PRIOR_ROUND_FILES}` | full list of R0~R{N-1} artifacts | enumerated below |
| `{THIS_ROUND_EARLIER_FILES}` | files already written this round by earlier speakers in `{ROTATION}` | same round, earlier-in-rotation |
| `{TOPIC_ATTACK_SURFACE}` | round-specific seed issues or open questions | chairman A's judgment |
| `{DEVIL_ADVOCATE_ROLE}` | A / B / C | BRD-040 rotation (different per round) |
| `{DEGRADED_MODE}` | `true` / `false` | `.board-meta.json.quota_snapshot.degraded_mode` |

---

# === BEGIN BRIEF BODY (copy-paste and fill slots) ===

# {ROUND}.{PASS} Dispatch — {ROLE} ({CLI}) — SPEAKER {SPEAKER_POSITION}

**Board:** {BOARD_ID}
**Round:** {ROUND}, Pass {PASS}
**Rotation:** {ROTATION}
**Your role:** {ROLE} — speaker #{SPEAKER_POSITION} of 3.
**Your target file:** `{TARGET_FILE}`
**Your completion flag:** `{FLAG_PATH}`
**Devil's Advocate this round (BRD-040):** {DEVIL_ADVOCATE_ROLE}

---

## [MANDATORY 1] Enter-Rule (CEO 2026-04-23)

**매 tmux 전송 마지막에 Enter 를 별도로 눌러서 전송해야 함.** 메시지 + Enter 를 한 명령에 넣지 마라. 그러면 Enter 가 삼켜짐.

When you notify conductor A of completion at the end of this task, use TWO send-keys calls:
```bash
tmux send-keys -t conductor:0 "DONE-{ROLE}: {ROUND}.{PASS} done"
tmux send-keys -t conductor:0 Enter
```
NEVER combine into `tmux send-keys -t conductor:0 "DONE-..." Enter` — the Enter gets eaten.

---

## [MANDATORY 2] Concrete-and-Detailed Rule (CEO 2026-04-22)

**의견(Opinion) 과 대안(Alternative) 섹션은 반드시 구체적이고 자세하게 논의하라.**

NO hand-waving. Every claim MUST include:
- Specific file path with line number (e.g., `rounds/R2.2/A.md:68`)
- Specific failure mode (what breaks, how, under which condition)
- Specific fix path (what file changes, what line changes, what new check is added)
- Specific cost or trade-off (time, tokens, operational complexity)

Abstract statements like "this is risky" or "consider another approach" are FAIL. Replace with "At `path/file.py:42`, the flock acquisition on WSL overlay filesystem can return success while the actual inode lock is not held; under concurrent write from Codex sandbox in workspace-write mode, this produces a silent data race. Fix: switch to `fcntl.lockf()` + verify inode via `os.fstat().st_ino` before release."

---

## [MANDATORY 3] Required Reads — 이전 모든 토론 전수 숙지

Before you write a single line of `{TARGET_FILE}`, READ EVERY FILE in this list using the Read tool:

### Board meta & CEO context
1. `_bmad-output/kdh-plans/{BOARD_ID}/00-CEO-instruction-verbatim.md`
2. `_bmad-output/kdh-plans/{BOARD_ID}/.board-meta.json`
3. `conductorA/CLAUDE.md` (your chairman's role spec)
4. `CLAUDE.md` (repo-level orchestration rules)

### Round 0 artifacts (research foundation — reread every round)
5. `_bmad-output/kdh-plans/{BOARD_ID}/rounds/R0/research-summary.md`
6. `_bmad-output/kdh-plans/{BOARD_ID}/rounds/R0/EARS-skeleton.md`
7. `_bmad-output/kdh-plans/{BOARD_ID}/rounds/R0/corpus-supplement/B-r0-research.md`
8. `_bmad-output/kdh-plans/{BOARD_ID}/rounds/R0/corpus-supplement/C-r0-research.md`

### Prior rounds (all passes, all speakers — enumerated in {PRIOR_ROUND_FILES})
{PRIOR_ROUND_FILES}

### This round's earlier files (BRD-029 pass-2 refute base, or within-round precedence)
{THIS_ROUND_EARLIER_FILES}

### Evidence of reading (MANDATORY — top of your response)
**At the very top of `{TARGET_FILE}`, write a section titled `## Read-evidence` with 3-line summaries per actor-round:**
```
## Read-evidence

- R0 (A research-summary): [3-line summary of A's key claims]
- R0 (B corpus-supplement): [3-line summary]
- R0 (C corpus-supplement): [3-line summary]
- R1.1 A: [3-line summary]
- R1.1 B: [3-line summary]
- ... (every file in {PRIOR_ROUND_FILES})
```

**If your output lacks this Read-evidence block, you did NOT read the files. Go back and read them. Chairman A validates this manually + validator `citation_resolver.py` (BRD-032) will cross-check that your later citations resolve to real `file:line`.**

---

## [MANDATORY 4] Required structure (BRD-005)

Your `{TARGET_FILE}` body AFTER the Read-evidence block MUST contain these 4 subheadings in this exact order, each with ≥1 citation (BRD-006, BRD-032):

### ### Research done
What new evidence did YOU research (not just restate prior rounds)? Cite sources (archive URLs in `sources/urls/`, repo files, package docs). New information only.

### ### Opinion
**구체적이고 자세하게 (see [MANDATORY 2] above).** Your stance on open issues. MUST address the specific open questions in {TOPIC_ATTACK_SURFACE}. For each stance: AGREE / AGREE-WITH-AMENDMENT(<concrete text>) / DISSENT(<concrete reason>). Per-REQ sign-off preview expected in R2+ rounds.

### ### Aggressive review
Attack ≥1 claim made by another actor in prior rounds or this round. Cite the exact `file:line`. State what's wrong and how it breaks. Do not hedge.

### ### Alternative
**구체적이고 자세하게.** If R3+ surfaces your primary approach fails, what's plan-B? Concrete enough that an implementer could execute without further questions. Include effort estimate + file list + failure mode it avoids.

---

## [MANDATORY 5] Citation requirement (BRD-006, BRD-032)

- **≥1 citation per subheading** above.
- Format: `` `path/file.md:LINE` `` (backticks + path + colon + line number).
- Citations MUST resolve — validator `citation_resolver.py` (BRD-032) opens the cited file and checks the line exists and the content roughly matches your summary. Fabricated citations FAIL the round.
- External sources: reference archived HTML under `sources/urls/` (e.g., `sources/urls/tmux-env-unset.html`) — NOT live URLs.

---

## [MANDATORY 6] Pass-2 rule (BRD-029) — applies only if {PASS}=2

**You MUST either refute ≥1 pass-1 claim (cite `file:line`) OR extend a pass-1 claim with genuinely new evidence.**

Empty agreement phrases are FAIL. Examples of FAIL:
- "I agree with A's analysis."
- "B is correct, nothing to add."
- "C's points are reasonable."

Examples of PASS:
- "I refute A's claim at `rounds/R2.2/A.md:68` that probe spoofing via tmux scrollback is a live risk — B already designed flock-based subprocess probes at `rounds/R1/B.md:126`. Replacement R3 seed: [concrete issue]."
- "I extend B's REQ-T2-015 TTL from `per-round` to `per-actor per-pass` because [concrete reasoning with file:line]."

---

## [MANDATORY 7] R3 adversarial rule (BRD-017 + BRD-039) — applies only if {ROUND}=R3

Both R3.1 and R3.2 MUST produce ≥1 HIGH or CRITICAL issue. You MUST append your issue(s) to `events/issues.jsonl` with the 3-element structure (BRD-039):

```json
{"issue_id":"T2-R3-{unique}","severity":"HIGH|CRITICAL","scope":"<what component/path is affected>","mitigation":"<concrete fix path: file change + line + verification step>","evidence":"<file:line citation supporting the issue exists>","raised_by":"{ROLE}","round":"{ROUND}.{PASS}","utc_ts":"<ISO8601>"}
```

All three of `severity` + `scope` + `mitigation` MUST be non-empty. An issue with only severity and no mitigation will FAIL at validator `critical_issue.py` (BRD-039).

**Novelty (BRD-040):** If your issue repeats a point already raised in a prior R3 pass or in R2.2 pre-seeds, validator will FAIL. Read `events/issues.jsonl` before appending — only append if genuinely new angle.

---

## [MANDATORY 8] Devil's Advocate role (BRD-040) — if {DEVIL_ADVOCATE_ROLE}=={ROLE}

You are the designated devil's advocate this round. You MUST:
- Challenge the apparent consensus even if you privately agree.
- Raise the strongest possible objection to the majority position.
- Propose the most credible alternative even if you don't prefer it.
- Your role file header MUST state "**Devil's Advocate this round.**"

Other rounds' devil advocates rotate — read `.board-meta.json.devil_advocate_rotation` to confirm.

---

## [MANDATORY 9] R0 content gate (BRD-031) — applies only if {ROUND}=R0

R0 research-summary.md MUST contain these 5 sections (XOR ordering, no merging):
1. Problem (what are we trying to decide)
2. Constraints (what bounds the solution — cost, time, skill, integration)
3. Options (enumerated alternatives, ≥3)
4. Criteria (rubric to judge options)
5. Citations (archived sources, ≥5)

---

## [MANDATORY 10] Completion protocol

When your `{TARGET_FILE}` is written and you are satisfied:

```bash
# 1. Ensure inbox dir exists
mkdir -p _bmad-output/kdh-plans/{BOARD_ID}/inbox/{ROUND}.{PASS}

# 2. Atomic-create your DONE flag
: > _bmad-output/kdh-plans/{BOARD_ID}/{FLAG_PATH}

# 3. Notify conductor A — TWO send-keys calls (see [MANDATORY 1])
tmux send-keys -t conductor:0 "DONE-{ROLE}: {ROUND}.{PASS} done"
tmux send-keys -t conductor:0 Enter
```

**Do not mark DONE if:**
- Read-evidence block is missing.
- Any of the 4 subheadings is missing or empty.
- Any subheading has 0 citations.
- (Pass-2 only) Neither refute nor extend is present.
- (R3 only) No HIGH/CRITICAL issue in `events/issues.jsonl` from this role this round.

---

## [MANDATORY 11] Degraded mode status

Current `.board-meta.json.quota_snapshot.degraded_mode_locked = true` means: if you hit rate limits, WAIT until quota resets. Do NOT fall back to 1-pass or ask chairman to fill in for you. The CEO has explicitly forbidden degraded_mode fallback for this board (2026-04-22 23:40 KST).

If you physically cannot complete (model is unreachable, tool call permanently fails), do NOT write a partial file. Instead:
```bash
: > _bmad-output/kdh-plans/{BOARD_ID}/inbox/{ROUND}.{PASS}/{ROLE}-STALL.flag
tmux send-keys -t conductor:0 "STALL-{ROLE}: {ROUND}.{PASS} unable-to-complete — reason: <short>"
tmux send-keys -t conductor:0 Enter
```
Chairman A will escalate to CEO.

---

# === END BRIEF BODY ===

## After the template body, chairman A appends round-specific content

Below the [MANDATORY 1..11] blocks, A adds:
- `## {ROUND}.{PASS} specific context` — what happened in the immediate prior pass
- `## Open attack surface for this round` — concrete open questions with `file:line` citations (these become {TOPIC_ATTACK_SURFACE})
- `## Hints` — *only* if CEO has given explicit guidance for this round; otherwise omit (don't bias actor's independence)

---

## Maintenance

- **Version:** v1.0 (2026-04-23)
- **Trigger:** every R1~R6 dispatch for every board from 2026-04-23 onward.
- **Exempt:** R0 has its own template (`round0-prompt-template.md`).
- **Validator:** `brief_completeness.py` planned for v0.6 — until then, chairman A is responsible for template fidelity.
- **Change control:** modifying this template requires a new board deliberation (BRD-024 self-bootstrap).
