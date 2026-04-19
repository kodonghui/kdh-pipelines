---
name: 'kdh-phase-handoff'
description: 'Topic 4 writer skill — emits phase-handoff/{N}.yaml at Phase N exit. Activates Sprint N+1. Current Sprint N: reader-compat stub only.'
---

# kdh-phase-handoff (Topic 4 v4.1)

**Status:** Sprint N reader-compat stub. Writer activates Sprint N+1.
**Owner:** Topic 4 implementation track.
**Source spec:** `_bmad-output/kdh-plans/0419-topic4-phase-handoff-implementation-v4.md` §1, §3 (N+1-2).

---

## Purpose (Sprint N+1+)

Phase N이 종료될 때 두 파일을 원자적으로 기록:

1. `_bmad-output/retro/phase-retro/{N}.md` — 사람용 회고 (PHX-001)
2. `_bmad-output/retro/phase-handoff/{N}.yaml` — 기계 판독용 handoff (PHX-002)

Handoff schema (PHX-002):

```yaml
phase: N
scope_tags: [...]
source_retro: "_bmad-output/retro/phase-retro/{N}.md"
carry_forward:
  constraints: [...]
  rejected_options: [...]
  unresolved: [...]
active_plan_reconciliation:
  stale: [...]
  superseded: [...]
  still_active: [...]
recommended_next_phase_focus: "..."
workspace_snapshot:
  head_sha: "..."
  branch: "..."
  porcelain_status_sorted: "..."
  workspace_integrity_hash: "sha256:..."  # PHX-013
evidence_refs:  # PHX-014
  - plan_id: "..."
    action_id: "..."
    event_jsonl_ref:
      board_root: "..."
      events_path: "events/board-events.jsonl"
      sequence_no: 42  # 0-based line index (v4.1 fixed semantics)
      content_sha256: "..."
      captured_at_utc: "..."
status: DRAFT | RATIFIED   # PHX-006
```

---

## Current Behavior (Sprint N)

이 스킬은 **존재만** 하고 실행되지 않는다. Sprint N+1에 writer 로직이 들어온 뒤에야 Phase exit trigger에서 호출된다.

호출 시 no-op + log:
```
kdh-phase-handoff: Sprint N reader-compat mode — writer not activated. Skipping emit.
```

---

## Activation Gate (Sprint N+1 entry)

- [ ] GATE-1: _index.yaml schema migration atomicity (SPEC-1 자동 검증)
- [ ] GATE-2: flock(2) 환경 지원 확인
- [ ] GATE-4: Topic 2 LESSONS.jsonl schema freeze (40 entries validation)
- [ ] GATE-8: board-events authority path freeze (event_jsonl_ref resolve util)
- [ ] PHX-009 atomic supersession 스크립트 사용 가능 (`scripts/phx-atomic-supersession.sh`)

위 gate 모두 통과하면 이 SKILL.md의 **Sprint N+1 Writer Logic** 섹션이 활성화된다. 활성화 시점에 이 문서는 v2로 patched.

---

## References

- Plan: `_bmad-output/kdh-plans/0419-topic4-phase-handoff-implementation-v4.md`
- Canonical spec reports: `reports/0417_korean-ears-spec-table.md`, `reports/0417_topic-4-kdh-skill-phase-handoff.md`
- Atomic writer: `scripts/phx-atomic-supersession.sh`
- Consumer inventory: `_bmad-output/kdh-plans/consumers.yaml`
