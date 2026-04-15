---
name: kdh-plan
description: "실행 계획 생성기 v1.2 — research+analyze 결과를 파일/코드/명령어 수준의 구체적 실행 계획으로 변환. DAG 태스크 분해 + EARS 수락 기준 + 중단/롤백 조건 + Codex 필수 검증."
---

# /kdh-plan — 실행 계획 생성기

/kdh-research(조사) + /kdh-analyze(분석) 결과를 입력받아, **"이 파일의 이 줄을 이렇게 바꿔라"** 수준의 구체적 실행 계획을 만드는 명령어.

## 사용법

```
/kdh-plan [주제 또는 작업]
```

## 핵심 원칙

> **"좋은 계획 문서"가 아니라 "실행 전환율이 높은 실행 인터페이스"를 만든다.**
> — Codex (GPT-5.4) 지적 반영

- 계획의 목적 = 다음 액션이 바로 실행 가능한 것
- 각 태스크의 필수: **첫 실행 명령, 완료 기준, 중단 조건, 롤백 방법**
- 계획서가 실행보다 느리면 안 됨 → 복잡도에 따라 분량 조절

## 복잡도 자동 판단

| 복잡도 | 기준 | 실행 범위 |
|--------|------|----------|
| **간단** | 파일 1~3개, 의존관계 없음 | Step 2+3만 |
| **보통** | 파일 4~10개, 의존관계 있음 | Step 1~5 |
| **복잡** | 파일 10+, 다단계, 아키텍처 변경 | Step 1~6 전부 |

## 실행 흐름 (6단계)

## 입력 확인 (필수 — 생략 시 중단)

실행 전 반드시 출력:
```
입력 research: [파일 경로] 또는 "없음"
입력 analyze: [파일 경로] 또는 [같은 세션 인라인] 또는 "없음"
핵심: [research + analyze 결론 각 1줄]
```
둘 다 없으면 → "⚠️ research/analyze 없이 plan. CEO 확인 필요" → CEO 승인 없이 진행 금지.

### Step 1: Input Validation (입력 신뢰도 평가)

```
1. /kdh-research 보고서 검색:
   - _bmad-output/kdh-plans/ 에서 Glob "*-research-*.md" 중 현재 주제 매칭, 최신 우선
   - "Analyze-Ready Summary" 섹션이 있으면 우선 읽기
   - Summary가 없으면 research 본문 전체를 읽기
   - Summary만으로 태스크 분해/롤백 근거가 부족하면 research 본문 관련 섹션 추가 열람
2. /kdh-analyze 분석 결과:
   a. _bmad-output/kdh-plans/ 에서 Glob "*-analyze-*.md" 중 현재 주제 매칭, 최신 우선
   b. 파일 있으면 → "Plan-Ready Summary" 섹션 읽기
   c. 파일 없으면 → 같은 세션 채팅 맥락에서 확인
   d. 둘 다 없으면 → research만으로 진행 (경고 표시)
3. _bmad-output/kdh-plans/_index.yaml 읽기:
   - status: active이고 scope가 현재 작업과 관련된 plan 확인
   - 동일 scope plan이 이미 있으면: "기존 plan {id} 고도화할까요?" CEO 질문
   - 관련 plan 있으면 본문 읽어서 고도화 입력으로 사용
4. 입력 신뢰도 평가:
   - 날짜: 24시간 이내 → ✅ | 24시간+ → ⚠️ "오래된 분석"
   - 일관성: research+analyze 결론 일치 → ✅ | 충돌 → 🚩
   - 범위: 현재 작업과 관련 → ✅ | 다른 주제 → 🚩
5. 둘 다 없으면: "⚠️ research/analyze 없이 plan을 만들면 근거가 약합니다."
   → CEO에게 보고, 진행 여부 확인
```

### Step 2: Goal Definition (목표 정의)

```
목표 (1문장): "무엇을 달성하는 계획인가?"

성공 기준 (SMART):
- Specific: 정확히 뭐가 바뀌나?
- Measurable: 어떻게 확인? (테스트? 브라우저? tsc?)
- Achievable: 현재 코드베이스에서 가능?
- Relevant: 현재 Sprint/Stage와 관련?
- Time-bound: 언제까지?

범위:
- IN: [구체적 목록]
- OUT: [명시적 제외]

중단 조건:
- 전제가 틀린 것이 발견되면
- 예상보다 2배 이상 복잡하면
- 블로커가 발견되면

재계획 조건:
- 중단 조건 발동 시 → /kdh-analyze 재실행 후 /kdh-plan 재생성
```

CEO 확인: "이 목표와 범위가 맞나요?"

### Step 3: Task Decomposition (태스크 분해)

작업 성격에 따라 분해 패턴 선택:

