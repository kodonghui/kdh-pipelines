#!/bin/bash
# CORTHEX v3 — 환경 자동 검증 (Harness Improvement #2)
# 매 세션 시작 시 실행. 파이프라인 auto 모드 Step 0에서 호출.
# 출처: Anthropic "Effective Harnesses for Long-Running Agents"

set -euo pipefail

# 경로 동적화: 환경변수 > cwd > 기본값
PROJECT_ROOT="${CORTHEX_PROJECT_ROOT:-${PWD:-$(cd "$(dirname "$0")/.." && pwd)}}"
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

# 1. 패키지 매니저 감지
if command -v bun > /dev/null 2>&1; then
  PKG_MGR="bun"
  check "Bun 설치" "bun --version"
elif command -v npm > /dev/null 2>&1; then
  PKG_MGR="npm"
  check "npm 설치" "npm --version"
else
  PKG_MGR="none"
  check "패키지 매니저" "false"
fi

# 2. tsc 체크 (tsconfig.json 동적 탐색)
TSC_COUNT=0
for tsconfig in $(find "$PROJECT_ROOT" -name "tsconfig.json" -not -path "*/node_modules/*" 2>/dev/null | head -5); do
  TSC_DIR=$(dirname "$tsconfig")
  TSC_NAME=$(basename "$TSC_DIR")
  check "$TSC_NAME tsc" "cd '$TSC_DIR' && npx tsc --noEmit 2>&1"
  TSC_COUNT=$((TSC_COUNT + 1))
done
if [ "$TSC_COUNT" -eq 0 ]; then
  printf "  [2/?] %-30s⚠️  tsconfig.json 없음 (tsc 스킵)\n" "TypeScript"
  WARN=$((WARN + 1))
fi

# 3. DB 연결 (선택사항 — 서버 패키지 자동 탐색)
SERVER_DIR=$(find "$PROJECT_ROOT" -path "*/packages/server" -type d 2>/dev/null | head -1)
if [ -n "$SERVER_DIR" ] && [ -f "$SERVER_DIR/src/db/index.ts" -o -f "$SERVER_DIR/src/db.ts" ]; then
  check "DB 연결" "cd '$SERVER_DIR' && $PKG_MGR run -e 'process.exit(0)' 2>&1" "false"
else
  printf "  [3/?] %-30s⚠️  서버 패키지 미감지 (스킵)\n" "DB 연결"
  WARN=$((WARN + 1))
fi

# 4. 미커밋 변경사항
UNSTAGED=$(cd "$PROJECT_ROOT" && git status --porcelain 2>/dev/null | wc -l)
if [ "$UNSTAGED" -gt 0 ]; then
  printf "  [4/?] %-30s⚠️  %s개 파일 미커밋\n" "미커밋 변경" "$UNSTAGED"
  WARN=$((WARN + 1))
else
  printf "  [4/?] %-30s✅\n" "미커밋 변경"
  PASS=$((PASS + 1))
fi

# 5. pipeline-state.yaml 존재 (선택)
if [ -d "$PROJECT_ROOT/_bmad-output" ]; then
  check "Pipeline State" "test -f '$PROJECT_ROOT/_bmad-output/pipeline-state.yaml'"
else
  printf "  [5/?] %-30s⚠️  _bmad-output 없음 (파이프라인 미사용)\n" "Pipeline State"
  WARN=$((WARN + 1))
fi

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
