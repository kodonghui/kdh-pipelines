---
name: kdh-integration
description: "Batch/Sprint 통합 리뷰."
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
   {server_package_path}/src/routes/*.ts 파일들의 미들웨어 사용 비교 (from project-context.yaml):
     requireAuth, verifyTeamOwnership 등
   Story A가 미들웨어 추가/변경했는데 다른 라우트에 영향 → WARNING

3. 프론트 라우팅 일관성:
   {admin_package_path}/src/main.tsx의 Route 정의 (from project-context.yaml)
   vs 실제 페이지 컴포넌트의 auth 요구사항
   ProtectedRoute 안의 페이지가 비인증 접근 시도 → WARNING

4. 환경변수 교차 검증:
   이번 Batch에서 새로 추가된 process.env.XXX:
     .env.example에 있는지 확인
     fallback이 localhost면 → WARNING
```

### Phase 1.5: Cross-Model Verification — Codex + Gemini 병렬

```
v11.0 업데이트 (2026-04-10): tmux 실시간 패턴 폐기. codex-review.sh 병렬 실행으로 교체.
두 모델: Codex(GPT-5.4) + Gemini(3.1 Pro). 매번 fresh session (편향 방지).

--- 실행 ---

1. git diff {batch-start}..HEAD > /tmp/batch-diff.patch
   (untracked 파일은 별도 cat으로 append)

2. codex-review.sh 병렬 실행 (Bash run_in_background):
   bash ~/.claude/scripts/codex-review.sh /tmp/batch-diff.patch \
     "Batch {N} integration review. Cross-story integration issues: shared component changes, middleware consistency, auth flow, env vars, type signature changes. Focus on regression/race condition/resource leak. 한국어로 답해라."

3. 완료 대기 (background task notification)

4. 결과 파싱:
   - codex-review.sh output 끝에 "Complete. Codex:{PASS|FAIL} Gemini:{PASS|FAIL}"
   - party-logs/{sprint}-batch-{N}-codex.md + party-logs/{sprint}-batch-{N}-gemini.md 저장

--- 실행 실패 시 (인증/타임아웃) ---

★ Claude Agent fallback 금지 (CLAUDE.md 절대 규칙) ★
Codex 또는 Gemini 중 하나라도 못 돌아가면 → 멈추고 CEO 보고. 자동 스킵 금지.
CEO 승인 시 sprint-status.yaml에 {codex,gemini}_skipped: true 기록.

--- 판정 ---

★ 둘 다 PASS → Phase 2로 진행
★ 둘 다 FAIL → 자동 진행 금지. 수정 후 재실행 → PASS까지 반복 (v11.0 CEO 승인)
★ 하나만 FAIL + 치명 이슈 → CEO 판단 (false positive 판별)
★ 하나만 FAIL + 경미 이슈 → 기록 후 진행 OK
★ "범위 밖" 핑계로 치명 이슈 무시 금지

FAIL 수정 사이클:
1. 지적 사항을 party-logs/{sprint}-batch-{N}-fixes.md에 기록
2. 해당 스토리 dev(fresh instance)에게 수정 지시
3. dev 수정 → codex-review.sh 재실행 (횟수 제한 없음 — 둘 다 PASS까지)
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
     {shared_package_path}/src/ (from project-context.yaml)
     {server_package_path}/src/middleware/ (from project-context.yaml)
     {admin_package_path}/src/lib/ (from project-context.yaml)
     {admin_package_path}/src/components/ (공용 컴포넌트, from project-context.yaml)
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

### Phase 2.5: Cross-Model Verification — Sprint (Codex + Gemini 병렬)

```
v11.0 업데이트 (2026-04-10): tmux 실시간 패턴 폐기. codex-review.sh 병렬 실행.

--- 실행 ---

1. git diff {previous-sprint-end}..HEAD > /tmp/sprint-diff.patch

2. codex-review.sh 병렬 실행 (Bash run_in_background):
   bash ~/.claude/scripts/codex-review.sh /tmp/sprint-diff.patch \
     "Sprint {N} regression review against previous sprint. Shared module changes, auth flow consistency, env vars, API envelope format. Read-only analysis. 한국어로 답해라."

3. 완료 대기 → 결과 파싱:
   - party-logs/{sprint}-sprint-codex.md + party-logs/{sprint}-sprint-gemini.md 저장

--- 실행 실패 시 (인증/타임아웃) ---

★ Claude Agent fallback 금지 (CLAUDE.md 절대 규칙) ★
Codex 또는 Gemini 실행 실패 → 멈추고 CEO 보고. 자동 스킵 금지.

--- 판정 ---

★ 둘 다 PASS → E2E 진행
★ 둘 다 FAIL → 자동 진행 금지. 수정 후 재실행 → PASS까지 반복
★ 하나만 FAIL → CEO 판단 (치명이면 수정, false positive면 기록 후 진행)

FAIL 수정 사이클:
1. 지적 사항 기록
2. 해당 스토리 dev(fresh instance)에게 수정 지시
3. dev 수정 → codex-review.sh 재실행 (횟수 제한 없음)
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

## Cross-Model Verification 규칙 (v11.0)

```
1. Codex(GPT-5.4) + Gemini(3.1 Pro) 병렬 — 두 모델의 독립 시각
2. codex-review.sh 사용 (둘 다 실행 후 결과 합산)
3. 하나라도 실행 실패 → 멈추고 CEO 보고 (Claude Agent fallback 금지 — CLAUDE.md)
4. 둘 다 FAIL → 자동 진행 금지. 수정 후 재실행 → PASS까지 반복 (횟수 제한 없음)
5. 하나만 FAIL → CEO 판단:
   - 치명 이슈 (race condition, data loss, crash) → 수정 필수
   - 경미 이슈 (스타일, 추가 개선) → 기록 후 진행 OK
6. 항상 fresh context (이전 대화 맥락 없이)
7. 읽기 전용 (소스 코드 수정 절대 안 함 — 분석만)
8. "범위 밖" 핑계로 치명 이슈 무시 금지
9. 두 모델의 blind spot 보완: Codex = race condition/signal/리소스 누수, Gemini = 아키텍처 정합성/요구사항 매핑
```

## Anti-Patterns

```
1. Cross-Model 리뷰어에 코드 수정 시키지 않음 — 읽기 전용만
2. Codex/Gemini 의견을 무조건 따르지 않음 — Claude가 판단
3. false positive에 과민 반응 안 함 — HIGH만 테스트 재실행
4. PASS까지 반복 (v11.0) — "max 1회" 규칙 폐기
5. 전체 파일 다 읽으려 안 함 — 교차점만 분석
6. DA(Phase D) 미실행 시 compliance YAML에 `da_skipped: true` + `da_skip_reason` 필수. Story completion checklist에서 검증. 없으면 REJECT. (ref: planning-pipeline Anti-Pattern #16)
7. Self-enhancement bias 플래그 — fixes 후 직전 라운드 대비 3명 critics 점수가 모두 같은 방향으로 ≥1.0 상승 시, 오케스트레이터가 bias 의심 플래그. compliance YAML에 `bias_flag: true/false` 기록. bias_flag=true 시 독립 재채점 경고. (ref: planning-pipeline Anti-Pattern #8, PoLL study)
```

---

## Output

```
party-logs/
  {sprint}-batch-{N}-integration.md           ← Level 2 Batch 리포트
  {sprint}-batch-{N}-codex.md                 ← Codex Batch 의견 (GPT-5.4)
  {sprint}-batch-{N}-gemini.md                ← Gemini Batch 의견 (3.1 Pro)
  {sprint}-sprint-integration.md              ← Level 3 Sprint 리포트
  {sprint}-sprint-codex.md                    ← Codex Sprint 리뷰
  {sprint}-sprint-gemini.md                   ← Gemini Sprint 리뷰
sprint-status.yaml                            ← integration_state, batch_reviews
```
