---
name: kdh-e2e
description: "E2E 검증 — Sprint 끝에 Playwright로 전체 유저 저니 테스트. 스크린샷 증거 저장."
---

# KDH E2E — End-to-End Verification

Sprint 끝에 전체 유저 저니를 Playwright로 브라우저 테스트.
기존 kdh-playwright-e2e 2개(tmux/vs)를 통합 + 간소화.

## When to Use

- `/kdh-e2e` — 수동 실행
- `/kdh-sprint`에서 Sprint 완료 후 자동 호출됨
- "E2E 돌려", "전수검사", "브라우저 테스트"

## Pattern: Evaluator (독립 검증)

```
Anthropic 3-Agent 패턴: 독립 Evaluator
역할: 구현과 무관하게 사용자 관점에서 검증
증거 기반: 스크린샷 + 콘솔 로그 + API 응답
```

---

## Prerequisites

```
- Playwright MCP: .mcp.json에 설정됨 (headless chromium)
- Dev server: bun run dev (또는 live site)
- DB: 테스트 데이터 존재
```

---

## Phase 0: Pre-flight (30s)

```
1. Dev server 상태 확인:
   - curl http://localhost:5173 → Vite dev server alive?
   - 안 켜져 있으면: cd packages/admin && bun run dev & (백그라운드)
   - 5초 대기 후 재확인

2. API server 상태 확인:
   - curl http://localhost:3000/api/health
   - 안 켜져 있으면: cd packages/server && bun run dev & 
   - 5초 대기 후 재확인

3. 이전 E2E 결과 읽기:
   - _qa-e2e/playwright-e2e/cycle-report.md
   - 미해결 버그 = 이번 사이클 우선 타겟
```

## Phase 1: API Smoke Test (1min)

```
Admin token 발급:
  POST /api/auth/admin/login → { email, password } → token

모든 API 엔드포인트 호출:
  Auth:     POST /api/auth/signup, /api/auth/login, GET /api/auth/me
  Companies: GET/POST /api/companies, GET/PUT/DELETE /api/companies/:id
  Divisions: GET/POST /api/companies/:id/divisions, ...
  Teams:    GET/POST /api/divisions/:id/teams, ...
  Members:  GET/POST /api/teams/:id/members, ...
  Agents:   GET/POST /api/agents, ...

각 엔드포인트:
  - 200/201 → OK
  - 500 → CRITICAL (서버 에러)
  - 404 → HIGH (라우트 미등록)
  - 401/403 → 인증 문제 확인
```

## Phase 2: User Journey Test (5min)

**Phase 1 기능 5개 전체 흐름을 Playwright로 테스트.**

```
Journey 1: 회원가입 → 로그인
  1. /signup 페이지 이동
  2. 폼 입력: 이름, 이메일, 비밀번호
  3. 가입 버튼 클릭
  4. 성공 확인 (리다이렉트 또는 메시지)
  5. /login 페이지 → 방금 만든 계정으로 로그인
  6. 대시보드 도착 확인
  7. 스크린샷: screenshots/journey-1-auth.png

Journey 2: 회사 관리
  1. 회사 목록 페이지 이동
  2. 새 회사 추가 버튼 클릭
  3. 회사명 입력 → 저장
  4. 목록에 새 회사 표시 확인
  5. 회사 상세 → 수정 → 저장 → 반영 확인
  6. 스크린샷: screenshots/journey-2-company.png

Journey 3: 부서 관리
  1. 회사 선택 → 부서 탭/페이지 이동
  2. 새 부서 추가
  3. 부서 목록 확인
  4. 스크린샷: screenshots/journey-3-division.png

Journey 4: 직원(팀) 관리
  1. 부서 선택 → 팀/직원 관리
  2. 팀 생성 → 멤버 추가
  3. 조직도 확인
  4. 스크린샷: screenshots/journey-4-team.png

Journey 5: AI 에이전트
  1. 에이전트 목록 페이지 이동
  2. 새 에이전트 생성 (이름, 역할, 모델 선택)
  3. 에이전트 상세 확인
  4. 스크린샷: screenshots/journey-5-agent.png

각 Journey에서 체크:
  - [ ] 페이지 로드 완료 (빈 화면 아님)
  - [ ] 콘솔 에러 없음
  - [ ] CRUD 동작 확인 (Create → Read → Update)
  - [ ] 한국어 UI 정상 표시
  - [ ] 반응형 레이아웃 (깨지지 않음)
```

