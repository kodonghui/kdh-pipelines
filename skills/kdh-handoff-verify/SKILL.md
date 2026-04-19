---
name: 'kdh-handoff-verify'
description: 'Topic 4 Stage 3 Validator — checks plan against handoff rejected_options + LESSONS forbid_regex. Activates Sprint N+1. Current Sprint N: stub.'
---

# kdh-handoff-verify (Topic 4 v4.1)

**Status:** Sprint N stub. Activates Sprint N+1.
**Source spec:** `_bmad-output/kdh-plans/0419-topic4-phase-handoff-implementation-v4.md` §3 (N+1-5) + PHX-005.

---

## Purpose (Sprint N+1+)

`kdh-planning-pipeline` Stage 3 (Validate) 실행 시 invoke되어:

1. 현재 plan 내용을 이전 phase handoff의 `rejected_options[]`와 대조.
2. Topic 2 `LESSONS.jsonl`의 `forbid_regex[]`와 대조.
3. 매치 시 validation FAIL — `--override <id> --reason <text>` 없이는 진행 불가.

Stage map 위치:

| Stage | BMAD 역할 | Topic 4 추가 |
|-------|----------|------------|
| 0 | Brief | (none) |
| 1 | Research | (none) |
| 2 | PRD | (none) |
| **3** | **Validate** | **kdh-handoff-verify 실행 (PHX-005)** |
| 4 | Architecture | (none) |
| ... | ... | ... |

**중요:** v4.1 SPEC-1로 "Stage 3 = Validate"로 canonical 정정됨 (이전 "Stage 4" 표기는 오류였음).

---

## Current Behavior (Sprint N)

No-op. Stage 3에서 호출되지 않는다.

---

## Activation Gate (Sprint N+1 entry)

GATE-4 (LESSONS schema freeze), GATE-6 (canonical spec freeze — SPEC-1).

---

## CLI Signature (Sprint N+1 draft)

```bash
kdh-handoff-verify <plan_path> [--phase N] [--override <id> --reason <text>]
```

Exit codes:
- 0 pass
- 1 match found in rejected_options
- 2 match found in forbid_regex
- 3 handoff file missing (degraded — warn only unless --strict)

---

## Dual Gate Partition (C R2)

- Stage -1 (kdh-phase-bridge) = creative/generative — helps author write better Brief.
- Stage 3 (kdh-handoff-verify) = formal/legal — blocks ship if plan ignored prior decisions.

Both are necessary; they address different failure modes (hallucination vs drift).

---

## References

- Plan: `_bmad-output/kdh-plans/0419-topic4-phase-handoff-implementation-v4.md` §3 strict chain N+1-5
- Canonical Stage 3 spec: `reports/0417_korean-ears-spec-table.md` PHX-005
- Correction Notice: `_bmad-output/kdh-plans/0417-board-v2-discussions/topic-4-kdh-skill-phase-handoff.md` (bottom section)
