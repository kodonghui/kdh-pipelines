---
name: kdh-analyze
description: "CEO 전용 깊은 분석 v2 — 6 Perspectives + Pre-mortem + Self-Attack + Codex Cross-Model Verification"
---

# /kdh-analyze v2 — CEO 전용 깊은 분석 명령어

사장님이 "메타적으로 상세히 분석해서 구체적이고 자세하게 아이디어와 방법을 설명해줘 Ultrathink"를 한 단어로.

## 사용법

```
/kdh-analyze [주제 또는 질문]
/kdh-analyze [주제] Ultrathink    ← Codex cross-verification 포함
```

## 복잡도 자동 판단

| 복잡도 | 기준 | 실행 범위 |
|--------|------|----------|
| **간단** | 한 문장 질문, 기술 결정 1개 | Stage 1 + 2 + 6 (3단계) |
| **보통** | 방향 선택, 비교 분석 | Stage 1~4 + 6 (5단계) |
| **복잡** | 전략 결정, 아키텍처, "Ultrathink" 명시 | Stage 1~7 전부 (7단계, Codex 포함) |

판단 기준: 주제에 "Ultrathink" 포함 → 복잡. 선택지가 3개 이상 → 보통. 그 외 → 간단.

## 분석 프레임워크 (7단계)

### Stage 1: MECE 분해 — 구조 잡기
> 비유: 냉장고 칸 먼저 나누고, 그 다음에 뭘 넣을지 정하기

주어진 주제를 **겹치지 않고 빠짐없이** 분해한다:
1. 이 문제의 구성 요소 3~5개 식별
2. 우리가 **아는 것** vs **모르는 것** 분류
3. **결정해야 할 것**이 정확히 무엇인지 1문장으로 정리

출력: 문제 구조 맵 (테이블)

### Stage 2: 6 Perspectives — 다각도 분석
> 비유: 같은 사진을 6명이 다른 눈으로 보기

하나의 주제를 6가지 관점에서 **분리** 분석:

| 관점 | 질문 | 근거 |
|------|------|------|
| ⚪ **사실** | 확실히 아는 것만. 데이터/증거 기반. | "~라고 알려져 있다 [소스]" |
| 🔴 **위험** | 뭐가 잘못될 수 있지? | "~하면 ~할 위험" |
| 🟡 **기회** | 잘 되면 뭐가 좋지? | "~하면 ~을 얻음" |
| ⚫ **비판** | 이게 왜 나쁜 생각이지? | Devil's Advocate — 의도적 반대 |
| 🟢 **대안** | 다른 방법은 없나? | 최소 2개 대안 제시 |
| 🔵 **결정** | 어떻게 선택하지? | 판단 기준 + trade-off 명시 |

★ **비판(⚫)이 비어있으면 분석 불완전.** LLM은 positivity bias가 있으므로 (arxiv 2410.21819) 비판을 의도적으로 먼저 작성.
★ 각 관점은 **다른 관점을 참조하지 않고** 독립 작성. 그래야 편향이 섞이지 않음.

### Stage 3: Pre-mortem — 실패 상상
> 비유: "6개월 후 이 결정이 대실패했다. 왜?"

추천안이 형성되면, **이미 실패했다고 가정**하고:
1. **실패 원인 3개 이상** 추론 (구체적으로)
2. **숨겨진 가정** 식별 — "이게 사실이 아니면?"
3. **예방책** — 각 원인별 구체적 대응

출력:
| 실패 시나리오 | 숨겨진 가정 | 확률 | 예방책 |
|--------------|-----------|------|--------|

★ Wharton 연구: 이 방법만으로 리스크 예측 능력 30% 향상.

### Stage 4: Evidence-Grounded 추천
> 비유: 법정 변호사처럼 증거 번호 붙이기

각 추천에 confidence level 부여:
- ✅ **HIGH**: 3+ 소스/사례/경험에서 검증 → 단정형: "이렇게 하세요"
- ⚠️ **MEDIUM**: 2개 근거 → 제안형: "이렇게 하는 게 좋아 보여요"
- 🔴 **LOW**: 1개 근거 or 추측 → 참고형: "이런 방법도 있는데 확실하지 않아요"

출력:
| 추천 | Confidence | Trade-off | 근거 |
|------|-----------|-----------|------|

