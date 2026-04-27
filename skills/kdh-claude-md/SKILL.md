---
name: kdh-claude-md
description: "CLAUDE.md와 .claude 폴더 init/audit/optimize/check."
disable-model-invocation: true
---

# /kdh-claude-md v3 — 프로젝트 정비 도구

## 핵심 철학

> CLAUDE.md는 프로젝트의 **헌법**이다. 빠지면 사고, 넘치면 무시.
> "축소"가 아니라 "정규화" — 정리하고, 이관하고, 강제 계층을 올린다.
> **어떤 프로젝트에서든** 동일한 기준으로 진단/정리할 수 있어야 한다.

## 근거

| 사실 | 출처 |
|------|------|
| CLAUDE.md는 매 세션 시작 시 전체 로드 | Anthropic 공식 (code.claude.com) |
| CLAUDE.md 지시는 advisory (판단에 따라 무시 가능) | Anthropic 공식 |
| Hooks는 deterministic (exit 2면 100% 차단) | Anthropic 공식 |
| `.claude/rules/`는 on-demand (paths 매칭 시만 로드) | Anthropic 공식 |
| Skills는 메타데이터만 로드, 본문은 호출 시만 | Anthropic 공식 |
| 200줄 넘으면 규칙 무시 증가 | 커뮤니티 관행 + Anthropic "간결하게" 권장 |
| @import는 토큰 절약이 아님 (인라인 확장) | Anthropic 공식 |
| 파일별 코드베이스 설명은 넣지 말 것 | Anthropic 공식 Best Practices |

## 사용법

```
/kdh-claude-md                         → audit (기본)
/kdh-claude-md init                    → 새 프로젝트 세팅
/kdh-claude-md audit                   → 4축 감사
/kdh-claude-md optimize                → 감사 결과 기반 실제 정리 (CEO 승인 필수)
/kdh-claude-md check                   → 건강검진 (Rule-to-Enforcement Matrix)
/kdh-claude-md plan-add <file.md>      → Active Plans Index 에 plan 추가 + _index.yaml active 등록
/kdh-claude-md plan-done <plan-id>     → Active Plans Index 에서 제거 + _index.yaml done 플립
/kdh-claude-md plan-list               → 현재 인덱스 + _index.yaml 대조 출력
```

---

## 프리셋 시스템 (v3 추가)

프로젝트마다 핵심 규칙이 다르다. 자동 감지 후 해당 프리셋 적용.

### 프리셋 자동 감지

```
1. CLAUDE.md에서 키워드 스캔:
   - "pipeline" OR "kdh-dev-pipeline" → preset: corthex
   - "BMAD" OR "bmad" → preset: bmad
   - "Cloudflare" OR "Workers" → preset: cloudflare
   - 매칭 없음 → preset: general

2. package.json / tech stack 스캔:
   - Hono + Bun + Drizzle → 추가 태그: monorepo-bun
   - Hono + Wrangler → 추가 태그: cloudflare-worker
   - React + Vite → 추가 태그: react-vite

3. .claude/ 폴더 스캔:
   - hooks/ 있음 → "Hook 사용 중"
   - rules/ 있음 → "rules 사용 중"
   - commands/ OR skills/ 있음 → "스킬/명령어 사용 중"
   - 없음 → "구조 미설정"
```

### 프리셋별 핵심 규칙 ID

**corthex 프리셋:**

| ID | 규칙 | 기대 강제 계층 |
|----|------|-------------|
| CR-01 | 파이프라인 외 코드 수정 금지 | Hook |
| CR-02 | Party Mode 필수 | Hook |
| CR-03 | Codex 교차 검증 필수 | Hook |
| CR-04 | tsc 필수 | Hook |
| CR-05 | CLAUDE.md 변경 차단 | Hook |
| CR-06 | 한국어 존댓말 | CLAUDE.md |
| CR-07 | haiku 모델 금지 | CLAUDE.md |
| CR-08 | stub/mock 금지 | CLAUDE.md |
| CR-09 | 에이전트 재사용 금지 | .claude/rules/ |
| CR-10 | plan 보고 필수 | CLAUDE.md |

