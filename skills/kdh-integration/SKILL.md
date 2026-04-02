---
name: kdh-integration
description: "통합 리뷰 — Story 간 / Sprint 간 코드 통합 검증. Second Opinion Agent. 재형님 가설 기반 v13."
---

## Codex 역할 분담 (중요)

- **스토리 레벨 Codex**: kdh-sprint Phase B.5에서 1회 실행 (최대 1회 재실행)
- **배치/스프린트 레벨 Codex**: kdh-integration에서 실행 — 여기서 꼼꼼히 돌림
- 스토리별 Codex에서 놓친 것은 배치/스프린트 Codex가 잡는다.
- 중복 실행 금지 — kdh-integration은 통합 검증에 집중.

---

# KDH Integration v13 — "같이 붙여봤냐?"

Story 단독 리뷰(Level 1)로는 못 잡는 통합 버그를 잡는다.
독립 Claude 에이전트로 second opinion을 받아 blind spot을 보완.

## When to Use

- `/kdh-integration batch` — Batch(3개 스토리) 완료 후 Story 간 통합 리뷰
- `/kdh-integration sprint` — Sprint 완료 후 Sprint 간 회귀 리뷰
- `/kdh-sprint`에서 자동 호출됨 (직접 안 쳐도 됨)

## Pattern

```
Level 2 (Batch): "이 스토리들이 서로 안 깨뜨리나?"
Level 3 (Sprint): "이번 Sprint가 이전 Sprint를 안 깨뜨리나?"

Claude = 1차 분석 (자동 검증 스크립트)
Second Opinion Agent = 2차 의견 (독립 Claude 에이전트, fresh context, 읽기 전용)
Claude = 최종 판정 (Second Opinion + 자체 분석 종합)
```

---

## Prerequisites

```
1. sprint-status.yaml 읽기 가능
2. git history 접근 가능
3. Agent 도구 사용 가능 (Second Opinion 에이전트 소환용)
```

---

## Level 2: Batch Integration Review

```
시점: kdh-sprint Step 5.5에서 호출 (Batch 완료 시)
입력: 이번 Batch의 스토리 ID 목록
범위: git diff {batch-start-commit}..HEAD
```

### Phase 0: Context Load

```
1. 이번 Batch에서 완료된 스토리 목록
2. 각 스토리의 변경 파일 목록 (git diff --name-only per story commit)
3. 파일 간 교차점 찾기:
   - Story A가 수정한 파일을 Story B가 import → "교차 의존성"
   - 같은 파일을 2개 이상 스토리가 수정 → "충돌 위험"
```

### Phase 1: Cross-Impact Analysis

```
1. 공유 컴포넌트 변경 스캔:
   변경된 파일 중 export가 있는 것:
     grep -l "export" {changed_files}
   그 export를 다른 파일이 import하는지:
     grep -rl "from '.*{filename}'" packages/ --include="*.ts" --include="*.tsx"
   import하는 파일이 있고 + export 시그니처가 바뀌었으면 → INTEGRATION-WARNING

2. 미들웨어 체인 일관성:
   packages/server/src/routes/*.ts 파일들의 미들웨어 사용 비교:
     requireAuth, verifyTeamOwnership 등
   Story A가 미들웨어 추가/변경했는데 다른 라우트에 영향 → WARNING

3. 프론트 라우팅 일관성:
   packages/admin/src/main.tsx의 Route 정의
   vs 실제 페이지 컴포넌트의 auth 요구사항
   ProtectedRoute 안의 페이지가 비인증 접근 시도 → WARNING

4. 환경변수 교차 검증:
   이번 Batch에서 새로 추가된 process.env.XXX:
     .env.example에 있는지 확인
     fallback이 localhost면 → WARNING
```

### Phase 1.5: 세컨드 오피니언 — Codex CLI (1차) + Claude Agent (백업)

