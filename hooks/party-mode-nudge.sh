#!/bin/bash
# ═══════════════════════════════════════════════════════════
# CORTHEX v3 — Party Mode Auto-Nudge (TeammateIdle Hook)
# 에이전트가 idle 되려 할 때 → 남은 일 있으면 깨움
#
# 3가지 판단:
# 1. party-log 파일 존재 여부로 진행 상태 파악
# 2. 해당 에이전트가 해야 할 다음 일 결정
# 3. 할 일 있으면 exit 2 (깨움), 없으면 exit 0 (idle 허용)
# ═══════════════════════════════════════════════════════════

set -euo pipefail

# 경로 동적화: 환경변수 > cwd > 기본값
PROJECT_ROOT="${CORTHEX_PROJECT_ROOT:-${PWD:-/home/ubuntu/corthex-v3}}"
PARTY_DIR="$PROJECT_ROOT/_bmad-output/party-logs/planning-v2"
CONTEXT_FILE="$PROJECT_ROOT/_bmad-output/party-mode-context.json"

# ── stdin에서 teammate 정보 읽기 ──
INPUT=$(cat 2>/dev/null || echo "{}")
AGENT_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('teammate_name', d.get('name', '')))
except:
    print('')
" 2>/dev/null || echo "")

# 에이전트 이름 없으면 무시
if [ -z "$AGENT_NAME" ]; then
  exit 0
fi

# ── Party Mode 컨텍스트 읽기 ──
if [ ! -f "$CONTEXT_FILE" ]; then
  exit 0  # Party Mode 비활성 → idle 허용
fi

