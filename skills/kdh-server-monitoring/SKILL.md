---
name: 'kdh-server-monitoring'
description: '서버 SSH 안의 Claude를 백그라운드 감시 + (v0.5 신규) 주기적 오케스트레이션 자동화. monitor의 false positive를 verify-first로 차단하고, 매 N분 git log + tmux capture로 실제 진행 상태를 직접 확인 + 보고. 사장님 명령어: /kdh-server-monitoring [start|stop|status|--orchestrate=10m --ssh-host=corthex --tmux-session=claude --interval=15 --auto-approve]'
---

# kdh-server-monitoring v0.5

## 🟥 오케스트레이션 원칙 (2026-04-18 밤, CEO 지시 "지피티랑 재미나이 한도는 고려하지 말고, 병렬로 할 수 있는건 그렇게 오케스트레이션 할것")

**병렬성 우선 — Codex/Gemini 한도는 병렬 판단 요소가 아님.**

이 스킬이 server Claude를 감시하면서 추가 작업을 디스패치할 때 다음 규칙을 지킨다:

1. **의존성 분석에서 병렬 가능한 작업(파일 교차 0, spec dependency 없음)은 항상 병렬로 디스패치한다.** `/kdh-parallel` 또는 동등한 병렬 worktree + tmux pane 구성 사용.
2. **"Codex 한도 N% 남음" / "Gemini Pro 쿼터 위태"는 병렬 중단 또는 지연 사유가 아니다.** 한도는 CEO가 결제/업그레이드로 처리할 사안이고, 오케스트레이터는 한도를 이유로 보수적으로 판단하지 않는다.
3. **한도 고갈이 실측으로 발생한 경우에만 보고 + 복구 타이밍 조정** (예: 현재 돌던 job이 rate limit로 실제 중단 → CODEX_LIMIT 이벤트 발생). 사전적으로 "위태할 것 같으니 미루자"는 금지.
4. **병렬 중단 사유로 허용되는 것은 기술적 제약뿐:**
   - 파일/contract 교차 → MERGE_WARN 또는 SEQUENTIAL
   - Spec/BRD dependency (예: V3-020 topology가 V3-001/002 blocks)
   - 서버 리소스 실측 부족 (OOM, disk full, SSH 연결 한계)
5. **Conductor가 병렬 가능한데 직렬 권고하면 CEO "한도 고려 말라" 재교정 유발 → 실패 지표.**

**Rationale:** 2026-04-17~18 두 보드 publish + Phase 3 Sprint 3-3A dev 동안, Conductor가 Gemini Pro 한도 27% 남은 상황에서 3-3B/C/D 병렬 제안을 "쿼터 리셋(~16h) 대기 권고"로 감쇠시켰다. CEO 즉각 교정 — "병렬성이 전체 속도의 주요 레버인데 한도를 이유로 미루지 말라. 한도는 내가 결제로 해결할 문제다". 이 원칙을 스킬 문서에 박아서 Conductor가 세션 갈려도 동일 실수 반복하지 않게 한다.

---

## v0.5 변경사항 (2026-04-18 저녁, CEO 지적 "오케스트레이션 기능도 추가해줘 그 명령어에")

**문제:** 기존 v0.4는 monitor 신호만 잡고 끝. 실제 verify (git log + tmux capture)는 별도 cron `/loop`로 돌려야 했음. 두 명령 (monitor + loop) 따로 관리 = CEO 부담.

**해결:** `--orchestrate=10m` 플래그 하나로 monitor + 주기적 orchestration 사이클을 한 번에 시작. 매 N분마다 자체 cron 트리거 + verify-first 보고.

### orchestration 사이클 (매 N분, 기본 10분)
1. `tmux capture-pane -t {ssh}:{session} -p -S -25 | tail -22` 실행 → 실제 현재 상태
2. `git log --oneline -3` (server cwd 자동 감지) 실행 → 새 commit 있나
3. monitor 신호 vs 실제 상태 cross-check:
   - 신호 매치 텍스트가 현재 pane 또는 git log에 있으면 → real → 보고
   - 없으면 (스크롤백 재탐지) → suppress + log to `/tmp/kdh-monitor-suppressed.log`
4. 진행 상황 1-2줄 요약 보고
5. 다음 cron tick까지 대기

