#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Pipeline Guard — Claude Hook에서 호출
# git commit 시도 전에 파이프라인 준수 여부 검증
# ═══════════════════════════════════════════════════════════

STATE_FILE="/home/ubuntu/corthex-v3/_bmad-output/pipeline-state.yaml"
PARTY_DIR="/home/ubuntu/corthex-v3/_bmad-output/party-logs"

# Only guard git commit commands
if [[ "$1" != *"git commit"* ]] && [[ "$1" != *"git push"* ]]; then
  exit 0
fi

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

STORY=$(grep "current_story:" "$STATE_FILE" | head -1 | sed 's/.*: *//;s/"//g;s/ //g')
PHASE=$(grep "current_phase:" "$STATE_FILE" | head -1 | sed 's/.*: *//;s/"//g;s/ //g')

if [ -z "$STORY" ]; then
  exit 0
fi

# Count party logs for current story
LOG_COUNT=$(ls "$PARTY_DIR"/story-${STORY}-phase-*-*.md 2>/dev/null | wc -l)

if [ "$LOG_COUNT" -lt 3 ]; then
  echo "⚠️  Pipeline Guard: Story ${STORY} — party-log ${LOG_COUNT}개 (최소 3개 필요)"
fi

exit 0  # Warning only, pre-commit hook does the hard block
