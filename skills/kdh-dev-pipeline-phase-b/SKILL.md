---
name: kdh-dev-pipeline-phase-b
description: "kdh-dev-pipeline Phase B sub-skill — Implementation 단계. dev_executor (Codex CLI 전담, D3 ratified) 가 story 구현. Direct Claude impl = blocked (D3 rule). Wave 3 R-09 modular split, wrapper /kdh-dev-pipeline 가 호출자. Skill tool 호출 금지 (PROHIBITION 유지)."
status: skeleton-pending-body-migration
wrapper: kdh-dev-pipeline
phase: B
writer_role: dev_executor
allowed_verdict_scope: ["story_implementation", "phase_b_artifact", "code_diff"]
verdict_owner: dev_executor
oracle_proxy_by_d: blocked
prohibitions:
  - skill_tool_invocation  # CLAUDE.md 명시 PROHIBITION 유지
  - direct_claude_impl     # D3 Codex 전담 룰
governance:
  alias_resolver: skill-alias-map.yaml
  reporting_invariants: R-24
  codex_delegate: kdh-codex-delegate
  rollback_target: kdh-dev-pipeline (legacy monolith governance-patched)
---

# kdh-dev-pipeline Phase B — Implementation

## Status

**SKELETON.** 본 sub-skill 본문 이전 = Wave 3 step 2~5 후 완료. 현재 권위 source = wrapper `kdh-dev-pipeline/SKILL.md` Phase B 섹션 (line 460~547).

## When to Use

- Phase A 완료 후, wrapper 가 자동 진입
- Grade A: winston + qa_reviewer 2 critic party-mode 후 Codex impl
- Grade C: dev_executor solo

## Phase B 핵심 책임

1. Phase A artifact (story-design.md) 정독
2. Codex CLI 호출 (`codex exec --full-auto` 또는 kdh-codex-delegate skill)
3. 구현 PR 또는 commit 작성
4. tsc / biome / test green 자동 게이트
5. artifact = code diff + commit hash + party-log.md
6. Phase D 진입 전 Codex review (kdh-dev-pipeline-codex sub-skill)

## Critical Rules (CLAUDE.md + D3)

- **NEVER use Skill tool from inside Phase B.** PROHIBITION 명시.
- **Direct Claude impl = blocked.** D3 ratified 2026-04-21. dev_executor = Codex CLI / kdh-codex-delegate 만.
- **bmad-agent-dev (Amelia) = blocked alias** (skill-alias-map.yaml 참조). Direct invoke = error.
- **Codex 매 스토리 1회 필수** (CLAUDE.md 규칙).

## Delegation

- 본 sub-skill 직접 호출 가능: `/kdh-dev-pipeline phase=b story=<ID>` (advanced)
- 정석: wrapper 가 Phase A 완료 후 자동 호출

## Migration Status

| step | status |
|---|---|
| sub-skill 디렉토리 + frontmatter 신설 | ✅ Wave 3 step 1 |
| 본문 이전 (wrapper line 460~547) | 🗒️ Wave 3 step 2 |
| wrapper Phase B 섹션 → reference 축약 | 🗒️ Wave 3 step 3 |
| golden path regression | 🗒️ Wave 3 step 4 (R-10) |
| rollback 검증 | 🗒️ Wave 3 step 5 (R-11) |