★ LOW confidence 추천은 반드시 표시. 모든 추천이 HIGH면 → 편향 의심.

### Stage 5: Self-Adversarial Review — 자기 공격
> 비유: 자기가 쓴 시험 답안을 다른 사람인 척 채점

CEO에게 보여주기 전, **3가지 편향 자가 진단**:

**1. 긍정 편향 체크**
"내가 추천한 안의 단점을 충분히 말했나?"
→ 단점 0개 = 🚩 편향 확실. 최소 2개 추가.

**2. 효율 편향 체크**
"빠르고 쉬운 답을 골랐나? 느리지만 더 좋은 답은 없나?"
→ 이번 세션 교훈: 오케스트레이터가 3번 경량화 시도하다 CEO에게 잡힘.

**3. 빠진 관점 체크**
"6 Perspectives에서 비어있는 칸은?"
→ 사실(⚪) 약함 = 근거 부족. 비판(⚫) 약함 = 편향.

출력: `## Self-Attack` 섹션 (발견된 편향 + 수정사항)
★ 이 섹션이 비어있으면 분석 불완전.

### Stage 6: Codex Cross-Model Verification (★ 필수)
> 비유: 변호사가 작성한 의견서를 다른 법무법인에 보내서 검토받기

**모든 /kdh-analyze 실행 시 필수. 간단한 분석도 Codex 검증 거쳐야 함.**

왜: 같은 모델(Claude)이 쓰고 검증하면 self-preference bias 발생 (arxiv 2410.21819).
다른 모델(GPT-5.4 Codex)이 검증하면 correlated failures를 깨뜨림.

실행 방법 (v2 — 2026-04-11 Plan v4: 백그라운드 + 맥락 자동 주입):
```bash
# 분석 결과를 임시 파일에 저장
echo "[분석 요약 + 추천 + self-attack 결과]" > /tmp/kdh-analyze-review.md

# codex-review.sh v2 사용 — ★ Bash run_in_background: true 로 호출 ★
# 프로젝트 맥락(Sprint/story/phase)은 스크립트가 자동 주입
bash ~/.claude/scripts/codex-review.sh /tmp/kdh-analyze-review.md \
  "다음 분석 결과를 공격적으로 리뷰해라. 틀린 부분, 빠진 관점, 편향을 찾아라. 한국어로 답해라."
```

**Bash 호출 지침:** `run_in_background: true` 필수. 결과 도착 알림 받고 파일 읽기. Timestamp 10분 초과 시 재실행.

Codex 결과 처리:
- Codex가 찾은 이슈 → 분석에 반영 (수정 or "Codex 지적했지만 이유로 유지" 기록)
- Codex FAIL = 분석 재검토. Codex PASS = 신뢰도 상승.

★ Codex 실행 실패(인증/타임아웃) → CEO에게 보고, 자동 스킵 금지.
★ Codex 결과 중 맥락상 안 맞는 지적 → 사유 기록 후 스킵 OK.

### Stage 7: 실행 방안 + 선택지

Stage 5(자기 공격) + Stage 6(Codex) 결과가 반영된 최종 실행안:
- 구체적 구현 방법 (파일, 코드, 명령어)
- 순서와 의존관계
- **A/B/C 선택지** — 각각 confidence + trade-off + pre-mortem 결과 포함
- "A를 택하면 이런 위험이 있지만 이렇게 예방"

## 산출물 저장 (필수)

분석 완료 후 결과를 파일로 저장한다. 같은 세션에서 바로 /kdh-plan으로 이어가도, 파일은 반드시 저장.

저장 경로: `_bmad-output/kdh-plans/MMDD-analyze-{slug}.md`
- MMDD = 오늘 날짜
- slug = 주제 kebab-case
- _index.yaml에 등록하지 않는다 (glob 탐색으로 충분)

저장 내용:

```markdown
# Analyze: [주제]
> Analyzed: [date] | Complexity: [간단/보통/복잡] | Codex: [PASS/이슈 N개]

## TL;DR
[3줄 요약]

## 추천
| # | 추천 | Confidence | Trade-off |

## Self-Attack 요약
[핵심 편향 + 수정사항]

## Codex 지적 요약
[핵심 이슈 + 반영 여부]

## Plan-Ready Summary (kdh-plan 입력용)

추천안:
| # | 추천 | Confidence | 근거 요약 |

주요 위험:
| # | 위험 | 확률 | 예방책 |

CEO 선택: [A/B/C 또는 "대기중"]
```

