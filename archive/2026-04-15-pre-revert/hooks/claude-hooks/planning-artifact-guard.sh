#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Planning Artifact Guard v1.0 — PreToolUse Hook (Edit/Write)
# _bmad-output/phase-*/planning-artifacts/*.md 수정 시
# pipeline-state.yaml의 planning_active: true 확인
# fail-closed: 상태 파일 없으면 차단
# 긴급 우회: PLANNING_GUARD_BYPASS=1
# ═══════════════════════════════════════════════════════════

# ── 긴급 우회 (CEO 전용) ──
if [ "$PLANNING_GUARD_BYPASS" = "1" ]; then
  exit 0
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo /home/ubuntu/corthex-v3)"
STATE_FILE="$PROJECT_ROOT/_bmad-output/pipeline-state.yaml"
TOOL_INPUT="$1"

# ── file_path 추출 (Edit/Write tool) ──
FILE_PATH=$(echo "$TOOL_INPUT" | grep -oP '"file_path"\s*:\s*"([^"]+)"' | head -1 | sed 's/.*"file_path"\s*:\s*"//;s/"$//')

# ── Bash tool: planning-artifacts 직접 수정 감지 ──
if [ -z "$FILE_PATH" ]; then
  COMMAND=$(echo "$TOOL_INPUT" | grep -oP '"command"\s*:\s*"([^"]*)"' | head -1 | sed 's/.*"command"\s*:\s*"//;s/"$//')
  if [ -n "$COMMAND" ]; then
    if echo "$COMMAND" | grep -qE "(sed|awk|tee|cat\s*>|echo\s*>).*planning-artifacts/"; then
      FILE_PATH="planning-artifacts/_bash_write_detected"
    else
      exit 0
    fi
  else
    exit 0
  fi
fi

# ── planning-artifacts/*.md 가 아니면 통과 ──
if ! echo "$FILE_PATH" | grep -qE "_bmad-output/phase-[0-9]+\.?[0-9]*/planning-artifacts/.*\.md$"; then
  exit 0
fi

# ── pipeline-state.yaml 없으면 차단 (fail-closed) ──
if [ ! -f "$STATE_FILE" ]; then
  echo "❌ BLOCKED: pipeline-state.yaml 없음"
  echo "   파일: $FILE_PATH"
  echo "   해결: /kdh-planning-pipeline을 먼저 실행하세요"
  echo "   긴급: PLANNING_GUARD_BYPASS=1 (CEO 전용)"
  exit 2
fi

# ── planning_active: true 확인 ──
if grep -q "^planning_active: true$" "$STATE_FILE" 2>/dev/null; then
  exit 0
fi

# ── 차단 + 진단 ──
CURRENT_VAL=$(grep "^planning_active:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: *//')
echo "❌ BLOCKED: planning_active != true"
echo "   파일: $FILE_PATH"
echo "   상태: planning_active: ${CURRENT_VAL:-미정의}"
echo "   해결: /kdh-planning-pipeline을 먼저 실행하세요"
echo "   긴급: PLANNING_GUARD_BYPASS=1 (CEO 전용)"
exit 2
