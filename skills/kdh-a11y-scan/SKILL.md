# kdh-a11y-scan — 접근성 전수 스캔

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
