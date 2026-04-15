# kdh-design-review — 디자인 품질 검증

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
