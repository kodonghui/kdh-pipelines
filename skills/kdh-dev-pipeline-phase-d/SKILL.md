---
name: kdh-dev-pipeline-phase-d
description: "kdh-dev-pipeline Phase D sub-skill — Test + QA 단계 (Phase E 통합). qa_reviewer 가 testability + edge case + 보안 검증. Cross-model verification (Codex + Gemini 병렬, codex-review.sh) 강제. Wave 3 R-09 modular split."
status: skeleton-pending-body-migration
wrapper: kdh-dev-pipeline
phase: D
writer_role: qa_reviewer
allowed_verdict_scope: ["qa_verdict", "test_coverage", "phase_d_artifact"]
verdict_owner: qa_reviewer
oracle_proxy_by_d: blocked
governance:
  alias_resolver: skill-alias-map.yaml
  reporting_invariants: R-24 (UNKNOWN/PASS/FAIL machine-readable)
  cross_model_required: true  # Codex + Gemini 병렬 (codex-review.sh)
  cross_model_pass_repeat: unlimited  # v11.0 — PASS까지 무제한 반복
  rollback_target: kdh-dev-pipeline (legacy monolith governance-patched)
---

# kdh-dev-pipeline Phase D — Test + QA

## Status

**SKELETON.** 본 sub-skill 본문 이전 = Wave 3 step 2~5 후 완료. 현재 권위 source = wrapper `kdh-dev-pipeline/SKILL.md` Phase D 섹션 (line 548~614) + Cross-model verification (line 1005~1046).

## When to Use

- Phase B 완료 (구현 + tsc/biome/test green) 후 wrapper 가 자동 진입
- 매 story 마지막 phase

## Phase D 핵심 책임

1. Phase B artifact (code diff + party-log) 정독
2. testability 검증 (qa_reviewer = quinn QA alias resolved)
3. edge case + 보안 검증
4. EARS 요구사항 매칭
5. **Cross-model verification 강제 (Phase D 후)** — `~/.claude/scripts/codex-review.sh` Codex + Gemini 병렬 실행
6. 둘 다 FAIL → 자동 진행 금지, 수정 후 재실행 PASS까지 반복 (v11.0)
7. artifact = qa-review.md + cross-model-review.md + party-log.md

## Cross-Model Verification (필수)

```bash
bash ~/.claude/scripts/codex-review.sh /tmp/story-review.md \
  /tmp/codex-result.md /tmp/gemini-result.md
```

- Codex (GPT-5.4) + Gemini (3.1 Pro) 병렬
- 둘 다 FAIL → 자동 진행 금지
- 하나만 FAIL + 다른 쪽 치명 이슈 없음 → CEO 판단
- Context-irrelevant findings 자가 skip 가능 (사유 기록)
- 횟수 제한 없음 (v11.0 2026-04-10 CEO 승인)

## R-24 Reporting Invariants 준수

- Verdict = PASS / FAIL / UNKNOWN (silent VALID 금지)
- Report = exact command + exit code + skipped steps + final verdict owner
- UNKNOWN count + ORACLE WARNING 블록 강제

## Delegation

- 본 sub-skill 직접 호출: `/kdh-dev-pipeline phase=d story=<ID>` (advanced)
- 정석: wrapper 가 Phase B 완료 후 자동 호출

## Migration Status

| step | status |
|---|---|
| sub-skill 디렉토리 + frontmatter | ✅ Wave 3 step 1 |
| 본문 이전 (wrapper line 548~614 + 1005~1046) | 🗒️ Wave 3 step 2 |
| wrapper Phase D 섹션 → reference 축약 | 🗒️ Wave 3 step 3 |
| golden path regression | 🗒️ Wave 3 step 4 (R-10) |
| rollback 검증 | 🗒️ Wave 3 step 5 (R-11) |
