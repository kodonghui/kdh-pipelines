#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Code Edit Guard — PreToolUse Hook (Edit/Write/Bash)
# packages/ 코드 수정 시 pipeline-state.yaml의 current_story 확인
# current_story 없으면 exit 2 (100% 차단)
#
# 원칙: fail-closed (판단 못하면 차단)
# ═══════════════════════════════════════════════════════════

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo /home/ubuntu/corthex-v3)"
STATE_FILE="$PROJECT_ROOT/_bmad-output/pipeline-state.yaml"
TOOL_INPUT="$1"

# ── file_path 추출 (Edit/Write tool) ──
FILE_PATH=$(echo "$TOOL_INPUT" | grep -oP '"file_path"\s*:\s*"([^"]+)"' | head -1 | sed 's/.*"file_path"\s*:\s*"//;s/"$//')

# ── Bash tool: 코드 파일 직접 수정 명령 감지 ──
if [ -z "$FILE_PATH" ]; then
  # Bash command에서 packages/ 파일 수정 감지
  COMMAND=$(echo "$TOOL_INPUT" | grep -oP '"command"\s*:\s*"([^"]*)"' | head -1 | sed 's/.*"command"\s*:\s*"//;s/"$//')
  if [ -n "$COMMAND" ]; then
    # sed, awk, tee, cat >>, echo > 등으로 packages/ 파일 수정 감지
    if echo "$COMMAND" | grep -qE "(sed|awk|tee|cat\s*>|echo\s*>).*packages/"; then
      FILE_PATH="packages/_bash_write_detected"
    else
      exit 0  # packages/ 수정이 아닌 Bash 명령은 통과
    fi
  else
    exit 0  # command도 file_path도 없으면 통과
  fi
fi

# ── packages/ 밖이면 무조건 통과 ──
if [[ "$FILE_PATH" != *"/packages/"* ]] && [[ "$FILE_PATH" != packages/* ]]; then
  exit 0
fi

# ── _bmad-output 안이면 통과 ──
if [[ "$FILE_PATH" == *"_bmad-output"* ]]; then
  exit 0
fi

# ── __tests__ 안이면 통과 (테스트 파일은 자유) ──
if [[ "$FILE_PATH" == *"__tests__"* ]] || [[ "$FILE_PATH" == *".test."* ]] || [[ "$FILE_PATH" == *".spec."* ]]; then
  exit 0
fi

# ── pipeline-state.yaml 없으면 차단 ──
if [ ! -f "$STATE_FILE" ]; then
  echo "❌ BLOCKED: pipeline-state.yaml 없음."
  echo "   /kdh-dev-pipeline을 먼저 실행하세요."
  exit 2
fi

# ── current_story 확인 ──
STORY=$(grep "^current_story:" "$STATE_FILE" | head -1 | sed 's/.*: *//;s/"//g;s/ //g')

if [ -z "$STORY" ] || [ "$STORY" = "null" ] || [ "$STORY" = "~" ]; then
  echo "❌ BLOCKED: 활성 스토리 없음 (current_story: ${STORY:-empty})"
  echo "   /kdh-dev-pipeline으로 스토리를 시작한 뒤 코드를 수정하세요."
  exit 2
fi

# ── 활성 스토리 있으면 통과 ──
exit 0
