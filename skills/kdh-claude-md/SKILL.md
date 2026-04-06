---
name: kdh-claude-md
description: CLAUDE.md 감사(audit) 및 리팩토링. CLAUDE.md가 비대해졌거나 규칙 준수율이 떨어질 때 사용. "CLAUDE.md 정리해줘", "CLAUDE.md 최적화" 등.
disable-model-invocation: true
---

# /kdh-claude-md — CLAUDE.md 관리 도구

## 핵심 철학

> CLAUDE.md는 백과사전이 아니라 **지도(Index)**다.
> Claude가 이 지도를 보고 필요한 정보가 어디 있는지 빠르게 찾으면 된다.
> **목표: 35줄 이하. 200줄 절대 초과 금���.**

## 공식 근거 (Anthropic docs, 2026-04 확인)

| 사실 | 출처 |
|------|------|
| CLAUDE.md는 매 세션 시작 시 **전체 로드** | code.claude.com/docs/en/memory |
| 100줄당 ~500-800 토큰 소비 | 커뮤니티 측정 |
| `@import`는 **인라인 확장** — 토큰 절약 아님 | code.claude.com/docs/en/memory |
| `.claude/rules/` (paths 있음)만 **on-demand** | code.claude.com/docs/en/memory |
| Skills는 메타데이터 30-50 토큰, 본문은 **호출 시만** | code.claude.com/docs/en/skills |
| CLAUDE.md 규칙 준수율 ~60%, Hooks 적용 시 90%+ | 커뮤니티 실증 |
| 200줄 넘으면 Claude가 규칙 무시 시작 | Anthropic 공식 best practices |

## 실행 모드

### 모드 1: Audit (감사) — `$ARGUMENTS`가 "audit" 또는 없을 때

CLAUDE.md를 한 줄씩 읽고 아래 기준으로 판정한다:

```
각 줄/섹션마다 2개 질문:
① "이걸 지우면 Claude가 실수할 가능성이 있나?"
② "이건 모든 작업에 해당하나?"

판정 매트릭스:
┌──────────┬──────────┬──────────────────────────┐
│ ① 실수?  │ ② 모든?  │ 판정                      │
├──────────┼──────────┼──────────────────────────┤
│ Yes      │ Yes      │ CLAUDE.md에 유지          │
│ Yes      │ No       │ .claude/rules/ (paths)    │
│ No       │ Yes      │ 삭제 (자명한 내용)         │
│ No       │ No       │ 삭제                      │
└──────────┴──────────┴──────────────────────────┘

추가 라우팅:
- 린터/CI가 처리 가능 → 린터에 맡기기
- 객관적으로 판정 가능 (포맷, 테스트, 금지어) → Hooks
- 반복 워크플로우 → Skills
- LLM 아키텍처 판단 필요 → CLAUDE.md 유지
```

출력 형식:
```
## CLAUDE.md Audit Report

| 줄 | 내용 요약 | ①실수? | ②모든? | 판정 | 이동 경로 |
|-----|----------|--------|--------|------|----------|

현재: {N}줄
판정 후 예상: {M}줄
절약 토큰: ~{X}
```

### 모드 2: Refactor (리팩토링) — `$ARGUMENTS`가 "refactor"일 때

Audit 결과를 바탕으로 실제 파일 수정:

1. 분리할 내용 목록과 이동 경로를 CEO에게 보고
2. CEO 승인 후:
   - `.claude/rules/` 파일 생성 (path-specific이면 paths 프론트매터 포함)
   - Skills 파일 생성 (반복 워크플로우)
   - Hooks 추가 (settings.json)
   - CLAUDE.md 리팩토링
3. 검증:
   - `wc -l CLAUDE.md` 확인
   - 핵심 키워드 누락 체크
   - rules/ 파일 존재 확인

### 모드 3: Health Check (건강검진) — `$ARGUMENTS`가 "check"일 때

빠른 체크만:
```bash
# 1. 줄 수
wc -l CLAUDE.md

# 2. rules/ 파일 목록
ls .claude/rules/

# 3. CLAUDE.md와 rules/ 중복 체크
# 양쪽에 같은 키워드가 있으면 중복 의심

# 4. 결과
echo "CLAUDE.md: {N}줄 (목표: ≤35)"
echo "Rules: {M}개"
echo "중복 의심: {리스트}"
```

## 4계층 분리 기준표

| 계층 | 토큰 비용 | 준수율 | 넣어야 할 것 |
|------|-----------|--------|------------|
| **CLAUDE.md** | 항상 소비 | ~60% | Claude가 추측 못하는 핵심만 (명령어, 아키텍처, 금지사항) |
| **Skills** | 호출 시만 | 호출 시 높음 | 반복 워크플로우, 도메인 지식, 상세 가이드 |
| **Rules (paths)** | 매칭 시만 | ~60% | 특정 파일/디렉토리에만 해당하는 규칙 |
| **Hooks** | 0 토큰 | **90%+** | 객관적으로 판정 가능한 강제 규칙 |

## Anthropic 공식 Include/Exclude 가이드

**포함 (Claude가 추측 불가):**
- Bash 명령어
- 기본값과 다른 코드 스타일
- 테스트 러너/지침
- 브랜치/PR 관례
- 프로젝트 특유 아키텍처
- 환경 특이사항
- 비명백한 gotcha

**제외 (Claude가 이미 알거나 추론 가능):**
- 코드를 읽으면 아는 것
- 표준 언어 관례
- 상세 API 문서 (링크만)
- 자주 변하는 정보
- 긴 설명/튜토리얼
- 파일별 코드베이스 설명
- "깔끔한 코드 작성" 같은 자명한 관행

## 주의사항

- `@import`는 토큰 절약이 아님 (인라인 확장됨). 파일 정리용으로만 사용.
- 진짜 on-demand는 **path-specific rules**와 **Skills**만 가능.
- "IMPORTANT", "YOU MUST" 등 강조어로 준수율 향상 가능.
- CLAUDE.md를 코드처럼 취급 — 정기 리뷰, 가지치기, 변경 시 관찰.