## Phase 3: Interaction Sweep (2min)

```
모든 페이지에서:
  1. 사이드바 메뉴 전체 클릭 → 각 페이지 로드 확인
  2. 버튼 클릭 → 동작 확인 (dead button = BUG)
  3. 드롭다운/셀렉트 → 옵션 변경 확인
  4. 모달 → 열기/닫기 확인
  5. 콘솔 에러 수집

Dead button (클릭해도 아무 반응 없음) = BUG
콘솔 에러 = BUG
빈 페이지 (데이터 있어야 하는데 없음) = BUG
```

## Phase 4: Bug Report + Auto-Fix (3min)

```
수집된 버그 정리:

Priority:
  P0 CRITICAL — 500 에러, 페이지 크래시
  P1 HIGH — 404, dead button, CRUD 안 됨
  P2 MEDIUM — 콘솔 에러, 빈 페이지
  P3 LOW — 디자인, UX

P0/P1 자동 수정 시도:
  1. 관련 파일 읽기
  2. 원인 파악 → 최소 수정
  3. tsc 체크 → 테스트 체크
  4. 2회 시도 실패 → ESCALATED

수정 규칙:
  - 인증/미들웨어 수정 금지
  - package.json 변경 금지
  - 마이그레이션 변경 금지
  - 파일 삭제 금지
```

## Phase 5: Report + Cleanup (30s)

```
1. 테스트 데이터 정리:
   - E2E에서 생성한 테스트 회사/유저 삭제
   - API 호출로 cleanup

2. 결과 보고서:
   _qa-e2e/playwright-e2e/cycle-report.md에 추가:

   ## Sprint {N} E2E — {timestamp}
   - API Smoke: {passed}/{total} OK
   - Journey 1 (Auth): PASS/FAIL
   - Journey 2 (Company): PASS/FAIL
   - Journey 3 (Division): PASS/FAIL
   - Journey 4 (Team): PASS/FAIL
   - Journey 5 (Agent): PASS/FAIL
   - Console errors: {N}
   - Dead buttons: {N}
   - Bugs found: {N} (P0:{n} P1:{n} P2:{n} P3:{n})
   - Bugs fixed: {N}
   - Bugs escalated: {N}
   - Screenshots: screenshots/sprint-{N}/

3. 수정 사항 있으면:
   git add + commit + push
   "fix(e2e): sprint {N} — {bug count} bugs fixed"

4. 판정:
   - Journey 5개 전부 PASS + P0 0건 → SPRINT E2E PASS
   - P0 있거나 Journey FAIL → SPRINT E2E FAIL
   - FAIL이면 /kdh-gate에 사장님 알림
```

---

## Screenshots

```
_qa-e2e/playwright-e2e/screenshots/
  sprint-{N}/
    journey-1-auth.png
    journey-2-company.png
    journey-3-division.png
    journey-4-team.png
    journey-5-agent.png
    bug-{id}-{page}.png    ← 버그 증거
```

## 타임아웃

| Phase | 제한 | 초과 시 |
|-------|------|---------|
| Pre-flight | 30s | 서버 시작 실패 → ABORT |
| API Smoke | 2min | 부분 결과로 진행 |
| User Journey | 8min | 완료된 Journey만 보고 |
| Interaction | 3min | 부분 결과로 진행 |
| Auto-Fix | 5min | ESCALATE |
| 전체 | 15min | 강제 보고서 작성 |

---

## Output

```
_qa-e2e/playwright-e2e/
  cycle-report.md              ← 누적 보고서
  screenshots/sprint-{N}/      ← 스크린샷 증거
  ESCALATED.md                 ← 미해결 버그
sprint-status.yaml             ← e2e_result: PASS/FAIL
```
