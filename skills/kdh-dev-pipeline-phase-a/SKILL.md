---
name: kdh-dev-pipeline-phase-a
description: "개발 pipeline Phase A: story 생성과 critic review."
status: body-migrated-v1
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
  rollback_target: kdh-dev-pipeline (legacy monolith governance-patched, git tag 'wave3-step1-baseline')
---

# kdh-dev-pipeline Phase A — Story Create

## Status

**BODY MIGRATED v1.** 본 sub-skill = 권위 source. wrapper `kdh-dev-pipeline/SKILL.md` 의 Phase A 섹션은 reference 만 남음 (Wave 3 step 3 축약 결과).

## Phase A 본문 (migrated from wrapper line 434~459)

```
Team: dev_executor(Writer), winston, qa_reviewer, john = 4
Reference: _bmad/bmm/workflows/4-implementation/create-story/checklist.md

1. dev_executor reads story requirements from epics file
2. dev_executor reads create-story checklist and template
3. dev_executor writes story file following template
4. Party mode: dev_executor sends [Review Request] → winston/qa_reviewer/john review
   - winston: architecture alignment, file structure
   - qa_reviewer: testability, edge cases, acceptance criteria completeness
   - john: product requirements coverage, user value
   EARS + Gherkin (v9.4):
   - Story "Requirements" section: EARS syntax (WHEN/THE SYSTEM SHALL/IF THEN)
   - Story "Acceptance Criteria" section: Gherkin (Given/When/Then)
   - qa_reviewer validates: each EARS requirement has corresponding Gherkin AC
   UI Existence Check (v10.2):
   - qa_reviewer MUST verify: 본 스토리가 참조하는 UI 요소 (버튼/페이지/폼) 가
     다른 스토리 또는 UX 스펙에 정의되어 있는가?
   - 예: Story 1-3 가 "로그아웃 클릭" 참조 → 로그아웃 버튼이 어떤 스토리/UX 에
     정의됐는지 확인. 미정의 시 본 스토리에 "해당 UI 생성" 태스크 추가 OR
     선행 스토리 dependency 명시.
   - 빈 참조 = auto-FAIL ("UI element not defined anywhere")
5. Fix → verify → PASS (avg ≥ 3.0/5)
6. Save: context-snapshots/stories/{story-id}-phase-a.md
   (R-32 atomic-write 권장: scripts/atomic-write.py --target ... --lock-key ...)
```

## Alias Note (R-22)

본 본문의 `qa_reviewer` reference = `skill-alias-map.yaml` 의 `quinn (QA)` alias 의 target. legacy 호출자가 "quinn QA" 로 들어와도 R-22 alias resolver 가 본 sub-skill 의 qa_reviewer role 로 redirect.

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
