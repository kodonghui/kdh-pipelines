---
name: kdh-board-meeting
description: "Board meeting v2-RC1 — 3-agent (A/B/C) deliberation, 42 ratified BRDs. v0.5.2 core (R0 research BRD-025, 2-pass deliberation BRD-029, R3 HIGH/CRITICAL BRD-017, manifest-hashed publish BRD-010, atomic constitution migration BRD-022) + v2 hardening (content-gated R0 BRD-031, citation resolver BRD-032, post-render ACK BRD-033, strength-weighted verdicts BRD-034, fairness ledger BRD-035, signature coverage BRD-036, logger backoff BRD-037a, strict event provenance BRD-037b, Delphi reveal BRD-038, critical-issue L3 parser BRD-039, devil advocate rotation BRD-040, exception provenance BRD-041, manifest-bound send BRD-042). Prevents chairman fabrication + post-hoc tampering structurally. Invoke: /kdh-board-meeting topic=\"X\" corpus=\"p1,p2\" rounds=5"
---

# /kdh-board-meeting — Board Meeting Skill v2-RC1

When the user invokes `/kdh-board-meeting`, orchestrate a structurally-verifiable 3-agent board (A chairman, B/C participants) per the ratified 42 BRDs (BRD-001 ~ BRD-030 v0.5.2 core + BRD-031 ~ BRD-042 v2 hardening, with BRD-037 split into 037a/037b).

**Canonical BRD spec:** `_bmad-output/kdh-plans/0417-board-v2-discussions/topic-1-kdh-board-meeting-howto.EARS-normalized.md` (source of truth from 2026-04-18).

## 1. Invocation

```
/kdh-board-meeting topic="<text>" corpus="<comma-paths>" rounds=5 [chairman=A]
```

**Required:** `topic`, `corpus` (comma-separated paths).
**Default:** `rounds=5`, `chairman=A`.

`THE SYSTEM SHALL NOT` mutate or replace `kdh-discuss` (BRD-001).

## 2. Inputs — Preflight

Before creating workspace:
1. Read this SKILL.md and confirm the 10-step BRD-023 v0.5.2 sequence is available.
2. Resolve all corpus paths. `IF` any path is missing, `THEN THE SYSTEM SHALL` abort and emit the missing path to stderr.
3. `kdh-board-token-probe` — check A/B/C quota snapshots. `IF` any is below threshold, `THEN THE SYSTEM SHALL` set `.board-meta.json.degraded_mode=true` (BRD-029 falls back to 1-pass).
4. Confirm no other board is in Phase 8 atomic migration (workspace lock check).

## 3. Workspace Layout (per BRD-002 / BRD-003)

```
_bmad-output/kdh-plans/{YYYYMMDD}-board-{slug}/
├── .board-meta.json
├── INDEX.md
├── sources/
├── rounds/
│   ├── R0/
│   │   ├── research-summary.md
│   │   ├── corpus-supplement/
│   │   ├── EARS-skeleton.md
│   │   └── round0-fallback-reason.md            (only on MCP fail)
│   ├── R1/, R1.2/, R2/, R2.2/, R3/, R3.2/, R4/, R4.2/, R5/, R6/
│   └── extension-rounds/{brd-id}/R1..R5/
├── consensus/requirements.jsonl + signatures.jsonl
├── events/board-events.jsonl + send-audit.jsonl + issues.jsonl + timeout-evidence.jsonl
├── ledger/disagreement.jsonl
├── inbox/round-0/{A-DONE,B-ACK,C-ACK,R0-INVALID}.flag + inbox.jsonl
├── gates/phase-N-pass.json   (N = 0..9)
├── publish/{validator-pass.json, manifest.json, decision.yaml, prompt.md, READY_TO_SHIP.token}
├── reports/{YYYYMMDD}_{slug}.md                 (BRD-030 canonical)
├── RENDERED.md                                  (non-canonical)
└── .board-archive/{ts}/                         (atomic rollback backup)
```

## 4. Lifecycle (R0 → R6 → Publish → Send → Verify)

### 4.1 Init
- `THE SYSTEM SHALL` create workspace dir, write `.board-meta.json` (rotation_table from `templates/rotation-table.yaml`, round_structure from `templates/round-structure.yaml`, quota snapshot from token-probe).
- `THE SYSTEM SHALL` copy corpus → `sources/`.
- `THE SYSTEM SHALL` emit `BOARD_STARTED` to `events/board-events.jsonl` with `sequence_no=0` (flock-protected).

