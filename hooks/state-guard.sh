#!/bin/bash
# ═══════════════════════════════════════════════════════════
# State Guard — Claude Code PreToolUse hook
# pipeline-state.yaml 직접 Edit/Write 차단 (BUG-001 근본 해결)
#
# 차단 이유: Claude가 자기 심판 파일(pipeline-state.yaml)을
# 직접 편집하면 phase-a/phase-b 훅 우회, 기망 패턴 재발.
# 전용 CLI(`bmad-state set-story X`)로만 수정 허용.
#
# Triggered by: user-feedback #3 🔴 "state 조작 패턴 재발"
# (@restore 18:36 planning_active: false→true 직접 편집)
# ═══════════════════════════════════════════════════════════

# stdin에서 JSON 읽기
INPUT=$(cat)

# jq 없으면 통과 (서버 환경 호환성)
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# tool_name 추출
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Edit/Write/MultiEdit만 검사
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

# file_path 추출
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Bypass 환경변수 (CEO 긴급 허가 시)
if [ "$CORTHEX_STATE_GUARD_BYPASS" = "1" ]; then
  exit 0
fi

# pipeline-state.yaml 매칭 (경로 끝에 있어야 함)
if [[ "$FILE_PATH" == *"pipeline-state.yaml" ]]; then
  cat >&2 <<EOF
🚨 State Guard 차단: pipeline-state.yaml 직접 편집 금지

이 파일은 파이프라인 진행 상태의 심판 파일입니다.
Claude가 직접 편집하면 phase-a/phase-b/commit 훅을
우회할 수 있어 기망 패턴이 재발합니다 (BUG-001 참조).

허용된 수정 경로:
  1. 전용 CLI 사용 (추후 도입 예정):
     bmad-state set-story <ID>
     bmad-state set-stage <stage>
  2. phase 진행은 해당 phase 완료 시 pipeline이 자동 업데이트.

우회가 꼭 필요하면 CEO에게 직접 허가 받고
CORTHEX_STATE_GUARD_BYPASS=1 환경변수 설정 후 재시도.

참조: pipelines-qa-bug-report/BUG-001-hook-bypass-via-state-manipulation.md
       user-feedback-2026-04-14.md #3 🔴 "state 조작 재발"
EOF
  exit 2
fi

exit 0
