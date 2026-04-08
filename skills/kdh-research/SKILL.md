---
name: kdh-research
description: "Deep Research v3 — Source routing (Context7→GitHub→Web), 3-question credibility scoring, conditional Round 3, analyze-ready output"
---

# /kdh-research — Deep Research Command v3

When the user invokes `/kdh-research [topic]`, execute a comprehensive, multi-source deep research operation.

## Core Directive

- **Latest**: Reject sources older than 12 months for fast-moving topics (AI, frameworks).
- **Accurate**: Cross-reference across 3+ sources before stating a claim as fact.
- **Comprehensive**: Cover the topic from 7 different angles (Step 1).
- **Verified**: Every claim in the report must have a source. No source = don't include it.
- **Analyze-Ready**: Output format optimized for /kdh-analyze Stage 2 input.

## 입력 확인 (필수)

실행 전 반드시 출력:
1. 같은 세션 /kdh-discuss 결과 확인 → 논의 맥락 활용
2. _bmad-output/kdh-plans/ 에서 Glob "*-research-*.md" → 같은 주제 기존 research 확인
3. 기존 research 있으면 → CEO에게 "기존 [파일명] 있는데 새로 할까요?" 확인

```
입력: [discuss 맥락 유무] + [기존 research 유무]
핵심: [discuss 방향 1줄] 또는 "새 주제"
```

## Execution Steps (Step 0~6)

### Step 0: Source Routing (검색원 라우팅)

주제 분류 후 적합한 검색원을 **먼저** 사용한다.
"먼저" = 1순위로 시도, 결과 부족하면 2순위로 보충.
1순위 충분해도 교차 검증용 2순위 검색 최소 1회 실행.

| 검색원 | 강점 | 사용 시점 |
|--------|------|----------|
| **Context7 MCP** | 공식 문서, 버전별 정확 | 라이브러리/프레임워크 관련 각도 |
| **GitHub (gh CLI)** | 실제 구현체, 스타 수로 검증 | 코드 패턴/구현 관련 각도 |
| **WebSearch** | 최신 트렌드, 블로그, 뉴스 | 일반 지식, 비교, 의견 |
| **WebFetch** | 특정 URL 상세 분석 | Round 1/2에서 선별된 URL |

**Context7 사용법:**
1. `resolve-library-id` — 라이브러리명으로 Context7 ID 조회
2. `query-docs` — 해당 ID로 문서 검색
폴백: Context7 실패(MCP 미응답, 라이브러리 미지원) → WebSearch 전환. 멈추지 말 것.

**GitHub 검색:**
```bash
gh search repos "{topic}" --stars=">500" --sort=stars --limit=5
gh search repos "{topic}" --sort=updated --limit=5
```
품질: stars > 500 = 검증됨, 100-500 = 참고, < 100 = 참조만.

**학술 검색 (주제가 학술적일 때):**
```
WebSearch: "site:arxiv.org {topic} survey 2025 2026"
```
품질: citations > 10 = 신뢰, 5-10 = 최근이면 OK, < 5 = 최근 아니면 제외.

**패키지 레지스트리 (해당 시):**
```
WebSearch: "npmjs.com {package}" OR "pypi.org {package}"
```

### Step 1: Query Decomposition (쿼리 분해)

주제를 **7 sub-queries**로 분해. 30초 생각: "이 주제의 다른 면은?"

| # | Angle | Query Pattern | Purpose |
|---|-------|--------------|---------|
| 1 | Problem | "{topic} problem challenge bottleneck" | Why is this hard? |
| 2 | Solutions | "{topic} solution pattern best practice 2026" | How do people solve it? |
| 3 | Our Stack | "{our_tools} {topic} how to" | How does it apply to us? |
| 4 | Implementations | "github {topic} implementation stars:>500" | Real code examples |
| 5 | Research | "arxiv {topic} survey paper 2025 2026" | Academic grounding |
| 6 | Official | "{vendor} official {topic} documentation guide" | Vendor/framework docs |
| 7 | Production | "{topic} production experience lessons learned enterprise" | Real-world experience |

★ Step 0의 라우팅에 따라 각 angle의 1순위 검색원 선택.
  - Angle 4(Implementations) → GitHub 먼저
  - Angle 6(Official) → Context7 먼저
  - 나머지 → WebSearch
★ 7 WebSearch를 **single message에 병렬 호출**.
★ "2025 2026"을 최소 3개 쿼리에 포함.

### Step 2: Round 1 — Breadth (발견)

7 WebSearch + Step 0 결과에서:
1. **Top 5~8 URL 선별** — title + snippet relevance로 판단
2. **WebFetch 5~8개를 single message에 병렬 호출:**
   ★ 반드시 하나의 메시지에 여러 WebFetch를 동시 실행. 순차 호출 금지.
   ★ 각 WebFetch prompt:
   > "Extract: (1) specific findings with numbers/evidence, (2) what this source uniquely contributes, (3) claims without evidence. Be concrete."
3. **Extract learning** from each source:

```
Source: [Title](URL) | Date: YYYY-MM | Type: blog/paper/docs/repo
Finding: {core discovery in 1-2 sentences}
Evidence: {specific numbers, code, quotes}
Gap: {what this source alone can't answer}
```

### Step 3: Source Credibility (소스 신뢰도 평가)

Round 1 각 소스에 대해 **3가지 질문**:

