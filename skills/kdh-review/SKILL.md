---
name: kdh-review
description: "Story Reviewer (Evaluator) — BMAD party mode + D1-D6 루브릭 강제. Generator ≠ Evaluator."
---

# KDH Review v10.1 — Story Reviewer (Evaluator)

구현 완료된 스토리를 **별도 에이전트**로 리뷰하는 Evaluator 전용 스킬.
**구현한 에이전트와 리뷰하는 에이전트는 반드시 다르다 (자기 편향 제거).**

## When to Use

- `/kdh-review {story-id}` — 스토리 1개 리뷰 (예: `/kdh-review 1-1`)
- `/kdh-review {story-id} --re-review` — CONDITIONAL 후 재리뷰
- `/kdh-sprint`에서 build 완료 후 자동 호출됨

## Pattern: Producer-Reviewer (Reviewer Side)

```
Anthropic 3-Agent 패턴: Generator ≠ Evaluator (자기 편향 방지)
GSD 적용: Fresh context — 구현 과정 모름, 코드만 보고 판단
revfactory/harness 패턴: Producer-Reviewer
Superpowers 적용: Verification Before Completion
CEO 명령: Party mode 절대 생략 금지
```

---

## Review Team (BMAD Agents)

| Agent | Critic Type | Persona File | 리뷰 관점 |
|-------|------------|-------------|-----------|
| **winston** | Critic-A | `_bmad/bmm/agents/architect.md` | 아키텍처, API 설계, 확장성 |
| **quinn** | Critic-B | `_bmad/bmm/agents/qa.md` | 테스트 커버리지, 엣지 케이스, 보안 |
| **john** | Critic-C | `_bmad/bmm/agents/pm.md` | 요구사항 충족, 사용자 관점 |

3명이 독립적으로 리뷰 → 교차 토론 → D1-D6 가중 점수 → 최종 판정.

### Critic별 D1-D6 가중치 (critic-rubric.md)

| 차원 | winston (A) | quinn (B) | john (C) |
|------|------------|----------|---------|
| D1 구체성 | 15% | 10% | **20%** |
| D2 완전성 | 15% | **25%** | **20%** |
| D3 정확성 | **25%** | 15% | 15% |
| D4 실행가능성 | **20%** | 10% | 15% |
| D5 일관성 | 15% | 15% | 10% |
| D6 리스크인식 | 10% | **25%** | **20%** |

---

## D1-D6 코드 리뷰 기준 (기획용과 다름)

| 차원 | 코드 리뷰 맥락 | 높은 점수 = | 낮은 점수 = |
|------|--------------|-----------|-----------|
| D1 구체성 | 테스트명, assertion 대상, 에러코드, 줄번호 참조 | 모든 이슈에 file:line 근거 | 추상적 "코드 개선 필요" |
| D2 완전성 | AC 전부 충족, 엣지 테스트, 에러 경로 처리 | 요구사항 100% + 엣지 | 핵심 AC 누락 |
| D3 정확성 | 타입=contract, DB=schema, imports 정상 | 전부 일치 | 타입 불일치, 잘못된 참조 |
| D4 실행가능성 | 컴파일, 테스트 통과, 와이어링 작동 | tsc 0, test GREEN | 빌드 깨짐, 테스트 FAIL |
| D5 일관성 | contract import, 네이밍, API envelope | 인라인 타입 0, 컨벤션 준수 | 인라인 타입, 스타일 불일치 |
| D6 리스크인식 | 보안 취약점, 확장성, 배포 우려 식별 | 리스크 전부 식별 + 대안 | 명백한 보안 구멍 놓침 |

---

## Phase 0: Review Load (30s)

```
1. git log -1 --format="%H %s" → 마지막 커밋 (build 결과)
2. git diff HEAD~1 → 변경된 파일 목록
3. Read sprint-status.yaml → 스토리 스펙 + review_attempt
4. Read epics-and-stories.md → acceptance criteria
5. Read packages/shared/src/contracts/*.ts → 계약 타입
6. Read _bmad-output/planning-artifacts/critic-rubric.md → 채점 기준 + auto-fail 조건
7. --re-review 모드면: Read party-logs/{sprint}-{story}-fixes-needed.md → 수정 대상
```