```
1차: Codex CLI (npx @openai/codex) exec 모드 — GPT-5.4 fresh session, 별도 모델 독립 시각
2차: Codex 실패 시 Claude Agent fallback

인증: ~/.codex/auth.json (device-auth 방식, 이미 완료)
모드: exec (비대화형, TTY 불필요)
세션: 매번 fresh session (편향 방지 — 영속 세션 안 씀)

--- Codex CLI (1차 시도) — tmux 실시간 패턴 (CEO가 봄) ---

1. git diff {batch-start}..HEAD > /tmp/batch-diff.txt

2. Codex tmux 창 열기 + 리뷰 보내기 (Bash 도구):
   # Codex 창 열기 — CEO가 실시간으로 작업 과정을 봄
   CODEX_PANE=$(tmux split-window -h -P -F '#{pane_id}' "bash")
   tmux select-pane -t $CODEX_PANE -T "codex-batch-reviewer"

   # Codex한테 통합 리뷰 보내기
   tmux send-keys -t $CODEX_PANE 'npx @openai/codex exec - --json \
     --sandbox read-only \
     -o _bmad-output/party-logs/{sprint}-batch-{N}-second-opinion.md \
     -C /home/ubuntu/corthex-v3 <<'"'"'PROMPT'"'"'
   Integration review for batch {N}.
   Read /tmp/batch-diff.txt and analyze for cross-story integration issues.
   Focus: shared component changes, middleware consistency, auth flow,
   env vars, type signature changes.
   DO NOT modify source code — read-only analysis only.
   PROMPT' C-m

3. 완료 대기 (프롬프트 복귀 확인):
   while ! tmux capture-pane -t $CODEX_PANE -p | grep -q '❯'; do sleep 3; done

4. 결과 파일 읽기 (-o 플래그로 자동 저장됨) → Phase 2로 이동

5. Codex 창 닫기: tmux kill-pane -t $CODEX_PANE

--- Codex 실패 시 (인증/타임아웃) ---

★ Claude Agent fallback 금지 (CLAUDE.md 절대 규칙) ★
Codex가 못 돌아가면 → 멈추고 CEO에게 보고. 자동 스킵 금지.
CEO가 '스킵 OK' → sprint-status.yaml에 codex_skipped: true 기록.
CEO 응답 없으면 → 대기.

--- Codex FAIL 판정 시 ---

★ Codex FAIL → 수정 후 Codex 재실행 → PASS까지 반복 ★
★ "범위 밖" 핑계로 무시 금지 ★
1. Codex 지적 사항을 party-logs/{sprint}-batch-{N}-codex-fixes.md에 기록
2. 해당 스토리 dev에게 수정 지시
3. dev 수정 → Codex 재실행 (횟수 제한 없음 — PASS까지)
4. PASS 나올 때까지 끝까지 고친다. ESCALATE 없음.
```

### Phase 2: Dependent Test Re-run

```
1. 이번 Batch에서 변경된 모듈을 import하는 테스트 파일 찾기:
   for each changed_module:
     grep -rl "from '.*{module}'" packages/**/__tests__/ → test_files

2. 해당 테스트만 실행:
   bun test {test_files}

3. RED 있으면:
   → INTEGRATION-FAIL
   → 어떤 스토리 변경이 원인인지 git blame으로 추적
   → party-logs에 기록
```

### Phase 3: Report

```
출력: party-logs/{sprint}-batch-{N}-integration.md

## Batch {N} Integration Report
- Stories reviewed: [story-ids]
- Cross-dependencies found: {N}
- Second opinion issues found: {N}
- Dependent tests: {passed}/{total}
- Integration warnings: {list}
- Result: PASS / WARNING / FAIL

판정:
  PASS → 다음 Batch 진행
  WARNING → 기록 후 진행 (Sprint Review에서 재확인)
  FAIL → 해당 스토리 CONDITIONAL 되돌림, 수정 필요

sprint-status.yaml 업데이트:
  batch_reviews에 결과 추가
```

---

## Level 3: Sprint Integration Review

```
시점: kdh-sprint Phase 1.5에서 호출 (모든 스토리 완료 후, E2E 직전)
입력: 이번 Sprint 전체 + 이전 Sprint 마지막 커밋 해시
범위: git diff {previous-sprint-end}..HEAD
```

### Phase 0: Full Context Load

```
1. 이전 Sprint 마지막 커밋:
   sprint-status.yaml → sprint_{N-1}.completed_commit
   없으면: git log --oneline | grep "chore(sprint-{N-1})" → 해시 추출

2. 이번 Sprint 변경 파일 전체:
   git diff --name-only {prev-end}..HEAD

3. 이전 Sprint 핵심 파일 식별:
   sprint-status.yaml → sprint_{N-1}.stories → 각 스토리의 변경 파일
```

### Phase 1: Regression Analysis

```
1. 직접 수정 감지:
   이번 Sprint가 이전 Sprint의 파일을 직접 수정했는지:
   git diff {prev-end}..HEAD -- {prev-sprint-files}
   → 변경 있으면 → REGRESSION-RISK (해당 파일 집중 분석)

2. 간접 영향 분석:
   이번 Sprint가 수정한 공유 모듈:
     packages/shared/src/
     packages/server/src/middleware/
     packages/admin/src/lib/
     packages/admin/src/components/ (공용 컴포넌트)
   이 모듈을 이전 Sprint 파일이 import하는지:
   → import 있으면 → REGRESSION-WARNING

3. 교차점이 0이면 → 자동 PASS (이전 Sprint에 영향 없음)
```

### Phase 2: Assumption Drift Detection

```
이전 Sprint의 가정 vs 이번 Sprint의 변경:

1. 사용자 타입/역할:
   git diff {prev-end}..HEAD -- "*.ts" | grep -i "userType\|role\|permission"
   새 타입/역할 추가됨 → 기존 ProtectedRoute, 미들웨어에 반영했는지 확인

2. 인증 방식:
   auth.ts, auth-context.tsx 변경 여부
   변경됨 → 모든 인증 의존 페이지/라우트에 영향 분석

3. API envelope 형식:
   { success, data } / { success, error } 형식 일관성
   새 API가 다른 형식 쓰면 → WARNING

4. 라우팅 규칙:
   main.tsx Route 변경 → ProtectedRoute 조건과 일치하는지
```