**bmad 프리셋:**

| ID | 규칙 | 기대 강제 계층 |
|----|------|-------------|
| BM-01 | BMAD 5단계 스킬 필수 | CLAUDE.md |
| BM-02 | Party Mode 합의까지 반복 | CLAUDE.md |
| BM-03 | stub/mock 금지 | CLAUDE.md |
| BM-04 | 단계별 개별 커밋 | CLAUDE.md |
| BM-05 | 체크리스트 통과 후 커밋 | Hook (가능하면) |

**general 프리셋:**

| ID | 규칙 | 기대 강제 계층 |
|----|------|-------------|
| GN-01 | 한국어 존댓말 | CLAUDE.md |
| GN-02 | 비개발자 설명 | CLAUDE.md |
| GN-03 | 번호 목차 필수 | CLAUDE.md |
| GN-04 | 커밋 전 확인 | CLAUDE.md |

프리셋은 초기 목록이며 CEO 승인으로 추가/변경 가능.

---

## 모드 1: Init (신규 프로젝트 세팅) — `$ARGUMENTS`가 "init"

새 프로젝트 시작 시 CLAUDE.md + .claude/ 뼈대를 생성한다.

### 실행 흐름

```
1. 프로젝트 스캔:
   - package.json / Cargo.toml / go.mod 등 → tech stack 감지
   - 폴더 구조 트리 생성 (상위 2레벨만)
   - git remote → 레포 정보
   - 기존 CLAUDE.md 있으면 → "이미 있음. audit 하시겠어요?" 제안

2. 프리셋 감지 (위 프리셋 시스템 참조)

3. CLAUDE.md 초안 생성 (템플릿):
```

**CLAUDE.md 템플릿 (200줄 상한):**

```markdown
# {프로젝트명}

## User
- 비개발자. 한국어 존댓말. 번호 목차 필수.

## Architecture
- {자동 감지된 tech stack 1줄 요약}
- {Monorepo면: 패키지 목록}

## Commands
- {빌드}: `{자동 감지}`
- {테스트}: `{자동 감지}`
- {린트}: `{자동 감지}`
- {배포}: `{자동 감지 또는 "미설정"}`

## Conventions
- 파일명: kebab-case
- API 응답: `{ success, data }` / `{ success, error: { code, message } }`
- {preset별 추가 규칙}

## Rules
- {프리셋 핵심 규칙 중 advisory 항목만}
```

```
4. .claude/ 폴더 뼈대 제안:
   .claude/
   ├── settings.json    ← 기본 설정
   ├── rules/           ← 파일/경로별 규칙 (필요 시)
   └── hooks/           ← 강제 규칙 (필요 시)

5. CEO에게 초안 보여주기:
   - CLAUDE.md 초안 전문 출력
   - "이대로 생성할까요? 수정할 부분 있으면 말씀해주세요."
   - CEO 승인 후 파일 생성
```

### Init에서 하지 않는 것

- 스킬/에이전트 자동 생성 (필요 시 나중에 추가)
- 코드 수정
- 기존 CLAUDE.md 덮어쓰기 (audit/optimize 권장)

---

## 모드 2: Audit (4축 감사) — `$ARGUMENTS` 없음 또는 "audit"

CLAUDE.md + .claude/ 전체를 **4축**으로 감사한다.

### 실행 흐름

```
1. 프리셋 자동 감지
2. CLAUDE.md 읽기 + 줄 수 카운트
3. .claude/ 폴더 스캔 (rules/, hooks/, skills/, commands/, settings.json)
4. 4축 감사 실행
```

