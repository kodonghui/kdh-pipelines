---
name: kdh-plan
description: "실행 계획 생성기 v1 — research+analyze 결과를 파일/코드/명령어 수준의 구체적 실행 계획으로 변환. DAG 태스크 분해 + 중단/롤백 조건 + Codex 필수 검증."
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

### Step 1: Input Validation (입력 신뢰도 평가)

```
1. /kdh-research 보고서 검색 (최신 _bmad-output/ 또는 _research/)
2. /kdh-analyze 분석 결과 검색
3. 입력 신뢰도 평가:
   - 날짜: 24시간 이내 → ✅ | 24시간+ → ⚠️ "오래된 분석"
   - 일관성: research+analyze 결론 일치 → ✅ | 충돌 → 🚩
   - 범위: 현재 작업과 관련 → ✅ | 다른 주제 → 🚩
4. 둘 다 없으면: "⚠️ research/analyze 없이 plan을 만들면 근거가 약합니다."
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
│   ├── 완료 기준: "tsc pass + 테스트 pass"
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

**우선순위 원칙:**
1. 의존관계 해소 (dependency unlock)
2. 불확실성 제거 (uncertainty reduction)
3. 리스크 감소 (risk reduction)
4. 가치 전달 (value delivery)

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

### Step 5: Codex Cross-Verification (★ 필수)

**선택 아님. 모든 /kdh-plan 실행 시 필수 실행.**

```bash
# 계획서 요약을 파일로 저장
cat > /tmp/kdh-plan-review.md << 'EOF'
[Goal + Tasks + Dependencies + Risks 요약]
EOF

# Codex 실행
bash ~/.claude/scripts/codex-review.sh /tmp/kdh-plan-review.md \
  "이 실행 계획을 공격적으로 리뷰해라. 빠진 태스크, 잘못된 의존관계, 비현실적 복잡도, 빠진 롤백 전략, 빠진 중단 조건을 찾아라. 한국어로 답해라."
```

Codex 결과 처리:
- 이슈 발견 → 계획에 반영 (수정 or "사유 기록 후 유지")
- 실행 실패 → **CEO 보고, 자동 스킵 금지**
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

## Quality Self-Check

- [ ] 목표 SMART 기준 충족?
- [ ] 모든 태스크에 첫 실행 명령?
- [ ] 모든 태스크에 완료 기준?
- [ ] 의존관계 다이어그램?
- [ ] 롤백 방법 명시?
- [ ] Pre-mortem ≥ 3개?
- [ ] 중단 조건 정의?
- [ ] 재계획 조건 정의?
- [ ] Out of scope 목록?
- [ ] **Codex 실행 완료?** ← 필수
- [ ] CEO 요약 반 페이지 이내?

## 3명령어 워크플로우

```
/kdh-research [주제]  → 조사 (7각도, 2라운드, 교차검증)
/kdh-analyze [주제]   → 분석 (6관점, pre-mortem, self-attack, Codex)
/kdh-plan [작업]      → 실행 계획 (DAG 분해, 롤백, Codex 필수)
CEO: "A"             → 즉시 실행
```

각 명령어 독립 실행 가능. 이전 결과 있으면 자동 로드.