### 4.2 Round 0 (BRD-025 + ACK gate)
Chairman A executes in order:
1. Invoke `/kdh-research {topic}` per `templates/round0-prompt-template.md`. `THE SYSTEM SHALL` write output to `rounds/R0/research-summary.md`.
2. Collect supplementary corpus → `rounds/R0/corpus-supplement/`.
3. Write `rounds/R0/EARS-skeleton.md` with 4-column blank table (A / B / C / Conclusion).
4. Atomic create `inbox/round-0/A-DONE-R0.flag`.
5. Notify B and C via `tmux send-keys -t conductorB:0 '...'` + **separate Enter**, then same for conductorC (per CLAUDE.md rule 3-1).

B and C then:
- Read the 3 Round 0 artifacts.
- `IF` artifacts are relevant and sufficient, `THEN` atomic create `inbox/round-0/{B,C}-ACK-R0.flag`.
- `IF` artifacts are irrelevant or insufficient, `THEN` atomic create `inbox/round-0/R0-INVALID.flag`. `WHEN` this flag exists, `THE SYSTEM SHALL` abort the board.

Gate: `~/.claude/scripts/board/round0-validator.py {board_id}` — PASS requires 3 artifacts + A-DONE + B-ACK + C-ACK. Then write `gates/phase-r0-pass.json`.

### 4.3 R1 ~ R4 (BRD-029 2-pass)
For each round N in {1, 2, 3, 4}:
- **Pass 1:** Speakers in order `rotation_table["N.1"]`. Each writes `rounds/R{N}/{role}.md` with 4 mandatory subheadings (BRD-005): Research done / Opinion / Aggressive review / Alternative. Each must include ≥1 citation (BRD-006).
- **Pass 2:** Speakers in order `rotation_table["N.2"]`. Each writes `rounds/R{N}.2/{role}.md`. `THE SYSTEM SHALL` require each pass-2 writer to either (a) specifically refute ≥1 pass-1 claim or (b) extend their pass-1 opinion with new evidence. `THE SYSTEM SHALL NOT` permit empty-agreement phrases.
- **R3 special:** Both passes must produce ≥1 HIGH or CRITICAL issue in `events/issues.jsonl` (BRD-017). `IF` none, `THEN THE SYSTEM SHALL` mark R3.{pass} as `RERUN_REQUIRED`.
- Between rounds: `kdh-board-token-probe` check. `IF` quota below threshold, `THEN` set `degraded_mode=true` and fall back to 1-pass for remaining rounds.

Per pass, writers atomic-create `inbox/R{N}.{pass}/{role}-DONE.flag`.

### 4.4 R5 — EARS sign-off (1-pass, rotation 5.1 = [A, B, C])
Per CEO 2026-04-18, chairman A drafts EARS first:
1. A writes `consensus/requirements.jsonl` rows (one per BRD, using EARS-template.md structure, BRD-016 target_state enum).
2. A drafts `rounds/R5/A.md` with EARS spec reference.
3. B and C each write `rounds/R5/{B,C}.md` with `AGREE | AGREE-WITH-AMENDMENT(<text>) | DISSENT(<reason>)` per req_id.
4. Signatures are appended to `consensus/signatures.jsonl`.
5. `IF` any DISSENT, `THEN` `kdh-board-extension-spawn {brd-id}` creates `rounds/extension-rounds/{brd-id}/R1..R5/`.

### 4.5 R6 — Consensus (1-pass, rotation 6.1 = [B, C, A], A last)
Per BRD-030, each participant submits:
- Agreed items list
- Remaining disagreements with 1-2 sentence final stance
- Optional improvement suggestions

### 4.6 Publish (Phase 6 of v0.5.2; uses Phase 5 report)

```bash
~/.claude/scripts/board/kdh-board-publish {board_id}
```

Sequence:
1. `validator.py` runs all 6 modules. `IF` FAIL, `THEN` abort with `validator.log`, write nothing to `publish/`.
2. `report-renderer.py` produces `reports/{YYYYMMDD}_{slug}.md` (BRD-030). Byte-extract I/II/III, authored IV.
3. Compute sha256 of canonical files + report → `publish/manifest.json:canonical_inputs`.
4. Inline manifest hash header → `publish/prompt.md` + `publish/decision.yaml`.
5. Write `publish/validator-pass.json` (ephemeral per BRD-013).
6. Atomic write `publish/READY_TO_SHIP.token`. `ready-token-invalidate.js` hook auto-rm on any canonical change.

