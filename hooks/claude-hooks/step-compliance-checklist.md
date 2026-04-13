# Step Compliance Checklist — 매 스텝 시작 전 반드시 확인

오케스트레이터는 각 스텝 시작 전 이 파일을 Read tool로 읽고 모든 항목을 확인한다.

## Pre-Step (스텝 시작 전)
- [ ] 해당 Stage의 BMAD step file을 Read tool로 읽었는가?
- [ ] Party Mode Protocol 섹션을 기억이 아닌 파일에서 확인했는가?
- [ ] 해당 Grade (A/B/C) 규칙을 확인했는가?
- [ ] TeamCreate로 팀을 생성했는가?

## Party Mode (Grade A/B만)
- [ ] Writer가 step file을 Read tool로 읽고 작성했는가?
- [ ] Writer가 SendMessage [Review Request]를 critic 실명으로 보냈는가?
- [ ] Critics가 party-logs/{naming-standard}.md에 파일로 저장했는가?
- [ ] Cross-talk: 고정 쌍으로 토론했는가? (winston↔quinn, quinn↔john, john↔winston)
- [ ] Cross-talk 섹션이 각 critic 로그에 3줄 이상 존재하는가?
- [ ] Writer가 fixes.md를 작성했는가?
- [ ] Critics가 재검증(re-verify) + D1-D6 점수를 부여했는가?
- [ ] 점수 분산(stdev) ≥ 0.5인가? (아니면 독립 재채점)

## Grade A 추가
- [ ] 최소 2사이클 실행했는가?
- [ ] Cycle 2에서 Devil's Advocate가 ≥3개 이슈를 찾았는가?
- [ ] 평균 ≥ 8.0/10인가?

## UI Story 추가 (Sprint)
- [ ] has_ui: true인가?
- [ ] 오케스트레이터가 Subframe MCP design_page를 실행했는가?
- [ ] subframe-design.md 로그를 작성했는가?
- [ ] dev에게 "비즈니스 로직만 추가" 지시했는가? (UI 레이아웃은 이미 작성됨)

## Phase B 완료 후 (★ 매번 빠지는 항목)
- [ ] Phase B compliance YAML 생성했는가? (`story-X-X-phase-b.yaml`)
- [ ] Context snapshot 생성했는가? (`story-X-X-phase-b.md`)
- [ ] dev 에이전트 shutdown 전에 위 2개 파일 존재 확인했는가?

## Post-Step (스텝 완료 후)
- [ ] Context snapshot 저장했는가?
- [ ] Compliance YAML 작성했는가? (Phase A, B, D, F, Codex — 빠짐없이)
- [ ] pipeline-state.yaml 업데이트했는가?
- [ ] 완료된 critic들을 즉시 shutdown했는가?

## Cross-talk 규칙 (★ 형식적 작성 금지)
- [ ] Step 1: 각 critic이 독립 리뷰 완료 → 파일 저장
- [ ] Step 2: 각 critic에게 "다른 2명의 리뷰 파일을 Read tool로 읽고 Cross-talk 작성하라" 지시
- [ ] Cross-talk에 상대방 리뷰의 구체적 내용 인용이 있는가?
- [ ] "If X raises..." 조건부 형태가 아닌가?

## 점수 규칙 (★ 자기 합리화 금지)
- [ ] avg ≥ 8.0인가? (미만이면 FAIL — Cycle 2 필수)
- [ ] CONDITIONAL_PASS 사용하지 않았는가? (금지됨)
- [ ] compliance YAML의 grade가 실제 점수와 일치하는가?

## Phase D Layer 2 (★ v10.6 mock만 금지)
- [ ] integration test가 1개 이상 있는가? (실제 HTTP 요청, mock 아님)
- [ ] compliance YAML에 integration_tests_count ≥ 1인가?
- [ ] mock만 있으면 Phase D FAIL

## Phase E 완료 후 (★ v10.6 브라우저 검증 필수)
- [ ] Playwright E2E 실행했는가? (bunx playwright test)
- [ ] 해당 스토리 AC를 브라우저에서 전부 확인했는가?
- [ ] 스크린샷이 _bmad-output/e2e-screenshots/story-{id}/에 저장됐는가?
- [ ] E2E FAIL이면 Phase B 수정 → Phase D 재실행 → Phase E 재실행했는가?
- [ ] Dev 서버 정상 종료했는가?
