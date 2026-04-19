---
name: 'kdh-phase-bridge'
description: 'Topic 4 Sprint N+1 Stage -1 reader — injects prior phase handoff into Stage 0 Brief via Context Block.'
---

# kdh-phase-bridge (Topic 4 v4.1 — Sprint N+1 ACTIVE)

**Status:** Reader active (Sprint N+1).
**Implementation:** `scripts/kdh-phase-bridge.py` in consumer repo.

---

## When to invoke

`kdh-planning-pipeline` Stage 0 (Brief) 진입 **이전**에 자동 호출. 파이프라인이 알아서 실행.

CLI:
```bash
python3 scripts/kdh-phase-bridge.py \
  --target-phase N \
  [--lessons _bmad-output/LESSONS.jsonl]
```

Emits Context Block to stdout → planning-pipeline이 이 출력을 Stage 0 Brief 프롬프트 앞에 prepend.

---

## Inputs (priority order)

1. `_bmad-output/retro/phase-handoff/{N-1}.yaml` — primary RATIFIED or DRAFT handoff.
2. `_bmad-output/retro/handoff-buffer.tmp` — fallback (PHX-015):
   - Accepted only if `parent_commit_sha` is an ancestor of current HEAD.
   - Rejected (and logged) if diverged >2 commits or not ancestor.
   - Log → `_bmad-output/events/handoff-buffer-rejected.jsonl`.
3. Neither → degraded path (Context Block empty; Stage 0 proceeds without carried context).

---

## Output format

```
========================================================================
CRITICAL: CONTEXT CARRIED OVER. DO NOT RE-LITIGATE.
========================================================================
Target phase: N
Bridge timestamp (UTC): ISO-8601

Source: <path>
Handoff status: RATIFIED | DRAFT [| DEGRADED buffer fallback]

## Constraints carried forward
- ...

## Rejected options (DO NOT propose again)
- ...

## Unresolved from prior phase
- ...

## Superseded plans (closed at handoff)
- ...

## Stale plans (candidates for close)
- ...

## Recommended focus for next phase
...

## Applicable LESSONS (N entries)
- ...

## Adversarial stale detector (PHX-020)
- [Suspected Stale] <plan_id> — last_referenced 35d ago
  Author MUST defend each plan or close it.

========================================================================
END OF CONTEXT CARRIED OVER. Do not re-litigate items above.
========================================================================
```

---

## Adversarial stale detection (PHX-020)

Independent of handoff content, bridge inspects `_index.yaml` for plans whose `last_referenced_at_utc`:
- `>60d` → Force renewal
- `>30d` → Suspected Stale

Both are flagged in the Context Block; author must defend or close.

Plans missing `last_referenced_at_utc` are NOT auto-flagged (conservative — calibration is still Sprint N+2 concern).

---

## Dual Gate Partition (C R2)

- Stage -1 (this skill) = creative/generative — helps author write better Brief.
- Stage 3 (kdh-handoff-verify) = formal/legal — blocks ship if plan ignored prior decisions.

Both are necessary; they address different failure modes.

---

## References

- Spec: `_bmad-output/kdh-plans/0419-topic4-phase-handoff-implementation-v4.md` §3 N+1-3
- Canonical: `reports/0417_korean-ears-spec-table.md` PHX-004/006/015/020/021
