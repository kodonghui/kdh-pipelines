---
name: kdh-dev-pipeline-phase-a
description: "kdh-dev-pipeline Phase A sub-skill — Story 정의 단계 (Brief / PRD / Plan). winston + qa_reviewer party-mode (Grade A) 또는 dev_executor solo (Grade C). Wave 3 R-09 modular split, wrapper /kdh-dev-pipeline 가 호출자. 단독 호출보다 wrapper 통한 phase 전환 권장."
status: skeleton-pending-body-migration
wrapper: kdh-dev-pipeline
phase: A
writer_role: dev_executor
allowed_verdict_scope: ["story_create", "phase_a_artifact"]
verdict_owner: dev_executor
oracle_proxy_by_d: blocked
governance:
  alias_resolver: skill-alias-map.yaml
  manifest_audit: scripts/manifest-audit.py
  smoke_harness: scripts/skill-smoke-harness.py
  reporting_invariants: R-24 (UNKNOWN/PASS/FAIL machine-readable)
  rollback_target: kdh-dev-pipeline (legacy monolith governance-patched)
---

# kdh-dev-pipeline Phase A — Story Create

## Status

**SKELETON.** 본 sub-skill 본문 이전 = Wave 3 step 2~5 진행 후 완료. 현재는 wrapper 의 `kdh-dev-pipeline/SKILL.md` Phase A 섹션 (line 434~459) 본문이 권위 source.

## When to Use

- Story 진입 시점 (Sprint N 의 첫 Story 또는 다음 Story)
- Grade A: winston + qa_reviewer 2 critic party-mode (PRD / arch 영향 있는 story)
- Grade C: dev_executor solo (init / complete / 단순 fix)

## Phase A 핵심 책임

1. Story scope 자동 감지 (backend / frontend / fullstack)
2. plan 파일 정독 + Active Plan 의존성 확인
3. PRD-relevant story 면 winston/qa_reviewer party-mode 실행
4. artifact = story-design.md + party-log.md (Grade A) 또는 story-design.md (Grade C)
5. Phase B 진입 전 Codex 전담 룰 (D3) 적용 — 본 sub-skill 은 dev impl 직접 실행 금지

## Delegation Rules

- 본 sub-skill 직접 호출 가능: `/kdh-dev-pipeline phase=a story=<ID>` (advanced)
- 정석 진입: `/kdh-dev-pipeline [sprint N|story-ID|계속]` 의 wrapper 가 자동 호출
- Phase A 완료 후 → wrapper 가 Phase B sub-skill 호출 (현재 = wrapper 본문의 Phase B 섹션)

## Frontmatter Inheritance (R-06)

본 sub-skill = R-06 frontmatter requirement 준수. wrapper + 4 sub-skill 모두 frontmatter 의무.

## Cross-references

- wrapper master: `~/kdh-pipelines/skills/kdh-dev-pipeline/SKILL.md`
- Phase B sub-skill: `kdh-dev-pipeline-phase-b/SKILL.md`
- Phase D sub-skill: `kdh-dev-pipeline-phase-d/SKILL.md`
- Codex sub-skill: `kdh-dev-pipeline-codex/SKILL.md`
- alias resolver SSoT: `~/.claude/skill-alias-map.yaml`

## Migration Status

| step | status | note |
|---|---|---|
| sub-skill 디렉토리 + frontmatter 신설 | ✅ | Wave 3 step 1 (commit 본 turn) |
| 본문 이전 (wrapper line 434~459) | 🗒️ | Wave 3 step 2 (다음 turn) |
| wrapper 의 Phase A 섹션 → reference 로 축약 | 🗒️ | Wave 3 step 3 |
| golden path regression test | 🗒️ | Wave 3 step 4 (R-10) |
| rollback procedure 검증 | 🗒️ | Wave 3 step 5 (R-11) |
