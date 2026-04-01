---
name: kdh-ecc-12h
description: "12시간 학습+진화 — learn-eval + evolve + skill-health + context-budget. instinct를 스킬로 진화시키는 핵심 루틴."
tags: [learning, evolution, maintenance]
---

# KDH ECC 12시간 학습+진화

12시간마다 실행. ECC의 핵심: instinct → 스킬 자동 진화.

비유: 일기를 쓰고(learn), 반복되는 패턴을 정리해서 매뉴얼로 만들고(evolve), 기존 매뉴얼이 잘 쓰이는지 체크(health).

## 실행 흐름 (총 ~5분)

### Phase 1: Learn-Eval (패턴 추출 + 평가)

1. 최근 세션 기록 스캔
2. 교정사항(유저가 고친 것), 결정사항, 반복 패턴 추출
3. instinct로 저장 (confidence 0.3~0.9)
4. 품질 자가평가: 진짜 유용한 패턴인지 판단
5. Global vs Project 스코프 결정

### Phase 2: Evolve (진화)

1. instinct-status로 현재 목록 확인
2. confidence 0.7+ instinct 클러스터링
3. 관련 instinct 묶어서 → 스킬/커맨드/에이전트 후보 생성
4. 생성된 후보 리뷰 → 채택 or 보류

### Phase 3: Skill Health (건강 체크)

1. 모든 스킬 성공률 트렌드 분석
2. 하락하는 스킬 경고
3. 미사용 스킬 식별
4. sparkline 대시보드 출력

### Phase 4: Context Budget (컨텍스트 분석)

1. 에이전트/스킬/MCP/규칙별 토큰 소비 분석
2. 불필요하게 큰 컴포넌트 식별
3. 최적화 제안

## Report

```
[KDH-ECC-12H] Learn: N instincts (P:N G:N) | Evolve: N candidates | Health: N/N OK | Budget: Nk tokens
```