이 모든 동작이 `--orchestrate=10m` 한 번 켜면 자동.

# kdh-server-monitoring v0.4 (legacy notes 유지)

## 무엇을 하는 스킬인가

서버 SSH 안에서 돌아가는 Claude tmux 세션을 **사람이 옆에서 보고 있을 때처럼** 감시한다. 사장님 자율 운영 시간(밤샘 모드 등) 동안 다음을 자동 감지하고 PushNotification으로 알린다.

> **v0.4 변경사항 (2026-04-17 저녁, CEO 지적 "온갖 탐지를 다 먹으면 어떻게"):**
> 1. **DONE 이벤트 세분화** — Phase/critic/grade/score 파싱 → `DONE phase=B critic=winston grade=A score=4.63` 형식. dedup key가 이제 `phase+critic+grade` 조합이라 Phase A Grade A와 Phase B Grade A 구별.
> 2. **IDLE 오탐 감소** — "Still idle", "Awaiting team-lead" 같은 Party Mode placeholder 문구는 해시 계산 전 strip → thinking 중인데 IDLE 잡히던 문제 해결.
> 3. **Push 강제 규칙 명시** — 섹션 2-0에 "무조건 Push" vs "suppress" 목록. Conductor가 이벤트 다 먹지 못하게 강제.
> 4. **Party Mode 페르소나 인식** — capture에서 `@team-lead|@john|@winston|@sally|@dev` 현재 페르소나 + Ctx % 추출. team-lead 기준으로만 save-session 임박 판단. (v2 2026-04-17: quinn 제거, dev가 QA 흡수)
> 5. **Resume 후 baseline re-seed** — Conductor 재시작 직후 5분 내 DONE 이벤트는 "historical"로 ACK만 하고 Push 생략 (이전 세션 완료 건 재알림 방지).
> 6. **Deprecated alias 경고** — 옛 `/kdh-server-claude-watch` 슬래시 커맨드는 세션 재시작 전까지 레지스트리 캐시에 남음. 신규 세션에선 /kdh-server-monitoring만 유효.

| 신호 | 매치 패턴 (정규식) | 의미 |
|---|---|---|
| **NEW_SESSION_SAVED** | `~/.claude/session-data/*.tmp` 폴더에 새 파일 mtime 감지 | 서버 Claude가 `/save-session` 완료. 스토리 3개 사이클 종료 신호. **auto-cycle 모드면 자동으로 다음 작업 주입** |
| **PERM_WAIT** | `Bash command requires permission`, `requires permission`, `permission needed`, `Tool use approval`, `\(y/n\)`, `Would you like`, `Press enter to confirm` | 서버 Claude가 권한 승인을 기다리고 있음 |
| **IDLE** | 60초+ 동안 pane 변동 없음 (해시 비교) | 응답 없이 멈춤 |
| **ERROR** | `Error:`, `Failed:`, `Traceback`, `panic:`, `FAILED`, `\bECONNREFUSED\b`, `Cannot connect` | 작업 실패 또는 연결 끊김 |
| **DONE** | `Sprint complete`, `Story.*완료`, `Sprint.*완료`, `Phase.*complete`, `Grade A`, `\d+/\d+\s+(pass\|tests pass)`, `commit.*push`, `✅.*완료`, `READY_TO_SHIP` | 큰 단위 작업 종료 (v0.3: Grade A/테스트 통과/커밋 push 추가) |
| **CODEX_LIMIT** | `usage limit`, `rate limit`, `try again at`, `Upgrade to Pro` | Codex/GPT 한도 도달 |
| **PUSH** | `git push`, `Pushed.*to`, `\* \[new branch\]`, `Everything up-to-date` | git push 발생 (배포 트리거 가능성) |
| **OOM** | `Killed`, `OOM`, `out of memory` | 메모리 부족 |
| **TEAMMATE_REVIEW** | `\[Review Request\]`, `code-review`, `peer review` | 동료 에이전트 리뷰 요청 |
| **CEO_GATE** | **숫자** `^\s*[1-9]\.\s` 3회 이상 OR **알파벳** `\([A-E]\)` 3회 이상 OR **결정 키워드** `어느 걸.*할까요\|결정 필요\|어느 쪽\|선택 필요\|CEO 결정\|Anything to correct\|사장님.*결정` | 서버 Claude가 CEO 결정 기다리는 중. 사장님께 즉시 선택 요청 (v0.3: 알파벳 옵션 + 한국어 결정 키워드) |

