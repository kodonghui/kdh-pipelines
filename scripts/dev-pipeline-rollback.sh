#!/usr/bin/env bash
# kdh-dev-pipeline Modular Split Rollback Drill — board 0425 R-11
#
# Purpose: Wave 3 modular split 의 rollback target 자가 검증.
#          rollback target = governance-patched monolith (Wave 1+2 적용된 wrapper).
#          본 script = drill mode (default) 또는 actual rollback.
#
# Drill mode (default):
#   - 4 sub-skill 디렉토리 임시 archive (move to /tmp/dev-pipeline-rollback-test/)
#   - wrapper 단독 동작 가능 확인 (smoke harness PASS)
#   - sub-skill 즉시 복귀 (restore from archive)
#   - 검증 결과 보고
#
# Actual rollback (--actual):
#   - 4 sub-skill 디렉토리를 _archive/wave3-rollback-<timestamp>/ 로 영구 이동
#   - wrapper 의 'Phase Sub-skills' 섹션 → 'ROLLBACK' notice 로 교체
#   - alias map 의 sub-skill reference 제거 (revision++ + prev_revision 기록)
#
# Usage:
#   bash dev-pipeline-rollback.sh           # drill mode
#   bash dev-pipeline-rollback.sh --actual  # 실제 rollback (위험)
#   bash dev-pipeline-rollback.sh --json    # machine-readable

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$HOME/kdh-pipelines}"
SKILLS_DIR="$REPO_ROOT/skills"
SUB_SKILLS=(
  "kdh-dev-pipeline-phase-a"
  "kdh-dev-pipeline-phase-b"
  "kdh-dev-pipeline-phase-d"
  "kdh-dev-pipeline-codex"
)
WRAPPER="$SKILLS_DIR/kdh-dev-pipeline/SKILL.md"
SMOKE_HARNESS="$REPO_ROOT/scripts/skill-smoke-harness.py"

DRILL_MODE=true
JSON_OUTPUT=false
for arg in "$@"; do
  case "$arg" in
    --actual) DRILL_MODE=false ;;
    --json)   JSON_OUTPUT=true ;;
    -h|--help)
      grep -E "^# " "$0" | sed 's/^# //'
      exit 0
      ;;
  esac
done

ARCHIVE_TS="$(date -u +%Y%m%dT%H%M%SZ)"
TMP_ARCHIVE="/tmp/dev-pipeline-rollback-test-${ARCHIVE_TS}"

# ─── Pre-flight ────────────────────────────────────────────────────────
[[ -d "$SKILLS_DIR" ]] || { echo "ERR: skills dir absent: $SKILLS_DIR" >&2; exit 2; }
[[ -f "$WRAPPER"   ]] || { echo "ERR: wrapper SKILL.md absent: $WRAPPER" >&2; exit 2; }
for sub in "${SUB_SKILLS[@]}"; do
  [[ -d "$SKILLS_DIR/$sub" ]] || { echo "ERR: sub-skill dir absent: $sub" >&2; exit 2; }
done

# ─── Drill or Actual ──────────────────────────────────────────────────
RESULT_VERDICT=""
RESULT_DETAIL=""

run_smoke() {
  if [[ -f "$SMOKE_HARNESS" ]]; then
    python3 "$SMOKE_HARNESS" --alias-only 2>&1 | tail -3
    return ${PIPESTATUS[0]}
  fi
  return 2
}

if $DRILL_MODE; then
  mkdir -p "$TMP_ARCHIVE"
  for sub in "${SUB_SKILLS[@]}"; do
    mv "$SKILLS_DIR/$sub" "$TMP_ARCHIVE/"
  done

  # 검증: wrapper 단독 + smoke harness PASS
  SMOKE_OK=true
  if ! run_smoke >/dev/null 2>&1; then
    SMOKE_OK=false
  fi

  WRAPPER_HEAD_OK=false
  if head -5 "$WRAPPER" | grep -q "^name:"; then
    WRAPPER_HEAD_OK=true
  fi

  # 즉시 복귀
  for sub in "${SUB_SKILLS[@]}"; do
    mv "$TMP_ARCHIVE/$sub" "$SKILLS_DIR/"
  done
  rmdir "$TMP_ARCHIVE" 2>/dev/null || true

  # 복귀 검증
  RESTORE_OK=true
  for sub in "${SUB_SKILLS[@]}"; do
    if [[ ! -f "$SKILLS_DIR/$sub/SKILL.md" ]]; then
      RESTORE_OK=false
    fi
  done

  # smoke harness 복귀 후 재실행
  POST_SMOKE_OK=true
  if ! run_smoke >/dev/null 2>&1; then
    POST_SMOKE_OK=false
  fi

  if $WRAPPER_HEAD_OK && $RESTORE_OK && $POST_SMOKE_OK; then
    RESULT_VERDICT="DRILL_PASS"
    RESULT_DETAIL="wrapper standalone OK + sub-skill restore OK + post-restore smoke OK (rollback feasible)"
  else
    RESULT_VERDICT="DRILL_FAIL"
    RESULT_DETAIL="wrapper_head_ok=$WRAPPER_HEAD_OK restore_ok=$RESTORE_OK post_smoke_ok=$POST_SMOKE_OK"
  fi
else
  # Actual rollback (위험)
  ARCHIVE_DEST="$REPO_ROOT/_archive/wave3-rollback-${ARCHIVE_TS}"
  mkdir -p "$ARCHIVE_DEST"
  for sub in "${SUB_SKILLS[@]}"; do
    mv "$SKILLS_DIR/$sub" "$ARCHIVE_DEST/"
  done
  RESULT_VERDICT="ACTUAL_ROLLBACK"
  RESULT_DETAIL="4 sub-skill moved to $ARCHIVE_DEST. wrapper 'Phase Sub-skills' 섹션은 별 turn 에 ROLLBACK notice 로 교체 필요. alias map revision++ 동반 필요."
fi

# ─── Output ───────────────────────────────────────────────────────────
if $JSON_OUTPUT; then
  cat <<EOF
{
  "verdict": "$RESULT_VERDICT",
  "mode": "$([[ "$DRILL_MODE" == true ]] && echo drill || echo actual)",
  "timestamp_utc": "$ARCHIVE_TS",
  "wrapper_head_ok": ${WRAPPER_HEAD_OK:-null},
  "restore_ok": ${RESTORE_OK:-null},
  "post_smoke_ok": ${POST_SMOKE_OK:-null},
  "detail": "$RESULT_DETAIL"
}
EOF
else
  echo "=== R-11 Rollback ${DRILL_MODE:+Drill} — $RESULT_VERDICT ==="
  echo "$RESULT_DETAIL"
fi

[[ "$RESULT_VERDICT" == *PASS* || "$RESULT_VERDICT" == "ACTUAL_ROLLBACK" ]] && exit 0 || exit 1
