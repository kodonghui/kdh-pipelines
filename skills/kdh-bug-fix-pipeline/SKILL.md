---
name: 'kdh-bug-fix-pipeline'
description: 'Bug Fix Pipeline v3 — browser-use 중심 E2E 버그 탐색 + 수정 + 검증 루프. 경량화: 참조 docs/ + 스킬 분리. 사장님 명령어: /kdh-bug-fix-pipeline [auto|계속|scan|fix BUG-XXX|verify|deploy]'
---

# Bug Fix Pipeline v3 (경량화)

> v3 변경: Phase 2 리팩터링. 851줄 → ~195줄. 참조 문서/스킬 분리.
> 분리된 문서: docs/ (agent-spawn-template, metrics-schema, bug-fix-state-schema, browser-use-config, escalation-routing)
> 연관 스킬: /kdh-party-mode, /kdh-ui-verify, /kdh-project-scan

<HARD-GATE>
1. 근본 원인 못 찾으면 수정 금지 — root_cause null이면 Step 2b 진입 불가
2. Playwright 테스트 없이 Fix Complete 불가 — 모든 버그에 회귀 테스트 필수
3. browser-use FAIL이면 전체 FAIL — Playwright만 PASS로는 부족
4. Codex FAIL = 자동 진행 금지 — 수정 후 재실행. 미실행 = Phase 4 금지
5. CEO GATE 없이 종료 불가 — Phase 4e CEO 확인 필수 (계속 모드 제외)
6. 5개 테마 전부 확인 — 1개만 = D6 auto-FAIL
7. localhost + 프로덕션 둘 다 확인 — Phase 4d 프로덕션 browser-use 필수
8. 외부 루프 최대 5회 — 초과 시 CEO 보고 + 강제 종료
9. 새 기능 분류 → CEO 보고 — bugfix에서 기능 구현 금지
10. Origin 미지정 = Phase 3 금지 — 모든 버그에 origin(code/design/requirements/test)
11. 에스컬레이션 자동 금지 — design/requirements는 CEO 확인 후에만
12. Cross-Model 둘 다 FAIL = CEO 보고 — 자동 스킵 금지
13. 테스트 없이 커밋 금지 — party-log + Playwright 테스트 존재 확인
14. Entry/Exit 5조건 전부 충족 — browser-use 0bugs + Playwright 100% + Codex PASS + tsc PASS + CEO approved
15. TeamCreate 필수 — Phase 2 에이전트 소환 전 TeamCreate. 종료 시 TeamDelete
16. bug-fix-state.yaml 멀티라인 필수 — 인라인 YAML {key: value} 금지
17. compliance YAML 기록 — Phase 완료마다 compliance/bugfix-{date}-phase-{N}.yaml
18. context-snapshot 저장 — Phase 완료마다 context-snapshots/bug-fix/ 저장
19. 폐기 기준 — 2 Sprint 연속 무효과 규칙은 폐기 후보. 다음 고도화 시 CEO 확인 후 삭제
</HARD-GATE>

## Red Flags

| Claude가 이렇게 생각하면 | 실제로는 |
|----------------------|---------|
| "Playwright 통과했으니 OK" | browser-use도 필수. Rule #1 |
| "일단 고치고 원인은 나중에" | 근본 원인 먼저. Rule #9 |
| "CSS !important로 해결" | 증상 치료 금지. Anti-Pattern #2 |
| "1개 테마만 확인" | 5개 전부. Rule #8 |
| "시간 오래 걸리니 중단" | timeout 없음. stall만. Rule #14 |
| "여기도 고치는 김에" | 최소 변경. 버그만 고침. Rule #17 |
| "dev 서버 안 켜도 될 것 같은데" | 필수. Anti-Pattern #7 |
| "비슷한 버그니까 원인 같겠지" | 각각 조사. Rule #9 |
| "검증 안 해도 코드 보면 되잖아" | 도구 실행 증거 필수 |

## Mode Selection

