# CORTHEX Pipeline — Critic Scoring Rubric v1.0

> Critics는 이 루브릭에 따라 **차원별 점수**를 매기고, 평균을 최종 점수로 제출.
> 7/10 미만 = 재작성. 7+ = 통과. 차원별 3점 미만이 하나라도 있으면 = 자동 불합격.

---

## 채점 스케일 (1-10)

| 점수 | 등급 | 의미 |
|------|------|------|
| 10 | Perfect | 고칠 게 없음. 바로 프로덕션 투입 가능. |
| 9 | Excellent | 극히 사소한 개선점 1개. 전체 품질 탁월. |
| 8 | Great | 사소한 개선점 2-3개. 핵심은 완벽. |
| 7 | Good (PASS) | 기능적으로 완전. 개선 가능하나 블로커 없음. |
| 6 | Acceptable | 작동은 하지만 빠진 것 1-2개. 수정 후 통과 가능. |
| 5 | Mediocre | 핵심 요소 누락. 구조는 있으나 불완전. |
| 4 | Poor | 다수 누락. 요구사항 절반만 충족. |
| 3 | Bad | 근본적 문제. 방향 자체가 잘못됨. |
| 2 | Very Bad | 거의 쓸 수 없음. 재작성 필요. |
| 1 | Unacceptable | 빈 파일, 복붙, 무관한 내용. |

---

## 6개 채점 차원

### D1: 구체성 (Specificity) — "뭉뚱그리지 않았나"

| 점수 | 기준 |
|------|------|
| 9-10 | 모든 값이 구체적: 파일 경로, hex 색상, px 단위, 정확한 함수명, 줄 번호 |
| 7-8 | 대부분 구체적. 1-2곳만 "적절한", "필요에 따라" 같은 표현 |
| 5-6 | 절반이 구체적, 절반이 추상적 ("깔끔한 디자인", "효율적인 코드") |
| 3-4 | 대부분 추상적. 실제 구현 시 다시 물어봐야 함 |
| 1-2 | 전부 뜬구름. "좋은 UX 제공", "성능 최적화" 수준 |

**예시:**
- 10점: `bg-slate-950 (#020617)에서 bg-zinc-900 (#18181B)으로 변경. 파일: packages/admin/src/pages/dashboard.tsx:42`
- 5점: `배경색을 어두운 계열로 변경`
- 2점: `적절한 다크 테마 적용`

### D2: 완전성 (Completeness) — "빠진 게 없나"

| 점수 | 기준 |
|------|------|
| 9-10 | 요구사항 100% 커버. 엣지 케이스까지 포함. |
| 7-8 | 핵심 요구사항 전부 커버. 사소한 엣지 케이스 1-2개 누락. |
| 5-6 | 핵심 70% 커버. 중요한 요구사항 1-2개 누락. |
| 3-4 | 핵심 절반만 커버. 주요 기능 누락. |
| 1-2 | 요구사항 대부분 무시. |

**체크리스트:**
- [ ] Step instruction의 모든 항목이 다뤄졌는가?
- [ ] project-context.yaml의 모든 페이지가 포함되었는가?
- [ ] 에러 케이스 / 빈 상태 / 로딩 상태가 고려되었는가?
- [ ] PRD/아키텍처와 일치하는가?

### D3: 정확성 (Accuracy) — "틀린 게 없나"

| 점수 | 기준 |
|------|------|
| 9-10 | 모든 기술적 정보가 정확. API 경로, 타입, DB 스키마 일치. |
| 7-8 | 99% 정확. 오타/사소한 불일치 1건. |
| 5-6 | 95% 정확. 존재하지 않는 API를 참조하거나, 타입이 다른 곳 2-3건. |
| 3-4 | 다수 오류. 코드 구조를 잘못 이해. |
| 1-2 | 팩트와 무관한 추측/할루시네이션. |

**검증 방법:**
- 참조된 파일이 실제로 존재하는가? (`Read` 도구로 확인)
- API 경로가 서버 라우트와 일치하는가?
- DB 컬럼/타입이 스키마와 일치하는가?
- 의존성 패키지가 실제로 설치되어 있는가?

### D4: 실행 가능성 (Implementability) — "이거 보고 바로 코드 짤 수 있나"

| 점수 | 기준 |
|------|------|
| 9-10 | 코드 스니펫, 타입 정의, 파일 구조까지 포함. 복붙 수준. |
| 7-8 | 핵심 로직/구조 명확. 세부 구현만 개발자 판단. |
| 5-6 | 방향은 맞지만 "어떻게"가 부족. 추가 리서치 필요. |
| 3-4 | 요구사항만 있고 구현 가이드 없음. |
| 1-2 | 읽어도 뭘 만들어야 하는지 모름. |

### D5: 일관성 (Consistency) — "앞뒤가 맞나"

| 점수 | 기준 |
|------|------|
| 9-10 | 이전 Phase/Step 결정사항과 100% 정합. 컨벤션 통일. |
| 7-8 | 대부분 정합. 용어/네이밍 불일치 1-2건. |
| 5-6 | 이전 결정과 충돌 2-3건. 자기모순 존재. |
| 3-4 | 이전 Phase를 무시하고 독자적 결정. |
| 1-2 | 완전히 다른 방향. context-snapshot을 안 읽은 것 같음. |

