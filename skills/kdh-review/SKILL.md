---
name: kdh-review
description: "Story Reviewer (Evaluator) — BMAD party mode + D1-D6 루브릭 강제. Generator ≠ Evaluator."
---

## v15 절대 규칙: 3명 팀 에이전트 파티 모드 필수 (서브에이전트 금지)

CEO 명령: "파티 모드 빼먹으면 전부 삭제한다."
1명이 혼자 리뷰하면 파이프라인 위반. 리뷰 무효.

★★★ 서브에이전트 금지. 반드시 팀 에이전트 (team_name 필수). ★★★
서브에이전트는 SendMessage 못 함 → cross-talk 불가 → 회의 불가.

3명은 오케스트레이터(kdh-sprint)가 직접 팀 에이전트로 소환:
  - winston: Agent(name: "winston-{story}", team_name: "sprint-{N}")
  - quinn: Agent(name: "quinn-{story}", team_name: "sprint-{N}")
  - john: Agent(name: "john-{story}", team_name: "sprint-{N}")

★ 별도 reviewer 에이전트 없음. 오케스트레이터가 critics를 직접 관리. ★

각각 party-logs/sprint-{N}-{story}-{이름}.md 작성 필수.

검증 (BLOCKING — 오케스트레이터 체크리스트):
  [ ] party-logs/sprint-{N}-{story}-winston.md 존재
  [ ] party-logs/sprint-{N}-{story}-quinn.md 존재
  [ ] party-logs/sprint-{N}-{story}-john.md 존재
  [ ] 각 로그에 D1-D6 테이블 6행 존재
  (Cross-talk 섹션은 optional — blocking 아님)
  하나라도 없으면 → 해당 critic에게 재작성 요청

## Note: Codex는 kdh-sprint에서 관리

Codex 세컨드 오피니언은 kdh-sprint Phase B.5에서 실행됨 (스토리 레벨 1회).
kdh-review는 3명 팀 에이전트 파티 모드 리뷰만 담당. 중복 Codex 실행 금지.
배치/스프린트 레벨 통합 Codex는 kdh-integration에서 꼼꼼히 실행됨.

## 제대로 된 파티 모드 (v15 — 벤치마크 복원)

```
1. 오케스트레이터가 3명 팀 에이전트에게 SendMessage로 리뷰 지시
2. 각 에이전트 (병렬):
   a. 페르소나 파일 읽기 (_bmad/bmm/agents/{name}.md)
   b. 변경된 파일 읽기
   c. D1-D6 채점 + file:line 증거
   d. party-log 작성
3. Cross-talk (의무):
   - 각 critic → 다른 2명에게 SendMessage (핵심 의견 1개)
   - party-log에 "## Cross-talk" 섹션 추가 (받은 의견 + 반응)
   - placeholder 텍스트 = 거부 → 재작성 요구
4. 최종 점수 확정 (cross-talk 반영)
5. 오케스트레이터: 3개 party-log 읽기 → 평균 계산
6. 점수 분산 체크: stdev < 0.5 → 1명 독립 재채점 요청

CONDITIONAL (평균 < 3.0/4 OR 1명이라도 < 3.0/4 OR CRITICAL finding):
  → fixes-needed.md 생성
  → 오케스트레이터가 dev에게 SendMessage (수정 지시)
  → dev 수정 후 → Phase B 재실행 (critics 재리뷰)
  → 리뷰 CONDITIONAL: 수정 후 재리뷰 (합리적 시도 후 진행 판단은 오케스트레이터가 자체 결정)
```

절대 유지:
  - 3명 별도 팀 에이전트 (서브에이전트 금지, 1명이 3역할 금지)
  - D1-D6 채점 + file:line 증거 필수
  - Cross-talk 의무 (SendMessage로)
  - Auto-fail 체크 (보안, 빌드 깨짐, 타입 오류 등)
  - CONDITIONAL 루프 (dev 수정 → 재리뷰)

# KDH Review v11 — Story Reviewer (Evaluator)

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
| D6 리스크인식 | 보안, 확장성, 배포, **통합 영향** 식별 | 리스크 전부 식별 + 대안 + 타 스토리 영향 범위 | 보안 구멍, 공유 컴포넌트 영향 미파악, localhost fallback |

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

## Phase 1.5: Quick Integration Check (v12)

