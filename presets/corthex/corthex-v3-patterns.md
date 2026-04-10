---
name: corthex-v3-patterns
description: CORTHEX v3 프로젝트 코딩 패턴 및 워크플로우 (git 분석 기반)
version: 1.0.0
source: local-git-analysis
analyzed_commits: 95
---

# CORTHEX v3 — 프로젝트 패턴

## 커밋 컨벤션

Conventional Commits 사용 (총 95 커밋 분석):

| 타입 | 빈도 | 용도 |
|------|------|------|
| `feat` | 48% | 기능 구현 (story 완료) |
| `chore` | 31% | 파이프라인/유지보수/ECC |
| `fix` | 13% | 버그 수정 |
| `docs` | 11% | 문서/planning artifacts |
| `test` | 5% | 테스트 추가 |
| `revert` | 4% | Sprint 삭제 (CEO 지시) |

### 커밋 메시지 패턴
```
feat(story-{N}-{M}): {동사} {기능} — {상세}
feat(sprint-zero): {story-id} — {기능명}
chore: pipeline {version} — {변경 내용}
chore(ecc): {시간} maintenance {날짜}
docs(planning): {stage} complete — {N} steps, party mode
fix({package}): {무엇을} {어떻게} 고침
revert: {무엇} 삭제 — {이유}
```

## 코드 아키텍처

### 모노레포 구조 (Turborepo)
```
packages/
├── server/          # Hono + Bun (API 서버)
│   ├── src/
│   │   ├── routes/       # API 엔드포인트 (기능별 파일)
│   │   ├── middleware/    # auth, rate-limiter, timing
│   │   ├── db/           # Drizzle ORM 스키마 + 연결
│   │   ├── lib/          # 유틸리티
│   │   └── __tests__/    # Bun 테스트
│   └── drizzle/          # SQL 마이그레이션
│
├── admin/           # React + Vite + shadcn/ui (어드민 패널)
│   ├── src/
│   │   ├── features/     # 기능별 페이지 (auth/, company/, team/, ...)
│   │   ├── components/   # 공통 컴포넌트
│   │   ├── lib/          # api-client, auth-context, protected-route
│   │   ├── ui/           # shadcn/ui 컴포넌트
│   │   └── __tests__/    # 테스트
│   └── tests/            # 통합 테스트
│
├── app/             # React + Vite (CEO 앱 — Phase 2)
│   └── src/
│
└── shared/          # 공유 타입 패키지
    └── src/
        ├── contracts/    # API 타입 계약 (Hono RPC)
        ├── __tests__/    # 타입 내보내기 테스트
        └── index.ts      # 배럴 익스포트
```

### 파일 명명 규칙
- 파일: `kebab-case.ts` (login-page.tsx, api-client.ts)
- 컴포넌트: `PascalCase` (LoginPage, ProtectedRoute)
- 라우트: `kebab-case.ts` (auth.ts, company.ts)
- 테스트: `{name}.test.ts` 또는 `__tests__/{name}.test.ts`
- DB 스키마: `packages/server/src/db/schema.ts` (단일 파일)

### 자주 함께 변경되는 파일 (co-change)
| 파일 A | 파일 B | 이유 |
|--------|--------|------|
| `routes/auth.ts` | `middleware/auth.ts` | 인증 로직 연동 |
| `admin/src/main.tsx` | `admin/src/features/*/` | 라우팅 + 페이지 |
| `shared/src/index.ts` | `server/src/routes/*.ts` | 타입 계약 동기화 |
| `admin/src/lib/api.ts` | `admin/src/features/*/` | API 클라이언트 + 소비자 |
| `db/schema.ts` | `drizzle/*.sql` | 스키마 변경 → 마이그레이션 |

## 워크플로우