★ 같은 주제의 기존 analyze 파일 있으면: "기존 분석 있음. 갱신할까요?" CEO 확인
★ CEO가 선택지를 골랐으면 → "CEO 선택: B" 기록. 아직이면 → "대기중"
★ /kdh-plan이 이 파일의 "Plan-Ready Summary"를 자동 입력으로 사용

## 출력 규칙

- **한국어** — 기술 용어 최소화, 비유로 설명
- **구체적** — "좋은 방법"이 아니라 "이 파일의 이 부분을 이렇게"
- **선택지** — 마지막에 항상 A/B/C 선택지 제시
- **짧은 요약 먼저** — TL;DR 3줄 (confidence 포함) → 상세 분석
- **confidence 필수** — 모든 주장에 HIGH/MEDIUM/LOW
- **"~인 것 같다" 금지** — confidence level로 대체
- **Self-Attack 섹션 필수** — 빠지면 분석 불완전

## 리서치 연동

## 입력 확인 (필수 — 생략 시 중단)
1. _bmad-output/kdh-plans/ 에서 Glob "*-research-*.md" 중 현재 주제 매칭, 최신 우선
2. 출력:
   ```
   입력: [research 파일 경로] 또는 "없음"
   핵심: [Analyze-Ready Summary 첫 줄] 또는 "research 없이 진행 — CEO 확인 필요"
   ```
3. 입력이 없으면 → CEO에게 "research 없이 진행할까요?" 확인 후 진행

/kdh-research 결과가 있으면:
1. 보고서의 **"Analyze-Ready Summary"** 섹션을 먼저 읽는다
2. "검증된 사실" 테이블 → Stage 2(사실⚪) 자동 입력
3. "미검증 주장" 테이블 → Stage 2(사실⚪)에 [미검증] 태그로 표시
4. "핵심 갭" → Stage 1(MECE)의 "모르는 것"에 자동 입력
5. confidence level + 소스 수를 그대로 계승
6. 추가 리서치 불필요

/kdh-research 결과가 없고 외부 정보가 필요하면:
- Stage 2 작성 중 WebSearch 최소 3회 실행
- 결과를 사실(⚪)에 반영

## 실행 모드

분석 결과를 사장님이 승인하면, 같은 세션에서 바로 실행:

```
사장님: /kdh-analyze [주제]
→ 분석 + 선택지 제시

사장님: B로 해
→ B안 기반으로 즉시 구현 시작
```

## Quality Self-Check (출력 전)

- [ ] MECE 분해가 빠짐없는가? (3~5 요소)
- [ ] 6 Perspectives 중 비어있는 관점이 없는가?
- [ ] 비판(⚫) 관점에 구체적 근거가 있는가?
- [ ] Pre-mortem 실패 시나리오 ≥ 3개인가?
- [ ] 모든 추천에 confidence level이 있는가?
- [ ] LOW confidence 추천이 최소 1개 존재하는가? (없으면 편향 의심)
- [ ] Self-Attack 섹션이 비어있지 않은가?
- [ ] Codex 리뷰 실행했는가? ← 모든 복잡도에서 필수

## 4명령어 워크플로우

```
/kdh-discuss [주제]   → 논의 (선택지 + 반대의견 + 다음 행동)
/kdh-research [주제]  → 조사 (7각도, 검색원 라우팅, 신뢰도 점수)
/kdh-analyze [주제]   → 분석 (6관점, pre-mortem, self-attack, Codex)
/kdh-plan [작업]      → 실행 계획 (DAG 분해, 롤백, Codex 필수)
CEO: "A"             → 즉시 실행
```

각 명령어 독립 실행 가능. 이전 결과 있으면 자동 로드.

Sources:
- Self-Preference Bias: arxiv 2410.21819
- MAR Multi-Agent Reflexion: arxiv 2512.20845
- BMAD Adversarial Review: docs.bmad-method.org
- Pre-mortem: Wharton/Colorado/Cornell 1989 (30% risk prediction improvement)
- Six Thinking Hats: De Bono 1986
- Miessler RedTeam: 32-agent parallel analysis
