# kdh-deploy-verify — 배포 후 검증

## When to Use
- bug-fix-pipeline Phase 4 DEPLOY 후 자동 호출
- git push 후 수동 실행
- CEO가 "배포 확인해" 시

## 실행

### Step 1: 배포 완료 대기
```
gh run list --branch main --limit 1 --json status,conclusion
```
- status=completed + conclusion=success → Step 2
- conclusion=failure → CEO 보고 + 로그 확인

### Step 2: 프로덕션 Health Check
```
curl -sf {production_url}/api/health
```
- success=true → Step 3
- 실패 → 롤백 권고

### Step 3: 프로덕션 Smoke Test
```
source browser-use-env/bin/activate
python3.11 _browser-use-test/sweep.py --url {production_url} --model openai
```
또는 Playwright:
```
cd packages/admin && bunx playwright test e2e/smoke.spec.ts
```

### Step 4: 판정
- Health OK + Smoke PASS → "배포 성공" 보고
- Health OK + Smoke FAIL → 버그 등록 + CEO 보고
- Health FAIL → 롤백 권고 + CEO 보고

### Step 5: 롤백 (필요 시)
```
git revert HEAD --no-edit && git push origin main
```
CEO 확인 후에만 실행.

## Rules
- 자동 롤백 금지 (CEO 확인 필수)
- 프로덕션 sweep은 browser-use 또는 Playwright 중 하나
- 결과는 `_bmad-output/deploy-verify/` 에 기록