## Phase 1: Automated Checks (1min)

자동 검증 — 사람 판단 불필요한 것들.

```
1. tsc 체크:
   bunx tsc --noEmit -p packages/server/tsconfig.json
   bunx tsc --noEmit -p packages/admin/tsconfig.json
   bunx tsc --noEmit -p packages/shared/tsconfig.json
   → 에러 있으면 즉시 FAIL (리뷰 불필요)

2. 테스트 실행:
   bun test
   → FAIL 있으면 즉시 FAIL

3. Contract Compliance 자동 스캔:
   변경된 .ts/.tsx 파일에서 검색:
   - "interface " + PascalCase + " {" → 인라인 타입 의심
   - "type " + PascalCase + " = {" → 로컬 타입 의심
   - contracts/에 이미 같은 이름 있으면 → 중복 = FAIL
   - @corthex/shared import 없는 파일에서 API 타입 사용 → FAIL

4. 파일 크기 체크:
   - 800줄 초과 파일 → WARNING
   - 50줄 초과 함수 → WARNING
```

## Phase 2: Party Mode Review (5min)

**BMAD 에이전트 3명이 D1-D6 루브릭으로 독립 리뷰.**

```
Step 1: Spawn 3 review agents (parallel)
  Each agent receives:
  - Persona file path (MUST read first)
  - Changed files list (git diff HEAD~1)
  - Story spec + acceptance criteria
  - Contract types
  - D1-D6 가중치 (critic type별)
  - Auto-fail 조건 5개

Step 2: Independent Review (D1-D6 강제 템플릿)
  Each agent writes: party-logs/{sprint}-{story}-{agent-name}.md
  MUST use the EXACT template below. 커스텀 차원 금지.
```

### D1-D6 Review Template (강제 — 이 양식 외 사용 금지)

```markdown
## {Agent Name} ({Critic Type}) Review: Story {story-id}
Date: {date} | Sprint: {sprint-N}

### 1. Auto-Fail Check (먼저 평가 — 하나라도 YES면 즉시 중단)
- [ ] 할루시네이션 없음 (참조한 파일/API/함수 전부 실존 확인)
- [ ] 보안 구멍 없음 (하드코딩 시크릿, SQL injection, XSS)
- [ ] 빌드 깨짐 없음 (tsc 통과 확인)
- [ ] 데이터 손실 위험 없음 (DROP TABLE/COLUMN 없음)
- [ ] 아키텍처 위반 없음 (engine/ public API 준수)

Auto-fail 발동? [ ] YES → 사유: ___ [ ] NO → 계속

### 2. Acceptance Criteria 체크
- [ ] AC1: {description} — 근거: {file:line 또는 테스트명}
- [ ] AC2: {description} — 근거: {file:line}
...

### 3. D1-D6 차원별 점수 (critic-rubric.md 기준)

| 차원 | 점수 | 가중치 | 가중점수 | 근거 (file:line 필수) |
|------|------|--------|----------|---------------------|
| D1 구체성 | /10 | {%} | | {구체적 근거} |
| D2 완전성 | /10 | {%} | | {구체적 근거} |
| D3 정확성 | /10 | {%} | | {구체적 근거} |
| D4 실행가능성 | /10 | {%} | | {구체적 근거} |
| D5 일관성 | /10 | {%} | | {구체적 근거} |
| D6 리스크인식 | /10 | {%} | | {구체적 근거} |

### 가중 평균: X.XX/10
계산: (D1×{w1}) + (D2×{w2}) + (D3×{w3}) + (D4×{w4}) + (D5×{w5}) + (D6×{w6}) = {결과}

### D < 3 체크
최저 차원: D{N} = {score}/10
D < 3 auto-fail 발동? [ ] YES [ ] NO

### 4. Issues Found (차원 태그 필수)
1. **[D{N} {차원명}] [{CRITICAL|HIGH|MEDIUM|LOW}]** {설명} — File: {path}:{line}
2. ...

### 5. Cross-talk (다른 리뷰어 참조 필수 — 빈칸 = 거부)
- {다른 리뷰어 이름}이 지적한 {이슈}에 대해: {동의/반박 + 이유}
- {추가 인사이트 또는 다른 리뷰어와의 의견 차이}

### Final: {가중평균}/10 → {PASS|CONDITIONAL|FAIL|AUTO-FAIL}
```