**축 1 — 완전성:** 프리셋 핵심 규칙 ID 중 빠진 것이 있는가?
- CLAUDE.md, .claude/rules/, hooks(settings.json)를 순회
- 프리셋 핵심 규칙 ID 테이블과 대조. 누락 = 위험 표시

**축 2 — 중복:** 같은 규칙이 여러 곳에 있는가?
- CLAUDE.md와 .claude/rules/ 사이 키워드 중복 탐지
- CLAUDE.md와 hooks 사이 동일 규칙 중복 탐지
- 중복 = 정규화 대상 (optimize에서 처리)

**축 3 — 충돌:** 규칙끼리 모순되는가?
- 규칙 쌍을 비교하여 논리적 충돌 탐지
- 예: "자동 커밋" vs "승인 후 커밋"
- 충돌 = CEO에게 보고, 해결 요청

**축 4 — 배치 적정성:** 규칙이 올바른 계층에 있는가?
- CLAUDE.md에 있는 규칙 중 Hook으로 강제 가능한 것 식별
- .claude/rules/에 있어야 할 경로별 규칙이 CLAUDE.md에 있는지
- 워크플로우 규칙이 스킬로 빠져야 하는지
- 보고/템플릿 형식이 스킬로 빠져야 하는지

### 출력

```
## CLAUDE.md 감사 보고

프리셋: {감지된 프리셋}
줄 수: {N}줄 (✅ <100 / ⚠️ 100~200 / 🔴 >200)
.claude/ 구조: {있음/없음 + 하위 폴더 목록}

| 규칙 ID | 규칙 | 축1 완전 | 축2 중복 | 축3 충돌 | 축4 배치 | 현재 위치 |
|---------|------|---------|---------|---------|---------|----------|

핵심 규칙 누락: {N}개
중복: {N}개
충돌: {N}개
배치 이관 추천: {N}개
건강 점수: {N}/10
```

**건강 점수 산정:**
- 기본 10점에서 감점
- 200줄 초과: -3
- 100~200줄: -1
- 핵심 규칙 누락 1개당: -1
- 중복 1개당: -0.5
- 충돌 1개당: -2
- .claude/ 구조 없음: -1

---

## 모드 3: Optimize (정리 실행) — `$ARGUMENTS`가 "optimize"

Audit 결과를 바탕으로 **실제 파일 이관/정리**를 실행한다.

### 전제 조건

- 같은 세션에서 audit가 먼저 실행되었거나, 실행 시 audit 자동 선행
- **CEO 승인 없이 파일 수정 금지**

### 실행 흐름

```
1. Audit 실행 (아직 안 했으면)
2. 정규화 제안 목록 생성:

| # | 행동 | 대상 규칙/내용 | 현재 위치 | 제안 위치 | 이유 |
|---|------|--------------|----------|----------|------|

행동 유형:
  a. 죽은 규칙 제거 — 더 이상 해당 안 되는 규칙
  b. 규칙 이관 — CLAUDE.md → .claude/rules/ (경로별 규칙)
  c. Hook 승격 — advisory → Hook (객관적 판정 가능한 규칙)
  d. 스킬 이관 — 워크플로우/보고 템플릿 → .claude/skills/
  e. 중복 제거 — 같은 규칙 여러 곳 → 1곳으로 통합
  f. 빠진 규칙 추가 — 핵심 규칙 ID 중 누락된 것

3. CEO에게 제안 목록 보여주기
4. CEO 승인 (전체 or 항목별)
5. 승인된 항목만 실행:
   - CLAUDE.md에서 해당 내용 제거
   - .claude/rules/{name}.md 생성 (이관 시)
   - 스킬 파일 뼈대 생성 (스킬 이관 시)
   - Hook 설정 제안 (Hook 승격 시 — 실제 스크립트는 별도)
6. 결과 보고: "CLAUDE.md {이전}줄 → {이후}줄, {N}개 이관 완료"
```

### Optimize에서 하지 않는 것