기본 폴링 주기 15초 (변경 가능). 모든 알림에 캡처된 pane 마지막 50줄을 함께 보냄.

## 호출 방법

```
/kdh-server-monitoring start            # 기본 설정으로 감시 시작
/kdh-server-monitoring stop             # 모든 감시 중지
/kdh-server-monitoring status           # 현재 활성 감시 목록
/kdh-server-monitoring --ssh-host=corthex --tmux-session=claude --interval=15
/kdh-server-monitoring --auto-approve   # PERM_WAIT 시 "1" + Enter 자동 전송
/kdh-server-monitoring --auto-cycle     # NEW_SESSION_SAVED 시 자동 /clear + /resume-session + 다음 지시 주입
/kdh-server-monitoring --include=admin-dev,claude   # 동시에 여러 tmux 세션 감시
/kdh-server-monitoring --next="다음 스토리 계속. 완료 시 /save-session."  # auto-cycle 시 resume 뒤 주입할 지시
```

## 1. 구현: Monitor + persistent

Monitor 도구로 백그라운드 감시 프로세스를 띄운다. `persistent: true`로 세션 끝까지 유지.

### 1-1. 단일 세션 기본 명령어

```bash
# Monitor에 들어갈 명령어 — 한 줄에 한 이벤트 emit
# v0.2: SSH ControlMaster + NEW_SESSION_SAVED 감시 + CEO_GATE 감시 추가
LAST_HASH=""
LAST_SESSION_FILE=""
IDLE_COUNT=0
SSH_HOST="${SSH_HOST:-corthex}"
SSH_BASE="ssh -o ControlMaster=auto -o ControlPath=/tmp/ssh-kdh-watch-%r-%h-%p -o ControlPersist=10m $SSH_HOST"
TMUX_SESSION="${TMUX_SESSION:-claude}"
INTERVAL="${INTERVAL:-15}"
IDLE_THRESHOLD="${IDLE_THRESHOLD:-4}"   # 4 * 15s = 60s
SESSION_DATA_DIR="${SESSION_DATA_DIR:-~/.claude/session-data}"

# 초기 baseline 잡기 (기존 파일들은 알림하지 않음)
LAST_SESSION_FILE=$($SSH_BASE "ls -t $SESSION_DATA_DIR/*.tmp 2>/dev/null | head -1" 2>/dev/null || true)

while true; do
    PANE=$($SSH_BASE "tmux capture-pane -t $TMUX_SESSION -p -S -50 2>/dev/null" 2>/dev/null)
    NOW=$(date +%H:%M:%S)
    # v0.4: IDLE 오탐 감소 — Party Mode placeholder 문구는 해시 계산 전 제거
    STRIPPED=$(echo "$PANE" | grep -vE "Still idle|Awaiting team-lead|Standing by as|Acknowledged\. Standing by|Enchanting…|Cooked for|Sautéed for|Blanching…|Tip: /mobile|Thinking$|Hmm…")
    HASH=$(echo "$STRIPPED" | sha256sum | cut -d' ' -f1)

    # v0.4: 현재 페르소나 추출 (Party Mode)
    CURRENT_PERSONA=$(echo "$PANE" | grep -oE "@(team-lead|john|winston|sally|dev|mary|po|sm|architect)" | tail -1 | tr -d '@')
    TEAM_LEAD_CTX=$(echo "$PANE" | grep -oE "Ctx ▓+░* [0-9]+%" | tail -1 | grep -oE "[0-9]+%")

    # NEW_SESSION_SAVED — session-data/*.tmp 새 파일 감지 (save-session 완료 신호)
    CURRENT_SESSION_FILE=$($SSH_BASE "ls -t $SESSION_DATA_DIR/*.tmp 2>/dev/null | head -1" 2>/dev/null || true)
    if [ -n "$CURRENT_SESSION_FILE" ] && [ "$CURRENT_SESSION_FILE" != "$LAST_SESSION_FILE" ]; then
        FNAME=$(basename "$CURRENT_SESSION_FILE")
        echo "[$NOW] NEW_SESSION_SAVED host=$SSH_HOST session=$TMUX_SESSION file=\"$FNAME\""
        LAST_SESSION_FILE="$CURRENT_SESSION_FILE"
    fi

    # CEO_GATE — 번호/알파벳 옵션 리스트 OR 결정 키워드 + input 대기 패턴 (v0.3 확장)
    NUM_OPT=$(echo "$PANE" | grep -cE "^\s*[1-9]\.\s" || true)
    ALPHA_OPT=$(echo "$PANE" | grep -cE "^\s*\([A-E]\)\s|^\s*-\s\([A-E]\)" || true)
    DECISION_KW=$(echo "$PANE" | grep -cE "어느 걸.*할까요|결정 필요|어느 쪽|선택 필요|CEO 결정|Anything to correct|choose|사장님.*결정" || true)
    TAIL_IDLE=$(echo "$PANE" | tail -5 | grep -qE "^❯\s*$" && echo 1 || echo 0)
    if [ "$TAIL_IDLE" = "1" ] && { [ "${NUM_OPT:-0}" -ge 3 ] || [ "${ALPHA_OPT:-0}" -ge 3 ] || [ "${DECISION_KW:-0}" -ge 1 ]; }; then
        GATE_LINES=$(echo "$PANE" | grep -E "^\s*[1-9]\.\s|^\s*\([A-E]\)\s|^\s*-\s\([A-E]\)" | head -5 | tr '\n' ' | ')
        echo "[$NOW] CEO_GATE host=$SSH_HOST session=$TMUX_SESSION options=\"${GATE_LINES:0:200}\""
    fi

    # IDLE 검출 (해시 비교)
    if [ "$HASH" = "$LAST_HASH" ]; then
        IDLE_COUNT=$((IDLE_COUNT + 1))
        if [ "$IDLE_COUNT" -ge "$IDLE_THRESHOLD" ]; then
            echo "[$NOW] IDLE host=$SSH_HOST session=$TMUX_SESSION duration=$((IDLE_COUNT * INTERVAL))s"
            IDLE_COUNT=0   # 한 번 알리고 카운트 리셋
        fi
    else
        IDLE_COUNT=0
        LAST_HASH="$HASH"
    fi

    # 패턴 매치 — 마지막 50줄 안에서 키워드 탐색 (각 패턴 1회만 알림하도록 dedup 키 사용)
    # v0.3: DONE 패턴 확장 (Grade A, N/N pass, commit push, 완료 한국어)
    SIG=$(echo "$PANE" | grep -oE "Bash command requires permission|requires permission|permission needed|Tool use approval|\(y/n\)|Would you like|Press enter to confirm|usage limit|rate limit|try again at|Upgrade to Pro|Error:|Failed:|Traceback|panic:|FAILED|ECONNREFUSED|Cannot connect|Sprint complete|Sprint.*완료|Story.*완료|Phase.*complete|Grade A|[0-9]+/[0-9]+ (pass|tests pass)|commit.*push|✅.*완료|READY_TO_SHIP|git push|Pushed.*to|\* \[new branch\]|Everything up-to-date|Killed|OOM|out of memory|\[Review Request\]" | head -3)

    if [ -n "$SIG" ]; then
        # v0.4: DONE이면 phase/critic/grade/score 파싱해서 dedup key 세분화
        CATEGORY="UNKNOWN"
        case "$SIG" in
            *permission*|*y/n*|*approval*|*"Would you like"*|*"Press enter to confirm"*) CATEGORY="PERM_WAIT" ;;
            *"usage limit"*|*"rate limit"*|*"Upgrade to Pro"*|*"try again at"*) CATEGORY="CODEX_LIMIT" ;;
            *Error:*|*Failed:*|*Traceback*|*panic:*|*FAILED*|*ECONNREFUSED*|*"Cannot connect"*) CATEGORY="ERROR" ;;
            *"Sprint complete"*|*"Sprint"*"완료"*|*"Story"*"완료"*|*"Phase"*"complete"*|*"Grade A"*|*"tests pass"*|*"pass"*|*"commit"*"push"*|*"✅"*"완료"*|*READY_TO_SHIP*) CATEGORY="DONE" ;;
            *"git push"*|*"Pushed"*|*"new branch"*|*"Everything up-to-date"*) CATEGORY="PUSH" ;;
            *Killed*|*OOM*|*"out of memory"*) CATEGORY="OOM" ;;
            *"Review Request"*) CATEGORY="TEAMMATE_REVIEW" ;;
        esac

        EXTRA=""
        if [ "$CATEGORY" = "DONE" ]; then
            # Phase A|B|C, critic 이름, Grade X, score N.NN 추출
            D_PHASE=$(echo "$PANE" | grep -oE "[Pp]hase [A-D]" | tail -1 | tr 'a-z' 'A-Z')
            D_CRITIC=$(echo "$PANE" | grep -oE "critic: (john|winston|sally|dev|mary)" | tail -1 | awk '{print $2}')
            [ -z "$D_CRITIC" ] && D_CRITIC=$(echo "$PANE" | grep -oE "as (john|winston|sally|dev|mary)" | tail -1 | awk '{print $2}')
            D_GRADE=$(echo "$PANE" | grep -oE "Grade [A-F]" | tail -1 | awk '{print $2}')
            D_SCORE=$(echo "$PANE" | grep -oE "\([0-9]+\.[0-9]+/5\)" | tail -1)
            EXTRA=" phase=${D_PHASE:-?} critic=${D_CRITIC:-?} grade=${D_GRADE:-?} score=${D_SCORE:-?}"
            DEDUP_SEED="DONE:${D_PHASE}:${D_CRITIC}:${D_GRADE}:${D_SCORE}"
        else
            DEDUP_SEED=$(echo "$SIG" | head -1)
        fi

        DEDUP_KEY="/tmp/kdh-watch-$(echo "$DEDUP_SEED" | sha256sum | cut -d' ' -f1 | cut -c1-12)"
        if [ ! -f "$DEDUP_KEY" ] || [ "$(find "$DEDUP_KEY" -mmin +15 2>/dev/null | wc -l)" -gt 0 ]; then
            PERSONA_INFO=""
            [ -n "$CURRENT_PERSONA" ] && PERSONA_INFO=" persona=$CURRENT_PERSONA"
            [ -n "$TEAM_LEAD_CTX" ] && PERSONA_INFO="$PERSONA_INFO ctx=$TEAM_LEAD_CTX"
            echo "[$NOW] $CATEGORY host=$SSH_HOST session=$TMUX_SESSION${PERSONA_INFO}${EXTRA} signal=\"$(echo "$SIG" | head -1 | tr '"' "'")\""
            touch "$DEDUP_KEY"
        fi
    fi

    sleep "$INTERVAL"
done 2>&1 | grep --line-buffered -E "PERM_WAIT|IDLE|ERROR|DONE|CODEX_LIMIT|PUSH|OOM|TEAMMATE_REVIEW"
```

