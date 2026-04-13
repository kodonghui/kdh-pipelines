#!/bin/bash
# ═══════════════════════════════════════════════════════════
# git-safety-guard.sh v1.0 — Hook 우회 및 변조 차단
# PreToolUse Hook: Bash/Edit/Write tool에 대해 실행
#
# 차단 대상:
#   - --no-verify (pre-commit hook 우회)
#   - core.hooksPath 변경 (hook 경로 변조)
#   - .git/hooks/ 파일 수정/삭제/권한변경
#   - git -c core.* 직접 설정
#   - Hook 스크립트 직접 수정
# ═══════════════════════════════════════════════════════════

TOOL_INPUT="$1"

# ── Bash 명령 추출 ──
COMMAND=$(echo "$TOOL_INPUT" | grep -oP '"command"\s*:\s*"([^"]*)"' | head -1 | sed 's/.*"command"\s*:\s*"//;s/"$//')

# ── Edit/Write 파일 경로 추출 ──
FILE_PATH=$(echo "$TOOL_INPUT" | grep -oP '"file_path"\s*:\s*"([^"]+)"' | head -1 | sed 's/.*"file_path"\s*:\s*"//;s/"$//')

# ── Bash 명령 검사 ──
if [ -n "$COMMAND" ]; then
  # --no-verify 차단
  if echo "$COMMAND" | grep -qE "\-\-no-verify"; then
    echo "❌ BLOCKED: --no-verify 사용 금지. 파이프라인 규칙 위반."
    exit 2
  fi

  # core.hooksPath 변경 차단
  if echo "$COMMAND" | grep -qiE "core\.hookspath"; then
    echo "❌ BLOCKED: core.hooksPath 변경 금지."
    exit 2
  fi

  # .git/hooks 파일 수정/삭제/이동/권한변경 차단
  if echo "$COMMAND" | grep -qiE "(sed|awk|tee|cat\s*>|echo\s*>|rm|mv|chmod|ln\s|cp\s).*\.git/hooks"; then
    echo "❌ BLOCKED: .git/hooks 파일 수정/삭제/권한변경 금지."
    exit 2
  fi

  # git -c core.* 직접 설정 차단
  if echo "$COMMAND" | grep -qE "git\s+-c\s+core\."; then
    echo "❌ BLOCKED: git -c core.* 직접 설정 금지."
    exit 2
  fi
fi

# ── Edit/Write 파일 경로 검사 ──
if [ -n "$FILE_PATH" ]; then
  # .git/hooks/ 내 파일 직접 수정 차단
  if echo "$FILE_PATH" | grep -qE "\.git/hooks/"; then
    echo "❌ BLOCKED: .git/hooks/ 파일 직접 수정 금지."
    exit 2
  fi

  # git-safety-guard 자체 수정 차단
  if echo "$FILE_PATH" | grep -qE "git-safety-guard"; then
    echo "❌ BLOCKED: git-safety-guard.sh 자기 보호 — 수정 금지."
    exit 2
  fi
fi

exit 0
