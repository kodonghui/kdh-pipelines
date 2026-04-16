# Critic Scoring Rubric v2.0 (BARS — 8 dimensions × 5 levels)

> Critics는 이 루브릭에 따라 **차원별 점수**를 매기고, 평균을 최종 점수로 제출.
> 3.0/5 미만 = 재작성. 3.0+ = 통과. 차원별 1점이 하나라도 있으면 = 자동 불합격.

---

## 채점 스케일 (1-5 Likert)

| 점수 | 등급 | 의미 |
|------|------|------|
| 5 | Exceptional | 모범적, 추가 개선 여지 거의 없음 |
| 4 | Strong | 의식적 디자인, 작은 nit만 |
| 3 | Acceptable | 작동, 개선 여지 있음 |
| 2 | Weak | 대수정 권고 |
| 1 | Defect | 즉시 수정 필요 |

★ Score=3 부여 시 "왜 4가 아닌가" written justification 의무

---

## Per-Dimension Output Format (강제)

```
D{N} {Dimension Name}: {1-5}/5
Evidence: [file:line — quoted code or pattern]
Score match: [why this level — cite which BARS anchor matches]
Not next level: [why not N+1 — what's missing for upgrade]
```

3 슬롯 모두 필수. 주관 묘사 금지. UNCITED 표시 허용 (단 점수 ≤2로 강제).

---

## 8개 채점 차원

### D1: YAGNI / 미니멀리즘

**Scope:** Added but unused/unreached code only. dead branches, unused exports, speculative params, abstractions with single call site. **D7과 boundary**: D1=죽은 코드, D7=살아있는 코드의 가독성/모듈성.

| Score | BARS Anchor |
|-------|-------------|
| 1 | 3개 이상 unused export + dead conditional branch + abstract factory with 1 impl. 또는 새 컴포넌트 정의했는데 어디서도 mount 안 됨 |
| 2 | 1-2개 speculative param 추가 ("for future"), 또는 미래 기능 위한 enum variant 정의됐는데 미사용 |
| 3 | Mostly used, 1개 minor speculative element with 명시적 주석 (e.g. "deferred to next story") |
| 4 | 모든 added symbol이 same diff에서 referenced, no premature generics, abstraction은 ≥2 call site 보유 |
| 5 | Minimal viable code, 추가하면서 unused가 된 기존 코드도 같이 삭제 |

### D2: State / Data model 설계

**Scope:** Source of truth, redundancy, derived state, invariants, schema↔runtime alignment. **D4와 boundary**: D2=데이터 shape, D4=타입 시스템 사용.

| Score | BARS Anchor |
|-------|-------------|
| 1 | Multiple sources of truth (예: parallel boolean+enum 같은 의미), derived state 따로 저장, 수동 sync 필수 |
| 2 | 1개 redundant state field, 둘 manually sync |
| 3 | Mostly normalized, 1-2개 derived-state-as-stored, but invariant 명시 |
| 4 | Single source of truth, derived는 use site에서 compute, immutable defaults, schema↔runtime 일치 |
| 5 | Impossible-state-by-design (discriminated union으로 invalid 조합 차단), exhaustive state machine |

### D3: 주석 품질 (WHY vs WHAT/story-ID)

**Scope:** WHY (motivation, constraint, runtime reason, gotcha) durable / WHAT or story-ID ephemeral. Story-ID regex: `[A-Z]+\-?\d+`, `#\d+`, `MF-`, `Phase [A-Z]`.

| Score | BARS Anchor |
|-------|-------------|
| 1 | Story-ID/ticket reference dominant (5+ occurrences in diff), zero motivation comments |
| 2 | Mix WHY+story-ID, story-ID slightly more (3-5건) |
| 3 | WHY 일부 + story-ID 일부 (2-3건). main concept 정도는 설명 |
| 4 | Mostly WHY (constraint, runtime reason). 1-2개 story tag만 traceability 용도 |
| 5 | All meaningful comments explain WHY. zero ephemeral references. silent code도 self-documenting |

### D4: Type Safety

**Scope:** null handling, type assertions, contract discipline, end-to-end integrity, escape hatches.

| Score | BARS Anchor |
|-------|-------------|
| 1 | 다수 `as any` cast, nullable path unchecked, broken contract, `@ts-ignore` 무근거 |
| 2 | 1-2개 avoidable `any`/cast, partial null guard, 1개 escape hatch without comment |
| 3 | Types 대체로 정확, 1개 minor escape hatch with comment, narrowing 일부 누락 |
| 4 | End-to-end typing, explicit narrowing, no `any` without justification, contract import-only |
| 5 | Impossible state encoded out (discriminated union), exhaustive switch with `never` check, contract 강제 across boundary |

### D5: Security / API Surface 규율

**Scope:** Field whitelisting, info leak risk, attack surface, validation at edge. UI에서도 적용: input sanitization, XSS, CSRF.

