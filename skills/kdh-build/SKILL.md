---
name: kdh-build
description: "Story Builder (Generator) — 스토리 1개를 TDD로 구현. Fresh context. Contract import 강제."
---

# KDH Build — Story Builder (Generator)

스토리 1개를 TDD 방식으로 구현하는 Generator 전용 스킬.
**이 스킬은 구현만 한다. 리뷰는 /kdh-review가 별도 에이전트로 수행.**

## When to Use

- `/kdh-build {story-id}` — 스토리 1개 구현 (예: `/kdh-build 1-1`)
- `/kdh-sprint`에서 자동 호출됨 (직접 안 쳐도 됨)

## Pattern: Producer (Generator)

```
revfactory/harness 패턴: Producer
Superpowers 적용: TDD 강제 (RED-GREEN-REFACTOR)
Ralph Wiggum 적용: Fresh context per story
GSD 적용: 파일 기반 상태 전달 (메시지 기억 의존 금지)
```

---

## Prerequisites

구현 시작 전 반드시 읽어야 하는 파일:

```
1. project-context.yaml — 프로젝트 구조, 패키지 매니저, 빌드 명령어
2. sprint-status.yaml — 스프린트 상태, 스토리 목록
3. _bmad-output/planning-artifacts/epics-and-stories.md — 스토리 스펙
4. _bmad-output/planning-artifacts/api-contracts.md — API 엔드포인트 정의
5. packages/shared/src/contracts/index.ts — 타입 계약서 (SINGLE SOURCE OF TRUTH)
6. 관련 DB 스키마: packages/server/src/db/schema/*.ts
```

---

## Phase 0: Story Load (30s)

```
1. Read sprint-status.yaml → 해당 스토리 찾기
2. Read epics-and-stories.md → 스토리 상세 스펙
3. Read api-contracts.md → 관련 엔드포인트
4. Read packages/shared/src/contracts/*.ts → 사용할 타입들
5. Detect story type:
   - API story → server package
   - UI story → admin/app package + Subframe GATE
   - Wiring story → 연결만 (새 코드 최소)
   - Full-stack → server + admin/app
```

## Phase 1: TDD — Test First (RED)

**Superpowers TDD 강제: 테스트를 먼저 쓴다.**

```
1. 스토리 스펙에서 acceptance criteria 추출
2. 테스트 파일 생성:
   - API: packages/server/src/__tests__/{feature}.test.ts
   - UI: packages/admin/src/__tests__/{feature}.test.tsx
3. 테스트 작성 규칙:
   - Contract 타입만 import (인라인 타입 금지)
   - Happy path + Error case + Edge case
   - 최소 3개 테스트 케이스
4. 테스트 실행 → 전부 FAIL 확인 (RED)
   - bun test {test-file}
   - FAIL이 아니면 테스트가 잘못된 것 → 수정
```

## Phase 2: Implementation (GREEN)

```
1. 테스트를 통과시키는 최소 코드 작성
2. Contract import 강제:
   - import { Type } from '@corthex/shared'
   - 인라인 타입 정의 = 절대 금지 (v2 실패 원인)
3. 코드 작성 순서:
   a. DB 스키마 변경 (필요 시)
   b. Server route/handler
   c. Shared types (필요 시 contracts에 추가)
   d. Frontend page/component
   e. API client 연결 (Hono RPC 또는 fetch)
4. 테스트 실행 → 전부 PASS 확인 (GREEN)
   - bun test {test-file}
   - FAIL 있으면 구현 수정 (테스트 수정 금지)
```

## Phase 3: Type Check + Refactor

```
1. tsc 전체 체크:
   - bunx tsc --noEmit -p packages/server/tsconfig.json
   - bunx tsc --noEmit -p packages/admin/tsconfig.json
   - bunx tsc --noEmit -p packages/shared/tsconfig.json
   - 에러 0 필수. 에러 있으면 수정.

2. Refactor (IMPROVE):
   - 중복 코드 → 유틸로 추출
   - 매직 넘버 → 상수로
   - 함수 50줄 이하
   - 파일 400줄 이하
   - 하지만 과도한 리팩토링 금지 — 스토리 범위만

3. 테스트 재실행 → 여전히 GREEN 확인
```

## Phase 4: Wiring Verification

**v2 실패 원인: 백-프론트 미연결. 반드시 확인.**

```
1. API story: curl로 실제 호출 가능한지 확인
   - dev 서버 켜져 있으면: curl http://localhost:3000/api/{endpoint}
   - 아니면: 테스트에서 supertest/hono-testing으로 확인

2. UI story: 컴포넌트가 실제 API를 호출하는지 확인
   - fetch/axios/hono-client import 존재하는지
   - API URL이 실제 서버 라우트와 일치하는지
   - 에러 핸들링 있는지

3. Wiring story: 연결 대상이 실제로 존재하는지
   - import 경로가 유효한지
   - 호출 시그니처가 contract와 일치하는지
```

## Phase 5: Commit + Progress Update

```
1. git add {변경된 파일만 — 구체적으로 나열}
2. git commit:
   "feat({epic}): {story-id} — {story title}

   - TDD: {N} tests (RED→GREEN)
   - Contract types: imported from @corthex/shared
   - tsc: 0 errors

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"

3. sprint-status.yaml 업데이트:
   - 해당 스토리 status: completed
   - completed_at: {timestamp}
   - tests_passed: {count}
   - tsc_errors: 0

4. git push origin main
```

---

## UI Story: Subframe GATE

UI가 있는 스토리에서는 디자인 확인이 필요할 수 있다.

```
1. Subframe MCP로 컴포넌트/페이지 디자인
2. /kdh-gate page-design 호출 (사장님 확인)
3. `계속` 모드면 자동 진행 (기본 선택)
4. 승인 후 React 코드로 내보내기 → 구현
```

---

## Contract Compliance (절대 규칙)

```
ALLOWED:
  import { Company, CreateCompanyRequest } from '@corthex/shared'
  import type { ApiResponse } from '@corthex/shared'

FORBIDDEN (자동 FAIL):
  interface Company { ... }           ← 인라인 타입 정의
  type CreateCompanyRequest = { ... } ← 로컬 타입 정의
  const response: { id: string }     ← 익명 타입
```

인라인 타입이 발견되면 /kdh-review에서 자동 FAIL 처리된다.
**contracts에 없는 타입이 필요하면 → contracts에 먼저 추가 후 import.**

---

## Fresh Context 규칙 (Ralph Wiggum)

```
- 이 스킬이 끝나면 에이전트는 종료된다
- 다음 스토리는 새 에이전트가 처리한다
- 상태 전달은 오직 파일로 (sprint-status.yaml, git history)
- 대화 기억에 의존하지 않는다
```

---

## 타임아웃

| Phase | 제한 | 초과 시 |
|-------|------|---------|
| Story Load | 1min | 스펙 파일 경로 확인 |
| TDD (RED) | 5min | 테스트 단순화 |
| Implementation (GREEN) | 15min | 스토리 분할 검토 |
| Type Check | 2min | 에러 3개 이상이면 ESCALATE |
| Wiring | 2min | 로그 남기고 진행 |
| Commit | 1min | 수동 커밋 |

총 제한: 30분/스토리. 초과 시 진행 상황 저장 후 종료.

---

## Output

```
sprint-status.yaml          ← 스토리 상태 업데이트
packages/*/src/**            ← 구현 코드 + 테스트
git commit                   ← feat({epic}): {story} 커밋
```
