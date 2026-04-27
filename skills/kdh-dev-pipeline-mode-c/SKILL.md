---
name: kdh-dev-pipeline-mode-c
description: "개발 pipeline Mode C bug-fix loop sub-skill."
status: body-migrated-v1
provenance:
  source: kdh-dev-pipeline SKILL.md (line 598-622)
  extracted_at: 2026-04-26T03:55:00+09:00
  extraction_authority: "CEO 2026-04-26 [03:37] D2 ratify + 본 turn '전부 하라니까네' 자율 진행"
  ratification_link: "_bmad-output/boards/0425-skill-ecosystem-improvement/publish/RATIFIED.token"
  related_sub_skills: [kdh-dev-pipeline-phase-a, kdh-dev-pipeline-phase-b, kdh-dev-pipeline-phase-d, kdh-dev-pipeline-codex, kdh-swarm, kdh-integration]
writer_role: orchestrator
allowed_verdict_scope: integration-only
verdict_owner: kdh-dev-pipeline (wrapper)
oracle_proxy_by_d: blocked
ad_hoc_layer: R-30
---

# kdh-dev-pipeline Mode C — Parallel Story Dev

> 본 sub-skill = wrapper `/kdh-dev-pipeline` 의 호출자. 직접 호출 금지.
> 호출자: `/kdh-dev-pipeline parallel <id1> <id2> [<id3>]` (max 3 workers)
> 분리 근거: board 0425-skill-ecosystem-improvement R-09 spec 후속 + CEO D2 ratify (2026-04-26).

## Mode C: Parallel Story Dev

Usage: `/kdh-dev-pipeline parallel 9-1 9-2 9-3` (max 3 workers)
Requires: stories are independent (no mutual dependencies, different files)

```
Step 0: Project Auto-Scan → load project-context.yaml
Step 1: Read status/dependency info → verify no cross-dependencies
Step 2: For each story (up to 3), in separate Git Worktrees:
  - TeamCreate("{project}-story-{id}")
  - Spawn team: dev, winston, quinn, john
  - Execute Phase A → F (same as Mode B)
Step 3: Collect all results (timeout: 30min per story)
Step 4: Sequential merge (in dependency order):
  - checkout main → merge --no-ff → tsc → commit or revert
Step 5: git push → wait for deploy → report
```

## Worktree Rule

Workers must NOT touch files outside their story scope. Shared files → ESCALATE to Orchestrator.

## Contract & Wiring in Parallel (v9.4)

- **Contract conflict:** if two parallel stories modify contract types → sequential merge + tsc after each
- **Wiring Story:** must be in same parallel batch as parent story (never split across workers)

## D3 Codex 전담 룰 (RATIFIED 2026-04-26 D3)

각 worker team 의 dev = configured Codex CLI / B Codex session / approved Codex wrapper 만 허용. bmad-agent-dev direct Claude impl = blocked. wrapper `/kdh-dev-pipeline` 의 dev_executor contract 와 동일.

## Verdict Ownership

본 sub-skill = orchestrator (Mode C 흐름 관리). verdict 발행 권한 X. 각 worker team 의 verdict (Phase A/B/D PASS) 는 wrapper `/kdh-dev-pipeline` 가 통합 판정. 통합 verdict 단위 = parallel batch (3 stories).

## Integration Review Hand-off

parallel batch 완료 후 자동 `/kdh-integration batch` 호출. wrapper 가 hand-off 책임.

## Output Path

party-logs: `_bmad-output/phase-{N}/party-logs/story-{id}-phase-{phase}-{critic}.md`
parallel batch report: `_bmad-output/phase-{N}/party-logs/batch-parallel-{batch-id}.md`