### 4.7 Send / Verify / Override / Extension / Timeout

| Command | Purpose | BRD |
|---------|---------|-----|
| `kdh-board-send --target {ceo\|server-claude} --board-id N` | verbatim copy of `publish/prompt.md` or `reports/{slug}.md`; logs to `send-audit.jsonl` | BRD-011 |
| `kdh-board-verify {board_id}` | recompute manifest hashes, rerun validator, check READY_TO_SHIP consistency | BRD-012 |
| `kdh-board-override {board_id} --supersede-id N [--reason TEXT]` | CEO supersede with TTL 1800s | BRD-018 |
| `kdh-board-extension-spawn {brd-id}` | spawn extension-rounds for DISSENT | BRD-018 |
| `kdh-board-timeout-emit {participant}` | write PARTICIPANT_TIMEOUT with evidence (monitor/inbox/capture) | BRD-019 |
| `kdh-board-token-probe` | update quota snapshot in `.board-meta.json` | v0.5.2 |

## 5. Rotation Table (BRD-028)

See `templates/rotation-table.yaml`. Per CEO 2026-04-18:
- R5.1 = `[A, B, C]` (chairman-first for EARS draft)
- R5.2 = null (1-pass per BRD-029)
- R6.1 = `[B, C, A]` (A last)
- First-speaker counts: A=4, B=3, C=3 (±1 permitted per BRD-028)

## 6. Signature Protocol

- `signatures.jsonl` row: `{req_id, role, verdict, text, timestamp, signer_session_id, signature_path, signature_status, signature_algorithm}`.
- `verdict` ∈ {AGREE, AGREE-WITH-AMENDMENT, DISSENT}.
- `signature_*` fields reserved for v0.6 PKI (BRD-021), null in v0.5.2.

## 7. Severity Rubric (BRD-016)

See `consensus/requirements.jsonl:target_state` enum: `STABLE | PROPOSED | CONTESTED | QUARANTINED | SUPERSEDED`. `WHERE` publish artifact diverges from canonical → `CRITICAL`. `WHERE` quarantine cannot complete within TTL → `HIGH`. See BRD-016 for full rubric.

## 8. BRD Cross-Reference Matrix