```
1. 공유 모듈 변경 감지:
   이 스토리가 수정한 파일 중 다른 파일이 import하는 것:
   for file in changed_files:
     importers = grep -rl "from '.*$(basename $file)'" packages/
     if importers.length > 0:
       integration_alert: "{file} is imported by {importers.length} files"

2. 의존 스토리 테스트 실행:
   해당 importer 파일의 테스트만 실행
   RED 있으면 → Party Mode에 "통합 이슈 발견" 전달

3. 환경변수 검증:
   새로 추가된 process.env.XXX:
     .env.example에 없으면 → WARNING
     fallback이 localhost면 → WARNING

4. D6 통합 체크리스트 (Party Mode에 전달):
   □ 공유 컴포넌트(auth, routing, middleware) 변경 → 영향 범위?
   □ 새 환경변수 → 프로덕션에 설정 가능?
   □ 사용자 타입/역할/권한 가정 변경?

결과 → Phase 2 Party Mode에 전달 (D6 채점 시 참고)
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

### D1-D6 Review Template v16 (Finding-First + CoT + 4-point — MANDATORY)

```markdown
## {Agent Name} Review: Story {story-id}
Date: {date} | Sprint: {sprint-N}

### 1. Auto-Fail Gate
- [ ] No hardcoded secrets
- [ ] No SQL injection / XSS
- [ ] No tsc errors
- [ ] No data loss risk (DROP TABLE etc)
- [ ] No inline types (must use @corthex/shared)
Auto-fail triggered? [ ] YES → reason: ___ [ ] NO → continue

### 2. Evidence Collection (Chain-of-Thought — write BEFORE scoring)
For each changed file, verify line by line:
  file.ts:15 — AuthUser import ✓ matches contracts/auth.ts
  file.ts:42 — db query ✓ matches schema/sessions.ts
  file.ts:71 — expiresAt uses > instead of >= ✗ OFF-BY-ONE
(This section MUST exist. No evidence = review rejected.)

### 3. Acceptance Criteria Check
- [ ] AC1: {desc} — evidence: {file:line or test name}
- [ ] AC2: {desc} — evidence: {file:line}

### 4. Findings (for each ✗ from Evidence Collection)
[D{N}] [{CRITICAL|HIGH|MEDIUM|LOW}] file:line — description
  Expected: {what should happen}
  Actual: {what happens now}
  Impact: {why this matters}
  Fix: {specific code change to resolve}

### 5. Dimension Scoring (4-point scale)
| Dim | Score | Weight | Evidence Summary |
|-----|-------|--------|-----------------|
| D1 Specificity  | /4 | {%} | {from Evidence Collection} |
| D2 Completeness | /4 | {%} | {ACs pass/fail count} |
| D3 Accuracy     | /4 | {%} | {type/schema match count} |
| D4 Buildability | /4 | {%} | {tsc/test status} |
| D5 Consistency  | /4 | {%} | {contract compliance} |
| D6 Risk         | /4 | {%} | {security/integration} |

4=EXCELLENT(0 issues) 3=GOOD(LOW/MED only) 2=NEEDS_WORK(≥1 HIGH) 1=FAIL(CRITICAL)
Weighted avg = (D1×w1+...+D6×w6)/100 = {result}

### 6. Cross-talk
- {other critic} found {issue}: I {agree/disagree} because {reason}

### Final: {weighted avg}/4 → {PASS|CONDITIONAL|FAIL|AUTO-FAIL}
PASS: avg ≥ 3.0/4 (= 7.5/10) AND each critic ≥ 3.0/4 AND 0 CRITICAL findings
Report to orchestrator: overall = (avg / 4) × 10 → "리뷰 평균: X.X/10"
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

Step 4.5: 오케스트레이터 형식 검증 (BLOCKING)
  각 party-log에서:
  1. "| D1" ~ "| D6" 6행 존재? → NO면 재작성 요구
  2. 각 점수가 "/4" 형식? → "/10", "/100" 등 다른 형식 = 재작성 요구
  3. "Weighted avg = " 계산식 존재? → NO면 재작성 요구
  4. 하나라도 실패 → SendMessage: "4-point scale (/4)로 재작성해주세요."
```

## Phase 3: Score Evaluation (v11 — 평균 escape 제거)

```
1. 가중 평균 점수 계산: (winston.weighted_avg + quinn.weighted_avg + john.weighted_avg) / 3
2. 개별 minimum 체크 (v11 신규):
   - 3명 모두 개별 가중 평균 >= 3.0/4 필수
   - 어떤 1명이라도 < 3.0/4 → CONDITIONAL
   - CRITICAL finding 1개라도 → CONDITIONAL
   
3. 판정 (v17 — 4-point scale 통일):
   - 3명 모두 >= 3.0/4 AND avg >= 3.0/4 AND CRITICAL 0건 → PASS
   - avg < 3.0/4 OR 1명이라도 < 3.0/4 OR CRITICAL → CONDITIONAL (수정 후 재리뷰)
   - AUTO-FAIL 조건 해당 → FAIL (재구현 필요)
   
   CEO override: /kdh-gate에서 "일단 넘어가" 선택 가능
   → sprint-status.yaml에 ceo_override: true 기록

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
   - 기록: "{reviewer}가 D{N}에 {score}/4 → 자동 불합격"

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