| 명령어 | 동작 |
|--------|------|
| `auto` (기본) | bug-fix-state.yaml 읽고 이어서. 없으면 Phase 1 |
| `계속` | 밤새 모드 — Phase 4 GATE만 자동, 외부 루프 5회 제한 |
| `scan` | Phase 1만 (전수 탐색) |
| `fix BUG-XXX` | 특정 버그만 Phase 2 |
| `verify` | Phase 3만 (전체 회귀) |
| `deploy` | Phase 4만 (배포 + CEO) |

Ralph Loop: `while true; do claude -p "/kdh-bug-fix-pipeline 계속"; sleep 5; done`

---

### ★ 자동 스킬 로드 (분리된 스킬 — 반드시 Read)

<HARD-GATE>
오케스트레이터는 파이프라인 시작 시 Read tool로 반드시 읽어라:
1. Party Mode: Read ~/.claude/skills/kdh-party-mode/SKILL.md
읽지 않고 Phase 2e Party Mode 실행 = 규칙 위반.
</HARD-GATE>

## Step -1: Tool Readiness → Step 0: /kdh-project-scan → Step 0.5: Active Plans

Step -1: browser-use venv + Playwright + Codex + Gemini + Dev 서버 + OpenAI API 키 검증. 🚩 1개라도 → 즉시 중지.
Step 0: /kdh-project-scan → project-context.yaml 캐시.
Step 0.1: ★ Read ~/.claude/skills/kdh-party-mode/SKILL.md (Party Mode 규칙 로드)
Step 0.5: _index.yaml에서 pipeline:"bug-fix" or "all" plan 읽기.

---

## Phase 1: SCAN — browser-use 전수 탐색

```
오케스트레이터 직접 실행 (에이전트 없음)

Step 1: Playwright 기존 smoke 실행 → FAIL = 확실한 버그
Step 2: browser-use 전수 탐색 (sweep.py → docs/browser-use-config.md 참조)
  ★ timeout 없음. stall(5분 무활동)만 감지 → 다음 페이지로
Step 3: 서버 로그 분석 (Error/500/FATAL grep)
Step 4: 3소스 종합 → bug-fix-state.yaml 생성 (docs/bug-fix-state-schema.md 참조)
Step 4.5: 멀티 테마 중복 제거 — 같은 (page, component, css_property) = 1 master bug
Step 5: CEO 보고 (심각/보통/경미 건수 + feature-request 분리)

★ bugs 0 → "깨끗합니다!" → 종료
```

## Phase 2: FIX+VERIFY 루프

```
팀: dev(Writer,sonnet), quinn(Critic,sonnet), winston(Critic,sonnet)
Grade B (≥7.5/10, 1 cycle). haiku 금지. 처리 순서: critical → major → minor

각 버그마다:
━━━━━━━━━━━━━━━━
Step 2a: DIAGNOSE (오케스트레이터)
  - 관련 파일 Grep + 서버 로그 추출 → 근본 원인 1줄 특정
  - Origin 판단 (ODC): code | design(3회+ 같은 컴포넌트) | requirements(API 불일치) | test
  - Dependency Correlation: git log → 변경 커밋과 버그 연결
  - status: discovered → diagnosing

Step 2b: FIX (dev)
  - 최소 변경. 버그만 고침. 리팩토링 금지. tsc 통과 필수.
  - status: diagnosing → fixing

Step 2c: REGRESSION TEST (dev)
  - Playwright 테스트 작성: e2e/bugfix/bug-{id}.spec.ts
  - repro 시나리오를 코드로 고정 → 실행 PASS 확인
  - dev → [Fix Complete]

Step 2d: VERIFY (오케스트레이터)
  1. Playwright 회귀 테스트 실행
  2. browser-use 재확인 (verify-bug.py)
  3. 둘 다 PASS → Step 2e. 하나라도 FAIL → Step 2b (재수정)
  4. fix_attempts >= 3 → ESCALATE (CEO 보고)

Step 2e: REVIEW (Party Mode — 2 critics)
  > 참조: /kdh-party-mode → "리뷰 수용 규칙" 6단계 프로세스
  quinn: D1(재현성) + D3(회귀방지) + D4(부작용)
  winston: D2(근본원인) + D5(코드품질) + D6(테마호환)
  party-log: bugfix-{id}-quinn.md, bugfix-{id}-winston.md
  Cross-talk 필수: 상호 로그 Read → Cross-talk 섹션 추가
  avg >= 7.5 → PASS. avg < 7.5 → fixes → 재리뷰 (max 1). Any D < 2 → auto-FAIL
  ★ Critics에게 dev 수정 의도 전달 금지. bug report + 코드만 (자기평가 편향 방지)

Step 2f: 상태 업데이트 → 다음 버그로

모든 버그 수정 → Phase 3
```