ACTIVE=$(python3 -c "
import json
with open('$CONTEXT_FILE') as f:
    d = json.load(f)
    print(d.get('active', False))
" 2>/dev/null || echo "False")

if [ "$ACTIVE" != "True" ]; then
  exit 0
fi

# 컨텍스트 파싱
eval $(python3 -c "
import json
with open('$CONTEXT_FILE') as f:
    d = json.load(f)
    print(f'PREFIX=\"{d.get(\"prefix\", \"\")}\"')
    print(f'WRITER=\"{d.get(\"writer\", \"\")}\"')
    critics = ' '.join(d.get('critics', []))
    print(f'CRITICS=\"{critics}\"')
" 2>/dev/null)

if [ -z "$PREFIX" ]; then
  exit 0
fi

# ── 파일 존재 체크 함수 ──
file_exists() {
  [ -f "$PARTY_DIR/${PREFIX}-${1}.md" ]
}

# ── Writer(analyst) 판단 ──
if [ "$AGENT_NAME" = "$WRITER" ]; then
  # analyst review 존재 확인
  if ! file_exists "${WRITER}-review"; then
    # 아직 리뷰 안 씀 → 이건 정상 (작업 중이었을 수 있음)
    exit 0
  fi

  # 모든 critic 리뷰 존재 확인
  ALL_CRITICS_DONE=true
  CRITIC_COUNT=0
  for critic in $CRITICS; do
    if file_exists "$critic"; then
      CRITIC_COUNT=$((CRITIC_COUNT + 1))
    else
      ALL_CRITICS_DONE=false
    fi
  done

  # fixes 존재 확인
  FIXES_EXIST=false
  if file_exists "fixes"; then
    FIXES_EXIST=true
  fi

  # 판단
  if [ "$ALL_CRITICS_DONE" = true ] && [ "$FIXES_EXIST" = false ]; then
    echo "📬 critic 피드백 ${CRITIC_COUNT}개가 전부 도착했습니다. party-logs 디렉토리에서 ${PREFIX}-{winston,john,sally,bob}.md 파일을 읽고 fixes를 작성하세요. fixes 파일: ${PREFIX}-fixes.md. 완료 후 [Fixes Applied]를 모든 critics에게 SendMessage하세요."
    exit 2  # 깨움!
  fi

  if [ "$FIXES_EXIST" = true ]; then
    # fixes 작성됨 → 모든 critic이 verified했는지 확인
    ALL_VERIFIED=true
    for c in $CRITICS; do
      if file_exists "$c"; then
        if ! grep -q "\[Verified\]\|verified\|VERIFIED\|post-fix\|Post-fix" "$PARTY_DIR/${PREFIX}-${c}.md" 2>/dev/null; then
          ALL_VERIFIED=false
        fi
      else
        ALL_VERIFIED=false
      fi
    done

    if [ "$ALL_VERIFIED" = true ]; then
      # 모든 critic verified → Writer 작업 완료 → 자동 종료
      echo '{"continue": false, "stopReason": "모든 critic이 fixes를 검증했습니다. Party Mode 완료."}'
      exit 0
    fi

    # 아직 verified 안 된 critic → idle 허용 (기다림)
    exit 0
  fi

  # 아직 critic 리뷰가 안 끝남 → idle 허용 (기다려야 함)
  if [ "$CRITIC_COUNT" -gt 0 ] && [ "$CRITIC_COUNT" -lt 4 ]; then
    echo "📭 critic 피드백 ${CRITIC_COUNT}/4 도착. 나머지를 기다리세요. 도착하면 다시 알려드리겠습니다."
    exit 0
  fi

  exit 0
fi

# ── Critic 판단 ──
for critic in $CRITICS; do
  if [ "$AGENT_NAME" = "$critic" ]; then
    # 1. analyst review 있고, 내 리뷰 없으면 → 리뷰 해야 함
    if file_exists "${WRITER}-review" && ! file_exists "$critic"; then
      echo "📬 analyst 리뷰가 도착했습니다. ${PARTY_DIR}/${PREFIX}-${WRITER}-review.md 를 읽고 리뷰를 작성하세요. 출력: ${PREFIX}-${critic}.md. Cross-talk도 잊지 마세요."
      exit 2  # 깨움!
    fi

    # 2. fixes 있고, 내 파일에 "Verified" 없으면 → 검증 해야 함
    if file_exists "fixes" && file_exists "$critic"; then
      if ! grep -q "\[Verified\]\|verified\|VERIFIED\|post-fix\|Post-fix" "$PARTY_DIR/${PREFIX}-${critic}.md" 2>/dev/null; then
        echo "📬 fixes가 도착했습니다. ${PARTY_DIR}/${PREFIX}-fixes.md 를 읽고 검증하세요. 업데이트된 D1-D6 점수와 함께 [Verified] 메시지를 analyst에게 보내세요."
        exit 2  # 깨움!
      fi
    fi

    # 3. 내가 verified + 다른 모든 critic도 verified → 자동 종료
    if file_exists "fixes" && grep -q "\[Verified\]\|verified\|VERIFIED\|post-fix\|Post-fix" "$PARTY_DIR/${PREFIX}-${critic}.md" 2>/dev/null; then
      ALL_OTHERS_VERIFIED=true
      for other_c in $CRITICS; do
        if [ "$other_c" != "$critic" ]; then
          if file_exists "$other_c"; then
            if ! grep -q "\[Verified\]\|verified\|VERIFIED\|post-fix\|Post-fix" "$PARTY_DIR/${PREFIX}-${other_c}.md" 2>/dev/null; then
              ALL_OTHERS_VERIFIED=false
            fi
          else
            ALL_OTHERS_VERIFIED=false
          fi
        fi
      done

      if [ "$ALL_OTHERS_VERIFIED" = true ]; then
        echo '{"continue": false, "stopReason": "모든 리뷰가 검증되었습니다. Party Mode 완료."}'
        exit 0
      fi
    fi

    # 4. cross-talk 체크 (상대방이 보냈는데 내가 안 읽은 경우)
    # cross-talk은 critic 파일 내 섹션이므로, 파일이 이미 있으면 OK

    exit 0  # 할 일 없음
  fi
done

# 알 수 없는 에이전트 → idle 허용
exit 0
