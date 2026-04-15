#!/bin/bash
# no-haiku-guard.sh — haiku 모델 사용 물리적 차단
# PreToolUse Agent hook: model에 "haiku"가 포함되면 exit 2 (block)

TOOL_INPUT="$1"

# Check if model parameter contains "haiku"
if echo "$TOOL_INPUT" | grep -qi '"model"[[:space:]]*:[[:space:]]*"haiku"'; then
  echo "BLOCKED: haiku 모델 사용 금지. sonnet 또는 opus만 허용됩니다." >&2
  exit 2
fi

exit 0