### 1-2. Monitor 호출 예시

```
Monitor(
    description: "서버 corthex 'claude' tmux 감시 — perm/idle/error/done/codex/push",
    persistent: true,
    timeout_ms: 3600000,
    command: "<위의 1-1 명령어>"
)
```

## 2. 액션 흐름 (이벤트별)

각 이벤트가 `<task-notification>`으로 들어오면 다음을 자동으로 수행한다.

### 2-0. Push 강제 규칙 (v0.4 신규 — CEO "온갖 탐지를 다 먹으면 어떻게")

Conductor가 이벤트를 조용히 처리하지 않도록 **무조건 Push** 대상과 **suppress** 대상을 명시한다.

**무조건 Push (PushNotification 강제):**
- NEW_SESSION_SAVED — 새 세션 파일 발견
- PERM_WAIT — 권한 승인 대기
- ERROR / OOM — 에러 또는 메모리 부족
- DONE 이벤트 중 다음:
  - `phase` 또는 `grade` 값이 이전 Push와 다름 (새 Phase 완료)
  - "Story 완료" / "Sprint 완료" / "Phase complete" / READY_TO_SHIP 문구 존재
  - `git push` / "new branch" 감지
- CEO_GATE — 결정 옵션 3개 이상 또는 결정 키워드 매치
- IDLE `duration >= 900s` (15분 이상 멈춤)

