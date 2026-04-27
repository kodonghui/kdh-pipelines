---
name: kdh-gate-protocol
description: "Business/Technical GATE 분류와 19개 인벤토리."
---

# User Gate Protocol (v10.1)

19 GATE steps, 분류: **Business** (CEO 대기) vs **Technical** (자동 통과 + 기록).
Business GATE = 제품 방향/의미/사용자 경험. Technical GATE = 기술 결정/수치/세부사항.

### Gate Flow

**Business GATE:**
```
1. Writer drafts options (A/B/C format with pros/cons)
2. Writer sends "[GATE] {step_name}" to team-lead (Orchestrator)
3. Orchestrator presents to user (preset gate.language, 기술 용어 금지):
   - Summary of what was written
   - Options with pros/cons
   - Clear question: "어떻게 할까요? A/B/C 또는 수정사항?"
   - Format: 번호 목차 필수 (I. II. III. 또는 1. 2. 3.), 비유/은유 최소화, 직접 설명. Stage 완료 보고도 동일 형식.
4. User responds
5. Orchestrator sends user decision to Writer
6. Writer incorporates decision into document
7. Normal party mode continues
```

**Technical GATE:**
```
1. Writer drafts decision with rationale
2. Critics review and approve/challenge
3. Orchestrator logs decision to party-logs/{stage}-gate-{step}-auto.md
4. Auto-proceed. CEO can review logged decisions at any time.
```

### Gate Inventory

| # | Stage | Step | Type | Question / Auto-decision |
|---|-------|------|------|--------------------------|
| 1 | 0 Brief | vision | **BIZ** | 제품 비전 방향 맞는지? |
| 2 | 0 Brief | users | **BIZ** | 타겟 사용자 우선순위? |
| 3 | 0 Brief | metrics | TECH | 업계 표준 기반 성공 기준 자동 설정 |
| 4 | 0 Brief | scope | **BIZ** | 기능 넣을지/뺄지/수정 |
| 5 | 2 PRD | discovery | TECH | v1→v2 기능 변환은 기술 판단 |
| 6 | 2 PRD | vision | TECH | Brief에서 이미 결정됨, 문구 자동 반영 |
| 7 | 2 PRD | success | TECH | metrics에서 결정됨, 수치 자동 반영 |
| 8 | 2 PRD | journeys | **BIZ** | 사용자 흐름이 사장님 상상과 일치? |
| 9 | 2 PRD | innovation | TECH | 혁신 vs 기본은 아키텍트 판단 |
| 10 | 2 PRD | scoping | **BIZ** | Phase 나누기, 우선순위 결정 |
| 11 | 2 PRD | functional | TECH | scope에서 큰 방향 결정됨, FR 세부는 기술 |
| 12 | 2 PRD | nonfunctional | TECH | NFR 수치는 기술 벤치마크 기반 |
| 13 | 4 Arch | decisions | TECH | 기술 선택은 에이전트 자율 (CLAUDE.md 규칙) |
| 14 | 5 UX | design-system | TECH | 테마 방향은 design-directions에서 결정 |
| 15 | 5 UX | design-directions | **BIZ** | 디자인 시안 선택 |
| 16 | 6 Epics | design-epics | TECH | Epic 스코프는 scope에서 이미 결정됨 |
| 17 | Sprint Zero | theme-select | TECH | 5개 테마 이미 확정됨 (CEO 선정) |
| 18 | Story Dev | page-design | TECH | ui-design.md 기반, Sprint End에서 일괄 확인 |
| 19 | Sprint End | visual-verify | **BIZ** | 브라우저에서 전체 화면 확인 — 최종 관문 |