**템플릿 준수 규칙:**
- 커스텀 차원명 금지 ("API Design", "Test Coverage" 등 → 무효)
- D1-D6 6개 행 전부 필수 (빈 행 = 리뷰 거부)
- 가중 평균 계산식 표시 필수
- 이슈마다 [D{N}] 태그 필수 (어떤 차원의 문제인지)
- file:line 근거 없는 이슈 = 무효

```
Step 3: Cross-talk (1 round — 빈칸 거부)
  Each agent reads other 2 agents' logs.
  
  Cross-talk 검증 (BLOCKING):
  - 2문장 이상 필수
  - 다른 리뷰어 이름(winston/quinn/john) 최소 1명 인용 필수
  - 구체적 이슈 번호 또는 차원(D1-D6) 언급 필수
  - placeholder 텍스트("empty", "to be filled", "없음") 감지 → 즉시 REJECT
  - 미충족 → 해당 리뷰어에게 재작성 요구

Step 4: Final Scoring
  Each agent updates their D1-D6 table (cross-talk 반영 가능).
  Final weighted average를 orchestrator에게 전달.
```

## Phase 3: Score Evaluation

```
1. 가중 평균 점수 계산: (winston.weighted_avg + quinn.weighted_avg + john.weighted_avg) / 3
2. 판정:
   - avg >= 7.5 → PASS
   - avg >= 6.0, < 7.5 → CONDITIONAL (수정 후 재리뷰)
   - avg < 6.0 → FAIL (재구현 필요)

3. Score Variance 체크:
   - 3명 가중평균 표준편차 < 0.5 → "의심스러운 합의" 경고
   - 1명이 독립 재점수 (다른 점수 안 보고)

4. Verification Before Completion (Superpowers):
   PASS 판정 시에도 아래 증거 필수:
   - [ ] tsc 0 errors (Phase 1 결과)
   - [ ] Tests all GREEN (Phase 1 결과)
   - [ ] Contract compliance PASS (Phase 1 결과)
   - [ ] 3개 party-log 파일 존재
   - [ ] 각 로그에 D1-D6 테이블 6행 존재
   - [ ] 각 로그에 가중 평균 계산식 존재
   - [ ] 각 로그에 Cross-talk 실질 내용 존재 (placeholder 아님)
   - [ ] 최소 1개 이상 이슈 발견됨 (이슈 0 = 의심)
   증거 하나라도 없으면 → PASS 취소, 재검증
```

## Phase 3.5: Auto-Fail Gate (BLOCKING)

```
1. 각 리뷰어의 D1-D6 점수 스캔:
   - 어떤 차원이든 점수 < 3 존재? → AUTO-FAIL 발동
   - 기록: "{reviewer}가 D{N}에 {score}/10 → 자동 불합격"

2. 각 리뷰어의 Auto-Fail Check 섹션 확인:
   - "YES" 체크된 항목 존재? → AUTO-FAIL 발동

3. 이슈 목록에서 auto-fail 키워드 스캔:
   - "존재하지 않는", "hallucination" (할루시네이션)
   - "hardcoded secret", "SQL injection", "XSS" (보안)
   - "tsc error", "compile fail", "빌드 깨짐" (빌드)
   - "DROP TABLE", "data loss" (데이터 손실)
   CRITICAL 이슈 + 키워드 매칭 → auto-fail 확인

4. AUTO-FAIL 발동 시:
   - sprint-status.yaml: review_state → auto-fail
   - party-logs/{sprint}-{story}-AUTO-FAIL.md 생성 (사유 포함)
   - PASS/CONDITIONAL 판정 무시 → FAIL 처리로 전환
   - /kdh-gate auto-fail 호출 (사장님 판단)
```

## Phase 4: Result Action