**Suppress (Conductor 내부 ACK만, Push 안 함):**
- DONE 이벤트 중 이전 Push와 동일 `phase+critic+grade` 조합 (dedup 재탐지)
- IDLE `duration < 900s` (Party Mode 페르소나 전환 과도기)
- Resume 후 5분 이내에 발생한 DONE (baseline re-seed — 이전 세션 완료 건 재알림 방지)
- TEAMMATE_REVIEW 단독 (capture 확인 시 동일 페르소나 대기 반복이면 suppress, 새 페르소나 진입이면 Push)

**Conductor 행동 원칙:** 모호하면 Push. "이건 routine이다"고 먹는 횟수 = 실패 지표. CEO가 "계속 조용하네" 하면 규칙 미달.

### 2-1. NEW_SESSION_SAVED (v0.2 신규)

- **기본**: PushNotification으로 사장님께 알림 (`서버 Claude가 save-session 완료. 파일: {filename}. 다음 사이클 시작 필요.`)
- **--auto-cycle 옵션 시**: 다음 4단계 자동 실행 (각 단계 사이 Enter는 **반드시 별도 전송** — CLAUDE.md 3-1 규칙)
  1. `ssh $SSH_HOST "tmux send-keys -t $TMUX_SESSION '/clear' Enter"` → 3초 대기
  2. `ssh $SSH_HOST "tmux send-keys -t $TMUX_SESSION '/resume-session' Enter"` → 10초 대기 (브리핑 완료)
  3. 브리핑에서 "Ready to continue" 또는 "What would you like to do?" 감지되면:
  4. `--next="..."` 옵션의 지시문을 tmux send-keys로 주입 + Enter 별도 전송
