#!/bin/bash
# ═══════════════════════════════════════════════════════════
# UI Design Gate Check v2.0 — UI story에 UI 디자인 문서 여부 검증
# .tsx 파일 변경됐는데 ui-design.md 없으면 경고
# v2.0: Phase별 동적 경로 + current_story 사용 + app 패키지 포함
# ═══════════════════════════════════════════════════════════

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo /home/ubuntu/corthex-v3)"
STATE_FILE="$PROJECT_ROOT/_bmad-output/pipeline-state.yaml"

# Only check on git commit
if [[ "$1" != *"git commit"* ]]; then
  exit 0
fi

# pipeline-state.yaml 없으면 통과
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# 현재 스토리 확인 (current_story 필드 사용)
STORY=$(grep "^current_story:" "$STATE_FILE" | head -1 | sed 's/.*: *//;s/"//g;s/ //g')
if [ -z "$STORY" ] || [ "$STORY" = "null" ]; then
  exit 0
fi

# Phase 번호로 동적 경로 구성
PHASE_NUM=$(grep "current_phase_number:" "$STATE_FILE" | head -1 | sed 's/.*: *//;s/"//g;s/ //g')
if [ -z "$PHASE_NUM" ]; then PHASE_NUM="1"; fi
PARTY_DIR="$PROJECT_ROOT/_bmad-output/phase-${PHASE_NUM}/party-logs"

# UI 파일(.tsx) staged 여부 확인 (admin + app 패키지 모두)
TSX_STAGED=$(git diff --cached --name-only 2>/dev/null | grep -E 'packages/(admin|app)/src/(pages|features|components)/.*\.tsx$' | head -1)
if [ -z "$TSX_STAGED" ]; then
  exit 0
fi

# UI 파일 변경됨 — ui-design.md 존재 확인
DESIGN_LOG="$PARTY_DIR/story-${STORY}-ui-design.md"
if [ ! -f "$DESIGN_LOG" ]; then
  echo ""
  echo "🎨 UI Design Gate: Story ${STORY} — UI 파일 변경됨 (.tsx)"
  echo "   ❌ ui-design.md 없음!"
  echo "   → 오케스트레이터가 UI 디자인 문서를 먼저 작성해야 합니다."
  echo "   → $DESIGN_LOG 파일이 필요합니다."
  echo ""
  # WARNING only — pre-commit hook does the hard block
  exit 0
fi

echo "🎨 UI Design Gate: Story ${STORY} — ui-design.md 확인됨 ✅"
exit 0