## Phase 3: SWEEP — 전체 회귀 + Codex

```
Step 3a: Playwright 전체 suite → FAIL = 새 버그 → Phase 2로
Step 3b: bun test 전체 → FAIL = 새 버그 → Phase 2로
Step 3c: tsc 전체 → FAIL = 수정 필요
Step 3d: browser-use 전수 재탐색 → 새 버그 = Phase 2로 (외부 루프)
  ★ outer_loop_count >= 5 → CEO 보고 + 강제 종료
Step 3e: Cross-Model 일괄 (Codex+Gemini 병렬)
  둘 다 PASS → Phase 4. 둘 다 FAIL → 수정 후 재실행. 실행 불가 → CEO 보고
Step 3f: 5개 테마 스크린샷 (주요 페이지 × 5테마)
```

## Phase 4: DEPLOY + GATE

```
Step 4a: tsc 최종 + git status 확인
Step 4b: git commit -m "fix: {N}건 버그 — browser-use sweep #{count}"
Step 4c: git push → 배포 대기
Step 4d: 프로덕션 browser-use 확인 → localhost와 차이 있으면 env/deploy 버그
Step 4e: CEO GATE — "버그 N개 수정! 프로덕션에서 확인해주세요."
  → CEO "OK" → gate: approved → 종료
  → CEO "이상해" → 새 버그 → Phase 1 (새 sweep)
  → 계속 모드: [AUTO] 자동 통과
```

---

## Defense & Stall Detection

| 메커니즘 | 조건 | 행동 |
|----------|------|------|
| stall | 5분 무활동 | 현재 페이지 종료 → 다음 페이지 |
| fix_max | 버그당 3회 | ESCALATE → CEO |
| outer_loop | Phase 3→2 루프 5회 | 강제 종료 + 잔여 버그 목록 |
| action_loop | 10회 action 1-2-3 반복 패턴 | 경고 + 페이지 종료 |
| server_crash | sweep 중 5xx 3연속 | sweep 중단 → 서버 재시작 → source: server-crash |

★ **timeout 없음** — stall만. browser-use가 20분 걸려도 탐색 중이면 정상.

## Entry / Exit Criteria

**Entry**: CEO 버그 보고, Sprint End GATE 실패, Sprint End 자동 연동 (dev-pipeline Rule #40)
**Exit (전부 충족)**: browser-use 0bugs + Playwright 100% + Codex PASS + tsc PASS + CEO approved

---

## 참조 링크

| 참조 | 위치 |
|------|------|
| Party Mode (리뷰) | /kdh-party-mode (Sprint Dev = per-step v10.3) |
| UI Verification | /kdh-ui-verify |
| Project Scan | /kdh-project-scan |
| Agent Spawn Template | docs/agent-spawn-template.md |
| Metrics Schema | docs/metrics-schema.md |
| State Schema | docs/bug-fix-state-schema.md |
| browser-use Config | docs/browser-use-config.md |
| Escalation Routing | docs/escalation-routing.md |
| Pipeline Protocol | docs/pipeline-protocol.md |
| Agent Roster | docs/agent-roster.md (Bug Fix: dev+quinn+winston, analyst 조건부) |
| Model Strategy | docs/model-strategy.md (전부 sonnet, haiku 금지) |
| 리뷰 수용 규칙 | /kdh-party-mode → "6단계 수용 프로세스" |

## 훅 커버리지 메모

다음 규칙은 Phase 1 훅이 자동 강제:
- compliance-checker: 커밋 전 party-log + codex status 확인
- quality-gate: Edit 후 타입 체크/린트 (async)
- verification-check: 증거 없이 완료 선언 차단
- loop-detector: 같은 파일 반복 수정 경고
- safety-guard: 파괴 명령 차단
- block-no-verify: --no-verify 차단