- **--next 미지정 시**: auto-cycle은 /clear + /resume-session까지만 실행하고, 다음 지시는 사장님께 물음 (PushNotification)
- **연속 cycle 안전장치**: 같은 세션에서 5회 이상 auto-cycle 실행되면 stop + 사장님 호출 (무한 루프 방지)

### 2-1. PERM_WAIT
- **기본**: PushNotification으로 사장님께 알림 (`서버 Claude가 권한 대기. 캡처 pane 확인 요망.`)
- **--auto-approve 옵션 시**: `ssh $SSH_HOST "tmux send-keys -t $TMUX_SESSION '1' Enter"`로 자동 승인. 단 `Bash(rm`, `git push --force`, `git reset --hard` 같은 위험 명령이 캡처에 보이면 자동 승인 X — 무조건 사장님께 알림.

### 2-2. IDLE
- 60초+ 무 변동 시 1회 알림. 다음 변동 발생 전까지 추가 알림 안 함.
- **--auto-restart-on-idle=N 옵션 시 (N분)**: N분 idle이면 `ssh $SSH_HOST "tmux send-keys -t $TMUX_SESSION 'continue' Enter"` 자동 전송 (시도 1회만, 그래도 idle이면 사장님 호출).

### 2-3. ERROR
- 즉시 사장님 알림 + 캡처 pane 마지막 30줄 첨부.
- 자동 액션 없음. 사장님 판단 필요.

### 2-4. DONE
- 사장님 알림 + 캡처 pane 마지막 20줄 첨부.
- **--auto-followup 옵션 시**: 다음 작업 가이드를 사장님께 묻는 메시지 표시.

### 2-5. CODEX_LIMIT
- 사장님 알림 + "12:24 PM 같은 회복 시각이 메시지에 있으면 그 시각도 함께 보고".
- 자동 액션 없음. (서버 측 codex 한도는 본 세션에서 정상 동작 확인됨, 발견 시 그대로 보고만.)

### 2-6. PUSH
- 사장님 알림 ("$SSH_HOST에서 git push 감지. 배포 트리거 가능성.")
- 추가 정보: `ssh $SSH_HOST "cd /home/ubuntu/corthex-v3 && git log --oneline -3 && git status -s"` 함께 첨부.

### 2-7. OOM
- **즉시** 사장님 알림 (HIGH severity).
- `ssh $SSH_HOST "free -h && ps aux --sort=-%mem | head -10"` 추가 첨부.

### 2-8. TEAMMATE_REVIEW
- 사장님 알림 + 어느 teammate가 누구에게 리뷰 요청했는지 캡처에서 추출.
- 자동 액션 없음.

## 3. 다중 세션 감시 (`--include=A,B,C`)

쉼표로 여러 tmux 세션을 지정하면 각각 별도 Monitor를 띄운다. 본 세션에서 사장님이 운영하는 서버에는 통상 다음 두 세션 존재:

