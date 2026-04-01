---
name: kdh-build
description: "Story Builder (Generator) — 스토리 1개를 TDD로 구현. Fresh context. Contract import 강제."
---

## v13 절대 규칙: 팀 에이전트로만 실행

이 스킬은 반드시 팀 에이전트(Agent 도구로 소환된 팀원)로 실행해야 합니다.
오케스트레이터(메인 세션)가 직접 실행하면 안 됩니다.
CEO가 3번 코드 전체 삭제함 — 감독이 직접 코딩하면 사형.

실행 방법:
→ TeamCreate("sprint-{N}") 로 팀 생성
→ Agent(name: "builder-{story}", team_name: "sprint-{N}") 로 빌더 소환
→ 빌더가 이 스킬을 실행

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

## Phase -1: Review State Verification (10s)

구현 시작 전 의존성 리뷰 상태 확인:
```
1. Read sprint-status.yaml → 이 스토리의 blockedBy 확인
2. 의존 스토리 중 review_state: conditional/auto-fail/escalated → BLOCK
   "스토리 {dep-id}의 리뷰가 미해결입니다. {this-id} 빌드 불가."
3. 전부 review_state: passed 또는 null → 진행
```

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

## Phase 0.5: Dependent Story Discovery (v12)

```
1. sprint-status.yaml에서 이 스토리에 의존하는 스토리 찾기:
   for story in stories: if story.depends_on includes this.id → DEPENDENT

2. 이 스토리가 export하는 모듈을 import하는 파일 찾기:
   grep -rl "from '.*{this-story-module}'" packages/ → importers

3. party-logs/{sprint}-{story}-dependents.md 생성:
   "이 스토리 변경 시 영향받는 곳: {list}"

4. Phase 5 (Commit) 시:
   의존 스토리의 테스트 파일만 추가 실행
   RED 있으면 → 커밋 전에 경고
```

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

## Phase 4.5: Browser Smoke Check (BLOCKING — UI/Full-stack 스토리만)

**v11 핵심: "눌러봤냐?" — 코드 리뷰 전에 브라우저에서 확인.**

```
스킵 조건: story type = API-only → 이 Phase 건너뜀

1. Dev server 확인:
   - curl http://localhost:3000/api/health → alive?
   - 안 켜져 있으면: cd packages/server && NODE_ENV=production bun src/index.ts & + 3초 대기

2. Playwright CLI 스크린샷:
   - npx playwright screenshot --wait-for-timeout 3000 http://localhost:3000/{page} /tmp/smoke-{story-id}.png
   - {page} = 스토리 대상 페이지 (예: /login, /signup, /divisions, /invite)

3. 스크린샷 분석 (Read tool로 이미지 확인):
   □ 페이지 렌더링됨 (빈 흰 화면 아님)
   □ 주요 UI 요소 보임 (제목, 버튼, 폼)
   □ "Content-Length" 같은 깨진 텍스트 없음
   □ 에러 메시지가 부적절하게 표시되지 않음

4. 콘솔 에러 체크 (가능하면):
   - Playwright로 page error 캡처
   - "Unexpected token", "TypeError", "ChunkLoadError" → FAIL

5. Full-stack 스토리 추가 검증:
   - 실제 유저 플로우 테스트 (예: signup → 폼 채우기 → 제출 → 결과 확인)

6. 판정:
   - 렌더링 OK + 에러 없음 → PASS → Phase 4.6으로
   - 빈 화면 또는 에러 → FAIL → 수정 후 재실행
   - 3회 FAIL → ESCALATE (스토리 구현 문제)
```

## Phase 4.6: Static Analysis (BLOCKING — 전체 스토리)

```
1. 하드코딩 URL 탐지:
   grep -rn "localhost:5173\|localhost:3000\|127\.0\.0\.1" packages/ \
     --include="*.ts" --include="*.tsx" | grep -v "__tests__" | grep -v "node_modules"
   - 허용: process.env.XXX || 'http://localhost:...' 패턴 (fallback)
   - 비허용: 'http://localhost:5173' 직접 사용 → FAIL
   - 비허용: URL 문자열 하드코딩 (BASE_URL 없이) → FAIL

2. 환경변수 검증:
   - 새로 추가된 process.env.XXX → .env.example에도 추가했는지 확인
   - 프로덕션 fallback 있는지 확인 (NODE_ENV === 'production' 분기)

3. Contract 타입 위반 (WARNING):
   - 라우트/페이지 파일에서 interface/type 직접 정의 탐지
   - @corthex/shared import 없으면 → WARNING (FAIL은 kdh-review에서)

전부 PASS → Phase 5로 진행
FAIL → 해당 코드 수정 후 재실행
```

## Phase 5: 빌드 완료 보고 (커밋 금지 — 리뷰 후에만 커밋)

```
★★★ 빌더는 절대 git commit/push 하지 않는다 ★★★
커밋은 리뷰 PASS 후 오케스트레이터(kdh-sprint)가 한다.
이유: 리뷰 전 커밋 = 리뷰 무력화. CEO가 4번 코드 삭제한 원인.

빌더가 할 것:
1. sprint-status.yaml 업데이트:
   - 해당 스토리 status: built (completed 아님!)
   - built_at: {timestamp}
   - tests_passed: {count}
   - tsc_errors: 0
   - changed_files: [파일 목록]

2. 오케스트레이터에게 보고:
   "스토리 {id} 빌드 완료. 테스트 {N}개 통과. tsc 0 에러.
    변경 파일: {목록}. 리뷰 대기 중."

3. 종료 (커밋하지 않고 종료)

빌더가 하면 안 되는 것:
  ❌ git add
  ❌ git commit  
  ❌ git push
  ❌ status를 'completed'로 변경 (built까지만)
```

---

## UI Story: Subframe 필수 (선택 아님)

UI/프론트엔드가 있는 스토리는 반드시 Subframe을 사용해야 한다.
Subframe 안 쓰고 직접 React 짜면 = 자동 FAIL.

```
CEO 디자인 기준 (절대):
  - Linear 다크 미니멀 + Genesis 프리미엄 + 한국 기업 세련됨
  - 색상 테마: CEO가 정한 테마 유지 (벚꽃, Toss 라이트/다크, 라벤더 등)
  - 테마 변경 가능하게 (커스터마이징)
  - 참고: memory/feedback_design_taste.md

Subframe 프로젝트: fe1d14ed3033
  참고: memory/reference_subframe_project.md
  5개 페이지 디자인이 이미 만들어져 있음 — 무시하지 말 것

실행 순서:
  1. /subframe:design 으로 Subframe MCP에서 페이지/컴포넌트 디자인
     - 기존 5개 페이지 디자인 참조
     - CEO 색상 테마 적용
  2. /subframe:develop 로 React 코드 내보내기
  3. 내보낸 코드를 프로젝트에 적용
  4. /kdh-gate page-design 호출 (사장님 확인)
  5. `계속` 모드면 자동 진행 (기본 선택)
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
sprint-status.yaml          ← 스토리 상태: built (not completed)
packages/*/src/**            ← 구현 코드 + 테스트 (커밋 안 됨, 워킹 디렉토리에만)
(커밋은 kdh-sprint가 리뷰 PASS 후 수행)
```
