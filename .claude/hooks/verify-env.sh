#!/bin/bash
# CORTHEX v3 — 환경 자동 검증 (Harness Improvement #2)
# 매 세션 시작 시 실행. 파이프라인 auto 모드 Step 0에서 호출.
# 출처: Anthropic "Effective Harnesses for Long-Running Agents"

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
WARN=0

check() {
  local label="$1"
  local cmd="$2"
  local required="${3:-true}"

  printf "  [%d/%d] %-30s" $((PASS + FAIL + WARN + 1)) 6 "$label"

  if eval "$cmd" > /dev/null 2>&1; then
    echo "✅"
    PASS=$((PASS + 1))
  elif [ "$required" = "false" ]; then
    echo "⚠️  (경고, 계속 진행)"
    WARN=$((WARN + 1))
  else
    echo "❌ FAIL"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "═══════════════════════════════════════"
echo " CORTHEX v3 — 환경 검증"
echo " $(date '+%Y-%m-%d %H:%M:%S KST')"
echo "═══════════════════════════════════════"
echo ""

# 1. Bun 버전
check "Bun 설치" "command -v bun"

# 2. Server tsc
check "Server 타입체크" "cd '$PROJECT_ROOT/packages/server' && npx tsc --noEmit 2>&1"

# 3. Admin tsc
check "Admin 타입체크" "cd '$PROJECT_ROOT/packages/admin' && npx tsc --noEmit 2>&1"

# 4. DB 연결 (선택사항 — .env 없을 수 있음)
check "DB 연결" "cd '$PROJECT_ROOT/packages/server' && bun run -e 'import { db } from \"./src/db\"; const r = await db.execute(\"SELECT 1\"); process.exit(r ? 0 : 1)' 2>&1" "false"

# 5. 미커밋 변경사항
UNSTAGED=$(cd "$PROJECT_ROOT" && git status --porcelain 2>/dev/null | wc -l)
if [ "$UNSTAGED" -gt 0 ]; then
  printf "  [5/6] %-30s⚠️  %s개 파일 미커밋\n" "미커밋 변경" "$UNSTAGED"
  WARN=$((WARN + 1))
else
  printf "  [5/6] %-30s✅\n" "미커밋 변경"
  PASS=$((PASS + 1))
fi

# 6. pipeline-state.yaml 존재
check "Pipeline State" "test -f '$PROJECT_ROOT/_bmad-output/pipeline-state.yaml'"

echo ""
echo "═══════════════════════════════════════"
if [ "$FAIL" -gt 0 ]; then
  echo " 결과: ❌ FAIL ($FAIL개 실패, $WARN개 경고)"
  echo " → 파이프라인 시작 전에 수정 필요"
  exit 1
else
  echo " 결과: ✅ PASS ($PASS개 통과, $WARN개 경고)"
  echo " → 작업 시작 가능"
  exit 0
fi