- Hook 스크립트 직접 작성 (제안만 — 구현은 별도)
- 스킬 본문 작성 (뼈대만 — 내용은 별도)
- CEO 미승인 항목 수정
- CLAUDE.md 외 기존 파일 삭제

---

## 모드 4: Health Check (건강검진) — `$ARGUMENTS`가 "check"

**Rule-to-Enforcement Matrix** 출력. audit보다 가벼운 빠른 진단.

```
## Rule-to-Enforcement Matrix

프리셋: {감지된 프리셋}
줄 수: {N}줄 — ✅ <100 / ⚠️ 100~200 / 🔴 >200
섹션별: {각 ## 섹션 줄 수 + 전체 비율}

| 규칙 ID | 규칙 | CLAUDE.md | rules/ | Hook | CI/Test | 강제 없음 |
|---------|------|-----------|--------|------|---------|----------|

★ "강제 없음" = advisory only → 위험 표시
★ 핵심 규칙 중 Hook 강제: {N}/{전체}
★ 건강 점수: {N}/10
```

---

## 모드 5: Plan Index 관리 (v4 추가)

CLAUDE.md 맨 위의 `Active Plans Index` 섹션을 프로그래밍적으로 관리한다.
CEO가 여러 아이디어를 병렬로 주면 plan이 여러 개가 되는데, 매 세션마다 어떤 plan이 진행 중인지 자동 로드되도록 CLAUDE.md 인덱스에 기록.

### 마커 규약 (CLAUDE.md 안에 존재해야 함)

```
<!-- PLANS-INDEX-START — /kdh-claude-md plan-add / plan-done 으로만 편집. 수동 편집 금지. -->
...plan 항목들...
<!-- PLANS-INDEX-END -->
```

마커가 없으면 생성: 제목 (첫 `# ` 줄) 바로 다음에 `## 📋 Active Plans Index (세션 시작 시 필독)` 섹션 + 마커 2개를 삽입.

### plan-add <file.md>

**입력:** plan 파일 경로 (예: `_bmad-output/plans/2026-04-21-foo.md`)

**실행 흐름:**
```
1. 입력 검증:
   - 파일 존재 확인. 없으면 에러.
   - plan-id 추출: 파일명에서 YYYY-MM-DD 제거 후 .md 제거. 또는 파일 상단 frontmatter 의 id.
   - 동일 slug 로 "-KR.md" / "-ceo-summary.md" 파일 있으면 함께 묶음.

2. Plan 파일 읽고 제목/TTL/상태 추출:
   - 첫 "# " 줄 → 제목
   - "## 목표" 또는 첫 본문 문단 첫 줄 → 1줄 요약
   - CEO summary 있으면 거기서 우선 추출
   - TTL = 기본 +7일 (CEO 지정 있으면 그것)

3. _bmad-output/kdh-plans/_index.yaml 업데이트:
   - 기존 entry 있으면 status: active 로 플립 + 날짜 갱신
   - 없으면 신규 entry 추가 (id, file, title, status: active, scope, pipeline, created, ttl)

4. CLAUDE.md 편집:
   - PLANS-INDEX-START / END 사이에 다음 형식으로 항목 추가:

     - **<plan-id>** — <1줄 요약>
       - 한글 요약: <KR file 경로> (있으면)
       - CEO 요약: <summary file 경로> (있으면)
       - 풀 EARS: <메인 file 경로>
       - 상태: active · TTL <YYYY-MM-DD> · 대기: <다음 액션>

   - 이미 같은 plan-id 있으면 덮어쓰기 (새 메타데이터로).

5. 보고:
   "Active Plans Index 에 <plan-id> 추가. 남은 active plan: N개."
```

### plan-done <plan-id>

**입력:** plan-id (예: `0421-claude-design-full-migration`)

