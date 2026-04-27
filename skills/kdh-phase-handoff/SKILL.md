---
name: 'kdh-phase-handoff'
description: "Phase 종료 handoff YAML 작성."
---

# kdh-phase-handoff (Topic 4 v4.1 — Sprint N+1 ACTIVE)

**Status:** Writer active (Sprint N+1).
**Implementation:** `scripts/kdh-phase-handoff.py` in consumer repo (e.g. `~/Desktop/고동희/kdh-conductor/scripts/`).

---

## When to invoke

Phase N이 끝날 때 자동으로 호출된다 (외부 트리거: retro 작성 완료 + 2-of-3 quorum 비준). 사장님이 직접 호출하지 않음.

CLI:
```bash
python3 scripts/kdh-phase-handoff.py \
  --phase N \
  --retro _bmad-output/retro/phase-retro/{N}.md \
  --ratify A B \
  [--author A --planner A]    # PHX-019 single-author collusion check
```

Writes → `_bmad-output/retro/phase-handoff/{N}.yaml`.

---

## Output schema (PHX-002, v4.1)

```yaml
phase: N
scope_tags: [from retro YAML frontmatter]
source_retro: _bmad-output/retro/phase-retro/{N}.md
carry_forward:
  constraints: [...]           # parsed from retro "## Constraints"
  rejected_options: [...]      # parsed from retro "## Rejected options"
  unresolved: [...]            # parsed from retro "## Unresolved" or "## Open questions"
active_plan_reconciliation:
  stale: [{id, title}]         # parsed from retro "## Stale"
  superseded: [{id, title}]    # parsed from retro "## Superseded"
  still_active: [{id, title}]
recommended_next_phase_focus: ""   # planner fills post-generation
workspace_snapshot:
  head_sha: ...                # git rev-parse HEAD
  branch: ...                  # git rev-parse --abbrev-ref HEAD
  porcelain_status_sorted: ... # git status --porcelain sorted
  workspace_integrity_hash: sha256:...   # PHX-013 normalized hash
evidence_refs: []              # populated by PHX-014 follow-up (kdh-phase-bridge + resolve-event-ref)
status: DRAFT | RATIFIED       # DRAFT unless >=2 --ratify args
ratified_by: [A, B]
generated_at_utc: ISO-8601
generator: "kdh-phase-handoff.py (Topic 4 v4.1 Sprint N+1)"
```

---

## Exit codes

- 0 success
- 4 PHX-019 violated (author=planner=A without non-A ratifier)
- 10 PyYAML missing

---

## Author-Planner Collusion defense (PHX-019)

When `--author A --planner A`, the script refuses to write unless `--ratify` contains at least one non-A ratifier. Prevents single-A rubber-stamping.

---

## Pair with

- `kdh-phase-bridge` — Stage -1 reader that consumes this output at the next Phase's planning start.
- `kdh-handoff-verify` — Stage 3 validator that re-checks the plan against `carry_forward.rejected_options[]`.
- `scripts/phx-atomic-supersession.sh` — called separately to atomically commit any resulting `_index.yaml` mutations.
- `scripts/resolve-event-ref.py` — attach evidence_refs entries pointing at BRD-015 events.

---

## References

- Spec: `_bmad-output/kdh-plans/0419-topic4-phase-handoff-implementation-v4.md` §3 N+1-2
- Canonical: `reports/0417_korean-ears-spec-table.md` PHX-001/002/013/019
