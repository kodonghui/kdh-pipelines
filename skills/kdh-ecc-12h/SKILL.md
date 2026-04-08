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

### Phase 1.5: Plan Retrospective (계획 회고)

1. _bmad-output/kdh-plans/_index.yaml 읽기
2. status: done인 plan 분석:
   - plan의 예상 시간 vs 실제 소요 시간 (git log으로 추적)
   - plan의 Risk 항목 중 실제 발생한 것
   - plan에서 빠졌던 태스크
3. 패턴 추출 → instinct 후보:
   - "Phase D 보충은 예상보다 빨리 끝남" (confidence 계산)
   - "PoC 스토리는 plan 없이 진행하면 나중에 보충 필요"
4. done plan이 30일 이상 → status: archived 자동 전환

### Phase 1.7: Prune (3h에서 이관)

1. 30일 넘은 미승격 instinct 삭제
2. 빈 메모리 파일 삭제
3. 오래된 세션 파일 정리 (최근 10개만 유지)

Run: `/prune` logic

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

### Phase 3.5: Health Check (3h에서 이관)

1. `~/.claude/metrics/costs.jsonl` 존재 확인
   - 없으면 → SKIP, 로그에 "Health: SKIP (no metrics file)" 기록
   - 있으면 → 세션 비용 누계 요약
2. skill-health: 하락하는 스킬 있으면 경고
3. .last-12h-run 타임스탬프 업데이트

### Phase 4: Context Budget (컨텍스트 분석)

1. 에이전트/스킬/MCP/규칙별 토큰 소비 분석
2. 불필요하게 큰 컴포넌트 식별
3. 최적화 제안

## Report

```
[KDH-ECC-12H] Learn: N instincts | PlanRetro: N analyzed | Evolve: N candidates | Health: N/N OK | Budget: Nk tokens
```