**패턴 A: DAG (구현 작업 — 대부분)**
```
Phase 1: Foundation
├── Task 1-1: [제목]
│   ├── 파일: path/to/file.ts:42
│   ├── 변경: "함수 X를 추가" (코드 스니펫 or 설명)
│   ├── 첫 실행 명령: "Read file → Edit → bun test"
│   ├── 의존: 없음
│   ├── 수락 기준 (EARS — 간단:1개, 보통:2~3개, 복잡:3~5개):
│   │   ├── WHEN [트리거], THE SYSTEM SHALL [동작]
│   │   ├── IF [예외], THEN THE SYSTEM SHALL [대응]
│   │   └── ...
│   ├── 검증 방법: [어떻게 확인? tsc? bun test? 브라우저?]
│   ├── 롤백: "git checkout -- path/to/file.ts"
│   └── 복잡도: S (구현:S, 불확실성:없음, 테스트:있음, 롤백:쉬움)

의존관계 다이어그램:
1-1 ──┐
      ├──→ 2-1 ──→ 3-1
1-2 ──┘
```

**패턴 B: Stage-Gate (탐색/불확실 작업)**
```
Stage 1: 조사 → Gate: 가능한가? → PASS/FAIL
Stage 2: 프로토타입 → Gate: 작동하나? → PASS/FAIL
Stage 3: 본 구현
```

**패턴 C: 체크리스트 (설정/검증 작업)**
```
- [ ] 항목 1: [구체적 명령어]
- [ ] 항목 2: [구체적 명령어]
```

**복잡도 4축:**
| 축 | S | M | L |
|----|---|---|---|
| 구현 난도 | 복붙/수정 | 새 로직 | 아키텍처 변경 |
| 불확실성 | 답을 알고 있음 | 조사 필요 | 될지 모름 |
| 테스트 | 기존 테스트 | 새 테스트 | E2E 필요 |
| 롤백 | git checkout | 마이그레이션 | 불가능 |

**EARS 5 Patterns (수락 기준 작성용):**
모든 수락 기준은 반드시 EARS 5 패턴 중 하나를 따른다.
"should/needs to/must" 같은 비EARS 표현 사용 금지.

| 패턴 | 형식 | 용도 |
|------|------|------|
| Ubiquitous | THE SYSTEM SHALL [동작] | 항상 성립하는 동작 |
| Event-driven | WHEN [트리거], THE SYSTEM SHALL [동작] | 특정 이벤트 발생 시 |
| State-driven | WHILE [상태], THE SYSTEM SHALL [동작] | 특정 상태 유지 중 |
| Unwanted | IF [예외], THEN THE SYSTEM SHALL [대응] | 에러/예외 처리 |
| Optional | WHERE [기능 활성], THE SYSTEM SHALL [동작] | 선택적 기능 |

**우선순위 원칙:**
1. 의존관계 해소 (dependency unlock)
2. 불확실성 제거 (uncertainty reduction)
3. 리스크 감소 (risk reduction)
4. 가치 전달 (value delivery)

**다이어그램 필수 (v1.1 — 2026-04-06 CEO 승인):**
구조 변경이 포함된 계획은 반드시 Mermaid 또는 ASCII 다이어그램을 포함한다.
- 아키텍처 변경 → 시스템 다이어그램
- 의존관계 복잡 → DAG 다이어그램
- 데이터 흐름 변경 → 시퀀스 다이어그램
CEO가 한눈에 구조를 파악할 수 있어야 한다. 산문 설명만으로는 부족.

### Step 4: Risk & Pre-mortem + Rollback

```
"이 계획이 실패했다. 왜?"

| 실패 시나리오 | 확률 | 영향 | 예방책 | 롤백 방법 |
|--------------|------|------|--------|----------|

롤백 전략 (전체):
- git: 커밋 단위 revert 가능한 구조
- DB: migration down 가능 여부
- 설정: 이전 설정 백업 여부

재계획 트리거:
- 확률 "높" 시나리오 현실화 → 즉시 중단 + /kdh-analyze 재실행
```

### Step 5: Codex Cross-Verification (★ 필수 — v2 백그라운드)

**선택 아님. 모든 /kdh-plan 실행 시 필수 실행.**

**v2 (2026-04-11 Plan v4): 백그라운드 실행 + 맥락 자동 주입**

