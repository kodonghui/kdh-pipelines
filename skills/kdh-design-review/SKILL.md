# kdh-design-review — 디자인 품질 검증


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
- UI 스토리 완료 후 디자인 품질 확인
- dev-pipeline Phase A.5에서 자동 호출
- CEO가 수동으로 `/kdh-design-review` 실행

## 실행

1. **체크리스트 실행**
   ```
   cd packages/admin && bunx playwright test e2e/design-check.spec.ts --reporter=list
   ```
   → D7-1~D7-8 항목별 PASS/FAIL 확인

2. **5테마 스크린샷 촬영**
   ```
   cd packages/admin && bunx playwright test e2e/visual/visual-regression.spec.ts --reporter=list
   ```
   → 5테마 × 해당 페이지 스크린샷 `_bmad-output/design-review/`에 저장

3. **벤치마크 참조 비교**
   - `_design-ref/{page-type}/` 에서 참조 이미지 설명 읽기
   - 촬영된 스크린샷과 참조 설명을 비교
   - 구조적 유사도 (레이아웃, 색감 톤, 타이포 위계) 평가

4. **결과 리포트**
   ```
   _bmad-output/design-review/
   ├── checklist-result.md    # 항목별 PASS/FAIL
   ├── {page}-{theme}.png     # 스크린샷
   └── benchmark-comparison.md # 참조 비교 결과
   ```

5. **판정**
   - 체크리스트 전체 PASS + 벤치마크 유사도 OK → PASS
   - FAIL 항목 있으면 → 수정 가이드 출력 (최대 2회 재수정)
   - 2회 후에도 FAIL → 항목 기록 + 다음 Phase 진행 (차단 안 함)

## 체크리스트 9항목

| # | 항목 | 자동 검증 |
|---|------|----------|
| D7-1 | 타이포그래피 위계 | Playwright computed style |
| D7-2 | Spacing rhythm (8px grid) | Playwright computed padding/margin |
| D7-3 | Color contrast WCAG AA | axe-core (5테마) |
| D7-4 | 버튼 배경색 + hover + disabled | Playwright button style |
| D7-5 | 입력란 테마별 배경 + 포커스 링 | Playwright input style |
| D7-6 | 카드 깊이감 (shadow/border) | Playwright computed box-shadow |
| D7-7 | 정보 밀도 (빈 공간 <50%) | Playwright content area ratio |
| D7-8 | 상태 컴포넌트 존재 | 코드 Grep |
| D7-9 | 벤치마크 유사도 | Party Mode critic 비교 |

## Rules
- admin 제품 참조만 (마케팅 랜딩 금지)
- 5테마 전부 검증
- FAIL 시 구체적 수정 가이드 (항목명 + 실제 값 + 기대 값)
