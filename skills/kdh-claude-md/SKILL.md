---
name: kdh-claude-md
description: CLAUDE.md 완전성 감사 + 정규화 + 강제 매핑. "CLAUDE.md 점검해줘", "규칙 빠진 거 없나", "CLAUDE.md 정리" 등.
disable-model-invocation: true
---

# /kdh-claude-md v2 — CLAUDE.md 감사+보호 도구

## 핵심 철학

> CLAUDE.md는 프로젝트의 **헌법**이다. 빠지면 사고, 넘치면 무시.
> 섹션별 예산 관리 + 200줄 상한(커뮤니티 관행). **핵심 규칙 누락 0**이 목표.
> "축소"가 아니라 "정규화" — 정리하고, 이관하고, 강제 계층을 올린다.

## 근거

| 사실 | 출처 |
|------|------|
| CLAUDE.md는 매 세션 시작 시 전체 로드 | Anthropic 공식 (code.claude.com) |
| CLAUDE.md 지시는 advisory (판단에 따라 무시 가능) | Anthropic 공식 |
| Hooks는 deterministic (exit 2면 100% 차단) | Anthropic 공식 |
| `.claude/rules/` (paths 있음)만 on-demand | Anthropic 공식 |
| Skills는 메타데이터만 로드, 본문은 호출 시만 | Anthropic 공식 |
| 200줄 넘으면 규칙 무시 증가 | 커뮤니티 관행 (Anthropic은 "간결하게" 권장) |

## 실행 모드

### 모드 1: Audit (4축 감사) — `$ARGUMENTS` 없음 또는 "audit"

CLAUDE.md + .claude/rules/ + hooks + skills를 **4축**으로 감사한다.

**축 1 — 완전성:** 핵심 규칙 ID(아래 테이블) 중 빠진 것이 있는가?
- CLAUDE.md, .claude/rules/, hooks(settings.json)를 순회
- 핵심 규칙 ID 테이블과 대조. 누락 = 위험 표시

**축 2 — 중복:** 같은 규칙이 여러 곳에 있는가?
- CLAUDE.md와 .claude/rules/ 사이 키워드 중복 탐지
- CLAUDE.md와 hooks 사이 동일 규칙 중복 탐지
- 중복 = 정규화 대상 (Normalize에서 처리)

**축 3 — 충돌:** 규칙끼리 모순되는가?
- 규칙 쌍을 비교하여 논리적 충돌 탐지
- 예: "자동 커밋" vs "승인 후 커밋"
- 충돌 = CEO에게 보고, 해결 요청

**축 4 — 강제 가능성:** 이 규칙은 Hook으로 강제 가능한가?
- advisory인 규칙 중 객관적으로 판정 가능한 것 식별
- "Hook 승격 추천" 표시. 실행은 Normalize에서.

출력:
```
## CLAUDE.md 4축 감사 보고

| 규칙 ID | 규칙 | 축1 완전성 | 축2 중복 | 축3 충돌 | 축4 강제 | 현재 위치 |
|---------|------|----------|---------|---------|---------|----------|

줄 수: {N}줄 (100줄 주의 / 200줄 경고)
섹션별: {각 ## 섹션 줄 수}
핵심 규칙 누락: {N}개
중복: {N}개
충돌: {N}개
Hook 승격 추천: {N}개
```

### 모드 2: Normalize (정규화) — `$ARGUMENTS`가 "normalize"

Audit 결과를 바탕으로 **4가지 정규화 행동**을 제안한다.
이 모드는 제안만 출력하고, 실제 파일 수정은 하지 않는다. CEO 승인 후 별도 실행.

1. **죽은 규칙 제거** — 더 이상 해당 안 되는 규칙 (예: 삭제된 도구 참조)
2. **변동 규칙 이관** — 자주 바뀌는 내용(경로, 버전) → `.claude/rules/`로 이동 제안
3. **Hook 승격** — Audit 축4에서 "Hook 가능"으로 판정된 규칙 → Hook 설정 제안
4. **빠진 규칙 추가** — Audit 축1에서 누락된 핵심 규칙 → 추가 위치 제안

출력:
```
## Normalize 제안

| # | 행동 | 대상 규칙 | 현재 위치 | 제안 위치 | 이유 |
|---|------|----------|----------|----------|------|

★ CEO 승인 없이 삭제/이관 금지
★ 200줄 초과 시에만 축소를 적극 제안
```

### 모드 3: Health Check (건강검진) — `$ARGUMENTS`가 "check"

**Rule-to-Enforcement Matrix** 출력:

```
## Rule-to-Enforcement Matrix

| 규칙 ID | 규칙 | CLAUDE.md | rules/ | Hook(git) | Hook(Claude) | CI/Test | 강제 없음 |
|---------|------|-----------|--------|-----------|-------------|---------|----------|

★ "강제 없음" = advisory only → 위험 표시 (붉은 줄)
★ 줄 수: {N}줄 — 100줄=주의, 200줄=경고
★ 섹션별 예산: 각 ## 섹션의 줄 수 + 전체 비율
★ 핵심 규칙 10개 중 Hook 강제: {N}/10
```

## 핵심 규칙 ID (CORTHEX v3)

| ID | 규칙 | 기대 강제 계층 |
|----|------|-------------|
| CR-01 | 파이프라인 외 코드 수정 금지 | Hook (pre-commit) |
| CR-02 | Party Mode 2명 필수 | Hook (pre-commit) |
| CR-03 | Codex 스토리당 1회 필수 | Hook (pre-commit) |
| CR-04 | tsc 필수 | Hook (pre-commit) |
| CR-05 | CLAUDE.md 변경 차단 | Hook (pre-commit v4.2) |
| CR-06 | 한국어 존댓말 | CLAUDE.md (advisory) |
| CR-07 | haiku 모델 금지 | CLAUDE.md (advisory) |
| CR-08 | stub/mock 금지 | CLAUDE.md (advisory) |
| CR-09 | 에이전트 재사용 금지 | .claude/rules/ |
| CR-10 | plan 보고 필수 | CLAUDE.md (advisory) |

Audit 축1이 이 테이블을 대조한다. 10개는 초기 목록이며 CEO 승인으로 추가/변경.

## 4계층 라우팅 결정

| 판단 기준 | 결과 |
|----------|------|
| Linter/CI가 처리 가능? | Linter에 위임 |
| 객관적으로 판정 가능? | Hook (deterministic) |
| 특정 파일에만 해당? | .claude/rules/ (paths) |
| 반복 워크플로우? | Skill (on-demand) |
| Claude가 추측 못하는 핵심? | CLAUDE.md (advisory, 항상 로드) |

## 주의사항

- 이 스킬의 목적은 **"축소"가 아니라 "정규화"**. 정리+이관+승격.
- 이 스킬은 CLAUDE.md를 직접 수정하지 않음. 보고서만 생성.
- CEO override: Hook이 차단해도 CEO가 직접 승인하면 수정 가능.
- `@import`는 토큰 절약이 아님 (인라인 확장됨). 파일 정리용으로만 사용.
- "IMPORTANT", "YOU MUST" 등 강조어로 advisory 준수율 향상 가능.
- 크기와 건강은 다르다. 57줄이어도 충돌 규칙 있으면 불건강.