```bash
# 계획서 요약을 파일로 저장
cat > /tmp/kdh-plan-review.md << 'EOF'
[Goal + Tasks + Dependencies + Risks 요약]
EOF

# Codex 실행 — ★ run_in_background: true 로 호출하라 ★
# 프로젝트 맥락(Sprint/story/phase)은 스크립트가 자동 주입
bash ~/.claude/scripts/codex-review.sh /tmp/kdh-plan-review.md \
  "이 실행 계획을 공격적으로 리뷰해라. 빠진 태스크, 잘못된 의존관계, 비현실적 복잡도, 빠진 롤백 전략, 빠진 중단 조건을 찾아라. 수락 기준이 EARS 5 패턴(Ubiquitous/Event-driven/State-driven/Unwanted/Optional) 중 하나를 따르는지 확인하고, should/needs to/must 같은 비EARS 표현이 있으면 지적해라. 한국어로 답해라."
```

**Bash 호출 지침 (Claude Code 도구 사용 시):**
- `run_in_background: true` 필수 (2분 타임아웃 회피)
- 결과 도착 알림 받으면 결과 파일 읽기
- 결과 첫 줄의 `Timestamp:` 확인 → 10분 경과 시 재실행

Codex 결과 처리:
- 이슈 발견 → 계획에 반영 (수정 or "사유 기록 후 유지")
- 실행 실패 → **CEO 보고, 자동 스킵 금지**
- Codex 실패 + Gemini 성공 → partial OK (v2 기본 동작)
- 이슈 0개 → 🚩 의심

### Step 6: Plan Presentation (보고)

**CEO용 요약 (반 페이지):**
```
## 실행 계획: [목표 1문장]

태스크: [N]개 ([M] Phase)
핵심 위험: [top 2]
Codex: [PASS / 이슈 N개 반영]

A) 이대로 실행
B) [수정] 후 실행
C) 더 분석 필요
```

**개발자용 전체:** Step 2~5 내용 전부.

### Step 7: Plan Registry (계획 등록)

**CEO 승인 후, plan 파일을 `_bmad-output/kdh-plans/`에 저장하고 인덱스를 업데이트한다.**

```
1. 파일명 생성: MMDD-{slug}.md
   - MMDD = 오늘 날짜 (0406, 0407...)
   - slug = 제목에서 kebab-case (예: sprint1-reverify, sse-streaming-plan)

2. Plan 파일 저장:
   _bmad-output/kdh-plans/MMDD-{slug}.md

3. _index.yaml 업데이트 (없으면 자동 생성):
   plans:
     - id: "MMDD-{slug}"
       file: "MMDD-{slug}.md"
       title: "{Step 2 목표 1문장}"
       status: active
       scope: "{자동 감지: sprint-N | story-X-Y | infrastructure | planning | all}"
       pipeline: "{자동 감지: dev | planning | bug-fix | all}"
       created: "YYYY-MM-DD"
       ttl: "{CEO가 지정 or null}"

4. 기존 plan 고도화 시:
   - 이전 plan의 status: active → done
   - 새 plan에 refines: "이전-plan-id" 추가
   - 새 plan의 status: active

5. CEO 보고 (★ 필수):
   plan 저장 후 채팅으로 전체 내용을 CEO에게 보여준다.
   - 목표, 태스크 목록, 의존관계, 위험을 한국어로 설명
   - CEO가 "좋아" / "수정해" / "다시" 응답할 때까지 대기
   - CEO 승인 없이 다음 단계 진행 금지
   - plan 파일만 저장하고 보고 안 하면 = 규칙 위반

★ 모든 파이프라인(dev/planning/bug-fix)이 시작 시 _index.yaml을 읽고
  status: active + scope/pipeline 매칭되는 plan 본문을 자동으로 읽음.
★ ECC-3h가 TTL 만료 plan을 자동 done 처리.
★ ECC-12h가 done plan에서 패턴을 추출해 학습.
```

## Quality Self-Check

- [ ] 목표 SMART 기준 충족?
- [ ] 모든 태스크에 첫 실행 명령?
- [ ] 모든 태스크에 EARS 수락 기준 ≥ 1개?
- [ ] EARS 비준수 표현 (should/needs to/must) 없음?
- [ ] 의존관계 다이어그램?
- [ ] 롤백 방법 명시?
- [ ] Pre-mortem ≥ 3개?
- [ ] 중단 조건 정의?
- [ ] 재계획 조건 정의?
- [ ] Out of scope 목록?
- [ ] **Codex 실행 완료?** ← 필수
- [ ] CEO 요약 반 페이지 이내?

## 4명령어 워크플로우

```
/kdh-discuss [주제]   → 논의 (선택지 + 반대의견 + 다음 행동)
/kdh-research [주제]  → 조사 (7각도, 검색원 라우팅, 신뢰도 점수)
/kdh-analyze [주제]   → 분석 (6관점, pre-mortem, self-attack, Codex)
/kdh-plan [작업]      → 실행 계획 (DAG 분해, 롤백, Codex 필수)
CEO: "A"             → 즉시 실행
```

각 명령어 독립 실행 가능. 이전 결과 있으면 자동 로드.