### 새 기능 추가 (Story)
```
1. Phase A: Story 스펙 작성 → Party Mode 리뷰
2. Phase B: 코드 구현 (server + admin + shared 동시)
   - shared/src/contracts/ 에 타입 먼저 정의
   - server/src/routes/ 에 API 구현
   - admin/src/features/ 에 UI 구현
3. Phase C: 코드 정리 (/simplify)
4. Phase D: 테스트 작성 + QA 검증
5. Phase F: 코드 리뷰
6. Codex: 외부 검증
7. git commit + push
```

### DB 마이그레이션
```bash
# 1. schema.ts 수정
vim packages/server/src/db/schema.ts

# 2. 마이그레이션 생성
cd packages/server && bun run db:generate

# 3. 마이그레이션 적용
cd packages/server && bun run db:migrate
```

### shadcn/ui 컴포넌트 추가
```bash
# 새 컴포넌트 추가 (Phase 3 Sprint 1 이후)
cd packages/admin && npx shadcn@latest add button card dialog

# 기존 컴포넌트 업데이트: diff 확인 후 선택적 반영
npx shadcn@latest diff
```

### 타입 체크 (전체)
```bash
# 모든 패키지 타입 체크
cd packages/server && npx tsc --noEmit
cd packages/admin && npx tsc --noEmit
cd packages/shared && npx tsc --noEmit
```

## 테스트 패턴

### 테스트 프레임워크
- Server: `bun test` (Bun 내장 테스트 러너)
- Admin: `vitest` (Vite 통합)
- Shared: `bun test`

### 테스트 파일 위치
```
packages/server/src/__tests__/auth-routes.test.ts    # API 테스트
packages/server/src/__tests__/middleware.test.ts      # 미들웨어 테스트
packages/server/src/__tests__/schema.test.ts          # DB 스키마 테스트
packages/admin/src/__tests__/api.test.ts              # API 클라이언트 테스트
packages/shared/src/__tests__/exports.test.ts         # 타입 내보내기 테스트
```

### 테스트 실행
```bash
# 서버 테스트
cd packages/server && bun test src/__tests__/

# 어드민 테스트
cd packages/admin && bun run test

# 전체 (Turborepo)
bun run test  # 루트에서
```

## API 패턴

### 응답 형식 (CLAUDE.md 규칙)
```typescript
// 성공
{ success: true, data: { ... } }

// 실패
{ success: false, error: { code: "ERROR_CODE", message: "한국어 메시지" } }
```

### 에러 코드
```
AUTH_FAILED        — 이메일 또는 비밀번호가 올바르지 않습니다
SESSION_EXPIRED    — 세션이 만료되었습니다
RATE_LIMITED       — 요청이 너무 많습니다
HAS_MEMBERS        — 이 팀에 아직 팀원이 있습니다
NOT_FOUND          — 찾을 수 없습니다
FORBIDDEN          — 권한이 없습니다
```

### 인증 방식
- HTTP-Only Cookie 세션 (JWT 아님)
- bcrypt cost 12
- 7일 슬라이딩 세션
- Rate limiting: 5회/15분 (로그인)
- Timing-safe dummy hash (사용자 열거 방지)

## 핵심 규칙 (CLAUDE.md에서)

1. **Phase 1만** — 5개 기능만, 36개 전체 아님
2. **실제 작동** — stub/mock 금지, 실제 DB+API+UI
3. **한국어** — 모든 UI, 에러, 빈 상태 메시지
4. **shadcn/ui** — Phase 3 마이그레이션 후 shadcn/ui 컴포넌트 사용
5. **Claude SDK만** — Gemini 금지 (제품 코드 한정. 코드리뷰 도구로 Codex+Gemini 병렬 OK)
6. **단일 회사** — 멀티테넌트 아님
7. **브라우저 검증** — CEO가 직접 확인
8. **Phase 3 재진입 트리거** — Phase 3 Sprint 1 시작 시: Storybook 전체 도입 + shadcn/ui 실제 설치 + Subframe 컴포넌트 교체