| Score | BARS Anchor |
|-------|-------------|
| 1 | User object passthrough (DB row 통째 노출), no input validation at edge, sensitive field 응답 포함 |
| 2 | Partial whitelist, 1-2 fields could leak, input validation 누락 |
| 3 | Most fields whitelisted, validation 일부 inconsistent |
| 4 | Explicit field whitelisting, input validation at edge (zod schema), no sensitive passthrough |
| 5 | Tight API surface, schema-validated at all edges, audit-ready, principle of least privilege |

### D6: A11y (UI only — N/A for backend)

**Scope:** WAI-ARIA, semantic markup, keyboard navigation, focus management, screen reader.

| Score | BARS Anchor |
|-------|-------------|
| 1 | No semantic markup, missing role/aria-live, keyboard-trap risk, focus 사라짐 |
| 2 | Some semantic tags but role/aria-live missing for status updates, focus management partial |
| 3 | Basic a11y (alt, semantic HTML), interactive states 일부 unclear, keyboard support 일부 |
| 4 | role/aria-live correctly used, keyboard nav works, focus management explicit |
| 5 | WCAG-AA-aligned: reduced-motion respected, full keyboard support, focus restore on dismiss, labels/roles/states 완비 |

### D7: 유지보수성 / 6-month future readability

**Scope:** Readability + modifiability + modularity, reusability, analyzability, testability. **D1과 boundary**: D7=살아있는 코드의 구조, D1=죽은 코드 존재.

| Score | BARS Anchor |
|-------|-------------|
| 1 | Tightly coupled, no module boundary, deep nesting (≥4 levels), magic numbers, function ≥80 lines |
| 2 | Some modules but 높은 coupling, 1-2 magic numbers, function 50-80 lines |
| 3 | Reasonable module split, few magic numbers, function 30-50 lines, occasional deep nesting |
| 4 | Clear modularity, named constants, shallow nesting (≤3), function ≤30 lines, easy to test |
| 5 | Clean module boundaries, seams for substitution/testing 명시, functionality split by responsibility |

### D8: Correctness / Async / Error 규율

**Scope:** Floating promises, awaited/catch, exhaustiveness, error propagation, race conditions, error type discipline.

| Score | BARS Anchor |
|-------|-------------|
| 1 | Floating promises, thrown strings 대신 Error 객체, swallowed catch, race condition obvious |
| 2 | 1-2 floating promises 또는 thrown string, error handling partial, 1 race risk |
| 3 | Async mostly correct, error envelope partial, 1 race acknowledged |
| 4 | All promises awaited or `.catch()`d, structured error types, error propagation explicit, effect cleanup 정확 |
| 5 | Discriminated error union, exhaustive handling with `never`, race impossible by design, observability hooks |

---

## 채점 출력 형식

```markdown
## Critic-{X} Review — {Step/Story Name}

### 차원별 점수
| 차원 | 점수 | Evidence | Score match | Not next level |
|------|------|----------|-------------|----------------|
| D1 YAGNI | 4/5 | file:line — ... | anchor 4 일치: ... | 기존 unused 미삭제 → 5 미달 |
| D2 State | 3/5 | ... | ... | ... |
| ... | ... | ... | ... | ... |

### 평균: {X.XX}/5 {✅ PASS / ❌ FAIL}

### 이슈 목록 (score ≤3 차원만)
1. **[D2 State]** redundant field X — 근거: ...
2. **[D8 Async]** floating promise in Y — 근거: ...
```

---

## 통과/불합격 기준

| 기준 | 값 |
|------|-----|
| PASS | 평균 ≥ 3.0/5 |
| Grade A (1-cycle 예외 가능) | 평균 ≥ 4.0/5 |
| 자동 불합격 | 어떤 차원이든 1점 |
| D6 A11y | 백엔드 라운드는 N/A 처리 (7 dims로 평균) |

---

## 자동 불합격 조건 (Override Rules)

아래 중 하나라도 해당되면 점수와 관계없이 **즉시 불합격**:

1. **할루시네이션**: 존재하지 않는 API/파일/함수를 참조
2. **보안 구멍**: 하드코딩된 시크릿, SQL 인젝션 가능 쿼리, XSS 취약점
3. **빌드 깨짐**: 제안된 코드가 tsc를 통과하지 못할 것이 명백
4. **데이터 손실 위험**: 마이그레이션에 DROP TABLE/COLUMN 포함 (백업 없이)
5. **아키텍처 위반**: engine/ public API 외 파일 직접 참조

---

## 적용 범위

이 루브릭은 다음 파이프라인에서 사용:
- `/kdh-plan` — planning mode의 모든 Stage
- `/kdh-dev-pipeline` — Phase B/D Party Mode 리뷰
- `/kdh-bug-fix-pipeline` — bug-fix Party Mode 리뷰
- Party Mode 전체 — 모든 critic agent 공통

Sources:
- Smith & Kendall (1963) — BARS 원론
- RULERS (arxiv 2601.08654) — LLM-as-judge BARS 적용
- 0415-rubric-code-quality-comparison-v1.md — KDH 5-round evaluation 결과
