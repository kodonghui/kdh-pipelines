---
name: kdh-dev-pipeline-codex
description: "개발 pipeline Codex review 전용 sub-skill."
status: skeleton-pending-body-migration
wrapper: kdh-dev-pipeline
phase: codex_review
writer_role: dev_executor  # Codex CLI 호출자
review_owner: codex_external
allowed_verdict_scope: ["codex_review_verdict", "phase_codex_artifact"]
verdict_owner: codex_external
oracle_proxy_by_d: blocked
governance:
  alias_resolver: skill-alias-map.yaml
  reporting_invariants: R-24
  external_script: ~/.claude/scripts/codex-review.sh
  invocation_pattern: bash run_in_background  # Phase D Cross-model 과 다름
  rollback_target: kdh-dev-pipeline (legacy monolith governance-patched)
---

# kdh-dev-pipeline Codex Review — 매 Story 1회 필수

## Status

**BODY MIGRATED v1.** 본 sub-skill = 권위 source.

## Codex 호출 본문 (migrated from wrapper line 33~60 + 596~614)

```
Codex 매 story 1회 필수 (CLAUDE.md 명시 룰).

호출 패턴 (v11.0 + Plan v4 백그라운드 병렬):
  1. 스토리 diff 준비:
     git diff HEAD~1 -- packages/ > /tmp/story-diff.patch

  2. codex-review.sh 호출:
     bash ~/.claude/scripts/codex-review.sh /tmp/story-diff.patch \
       /tmp/codex-result.md /tmp/gemini-result.md
     # Bash run_in_background: true (Plan v4 — Phase B party-mode 와 병렬)

  3. 결과 수집 = Phase B party-mode 완료 후 결과 파일 read
     codex-review.sh 가 Codex (GPT-5.4) + Gemini (3.1 Pro) 병렬 실행

  4. Plan v4 빈도 조정 (CEO 승인):
     - Codex = 매 story 필수
     - Gemini = 3 story 마다 1회 + Sprint End 전수
     이유: 비용 절감 + Codex 로 안전장치 유지

  5. 판정 (v11.0):
     - 둘 다 FAIL → 자동 진행 금지, 수정 후 재실행 PASS 까지 반복 (횟수 제한 없음)
     - 하나만 FAIL + 다른 쪽 치명 이슈 없음 → CEO 판단
     - Context-irrelevant findings 자가 skip 가능 (사유 기록)
```

## Phase D Cross-model 과 차이

| 구분 | Phase D Cross-model (kdh-dev-pipeline-phase-d) | Codex sub-skill (본 sub-skill) |
|---|---|---|
| 실행 시점 | Phase D PASS **후** | Phase B 와 **동시** 백그라운드 |
| Owner | qa_reviewer 가 결과 통합 후 verdict | codex_external = second opinion |
| Script | 동일 codex-review.sh | 동일 codex-review.sh |
| Plan v4 빈도 조정 | Codex 매 story + Gemini 3 story 1회 | 동일 |

## R-24 Reporting Invariants 준수

- Verdict = PASS / FAIL / UNKNOWN (silent VALID 금지)
- Report = exact command + exit code + skipped reasons + verdict owner = codex_external
- artifact = research-cache/{story-slug}-codex-score.md (R-15 reporting 형식)
- R-32 atomic-write 권장: scripts/atomic-write.py 통한 결과 저장

## Failure Handling

- Codex 세션 미가용 → research-cache/{slug}-codex-score.md 에
  "unavailable: <reason>" 기록. 보고서 자체 유효.
- FAIL → 자동 진행 금지 (Phase D Cross-model 과 동일 규칙).

## Phase D vs Codex sub-skill 차이

| 구분 | Phase D (kdh-dev-pipeline-phase-d) | Codex (본 sub-skill) |
|---|---|---|
| Owner | qa_reviewer (testability + 보안) | codex_external (second opinion) |
| 호출 | wrapper 가 Phase B 완료 후 자동 | wrapper 가 Phase B 와 병렬 (Plan v4 최적화) |
| Script | codex-review.sh (Cross-model 병렬) | codex-review.sh + Gemini 동일 |
| 빈도 | 매 story 1회 | 매 story 1회 (CLAUDE.md 필수) + Sprint End 전수 |

## When to Use

- 매 story 1회 (CLAUDE.md 명시 필수 룰)
- Phase B (party-mode winston+qa_reviewer) 와 **동시** 백그라운드 (Plan v4 최적화 → 40% 시간 절감)
- Sprint End 전수 review

## Codex 호출 절차

```bash
bash ~/.claude/scripts/codex-review.sh /tmp/story-review.md \
  /tmp/codex-result.md /tmp/gemini-result.md
# Bash run_in_background: true
```

- 결과 수집 = Phase B party-mode 완료 후 결과 파일 read
- Codex (GPT-5.4) + Gemini (3.1 Pro) 병렬
- Gemini 빈도 (Plan v4) = 3 story 마다 1회 + Sprint End 전수

## R-24 Reporting Invariants

- Verdict = PASS / FAIL / UNKNOWN
- Report = exact command + exit code + skipped reasons + verdict owner = codex_external
- artifact = research-cache/{story-slug}-codex-score.md (R-15 reporting 형식)

## Failure Handling

- Codex 세션 미가용 → research-cache 에 "unavailable: <reason>" 기록. 보고서 자체 유효.
- FAIL → 자동 진행 금지 (Phase D Cross-model 과 동일 규칙).

## Delegation

- 본 sub-skill 직접 호출: `/kdh-dev-pipeline phase=codex story=<ID>` (advanced)
- 정석: wrapper 가 Phase B 시작 시 백그라운드 호출

## Migration Status

| step | status |
|---|---|
| sub-skill 디렉토리 + frontmatter | ✅ Wave 3 step 1 |
| 본문 이전 (wrapper line 33~60, 596~614) | 🗒️ Wave 3 step 2 |
| wrapper Codex 섹션 → reference 축약 | 🗒️ Wave 3 step 3 |
| golden path regression | 🗒️ Wave 3 step 4 (R-10) |
| rollback 검증 | 🗒️ Wave 3 step 5 (R-11) |
