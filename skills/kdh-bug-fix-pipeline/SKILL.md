---
name: 'kdh-bug-fix-pipeline'
description: 'Bug Fix Pipeline v3.0 — 30분 주기 루프: 배포 확인 → 문서 전수검수 → Chrome MCP 자율 E2E + EARS/BARS 명세 → 픽스 → 배포. CEO 명령어: /kdh-bug-fix-pipeline (또는 loop 등록 시 30m 주기 자동 fire)'
---

# Bug Fix Pipeline v3.0 — Chrome MCP + EARS/BARS Loop

## 운영 형태

- **주기:** 30분 (`13,43 * * * *` cron, 클래시 피하려 :13/:43 고정)
- **사용 도구:** Chrome MCP (`claude-in-chrome` MCP 서버)
- **담당:** server Claude (CWD `/home/ubuntu/corthex-v3`)
- **산출물:** `_bmad-output/bug-fix/e2e-sweep-{timestamp}-spec.md` (EARS/BARS 명세) + commit/push

## 4 Step 순서 (매 fire 마다 수행)

### Step 1 · 배포 상태 확인

```bash
gh run list --repo kodonghui/corthex-v3 --limit 3 --json status,conclusion,displayTitle
gh run view <id> --repo kodonghui/corthex-v3 --json jobs --jq '.jobs[] | "\(.name): \(.status) \(.conclusion)"'
```

- 최근 push → deploy success 확인.
- e2e-hub SKIP 은 OK (DATABASE_URL secret 없을 때 gate).
- failure 시 즉시 `gh run view <id> --log-failed` → 원인 파악 후 fix + re-push.

### Step 2 · Planning + 이사회 문서 전수검수

매 fire 마다 다음 파일 mtime 확인 + delta 있으면 정독:

1. **corthex-v3**: `ROADMAP.md`, `CLAUDE.md`, `.claude/rules/*.md`,
   `_bmad-output/phase-*/planning-artifacts/prd.md` (current phase only),
   `_bmad-output/pipeline-state.yaml`.
2. **kdh-conductor**: `CLAUDE.md`, `README.md`, `conductorA/STATUS.md`, `DECISIONS.md`,
   `_bmad-output/kdh-plans/_index.yaml`, `_bmad-output/codex-orders/20*-orders-exec.md` (최신),
   `_bmad-output/board-*/`.

변화 없으면 "delta 없음" 로깅 후 Step 3.

### Step 3 · Chrome MCP 자율 E2E + EARS/BARS 명세

#### 3.1 seed 계정

- `qa-sweep@corthex-hq.com` / `CorthexSweep2026!`
- 비활성이면 `bun run packages/server/scripts/seed-sweep-account.ts` 재실행.

#### 3.2 탐색 대상 (admin + app 모두)

- **admin**: login, dashboard, divisions, teams, agents, agents/:id, members,
  conversations, settings, audit-logs, nexus-org-chart, approvals, agent-memory, runs/:id
- **app**: login, hub, chat, mini-office, profile, oauth-callback
- 3 테마 전환 (Paper/Carbon/Signal)
- 빈 상태, 로딩, 에러 경로
- 모바일 뷰포트 (375×812)

#### 3.3 각 페이지 체크

- `bodyHead.slice(0, 300)` — 렌더
- `document.querySelector('[role="alert"]')` — 에러 배너
- `read_console_messages({onlyErrors: true, pattern: 'error|Error|fail'})` — 콘솔
- `read_network_requests({urlPattern: '/api/'})` — 401/403/500
- 클릭 가능한 버튼/링크 샘플 실행
- 텍스트 입력 가능한 곳 (chat 등) 실제 보내보기

#### 3.4 EARS 명세 형식

```
### BUG-YYYYMMDD-NNN · <한 줄 제목>
- **EARS**: When|While|If <trigger>, the <system> shall <response>.
- **Observed**: <실제 결과, 콘솔/네트워크 근거>
- **Expected**: <기대 결과, PRD 섹션 번호 or DESIGN.md 섹션>
- **Severity**: BARS <1-5> <LABEL>
- **Fix location**: <파일 경로 + 함수/라인>
```

#### 3.5 BARS 심각도 (고정)