**체크리스트:**
- [ ] 이전 Step의 context-snapshot과 일치하는가?
- [ ] 네이밍 컨벤션(kebab-case 파일, PascalCase 컴포넌트)을 따르는가?
- [ ] 디자인 토큰이 Phase 3에서 정의한 것과 동일한가?
- [ ] API 응답 형식이 `{ success, data }` / `{ success, error }` 인가?

### D6: 리스크 인식 (Risk Awareness) — "위험한 부분을 알고 있나"

| 점수 | 기준 |
|------|------|
| 9-10 | 기술 리스크, 보안 리스크, 성능 리스크 모두 식별 + 대안 제시. |
| 7-8 | 주요 리스크 식별됨. 대안이 구체적. |
| 5-6 | 리스크 언급은 있으나 대안이 추상적. |
| 3-4 | 명백한 리스크를 놓침 (보안 취약점, 성능 병목 등). |
| 1-2 | 리스크 개념 자체가 없음. |

---

## Critic별 차원 가중치

각 Critic은 전문 영역에 따라 가중치가 다름:

### Critic-A (Architecture + API) — Winston + Amelia
| 차원 | 가중치 |
|------|--------|
| D1 구체성 | 15% |
| D2 완전성 | 15% |
| D3 정확성 | **25%** |
| D4 실행가능성 | **20%** |
| D5 일관성 | 15% |
| D6 리스크 | 10% |

### Critic-B (QA + Security) — Quinn + Dana
| 차원 | 가중치 |
|------|--------|
| D1 구체성 | 10% |
| D2 완전성 | **25%** |
| D3 정확성 | 15% |
| D4 실행가능성 | 10% |
| D5 일관성 | 15% |
| D6 리스크 | **25%** |

### Critic-C (Product + Delivery) — John + Bob
| 차원 | 가중치 |
|------|--------|
| D1 구체성 | **20%** |
| D2 완전성 | **20%** |
| D3 정확성 | 15% |
| D4 실행가능성 | 15% |
| D5 일관성 | 10% |
| D6 리스크 | **20%** |

---

## 채점 출력 형식

```markdown
## Critic-{X} Review — {Step Name}

### 차원별 점수
| 차원 | 점수 | 근거 |
|------|------|------|
| D1 구체성 | 8/10 | 파일 경로 전부 명시, hex 색상 포함. "적절한" 표현 2곳. |
| D2 완전성 | 7/10 | 핵심 커버됨. 에러 상태 UI 누락. |
| D3 정확성 | 9/10 | API 경로 전부 확인. 타입 일치. |
| D4 실행가능성 | 8/10 | 코드 스니펫 포함. 상태 관리 패턴 명확. |
| D5 일관성 | 9/10 | 이전 Phase와 정합. 컨벤션 준수. |
| D6 리스크 | 6/10 | WebSocket 연결 실패 시 fallback 미언급. |

### 가중 평균: 7.8/10 ✅ PASS

### 이슈 목록
1. **[D2 완전성]** 에러 상태 UI 미정의 — 네트워크 끊김 시 어떤 화면?
2. **[D6 리스크]** WebSocket 연결 실패 fallback 필요 — SSE? polling?
3. **[D1 구체성]** Line 42: "적절한 간격" → 구체적 px/rem 값 명시 필요

### Cross-talk 요약
- Critic-A가 지적한 DB 인덱스 누락에 동의.
- Critic-C의 스코프 우려는 Phase 2에서 해결 예정으로 판단.
```

---

## 자동 불합격 조건 (Override Rules)

아래 중 하나라도 해당되면 점수와 관계없이 **즉시 불합격**:

1. **할루시네이션**: 존재하지 않는 API/파일/함수를 참조
2. **보안 구멍**: 하드코딩된 시크릿, SQL 인젝션 가능 쿼리, XSS 취약점
3. **빌드 깨짐**: 제안된 코드가 tsc를 통과하지 못할 것이 명백
4. **데이터 손실 위험**: 마이그레이션에 DROP TABLE/COLUMN 포함 (백업 없이)
5. **아키텍처 위반**: engine/ public API(agent-loop.ts + types.ts) 외 파일 직접 참조

---

## 적용 범위

이 루브릭은 다음 파이프라인에서 사용:
- `/kdh-plan` — planning mode의 모든 Stage (Stage 0~8)
- `/kdh-review` — Sprint 스토리 리뷰 (D1-D6 강제 템플릿, 가중 평균 필수)
- `/kdh-code-review-full-auto` — 3-Critic Party의 모든 리뷰
- `/kdh-full-auto-pipeline` (legacy) — planning mode의 모든 Step

Sources:
- [Rubric Is All You Need (ACM 2025)](https://dl.acm.org/doi/10.1145/3702652.3744220)
- [LLM-As-Judge Best Practices](https://www.montecarlodata.com/blog-llm-as-judge/)
- [Anthropic: Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- [AI Code Review Predictions 2026](https://www.qodo.ai/blog/5-ai-code-review-pattern-predictions-in-2026/)
- [Architecture Assessment (CMU)](https://www.cs.cmu.edu/~pmerson/docs/ArchitectureAssessment-PauloMerson.pdf)
- [Code Quality Rubric Design](https://www.stgm.nl/quality/stegeman-quality-2016.pdf)
