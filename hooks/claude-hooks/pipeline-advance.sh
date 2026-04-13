#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Pipeline Advance — Stop Hook
# Claude가 멈추려 할 때 pipeline-state.yaml을 읽고
# 아직 할 일이 있으면 계속하게 함 (exit 2)
# ═══════════════════════════════════════════════════════════

STATE_FILE="/home/ubuntu/corthex-v3/_bmad-output/pipeline-state.yaml"
INPUT="$CLAUDE_STOP_HOOK_INPUT"

# Guard: stop_hook_active = true이면 무한 루프 방지
if echo "$INPUT" 2>/dev/null | jq -r '.stop_hook_active' 2>/dev/null | grep -q "true"; then
  exit 0
fi

# pipeline-state.yaml 없으면 패스
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# 현재 모드 확인
MODE=$(grep "^mode:" "$STATE_FILE" | head -1 | sed 's/mode: *//;s/"//g;s/ //g')

# planning 또는 sprint 모드가 아니면 패스
if [ "$MODE" != "planning" ] && [ "$MODE" != "sprint" ]; then
  exit 0
fi

# 현재 stage 확인
CURRENT_STAGE=$(grep "^current_stage:" "$STATE_FILE" | head -1 | sed 's/current_stage: *//;s/"//g;s/ //g')

# CEO 참여 필요한 stage = 멈춤 허용
# Stage 0 (Brief, GATE 3개), Stage 2 (PRD, GATE 2개), Stage 5 (UX, GATE 1개)
CEO_STAGES="0 2 5"
for S in $CEO_STAGES; do
  if [ "$CURRENT_STAGE" = "$S" ]; then
    # CEO stage는 자동 진행하지 않음
    exit 0
  fi
done

# Sprint End (visual-verify) = CEO 확인 필요
if [ "$CURRENT_STAGE" = "sprint-end" ]; then
  exit 0
fi

# 자동 진행 가능한 stage인데 아직 완료 안 됨 → 계속!
# planning 모드의 자동 stages: 1, 3, 4, 6, 6.1, 6.5, 7, 8
# sprint 모드: story 단위 자동 진행

# 현재 stage의 status 확인
if [ "$MODE" = "planning" ]; then
  # stage_N_xxx 에서 status 추출
  case "$CURRENT_STAGE" in
    1) STATUS_KEY="stage_1_research" ;;
    3) STATUS_KEY="stage_3_prd_validate" ;;
    4) STATUS_KEY="stage_4_architecture" ;;
    6) STATUS_KEY="stage_6_epics" ;;
    6.1) STATUS_KEY="stage_6_1_planning_da" ;;
    6.5) STATUS_KEY="stage_6_5_contracts" ;;
    7) STATUS_KEY="stage_7_readiness" ;;
    8) STATUS_KEY="stage_8_sprint_planning" ;;
    *) exit 0 ;;
  esac

  STATUS=$(grep -A1 "${STATUS_KEY}:" "$STATE_FILE" | grep "status:" | head -1 | sed 's/.*status: *//;s/"//g;s/ //g')

  if [ "$STATUS" = "complete" ]; then
    # 이 stage 끝남 → 다음 stage로 자동 이동
    echo "Pipeline auto-advance: Stage $CURRENT_STAGE 완료. 다음 Stage로 이동합니다."
    if [ "$MODE" = "planning" ]; then
      echo "Read pipeline-state.yaml and continue to the next stage. Execute /kdh-planning-pipeline"
    else
      echo "Read pipeline-state.yaml and continue to the next stage. Execute /kdh-dev-pipeline"
    fi
    exit 2
  elif [ "$STATUS" = "not_started" ] || [ "$STATUS" = "in_progress" ]; then
    # 아직 진행 중 → 계속
    echo "Pipeline auto-advance: Stage $CURRENT_STAGE 진행 중. 계속합니다."
    echo "Continue working on the current stage. Read pipeline-state.yaml for current position."
    exit 2
  fi
fi

if [ "$MODE" = "sprint" ]; then
  # Sprint 모드: 미완료 story가 있으면 계속
  SPRINT_STATUS=$(grep -A1 "sprint_1:" "$STATE_FILE" | grep "status:" | head -1 | sed 's/.*status: *//;s/"//g;s/ //g')

  if [ "$SPRINT_STATUS" = "in_progress" ] || [ "$SPRINT_STATUS" = "not_started" ]; then
    echo "Sprint auto-advance: Sprint 1 진행 중. 다음 story로 계속합니다."
    echo "Continue Sprint 1. Read pipeline-state.yaml for current story."
    exit 2
  fi
fi

# 기본: 멈춤 허용
exit 0