| Level | Label     | Anchor                                                                           |
|-------|-----------|----------------------------------------------------------------------------------|
| 5     | BLOCKER   | 기능 진입 자체 불가. 401/500/redirect loop. 사용자가 아무 것도 못 함.               |
| 4     | CRITICAL  | 핵심 기능 데이터/동작 오류. 사용자가 잘못된 결론.                                   |
| 3     | MAJOR     | 보조 기능 오동작, 라벨 혼동, 라우팅 이상. 워크어라운드 가능.                        |
| 2     | MINOR     | 표시 오류 (하드코딩, 정렬). 기능은 동작.                                           |
| 1     | TRIVIAL   | 타이포/색 어긋남 등 미세.                                                         |

#### 3.6 저장

`_bmad-output/bug-fix/e2e-sweep-{YYYYMMDD}-{HHMM}-spec.md`

### Step 4 · 픽스

#### 4.1 우선순위

- BARS 5 (BLOCKER) → 즉시 fix
- BARS 4 (CRITICAL) → 이번 fire 내 fix 시도
- BARS 3 (MAJOR) → 다음 fire 처리
- BARS 2~1 → batch 가능

#### 4.2 구현 원칙

- 실패 페이지마다 dev agent 병렬 dispatch 또는 server Claude 직접 Edit.
- 수정 후 `bun run type-check` green 필수.
- Scope 큰 수정 (API wiring, 새 기능) 은 `_bmad-output/bug-fix/DEFERRED-BUG-XXX.md` 로 분리.

#### 4.3 Commit + Push

- `fix(<scope>): BUG-XXX <short-title>` 또는 다건 묶으면 multi-line body 에 bug-id 전부 명시.
- `git push` → `gh run list` CI 추적.
- **Bug fix (route-guard / data-wiring / 표시 버그)** 는 Party Mode 생략 OK (CEO 2026-04-21 합의).
- **신규 기능 / architecture change** 는 `/kdh-dev-pipeline` 으로 분기.

### Step 4.5 · 배포 검증

- CI success 후 Chrome MCP 로 해당 페이지 re-navigate 해 수정 반영 확인.

## Loop 등록

### 현 세션
```
/loop 30m (1) 배포 (2) prd 등 planning문서와 condoctor폴더위 회의록 및 plan문서를 전수검수해서 숙지 (3) chrome extention으로 너가 직접 e2e를 자유롭게 돌아다니며 모든 ui눌러보고 채팅도 해보고 작동이나 기능이 안되는건 EARS 및 BARS 으로 명세표 작성해 (4) 버그 픽스
```

### Cron 직접 (session only)
```
CronCreate(cron: "13,43 * * * *", prompt: "<위 프롬프트 그대로>", recurring: true)
```

### Cloud 영속화 (선택)
`/schedule` durable 등록 가능. 단 server Claude 세션 (corthex-v3 CWD + Chrome MCP 접속) 필요.

## 기존 v2 와의 관계

- v2 (Phase 1 SCAN → 2 FIX → 3 SWEEP → 4 DEPLOY, 3사 sweep + origin 분류 + party-log)
  는 **Sprint End full sweep** 용으로 보존. 이 파일 bottom 의 Appendix 참조.
- v3 (본 파일) 은 **상시 감시 루프**.
- 전환:
  - Sprint 중: v3 (30분 주기)
  - Sprint End: v3 결과 누적 + v2 3사 full-sweep 1회 실행 → merge
- v3 가 포착 못 하는 레이어 (성능, A11y, SEO, 크로스 브라우저) 는 v2 유지.

## Honesty Contract

- 루프 내 sweep/fix 실패 시 `_bmad-output/conductor-impl-{ts}.md` 에 기록.
- 절대 Skip/축약 금지. 다음 fire 에서 이월.
- Sandbox denial 은 honest skip + CEO 명시 승인 요청.

## 산출물 예시

- `_bmad-output/bug-fix/e2e-sweep-20260421-0113-spec.md` — 첫 fire, 9 bugs (BUG-001~009)
- `cd31ac9d fix(ui): dashboard greeting/date dynamic + teams/members include userType` — 첫 fire fix

---

## Appendix · v2 (Phase 1~4, Sprint End full sweep)

기존 v2 세부 규칙은 하위 호환을 위해 보존됩니다:
- Phase 1 SCAN: browser-use 3사 (OpenAI + Gemini + Claude) full sweep + merge
- Phase 2 FIX: TeamCreate + origin 분류 + party-log 2명 (winston + quinn)
- Phase 3 SWEEP: 변경 페이지 re-sweep
- Phase 4 DEPLOY: CI + VPS deploy.sh

Sprint End 에서만 v2 전체 실행. 평소 루프는 v3.