- `claude` (메인 서버 Claude)
- `admin-dev` (관리/개발 보조)

```
/kdh-server-monitoring --include=claude,admin-dev
```

→ 두 개의 persistent Monitor 동시 실행, 각각 description에 세션 이름 포함.

## 4. 상태 관리

`~/.local/state/kdh-server-monitoring/state.json` 파일에 활성 Monitor 목록 기록:

```json
{
  "monitors": [
    {
      "task_id": "abc123",
      "ssh_host": "corthex",
      "tmux_session": "claude",
      "started_at_utc": "2026-04-17T01:30:00Z",
      "interval_s": 15,
      "auto_approve": false,
      "include": ["claude"]
    }
  ]
}
```

`/kdh-server-monitoring status` → 위 파일 읽고 표 형태로 출력 + 각 Monitor의 마지막 이벤트 시각.

`/kdh-server-monitoring stop` → state.json의 모든 task_id에 대해 TaskStop 호출 후 파일 비움.

## 5. 보안 가드 (CEO directive 5b 적용)

- **자동 승인 시 위험 명령 거부 목록** (v0.2: 프로덕션 관련 추가):
  ```
  rm -rf
  git push --force
  git push -f
  git push.*main.*force
  git reset --hard
  drop database
  drop table
  truncate
  /etc/
  systemctl stop corthex-v3
  systemctl disable
  systemctl restart corthex-v3    # 수동 재시작은 사장님 확인
  rm.*corthex-v3-deploy           # 배포 worktree 건들면 알림
  curl.*\| (sh|bash)
  wget.*\| (sh|bash)
  sudo.*shutdown
  sudo.*reboot
  ```
- 위 목록 패턴이 캡처에 보이면 `--auto-approve` / `--auto-cycle` 옵션이 켜져 있어도 자동 실행 안 하고 사장님께 즉시 알림 (HIGH).
- **auto-cycle의 `--next` 지시문도 필터 통과**: 주입할 지시문에 위 패턴 있으면 거부.

## 6. 사용 예시

### 예시 1: 사장님 자러 가기 전, 기본 감시 시작
```
/kdh-server-monitoring start
```
→ corthex의 `claude` 세션을 15초 주기로 감시. 모든 신호 발생 시 PushNotification.

### 예시 2: 권한은 자동 승인하되 위험 명령은 알림
```
/kdh-server-monitoring start --auto-approve
```
→ PERM_WAIT 발생 시 "1" + Enter 자동 전송. 위 5절의 위험 명령 패턴이 보이면 알림으로 fallback.

### 예시 3: 두 tmux 세션 + 5분 idle 시 자동 continue
```
/kdh-server-monitoring start --include=claude,admin-dev --auto-restart-on-idle=5
```

### 예시 4: 현재 활성 감시 확인
```
/kdh-server-monitoring status
```
→ 표:
```
| task_id    | host    | session    | interval | auto-approve | last_event           |
|------------|---------|------------|----------|--------------|----------------------|
| abc123     | corthex | claude     | 15s      | false        | 09:30 PERM_WAIT      |
| def456     | corthex | admin-dev  | 15s      | false        | 09:15 IDLE (60s)     |
```

### 예시 5: 모두 중지
```
/kdh-server-monitoring stop
```

## 7. 향후 v0.2 백로그

- **/save-session 통합**: stop 시 마지막 1시간 이벤트 로그를 세션 파일에 자동 첨부
- **알림 분류 학습**: false positive 패턴 (예: "Failed to load extension")을 사용자가 mark하면 다음번부터 무시
- **다른 host 지원**: corthex 외에 다른 SSH 호스트 (사장님 추가 서버)
- **Slack/카카오 webhook**: PushNotification 대신 외부 채널로 라우팅
- **이벤트 ledger**: 모든 알림을 `~/.local/state/kdh-server-monitoring/events.jsonl`에 append-only로 저장 (사후 분석용)
- **헌법 통합**: Topic 1 BRD-015 logger와 정합성 (board-events와 별도 로그)
- **자동 회복 액션 확장**: Codex 한도 회복 시각이 알려지면 해당 시각에 자동 재호출 (ScheduleWakeup 통합)

## 8. 의존성

