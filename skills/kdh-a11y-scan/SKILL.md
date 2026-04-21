# kdh-a11y-scan — 접근성 전수 스캔


## v2 Claude Design Integration (2026-04-21)

> `/kdh-corthex-design` skill 필수 호출 + 3 테마 + mypqjitg/ndpk SSoT + sally verdict-only. Reference: `_bmad-output/audit/2026-04-21-kdh-skills-claude-design-audit-v2.md`

- **Invoke `/kdh-corthex-design`** before any UI decision — returns brand checklist + tokens + preview paths + `ui_kits/console` pointers.
- **SSoT paths** (replaces `DESIGN.md` content):
  - React pages: `_bmad-output/ui-rebuild/claude-design-generate-result/2026-04-21-mypqjitg/project/reskin-react/src/routes/<Page>.tsx`
  - Design system: `_bmad-output/ui-rebuild/claude-design-generate-result/2026-04-21-ndpk/project/` (`colors_and_type.css` + `preview/` + `ui_kits/console/`)
  - Shared CSS: `packages/ui/src/styles/colors_and_type.css` (import via `@corthex/ui/styles/colors_and_type.css`)
- **3 themes only**: Paper (default light) / Carbon (dark) / Signal (burnt-sienna accent). Selector = `[data-theme="paper|carbon|signal"]` on `<html>`. Retired theme names **forbidden**: `theme-brand` / `theme-green` / `theme-toss-light` / `theme-toss-dark` / `theme-cherry-blossom`.
- **sally role** = verdict verifier only (visual drift vs mypqjitg). Sally authoring (Operator's Atelier / 9-section UX spec) is treated as FAIL → fresh-agent re-review.
- **DESIGN.md** = 26-line stub (CEO SKIPPED restore, 2026-04-21 T1-5). Do not read content; dereference to `/kdh-corthex-design` skill.
- **corthex-design-system artifacts** = CEO-owned. No direct edits by Claude. Use `_bmad-output/design-requests/YYYY-MM-DD-<slug>.md` with ready-to-paste English prompt block (5 sections: Context / Constraint / Ask / Target file / Acceptance).

## When to Use
- dev-pipeline Phase D 완료 후 자동 호출
- bug-fix-pipeline Phase 3에서 자동 호출
- CEO가 수동으로 `/kdh-a11y-scan` 실행

## 실행

```
cd packages/admin && bunx playwright test e2e/design-check.spec.ts -g "D7-3"
```

또는 전체 라우트 스캔:

```
1. 모든 라우트 × 5테마에 대해 axe-core 실행
2. 위반 건수 + 심각도 리포트 생성
3. critical/serious → FAIL
4. moderate/minor → 경고 (차단 안 함)
```

## 결과
```
_bmad-output/a11y/
├── a11y-report-{date}.md     # 전체 리포트
└── violations-{theme}.json   # 테마별 위반 목록
```

## WCAG AA 기준
- 텍스트 contrast ratio ≥ 4.5:1 (일반)
- 대형 텍스트 contrast ratio ≥ 3:1
- UI 컴포넌트 contrast ratio ≥ 3:1

## Rules
- 5테마 전부 검사 (특히 toss-dark)
- critical/serious = FAIL (커밋 차단)
- moderate/minor = 경고 (기록만)
- axe-core 오탐은 `axe-exclude.json`으로 관리
