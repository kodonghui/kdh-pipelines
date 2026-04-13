# kdh-visual-regression — 비주얼 회귀 테스트

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
