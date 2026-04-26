---
name: kdh-dev-pipeline-phase-b
description: "kdh-dev-pipeline Phase B sub-skill — Implementation 단계. dev_executor (Codex CLI 전담, D3 ratified) 가 story 구현. Direct Claude impl = blocked (D3 rule). Reference Code Search 우선. UI Story Gate (page-design CEO 승인). Wave 3 R-09 modular split."
status: body-migrated-v1
wrapper: kdh-dev-pipeline
phase: B
writer_role: dev_executor
allowed_verdict_scope: ["story_implementation", "phase_b_artifact", "code_diff"]
verdict_owner: dev_executor
oracle_proxy_by_d: blocked
prohibitions:
  - skill_tool_invocation  # CLAUDE.md 명시 PROHIBITION
  - direct_claude_impl     # D3 Codex 전담 룰
governance:
  alias_resolver: skill-alias-map.yaml
  reporting_invariants: R-24
  codex_delegate: kdh-codex-delegate
  rollback_target: kdh-dev-pipeline (legacy monolith governance-patched, git tag 'wave3-step1-baseline')
---

# kdh-dev-pipeline Phase B — Implementation

## Status

**BODY MIGRATED v1.** 본 sub-skill = 권위 source.

## Phase B 본문 (migrated from wrapper line 460~547)

```
Team: dev_executor(Writer), winston, qa_reviewer, john = 4
Reference: _bmad/bmm/workflows/4-implementation/dev-story/checklist.md

1. dev_executor reads story file + DoD checklist
   1b. dev_executor reads API contracts from shared/src/contracts/ →
       import ALL types from contracts (NEVER define inline).
       If needed type missing from contracts: STOP → update contract first
       → tsc → then continue

   === REFERENCE CODE SEARCH (v10.9 — CEO 지시 2026-04-05) ===
   1d. dev_executor searches for reference implementations BEFORE writing new code:
     i.   gh search repos "{story 핵심 기술 키워드}" --sort=stars --limit=5
     ii.  gh search code "{핵심 패턴/함수명}" --limit=10
     iii. npm/PyPI 에서 관련 라이브러리 확인
          (검증된 라이브러리가 80%+ 해결하면 직접 구현 대신 사용)
     iv.  참고 코드 발견 시 → party-log 에 "## Reference Code" 섹션 기록
          (URL + 채택/기각 사유)
     v.   검색 결과 0 건이어도 기록 ("searched: {query}, result: none")
     ★ "먼저 찾아보고, 있으면 검토" — 새로 짜는 건 검색 후 판단
     ★ 기각 시 사유 필수 (라이선스 비호환 / 의존성 과다 / 우리 패턴과 불일치)
     Source routing (ref: kdh-research v3):
     - Library/framework topics → Context7 MCP first, WebSearch second
     - Code implementation patterns → GitHub search first
     - General best practices → WebSearch first
     - Each source 3-question credibility (type, recency, evidence)

   === UI STORY GATE (v11 — 오케스트레이터 주도) ===
   1c. Check: does this story create or modify UI pages? (*.tsx in features/)
       If YES → UI Design Gate:
         i.   오케스트레이터: 프로젝트 UI 컴포넌트 라이브러리 (shadcn/ui 등) 로
              페이지 레이아웃 작성
         ii.  오케스트레이터: ui-design.md 저장 (party-logs/story-{id}-ui-design.md)
         iii. 오케스트레이터: [GATE page-design] → CEO 디자인 승인
         iv.  dev_executor: 승인된 레이아웃 위에 비즈니스 로직 구현
              (API 연결, 폼 검증)
       If NO → skip to step 2

2. dev_executor implements REAL working code (no stubs/mocks/placeholders)
   2b. UI stories: apply active theme from themes.ts, use consistent layout
       from ui-design.md reference

3. Party mode: dev_executor sends [Review Request] with changed files list
   - winston: architecture compliance, contract compliance, 전체 코드베이스
     패턴 일관성 (타입, API 호출 방식, 미들웨어)
   - qa_reviewer: code quality, error handling, test hooks
   - john: acceptance criteria 충족, 사용자 경험 갭, 제품 수준 품질
     (에러 메시지, 상태 유실, UX 흐름)
   - sally: (UI stories only) design matches approved ui-design.md layout
   Critics MUST write to FILE first:
     party-logs/story-{id}-phase-b-{critic-name}.md (v4.4 필수)
     R-32 atomic-write 권장.
   Then SendMessage with file path only. 리뷰 내용은 파일에.
   Critics include D1-D8 scores with rationale per dimension, diff file paths,
   inline code quotes
4. Fix → verify → PASS
5. Save: context-snapshots/stories/{story-id}-phase-b.md
```

## Critical Rules (CLAUDE.md + D3)

- **NEVER use Skill tool from inside Phase B.** PROHIBITION 명시.
- **Direct Claude impl = blocked.** D3 ratified 2026-04-21.
  dev_executor = Codex CLI / kdh-codex-delegate 만.
- **bmad-agent-dev (Amelia) = blocked alias** (skill-alias-map.yaml).
  Direct invoke = error.
- **Codex 매 story 1회 필수** (CLAUDE.md 규칙) — kdh-dev-pipeline-codex sub-skill 가
  Phase B 와 병렬 백그라운드 실행 (Plan v4 최적화).

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
