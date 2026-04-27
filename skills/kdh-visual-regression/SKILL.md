---
name: kdh-visual-regression
description: "테마별 screenshot baseline 비주얼 회귀."
---

# kdh-visual-regression — 비주얼 회귀 테스트


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
- dev-pipeline Phase A.5에서 자동 호출 (UI 스토리)
- bug-fix-pipeline Phase 3 SWEEP에서 자동 호출
- CEO가 수동으로 `/kdh-visual-regression` 실행

## 실행

### 기준선 생성 (첫 실행 또는 의도적 갱신)
```
cd packages/admin && bunx playwright test e2e/visual/ --update-snapshots
```

### 비교 실행 (매 커밋)
```
cd packages/admin && bunx playwright test e2e/visual/
```

### 결과
- PASS: 기준선과 동일 (threshold 0.2% 이내)
- FAIL: diff 이미지 생성 → `_bmad-output/e2e-screenshots/visual-diff/`

### 의도적 변경 시
```
/kdh-visual-regression update
```
→ 현재 화면으로 기준선 갱신

## 테스트 범위
- /login × 5테마
- /dashboard × 5테마 (인증 후)
- /divisions × 5테마 (인증 후)
- /members × 5테마 (인증 후)

## Rules
- threshold: 0.2% (폰트 렌더링 차이 허용)
- 기준선은 git에 커밋 (다른 환경에서도 비교 가능)
- FAIL = 의도적 변경이면 update, 아니면 버그
