---
name: 'kdh-handoff-verify'
description: "Phase handoff validator: rejected option/LESSONS 위반 차단."
---

# kdh-handoff-verify (Topic 4 v4.1 — Sprint N+1 ACTIVE)

**Status:** Validator active (Sprint N+1).
**Implementation:** `scripts/kdh-handoff-verify.py` in consumer repo.

---

## When to invoke

`kdh-planning-pipeline` Stage 3 (Validate)에서 자동 호출. Plan 작성 완료 후, Architecture 진입 전 gate.

CLI:
```bash
python3 scripts/kdh-handoff-verify.py <plan_path> \
  [--phase N]                       # pick handoff from phase (N-1).yaml
  [--lessons _bmad-output/LESSONS.jsonl]
  [--override CEO-001 --reason "authorized by CEO 2026-04-19"]
  [--strict]                        # exit 3 if handoff missing (default: warn)
```

---

## Exit codes

- 0 PASS (clean OR override accepted)
- 1 FAIL — plan re-proposes a `carry_forward.rejected_options[]` entry (substring match, case-insensitive)
- 2 FAIL — plan matches a `LESSONS.jsonl` `forbid_regex[]` pattern
- 3 FAIL — handoff missing AND `--strict` set
- 10 dependency error (PyYAML missing)

---

## Override protocol

Only CEO can override. Required:
```bash
--override <issue-id> --reason "<text>"
```

Override is logged to stderr with both fields. Without `--reason`, the script refuses.

---

## Validation logic

1. Load handoff (either `--phase N-1` explicit, or newest `{N}.yaml` if unspecified).
2. Extract `carry_forward.rejected_options[]`.
3. For each rejected option string, substring-search the plan text (case-insensitive).
4. Any hit → print location (line number) + FAIL exit 1.
5. For each LESSONS entry, compile `forbid_regex[]` and search plan text.
6. Any hit → print line number + matched snippet + FAIL exit 2.
7. No hits → PASS.

---

## Dual Gate Partition (C R2)

See `kdh-phase-bridge` SKILL.md. This skill = formal/legal gate.

---

## Example output

```
# clean plan
$ python3 scripts/kdh-handoff-verify.py plan.md --phase 4
kdh-handoff-verify: PASS

# plan re-proposes rejected option
$ python3 scripts/kdh-handoff-verify.py plan.md --phase 4
FAIL — plan re-proposes rejected options:
  - 'Mem0 library' @ line ~42
exit 1

# override
$ python3 scripts/kdh-handoff-verify.py plan.md --phase 4 --override CEO-001 --reason "rationale change"
OVERRIDE ACCEPTED id=CEO-001 reason='rationale change'. Rejected hits: 1, Forbid hits: 0.
kdh-handoff-verify: OVERRIDE PASS (id=CEO-001)
exit 0
```

---

## References

- Spec: `_bmad-output/kdh-plans/0419-topic4-phase-handoff-implementation-v4.md` §3 N+1-5
- Canonical: `reports/0417_korean-ears-spec-table.md` PHX-005