### Phase 2.5: 세컨드 오피니언 — Sprint (Codex 1차 + Claude Agent 백업)

```
--- Codex CLI (1차 시도) — tmux 실시간 패턴 (CEO가 봄) ---

1. git diff {previous-sprint-end}..HEAD > /tmp/sprint-diff.txt

2. Codex tmux 창 열기 + 리뷰 보내기 (Bash 도구):
   CODEX_PANE=$(tmux split-window -h -P -F '#{pane_id}' "bash")
   tmux select-pane -t $CODEX_PANE -T "codex-sprint-reviewer"

   tmux send-keys -t $CODEX_PANE 'npx @openai/codex exec - --json \
     --sandbox read-only \
     -o _bmad-output/party-logs/{sprint}-sprint-second-opinion.md \
     -C /home/ubuntu/corthex-v3 <<'"'"'PROMPT'"'"'
   Sprint integration review for sprint {N}.
   Read /tmp/sprint-diff.txt and analyze regressions against previous sprint.
   Focus: shared module changes, auth flow consistency, env vars, API envelope format.
   DO NOT modify source code — read-only analysis only.
   PROMPT' C-m

3. 완료 대기 → 결과 종합 → tmux kill-pane -t $CODEX_PANE

--- Codex 실패 시 (인증/타임아웃) ---

★ Claude Agent fallback 금지 (CLAUDE.md 절대 규칙) ★
Codex가 못 돌아가면 → 멈추고 CEO에게 보고. 자동 스킵 금지.

--- Codex FAIL 판정 시 ---

★ Codex FAIL → 수정 후 Codex 재실행 → PASS까지 반복 ★
1. Codex 지적 사항 기록
2. 해당 스토리 dev에게 수정 지시
3. dev 수정 → Codex 재실행 (횟수 제한 없음 — PASS까지)
4. PASS 나올 때까지 끝까지 고친다. ESCALATE 없음.
```

### Phase 3: Environment & Config Audit

```
1. 이번 Sprint에서 추가된 환경변수:
   git diff {prev-end}..HEAD | grep "process\.env\." | grep "+" → 신규 목록

2. .env.example 교차 검증:
   각 변수가 .env.example에 있는지

3. 프로덕션 fallback 검증:
   fallback이 localhost → FAIL
   fallback이 프로덕션 URL → OK
   fallback 없음 → WARNING
```

### Phase 4: Report

```
출력: party-logs/{sprint}-sprint-integration.md

## Sprint {N} Integration Report
- Previous sprint commit: {hash}
- Files changed this sprint: {N}
- Regression risks: {N} (직접 {N}, 간접 {N})
- Assumption drifts: {N}
- Environment gaps: {N}
- Second opinion issues: {N}
- Result: PASS / WARNING / FAIL

판정:
  PASS → E2E 진행
  WARNING → E2E에 추가 검증 포인트 전달 (integration-risks.md)
  FAIL → 수정 필수 (E2E 진행 불가)

sprint-status.yaml 업데이트:
  integration_state: passed/warning/failed
  integration_report: party-logs/{sprint}-sprint-integration.md
```

---

## Second Opinion 규칙

```
1. Codex CLI (npx codex) — 다른 모델의 독립 시각 제공
2. Codex 실행 실패 → 멈추고 CEO 보고 (Claude Agent fallback 금지 — CLAUDE.md)
3. Codex FAIL 판정 → 수정 후 재실행 → PASS까지 반복 (횟수 제한 없음)
4. 항상 fresh context (이전 대화 맥락 없이)
5. 읽기 전용 (소스 코드 수정 절대 안 함 — 분석만)
6. "범위 밖" 핑계로 Codex 지적 무시 금지
```

## Anti-Patterns

```
1. Second Opinion 에이전트에 코드 수정 시키지 않음 — 읽기 전용만
2. Second Opinion 의견을 무조건 따르지 않음 — Claude가 판단
3. false positive에 과민 반응 안 함 — HIGH만 테스트 재실행
4. 순환 의존성 무한 루프 안 됨 — 최대 1회 재실행, 2회 FAIL → GATE
5. 전체 파일 다 읽으려 안 함 — 교차점만 분석
```

---

## Output

```
party-logs/
  {sprint}-batch-{N}-integration.md           ← Level 2 Batch 리포트
  {sprint}-batch-{N}-second-opinion.md        ← Second Opinion Batch 의견
  {sprint}-sprint-integration.md              ← Level 3 Sprint 리포트
  {sprint}-sprint-second-opinion.md           ← Second Opinion Sprint 리뷰
sprint-status.yaml                            ← integration_state, batch_reviews
```
