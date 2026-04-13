#!/bin/bash
# Pipeline Progress Check — PostToolUse hook
# pipeline-state.yaml 수정 시 현재 위치 알림 (알림만, 자동 실행 아님)

STATE_FILE="_bmad-output/pipeline-state.yaml"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# pipeline-state.yaml 수정 시에만 동작
if echo "$TOOL_INPUT" | grep -q "pipeline-state" 2>/dev/null; then
  if [ -f "$STATE_FILE" ]; then
    STAGE=$(grep "current_stage:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: //' | tr -d ' "')
    STEP=$(grep "current_step:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: //' | tr -d ' "')
    echo "[Pipeline] Stage $STAGE, Step: $STEP"
  fi
fi
exit 0
