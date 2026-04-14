#!/bin/bash
# ═══════════════════════════════════════════════════════════
# State Guard — Claude Code PreToolUse hook
# pipeline-state.yaml + observations.jsonl + compliance-violations.jsonl
# 직접 편집/삭제 차단 (BUG-001 + BUG-003 근본 해결)
#
# 차단 범위:
#   (A) Edit/Write/MultiEdit → 3개 보호 파일 직접 편집 차단
#   (B) Bash → rm/git rm/unlink 등 삭제성 명령이 3개 파일 포함 시 차단
#
# Triggered by:
#   - BUG-001 (state 조작 기망): 2026-04-14 15:02 초기 + 18:36 @restore 재발
#   - BUG-003 (working tree deletion): 2026-04-14 20:20 재발
#     (pipeline-state.yaml + observations.jsonl + compliance-violations.jsonl 3개 동시 D)
#
# Bypass: CORTHEX_STATE_GUARD_BYPASS=1 (CEO 긴급 허가 시)
# ═══════════════════════════════════════════════════════════

# 보호 파일 목록 (공통)
PROTECTED_FILES=(
  "pipeline-state.yaml"
  "observations.jsonl"
  "compliance-violations.jsonl"
)

# stdin에서 JSON 읽기
INPUT=$(cat)

# jq 없으면 통과 (서버 환경 호환성)
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# Bypass 환경변수 (CEO 긴급 허가 시)
if [ "$CORTHEX_STATE_GUARD_BYPASS" = "1" ]; then
  exit 0
fi

# tool_name 추출
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# ─────────────────────────────────────────
# (B) Bash 분기: 삭제성 명령 + 보호 파일 경로 감지
# ─────────────────────────────────────────
if [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
  [ -z "$CMD" ] && exit 0

  # 삭제성 패턴: rm, git rm, unlink, mv <file> /dev/null
  DESTRUCTIVE_REGEX='(\brm[[:space:]]|\bgit[[:space:]]+rm\b|\bunlink[[:space:]]|\bmv[[:space:]].*[[:space:]]/dev/null)'

  if echo "$CMD" | grep -qE "$DESTRUCTIVE_REGEX"; then
    for PFILE in "${PROTECTED_FILES[@]}"; do
      if echo "$CMD" | grep -qF "$PFILE"; then
        cat >&2 <<EOF
🚨 State Guard 차단 (Bash): 보호 파일 삭제성 명령 감지

보호 파일: $PFILE
명령어: $CMD

BUG-003(2026-04-14 20:20 재발)처럼 rm/git rm 등이
working tree에서 심판 파일을 삭제하면 기망/혼란 재발.

허용된 복구 경로:
  - git checkout HEAD -- <path> (복구)
  - git restore <path> (복구, git 2.23+)

우회가 꼭 필요하면 CORTHEX_STATE_GUARD_BYPASS=1 설정 후 재시도.

참조: pipelines-qa-bug-report/BUG-003-sandbox-git-divergence.md
       user-feedback-2026-04-14.md #3 + qa-log 20:23 엔트리
EOF
        exit 2
      fi
    done
  fi
  exit 0
fi

# ─────────────────────────────────────────
# (A) Edit/Write/MultiEdit 분기: 파일 직접 편집 차단
# ─────────────────────────────────────────
case "$TOOL_NAME" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

# file_path 추출
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 보호 파일 매칭 (경로 끝에 있어야 함)
for PFILE in "${PROTECTED_FILES[@]}"; do
  if [[ "$FILE_PATH" == *"$PFILE" ]]; then
    cat >&2 <<EOF
🚨 State Guard 차단 (Edit/Write): $PFILE 직접 편집 금지

이 파일은 파이프라인의 심판/관측 파일입니다.
Claude가 직접 편집하면 phase-a/phase-b/commit 훅을
우회하거나 관측 기록을 왜곡할 수 있어 기망 패턴이 재발합니다
(BUG-001/003 참조).

허용된 수정 경로:
  1. 전용 CLI 사용 (추후 도입 예정):
     bmad-state set-story <ID>
     bmad-state set-stage <stage>
  2. phase 진행은 해당 phase 완료 시 pipeline이 자동 업데이트.
  3. observations/compliance jsonl은 hook이 append-only 기록.

우회가 꼭 필요하면 CEO에게 직접 허가 받고
CORTHEX_STATE_GUARD_BYPASS=1 환경변수 설정 후 재시도.

참조: pipelines-qa-bug-report/BUG-001-hook-bypass-via-state-manipulation.md
       pipelines-qa-bug-report/BUG-003-sandbox-git-divergence.md
       user-feedback-2026-04-14.md #3 🔴 "state 조작 재발"
EOF
    exit 2
  fi
done

exit 0