- `ssh corthex` (또는 사용자 SSH alias) — 비밀번호 없이 키 기반 접속 가능해야 함
- 서버에 `tmux` 설치 + 대상 세션이 실제로 존재
- Monitor 도구 (Claude Code 기본 제공) + PushNotification 도구
- `sha256sum`, `grep --line-buffered`, `find` (표준 GNU 유틸)

## 9. 한계

- **30초 이내 발생 후 사라지는 신호는 놓칠 수 있음** — 캡처는 마지막 50줄만 봄.
- **신호 패턴이 한국어/일본어/한자 등 비-라틴이면 매치 안 됨** — v0.2에서 다국어 패턴 확장 검토.
- **자동 승인은 "1" + Enter만 전송** — 다단계 confirmation (예: "정말 실행? (yes/no)")은 미지원.
- **IDLE 검출은 pane 텍스트 해시 비교 기반** — spinner 같은 시각적 변동도 "활동"으로 간주됨. 즉 spinner가 계속 돌면 IDLE 안 잡힘.

---

**스킬 만든 사람:** A (Claude Opus 4.7), 2026-04-17 ~10:15 KST
**근거:** 본 세션 (board v2 5라운드 5토픽 + 6 reports) 동안 Monitor `bkye4nwig` ("corthex-v3 leader+dev: 권한/idle/error/done/codex/push 감시")로 운영한 패턴을 영구 스킬화.
**버전 이력:**
- v0.1 (2026-04-17 ~10:15 KST) — 초기 8 신호 + --auto-approve + 보안 가드
- v0.2 (2026-04-17 ~15:30 KST) — 실측 후 강화:
  - **NEW_SESSION_SAVED** 신호 추가: `~/.claude/session-data/*.tmp` 폴더 mtime 감시 → 스토리 3개 사이클 자동 감지 (서버 Claude CLAUDE.md "스토리 3개마다 save-session" 룰과 결합)
  - **CEO_GATE** 신호 추가: 번호 옵션 리스트 감지
  - **--auto-cycle** 옵션: NEW_SESSION_SAVED 시 자동 /clear + /resume-session + --next 지시 주입
  - SSH ControlMaster 적용 — 연결 재사용으로 서버 부담 감소
  - 위험 명령 거부 목록에 `systemctl restart corthex-v3`, `rm.*corthex-v3-deploy`, `git push.*main.*force`, `sudo shutdown/reboot` 추가 (배포 worktree 분리 구조 반영)
  - auto-cycle 무한 루프 안전장치 (5회 이상 시 stop)
- v0.3 (2026-04-17 ~16:30 KST, kdh-server-claude-watch → kdh-server-monitoring 개명)
  - DONE 패턴 확장: Grade A / N/N pass / commit push / ✅ 완료
  - PERM 패턴 확장: Would you like / Press enter to confirm
  - 위험 명령 블랙리스트 확장 (배포 worktree 경로 보호)
- v0.4 (2026-04-17 17:40 KST, CEO 지적 "온갖 탐지를 다 먹으면 어떻게") — Conductor 실측 피드백:
  - **DONE 세분화**: phase+critic+grade+score 파싱 → dedup key 정밀화 (같은 "Grade A"라도 Phase A john vs Phase B winston 구별)
  - **IDLE 오탐 감소**: Party Mode placeholder 문구("Still idle", "Awaiting team-lead", "Enchanting…", "Thinking") 해시 계산 전 strip
  - **Push 강제 규칙** (섹션 2-0 신설): 무조건 Push / suppress 목록 명시 — Conductor가 이벤트 조용히 처리하지 않도록 강제
  - **Party Mode 페르소나 인식**: 현재 페르소나(@team-lead/@critic) + team-lead Ctx% 추출 → save-session 임박 판단은 team-lead 윈도우 기준
  - **dedup TTL 5분 → 15분**: 같은 Phase 완료 반복 재탐지 빈도 감소 (mouse escape / pane scroll 변동 무시)
  - **Resume baseline re-seed** (로직 명시): Conductor 재시작 직후 5분 내 기존 완료 DONE은 ACK만 하고 Push 생략
  - **Deprecated alias 경고**: 옛 `/kdh-server-claude-watch` 슬래시 커맨드는 세션 시작 시 로드된 레지스트리에 남을 수 있음 — 세션 재시작 후 /kdh-server-monitoring만 유효
