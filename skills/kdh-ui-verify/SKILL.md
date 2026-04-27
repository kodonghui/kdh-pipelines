---
name: kdh-ui-verify
description: "UI 전수 E2E와 테마별 스크린샷 검증."
---

# UI Verification


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

## UI Verification (triggered when UI files changed)

### Detection
UI files changed = any modified/added file matching:
- `**/*.tsx`, `**/*.jsx`, `**/*.vue`, `**/*.svelte`
- `**/*.css`, `**/*.scss`, `**/*.less`
- `**/*.html` (in src/ or app/ directories)
- Route/page config files

### Full Interaction E2E

```
Step 1: Start dev server (dev_command from project-context.yaml, 60s timeout)
Step 2: Identify changed pages (git diff → filter UI → map to routes)
Step 3: Playwright screenshot of ALL changed pages
Step 4: Full interaction E2E on each changed page:
  a. Every button: click → verify no crash + expected response
  b. Every input: type test data → verify value + validation
  c. Every form: fill + submit → verify success/error states
  d. Every dropdown: open → verify options → select → verify
  e. CRUD operations (if applicable): create → read → update → delete
  f. Console errors: capture all, filter benign, fail on unexpected
Step 5: Theme consistency check (design tokens match app shell)
Step 6: Router import check (all lazy-loaded routes resolve)
Step 7: Stop dev server
```

If Playwright not configured → skip automated E2E, still run router + console checks.
