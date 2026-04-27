---
name: kdh-dev-pipeline-phase-d
description: "개발 pipeline Phase D: test/QA/cross-model 검증."
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

**BODY MIGRATED v1.** 본 sub-skill = 권위 source.

## Phase D 본문 (migrated from wrapper line 548~590)

```
Team: qa_reviewer(Writer), dev_executor(Critic), winston(Critic), john(Critic) = 4
       UI stories: +sally(Critic) = 5
Reference: TEA risk-based test strategy + QA acceptance checklist

Phase D = 기존 Phase D (테스트 작성) + Phase E (QA 검증) 통합 (v10.1).
qa_reviewer 가 Writer 로 테스트 작성 + AC 검증을 한 Phase 에서 수행.
sally (UI stories only): 상호작용 흐름 자연스러움, 접근성, UX 시나리오 커버리지.
john=요구사항 충족, sally=UX 품질 (비중복).

오케스트레이터 MUST (v11.0):
  1. qa_reviewer 를 Writer 로 Agent 소환
  2. dev_executor, winston, john 을 Critic 으로 Agent 소환 (3 명 전부)
  3. qa_reviewer 작업 완료 후 SendMessage [Review Request] 를 3 명에게 전송
  4. Critic 3 명의 로그 파일 존재 확인 후에만 PASS
  ★ pre-commit hook 이 phase-d-winston.md, phase-d-qa_reviewer.md 검증
  ★ critic 로그 없으면 커밋 차단

1. qa_reviewer designs test strategy based on story requirements
2. qa_reviewer writes tests (unit + integration + E2E as needed)
   EARS-Driven Test Scaffolding (v9.4):
   2b. qa_reviewer parses EARS keywords from story requirements →
       generates test scaffold:
      - THE SYSTEM SHALL → unit test (verify behavior exists)
      - WHEN [trigger] → integration test (trigger event → assert response)
      - WHILE [condition] → state test (set condition → verify continuous)
      - IF [bad condition] → negative test (inject bad state → assert graceful)
      - WHERE [feature] → conditional test (enable/disable → verify both paths)
   Integration Verification (v9.4):
   2c. For wiring stories: import chain test + initialization test +
       data flow test
   2d. For stories that CREATE something: at least 1 integration smoke test
3. qa_reviewer runs QA checklist against implemented code
4. qa_reviewer verifies ALL acceptance criteria from story file
5. Party mode: qa_reviewer sends [Review Request] to dev_executor, winston, john
   BY NAME
   - dev_executor: implementability, test framework compliance, code completeness
   - winston: architecture test coverage, boundary tests
   - john: acceptance criteria met? user value delivered? 제품 수준 검증
   Critics MUST write to FILE first:
     party-logs/story-{id}-phase-d-{critic-name}.md (v4.4 필수)
     R-32 atomic-write 권장.
   Then SendMessage with file path only. 리뷰 내용은 파일에.
   Critics include D1-D8 scores with rationale per dimension, diff file paths,
   inline code quotes
6. Fix → verify → PASS
7. Run all tests — must pass
8. Save: context-snapshots/stories/{story-id}-phase-d.md
```

## Cross-Model Verification (Phase D 후, migrated from wrapper line 592~613)

```
Phase D PASS 후 실행. 에이전트 소환 불필요 — 오케스트레이터 직접 실행.
codex-review.sh 가 Codex (GPT-5.4) + Gemini (3.1 Pro) 병렬 실행.

1. 스토리 diff 준비:
   git diff HEAD~1 -- packages/ > /tmp/story-diff.patch

2. Cross-Model 실행:
   bash ~/.claude/scripts/codex-review.sh /tmp/story-diff.patch \
     "이 코드를 리뷰해라. 버그, 보안 문제, 타입 오류를 찾아라."

3. 판정 (v11.0):
   - 둘 다 FAIL → 자동 진행 금지, 수정 후 재실행 PASS 까지 반복 (횟수 제한 없음)
   - 하나만 FAIL + 다른 쪽 치명 이슈 없음 → CEO 판단
   - Context-irrelevant findings 자가 skip 가능 (사유 기록)
   - 기존 "max 1회 재실행" 규칙 폐기 (v11.0 2026-04-10 CEO 승인)

★ 둘 다 FAIL = 자동 진행 금지 (계속 모드에서도)
★ Codex (GPT-5.4) + Gemini (3.1 Pro) 병렬 실행
```

## Alias Note (R-22)

본 본문의 모든 `qa_reviewer` reference = `skill-alias-map.yaml` 의 `quinn (QA)` alias 의 target. legacy 호출자 (e.g. v10 이전 본문) 가 "quinn" 로 들어와도 R-22 alias resolver 가 본 sub-skill 의 qa_reviewer role 로 redirect.

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