**실행 흐름:**
```
1. _index.yaml 에서 해당 entry 찾기. 없으면 에러.
2. _index.yaml status: done 으로 플립 (파일에서 제거하지 않음 — archive 용도).
3. CLAUDE.md PLANS-INDEX-START / END 섹션에서 해당 - **<plan-id>** 블록 통째로 제거.
4. 보고:
   "<plan-id> 완료 처리. CLAUDE.md 인덱스에서 제거. _index.yaml status: done 로 플립.
   남은 active plan: N개."
```

### plan-list

**실행 흐름:**
```
1. CLAUDE.md PLANS-INDEX 섹션 파싱 → 인덱스 plan 목록
2. _index.yaml 읽고 status: active 목록 추출
3. 대조:
   - 인덱스에 있고 _index.yaml 에도 active → ✅ OK
   - 인덱스에만 있음 → 🚩 유령 (plan-done 미실행 또는 index.yaml 수동 변경)
   - _index.yaml 에만 있음 → 🚩 인덱스 누락 (plan-add 미실행)
4. 출력:
   | plan-id | CLAUDE.md | _index.yaml | TTL | 상태 |
```

### 자동 호출 포인트 (다른 스킬과 통합)

- `/kdh-plan` 의 Step 7 마지막에 `plan-add` 자동 호출 (새 plan 생성 후 자동 등록)
- `/kdh-ecc-3h` Phase 2 Plan Audit 에서 TTL 만료 plan 감지 시 자동 `plan-done` 제안
  - 단 자동 삭제 금지 — CEO 승인 필수 (ECC-3h 의 보고만)

### 안전장치

- 마커 (`PLANS-INDEX-START` / `END`) 밖의 CLAUDE.md 내용은 절대 건드리지 않음.
- 마커가 없으면 생성만 하고 기존 내용 보존.
- `_index.yaml` 파일이 없으면 생성 (빈 `plans: []` 구조).
- 동시 편집 충돌 방지: Edit 도구의 exact match 사용 (마커 기준).
- `plan-done` 은 파일 삭제하지 않음. 오직 인덱스 + status 만 변경.

---

## 4계층 라우팅 결정 (모든 모드에서 참조)

| 판단 기준 | 결과 |
|----------|------|
| Linter/CI가 처리 가능? | Linter에 위임 |
| 객관적으로 판정 가능? (exit code) | Hook (deterministic) |
| 특정 파일/경로에만 해당? | .claude/rules/ (paths 매칭) |
| 반복 워크플로우/템플릿? | Skill (on-demand) |
| Claude가 추측 못하는 핵심? | CLAUDE.md (advisory, 항상 로드) |

### CLAUDE.md에 넣을 것 vs 넣지 말 것

| ✅ 넣을 것 | ❌ 넣지 말 것 |
|-----------|-------------|
| Claude가 추론 못하는 명령어 | 코드에서 추론 가능한 것 |
| 기본값과 다른 코드 스타일 | 표준 언어 관례 |
| 아키텍처 결정 (1줄 요약) | 상세 API 문서 (링크만) |
| 워크플로우 규칙 (짧게) | 파일별 코드베이스 설명 |
| 개발 환경 특이사항 | 자주 바뀌는 정보 (버전, 경로) |
| 사용자 정보 | 당연한 말 ("깨끗한 코드 작성") |

---

## 주의사항

- 이 스킬은 **보고 + 제안** 중심. 실제 수정은 optimize 모드 + CEO 승인 시만.
- CEO override: Hook이 차단해도 CEO가 직접 승인하면 수정 가능.
- `@import`는 토큰 절약이 아님 (인라인 확장됨). 파일 정리용으로만 사용.
- "IMPORTANT", "YOU MUST" 등 강조어로 advisory 준수율 향상 가능.
- 크기와 건강은 다르다. 57줄이어도 충돌 규칙 있으면 불건강.
- 프리셋은 가이드일 뿐. 프로젝트마다 CEO가 규칙을 추가/제거할 수 있음.