```
PASS:
  1. party-logs에 PASS 기록
  2. sprint-status.yaml 업데이트:
     review_state: passed
     review_scores: {각 리뷰어별 d1-d6 + weighted_avg}
     review_avg: {3명 평균}
     review_completed_at: {timestamp}
  3. 다음 스토리로 진행 (kdh-sprint에게 알림)

CONDITIONAL (하드 블로킹 — 재리뷰 없이 PASS 전환 불가):
  1. 이슈 목록 저장: party-logs/{sprint}-{story}-fixes-needed.md
     - 각 이슈: 차원 태그 + 심각도 + 구체적 수정 방향
  2. sprint-status.yaml 업데이트:
     review_state: conditional
     review_attempt: +1
     review_scores: {현재 점수}
  3. review_attempt >= 3?
     - YES → review_state: escalated → /kdh-gate review-escalation 호출
     - NO → /kdh-build fix-mode spawn (fixes-needed.md 읽고 수정)
            수정 완료 후 → /kdh-review --re-review (새 에이전트)
  4. --re-review 시: 변경된 차원만 재채점, 나머지 carry forward
  5. 재리뷰 출력: party-logs/{sprint}-{story}-re-review-{N}.md

FAIL:
  1. 상세 이유 기록: party-logs/{sprint}-{story}-FAIL.md
  2. sprint-status.yaml: review_state: failed, fail_reason: {summary}
  3. /kdh-gate 호출 → 사장님 판단

AUTO-FAIL:
  1. party-logs/{sprint}-{story}-AUTO-FAIL.md (사유 + 발동 조건)
  2. sprint-status.yaml: review_state: auto-fail
  3. /kdh-gate auto-fail 호출 → 사장님 판단
```

---

## Contract Compliance Detail

**인라인 타입 = 자동 FAIL. 이유: v2에서 29개 통합 버그 발생.**

```
Scan pattern:
  1. 변경된 파일에서 type/interface 선언 추출
  2. packages/shared/src/contracts/에서 같은 이름 검색
  3. 매칭되면 → "Contract에 이미 있는 타입을 로컬에서 재정의" = FAIL
  4. 매칭 안 되면 → "Contract에 없는 타입" = WARNING (추가 필요할 수 있음)

Exception:
  - React component props (XxxProps) → 로컬 정의 허용
  - Internal utility types → 로컬 정의 허용
  - API request/response types → 반드시 contract에서 import
```

---

## Fresh Context 규칙

```
- Review 에이전트는 Build 에이전트와 다른 에이전트다
- 구현 과정을 모른다 — 코드와 스펙만 보고 판단
- 이전 스토리 리뷰 기억 없다 — 매번 새로 시작
- 상태 전달은 오직 파일로 (party-logs, sprint-status.yaml)
```

---

## Anti-Patterns (금지 사항)

1. **자기 리뷰 금지** — build한 에이전트가 review하면 안 됨
2. **party mode 스킵 금지** — CEO 명시적 명령. 절대 생략 불가.
3. **증거 없이 PASS 금지** — tsc, test, party-log, D1-D6 전부 있어야 PASS
4. **점수 조작 금지** — 표준편차 < 0.5면 독립 재점수
5. **Critic이 persona 안 읽고 리뷰 금지** — 첫 action = Read persona file
6. **커스텀 차원 사용 금지** — D1-D6만 사용. "API Design", "Test Coverage" 등 자체 차원 = 리뷰 무효
7. **빈 Cross-talk 금지** — placeholder 텍스트 = 리뷰 거부, 재작성 요구
8. **재리뷰 없이 CONDITIONAL 해제 금지** — 수정 → 재리뷰 → 점수 재산출 필수

---

## Output

```
party-logs/
  {sprint}-{story}-winston.md       ← Critic-A 아키텍처 (D1-D6)
  {sprint}-{story}-quinn.md         ← Critic-B QA (D1-D6)
  {sprint}-{story}-john.md          ← Critic-C 제품 (D1-D6)
  {sprint}-{story}-fixes-needed.md  ← (CONDITIONAL — 수정 지시서)
  {sprint}-{story}-re-review-{N}.md ← (재리뷰 결과, N=1,2)
  {sprint}-{story}-FAIL.md          ← (FAIL 사유)
  {sprint}-{story}-AUTO-FAIL.md     ← (AUTO-FAIL 사유)
sprint-status.yaml                  ← review_state, review_scores, review_avg
```
