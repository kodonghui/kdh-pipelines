---
name: 'kdh-phase-bridge'
description: 'Topic 4 Stage -1 bridge — injects prior phase handoff into Stage 0 Brief. Activates Sprint N+1. Current Sprint N: stub.'
---

# kdh-phase-bridge (Topic 4 v4.1)

**Status:** Sprint N stub. Activates Sprint N+1.
**Source spec:** `_bmad-output/kdh-plans/0419-topic4-phase-handoff-implementation-v4.md` §3 (N+1-3).

---

## Purpose (Sprint N+1+)

`kdh-planning-pipeline` Stage 0 (Brief) 진입 **이전**에 invoke되어 다음을 수행:

1. 이전 phase의 `phase-handoff/{N-1}.yaml` 읽기 (PHX-004).
2. 매칭되는 미해결 carry-forward 읽기 (PHX-004).
3. Topic 2 `LESSONS.jsonl` 필터링 (applies_to_repos + scope_tags 매치, PHX-004).
4. Step 0.5 active-plan list와 reconcile하여 stale_plan_ids 즉시 close (quorum 조건 PHX-019 + PHX-010 reopen으로 recover).
5. Context Block 생성 — 헤더: `CRITICAL: CONTEXT CARRIED OVER. DO NOT RE-LITIGATE.`
6. Context Block을 Stage 0 프롬프트 앞에 prepend.
7. Adversarial stale detector: 독립적으로 `kdh-help` 호출하여 PHX-016 stale criteria 매치 plan에 "Suspected Stale" flag (PHX-020).

Handoff 부재 시 `handoff-buffer.tmp` fallback (PHX-015): `parent_commit_sha`가 현재 HEAD의 ancestor인지 검증, divergent면 reject as Untrusted/Divergent 후 `events/handoff-buffer-rejected.jsonl` log.

---

## Current Behavior (Sprint N)

No-op. Stage -1이 호출되지 않는다. kdh-planning-pipeline SKILL.md가 Sprint N에서는 Stage 0 바로 진입.

---

## Activation Gate (Sprint N+1 entry)

kdh-phase-handoff writer와 동일 GATE-1/2/4/8 통과 필요.

---

## Why A-Author-Planner Collusion Defense Matters

PHX-019 + PHX-020 없이 Stage -1만 있으면 A=author+planner가 stale_plan_id를 "legitimate carry-forward"로 리마크하는 우회 가능. Bridge는 handoff reader + adversarial detector **이중역할**이다.

---

## References

- Plan: `_bmad-output/kdh-plans/0419-topic4-phase-handoff-implementation-v4.md` §3 strict chain N+1-3
- Handoff writer: `~/kdh-pipelines/skills/kdh-phase-handoff/SKILL.md`
- Planning pipeline hook point: `~/kdh-pipelines/skills/kdh-planning-pipeline/SKILL.md` (Step -1 섹션)