| BRD | Concern | Implementation |
|-----|---------|----------------|
| BRD-001 | Skill name | This file frontmatter |
| BRD-002 | Workspace | §3 |
| BRD-003 | Canonical set | §3, validators/registry.py |
| BRD-004 | Per-role files | §4.3 |
| BRD-005 | 4 subheadings | validators/rounds.py |
| BRD-006 | Citations | validators/research.py |
| BRD-007 | RENDERED non-canonical | rendered-renderer.py |
| BRD-008 | Publish gate | §4.6, kdh-board-publish |
| BRD-009 | Validator-first | §4.6 step 1 |
| BRD-010 | Manifest binding | §4.6 step 3 |
| BRD-011 | Outbound verbatim | kdh-board-send |
| BRD-012 | CEO verify | kdh-board-verify |
| BRD-013 | Validator-pass ephemeral | §4.6 step 5 |
| BRD-014 | Validator contract | validator.py + 6 modules |
| BRD-015 | board-events logger | board-events-logger.js (flock + sequence_no) |
| BRD-016 | Severity state machine | validators/registry.py |
| BRD-017 | R3 HIGH/CRITICAL | §4.3, validators/rounds.py |
| BRD-018 | Quarantine 2-of-3 OR | kdh-board-override, validators/registry.py |
| BRD-019 | Timeout evidence | kdh-board-timeout-emit |
| BRD-020 | File-flag inbox | §4.2~4.3 |
| BRD-021 | PKI reserved fields | signatures.jsonl schema |
| BRD-022 | Constitution migration | Phase 8 atomic-constitution-migrate.sh |
| BRD-023 | Impl order | v0.5.2 10-step sequence (Phase 0..9) |
| BRD-024 | Self-bootstrap | Phase 9, delta-report only |
| BRD-025 | Round 0 + /kdh-research | §4.2, ACK gate |
| BRD-026 | 발언 구체성 | validators/rounds.py WARNING rule |
| BRD-027 | 보고서 법학 형식 | report-renderer.py |
| BRD-028 | Rotation table | templates/rotation-table.yaml |
| BRD-029 | 2-pass R1~R4 | §4.3, validators/rounds.py |
| BRD-030 | R6 + auto report | report-renderer.py, §4.5~4.6 |
| BRD-031 | R0 content gate (5-section Problem/Constraints/Options/Criteria/Citations + XOR ordering) | validators/r0_content.py |
| BRD-032 | Citation resolver — `file:LINE` must resolve to real line + content match | validators/citation_resolver.py (9-field jsonl + basename fallback) |
| BRD-033 | Post-render B/C ACK gate — reports/ render 후 B·C 가 "왜곡 없음" 서명 (`publish/report-ack.jsonl`) 없으면 publish 차단 | validators/report_ack.py, kdh-board-publish |
| BRD-034 | Strength-weighted verdicts — 5-criterion rubric, evidence-based scores only, LLM judge 금지 | validators/strength.py |
| BRD-035 | Fairness ledger — 첫 발언 A/B/C 카운트 ±1 이상 불균형 시 board 정지, CEO ack 필요 | validators/fairness.py + `events/fairness-ledger.jsonl` |
| BRD-036 | Signature coverage — signatures.jsonl 에 각 REQ 당 A+B+C 세 서명 존재 확인 (누락 1 건도 FAIL) | validators/signature_coverage.py |
| BRD-037a | Logger backoff — board-events 쓰기 실패 시 100/300/900ms 재시도 + dead-letter 큐 | hooks/board-events-logger.js |
| BRD-037b | Strict event provenance — 모든 event row 에 `writer_role` + `session_id` mandatory | validators/event_provenance.py |
| BRD-038 | Delphi reveal phases — COMMIT(비밀 제출) → REVEAL(동시 공개), groupthink 방지 | kdh-board-delphi-reveal, `events/delphi-phases.jsonl` |
| BRD-039 | Critical L3 parser — R3 HIGH/CRITICAL issue 는 severity + scope + mitigation 3 필드 모두 non-empty | validators/critical_issue.py |
| BRD-040 | Devil's advocate rotation + novelty — 매 라운드 devil advocate 지정, 과거 라운드 재탕 시 novelty FAIL | validators/devil_advocate.py |
| BRD-041 | Exception provenance — dissent/override 시 dissenter 강제 서명 + sig-sha 매칭 | validators/event_provenance.py + `events/override-events.jsonl` |
| BRD-042 | Manifest-bound send — `kdh-board-send` 전에 manifest sha256 == 현재 canonical 파일 sha256 확인, 불일치 시 발송 차단 | kdh-board-send, validators/signature_coverage.py |

## 9. Gate Artifacts

`THE SYSTEM SHALL` require `gates/phase-N-pass.json` to exist with matching checksum before Phase N+1 starts. Schema:
```json
{
  "phase": <int>,
  "phase_name": "<string>",
  "completed_at_utc": "<ISO8601>",
  "plan_id": "<string>",
  "pass_artifacts_sha256": {"<path>": "<sha256>"},
  "validator_run_id": "<string>",
  "validator_result": {"rule_id": "<string>", "status": "pass|warn|fail", "detail": "<string>"},
  "ceo_approvals": [{"decision_utc": "...", "question": "...", "answer": "..."}],
  "next_phase": {"phase": <int+1>, "phase_name": "<string>", "blocker": null|"<reason>"},
  "notes": ["..."]
}
```

## 10. Fallbacks & Aborts

| Trigger | Action |
|---------|--------|
| `/kdh-research` fails (MCP down) | Chairman writes `rounds/R0/round0-fallback-reason.md` + manual corpus collection; ACK gate unchanged |
| `R0-INVALID.flag` exists | `THE SYSTEM SHALL` abort board immediately |
| validator false-negative > 5% fixtures | `THE SYSTEM SHALL` abort Phase 3, re-author failing modules |
| degraded_mode triggered 3 consecutive rounds | `THE SYSTEM SHALL` place board in hold, report to CEO |
| Phase 8 atomic verify fail | `THE SYSTEM SHALL` restore from `.board-archive/{ts}/constitution-backup.tar.gz` |
| Extension-round depth > 3 | `THE SYSTEM SHALL` place board in hold pending CEO decision |

---

*SKILL.md authored 2026-04-18 for v0.5.2. References EARS-normalized BRD spec at `_bmad-output/kdh-plans/0417-board-v2-discussions/topic-1-kdh-board-meeting-howto.EARS-normalized.md`.*