| 질문 | 좋음 | 보통 | 나쁨 |
|------|------|------|------|
| **유형?** | 논문, 공식문서 | GitHub (500+), 알려진 테크블로그 | 포럼, 무명 블로그, 출처 불명 |
| **최신?** | 6개월 이내 | 6~12개월 | 1년+ |
| **근거?** | 숫자+코드 제시 | 숫자 또는 코드 중 하나 | 주장만, 근거 없음 |

판정:
- 3개 다 좋음 → **HIGH**
- 2개 좋음 → **MEDIUM**
- 1개 이하 → **LOW**

★ 주제별 조정:
  - fast-moving (AI, 프레임워크) → "최신?" 가중: 6개월 넘으면 자동 1단계 하향
  - 보안/법률 → "유형?" 가중: 블로그는 자동 1단계 하향
★ LOW라도 "유일한 소스"면 제외 안 함 — [단일소스] 태그 표시
★ 이 단계 = 개별 소스 품질. Step 5(교차 검증) = 주장 단위 합의. 역할 다름.

### Step 4: Round 2 — Depth (깊이)

**입력 필터링:**
1. HIGH (≥ 2/3 좋음): Round 2에서 깊이 파는 우선 대상
2. MEDIUM: 갭 채우기용으로만 사용
3. LOW: Round 2 입력에서 제외 (단, [단일소스]면 유지)
   → LOW 제외 소스의 Finding은 Gaps에 "미검증 주장"으로 기록

**실행:**
1. **갭 목록 작성** (각 learning의 Gap 필드에서)
2. **충돌 목록 작성** (소스 간 불일치)
3. **타겟 검색 3~5개** 생성 (갭 + 충돌 기반, Round 1 반복 금지)
4. **WebSearch + WebFetch 실행** (병렬)
5. 새 learning에도 Step 3 신뢰도 평가 적용

### Step 4.5: Gap Check (갭 체크)

Round 2 완료 후:
1. 미해결 갭 목록 작성
2. 판정:
   - 갭 0~2개 → Step 5로 진행
   - 갭 3개 이상 → **Round 3 실행** (갭 기반 타겟 검색 3~5개)
3. Round 3는 **최대 1회**. 무한 루프 금지.
4. 보고서에 명시: "Rounds: 2" 또는 "Rounds: 3 (갭 N개로 추가)"

### Step 5: Cross-Verification (교차 검증)

주장 단위로 독립 소스 합의 확인 (소스 단위 아님 — Step 3과 역할 다름):

| Confidence | Criteria | Report Format |
|-----------|---------|---------------|
| ✅ HIGH | 3+ independent sources agree | "X is Y" |
| ⚠️ MEDIUM | 2 sources agree | "X appears to be Y" |
| 🔴 LOW | 1 source only | "According to [source], X is Y" |
| ❌ CONFLICTED | Sources disagree | "Source A says X, Source B says Y" |

★ LOW confidence claim을 사실처럼 쓰지 말 것.
★ CONFLICTED는 양쪽 + 어느 쪽이 맞을 가능성이 높은지 분석 포함.

### Step 6: Report Synthesis (보고서)

모든 learning을 합성. Copy-paste 금지.

```markdown
# Research Report: [Topic]
> Researched: [date] | Sources: [count] | Rounds: [N] | Queries: [N]
> Cross-verified claims: [N/N] | Overall confidence: [HIGH/MEDIUM/LOW]

## TL;DR
[3~5 bullet points — each with confidence indicator]

## Current State (as of [date])
[Cross-verified facts only]

## Detailed Analysis
[Subsections by theme. Each claim marked with confidence level.]
[CONFLICTED claims: present both sides with analysis.]

## Comparison Table
[Quantitative metrics where available]

## Recommendations
[Ranked. Each with: confidence level, evidence count, trade-offs.]

## Gaps & Limitations
[What we couldn't answer. 미검증 주장. Single-source claims.]

## Analyze-Ready Summary (kdh-analyze 입력용)

검증된 사실:
| # | 사실 | 신뢰도 | 소스 수 | 소스 목록 |
|---|------|--------|---------|----------|

미검증 주장:
| # | 주장 | 신뢰도 | 이유 |
|---|------|--------|------|

핵심 갭:
- [아직 모르는 것]

## Sources
| # | Source | Date | Type | Cited in | Credibility |
|---|--------|------|------|----------|------------|
```

★ 저장: _bmad-output/kdh-plans/MMDD-research-{slug}.md
  - MMDD = 오늘 날짜 (예: 0408)
  - slug = 주제 kebab-case (예: kdh-plan-upgrade, 4cmd-chaining)

## Rules

- Never rely on training data alone — always verify with live search
- If topic changed rapidly, note what changed and when
- If topic is vague, ask ONE clarifying question before researching
- Write report in same language user used
- Minimum: 7 WebSearch + 5 WebFetch per research
- Round 2 is MANDATORY — never skip
- Cross-verification is MANDATORY — never skip
- Gaps & Limitations section is MANDATORY
- Context7 먼저 for library/framework topics
- GitHub search 먼저 for code implementation topics

## Quality Self-Check

- [ ] Every claim has at least 1 source reference
- [ ] All sources have 3-question credibility score
- [ ] Confidence levels on all major claims
- [ ] At least 1 CONFLICTED or LOW claim exists (all HIGH = not looking hard enough)
- [ ] Gaps section is non-empty
- [ ] Comparison table includes quantitative data
- [ ] Sources table complete with dates, types, credibility
- [ ] No copy-paste — all text synthesized
- [ ] Analyze-Ready Summary section exists
- [ ] WebFetch calls were parallel (not sequential)
