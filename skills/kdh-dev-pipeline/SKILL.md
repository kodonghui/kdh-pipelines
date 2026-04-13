---
name: 'kdh-dev-pipeline'
description: 'Dev Pipeline v12 — Sprint 실행 (Story Loop + Party Mode + Integration + E2E + Codex). 경량화: 참조 docs/ + 스킬 분리. 사장님 명령어: /kdh-dev-pipeline [sprint N|story-ID|계속|parallel ID1 ID2]'
---

# Dev Pipeline v12 (경량화)

> v12 변경: Phase 2 리팩터링. 1,213줄 → ~200줄. 참조 문서/스킬 분리.
> 분리된 스킬: /kdh-party-mode, /kdh-integration, /kdh-swarm, /kdh-ui-verify, /kdh-project-scan
> 분리된 문서: docs/ (agent-roster, model-strategy, directory-convention, ui-component-workflow, dev-writer-template, timeouts, output-paths)

<HARD-GATE>
1. 계속 모드 = 절차 100% 동일 — GATE만 자동 통과. 나머지 생략/축약 금지
2. haiku 절대 금지 — opus(Grade A) 또는 sonnet(Grade B/C)
3. Cross-model 둘 다 FAIL = 자동 진행 금지 — 수정 후 재실행, PASS까지 반복
4. UI STORY GATE — CEO 디자인 승인 없이 UI 구현 금지
5. GATE = 사용자 무한 대기 — 자동 통과 금지 (계속 모드 제외)
6. 모든 읽기 FROM FILE — Read tool 사용, message memory 금지
7. Contract types = 단일 진실 — import only, inline 금지. 변경 시 contract FIRST → tsc
8. 에이전트 재사용 금지 (Rule 43) — Story 간 Shutdown ALL → TeamDelete → fresh team
9. FAIL 재리뷰 = fresh agent (Rule 44) — 기존 critic에 "다시 봐라" SendMessage 금지
10. Phase B party-log 필수 (Rule 45) — Phase D 진입 전 winston+quinn 로그 존재 필수
11. mock-only Phase D = FAIL (Rule 38) — 최소 1개 integration test (실제 HTTP)
12. Sprint End = /kdh-bug-fix-pipeline 필수 (Rule 40) — 0 bugs 아니면 다음 Sprint 금지
13. Parallel 계약 충돌 시 sequential 강제 — contract types 동시 수정 금지
14. D1-D6 루브릭 필수 — critic-rubric.md 기준. dim <3 = auto-fail. Grade A ≥8.0, Grade B ≥7.5
15. Writer NEVER calls Skill tool — Read tool로 step/checklist 파일 직접 읽기
16. pipeline-state.yaml 멀티라인 필수 — 인라인 YAML {key: value} 금지
17. Agent spawn 시 kdh-build rules verbatim 포함 — 요약 금지, 전문 embed
</HARD-GATE>

## Red Flags

| Claude가 이렇게 생각하면 | 실제로는 |
|----------------------|---------|
| "이건 간단해서 파이프라인 안 써도 돼" | 간단한 것도 파이프라인 필수. 훅이 강제 |
| "파티모드 스킵해도 될 것 같은데" | 동희님한테 물어봐. 넌 결정 못 해 |
| "테스트는 구현 다 하고 나중에" | TDD. 테스트 먼저 |
| "이미 비슷한 코드를 알고 있어" | gh search부터. research-guard 훅이 차단 |
| "빨리 커밋하고 넘어가자" | compliance-checker 훅이 party-log 확인 |
| "이 파일만 살짝 고치면 되는데" | gateguard 훅이 조사 먼저 시킴 |
| "계속이니까 빨리빨리" | 속도는 병렬화로만. 절차 생략 = HARD-GATE 위반 |
| "Codex 한번 FAIL이니 넘어가자" | 둘 다 FAIL = 자동 진행 금지. 수정 후 재실행 |
| "Phase B 리뷰 없이 Phase D로" | Rule 45. party-log 없으면 pre-commit hook 차단 |
| "Skill tool로 한번에 하면 빠름" | NEVER. Read tool로 step 파일 직접 읽기 |
| "대충 써도 의미 통하잖아" | Output 구체적 필수. 파일 경로, hex, 정확한 값. vague = FAIL |

## Mode Selection

- **`sprint N`**: Sprint N 실행 — 스토리 루프
- **`계속`**: 밤새 모드 — GATE 자동 통과, 3 stories/session 저장 (멈추지 않음)
- **Story ID** (e.g. `3-1`): 단일 스토리 개발
- **`parallel ID1 ID2 ...`**: Git Worktree 병렬 (max 3). 참조: /kdh-parallel

### `계속` 모드

GATE만 자동 통과([AUTO]). 나머지 Phase A→B→D→Codex, Party Mode, TeamCreate/Delete, tsc, bun test, context-snapshot **전부 동일**.
3 stories마다 save-session 자동 저장 후 즉시 계속 (CEO 확인 없이).
Codex+Gemini FAIL은 자동 진행 **금지**.

### Ralph Loop
```bash
while true; do claude -p "/kdh-dev-pipeline 계속"; sleep 5; done
```

### 보고 형식
시작: "Sprint {N} 이어서 합니다. 스토리 {M}개 남았어요."
스토리: "스토리 {id} 완료. 리뷰 평균: {X.X}/10. ({N}/{M} 진행)"
Sprint: "Sprint {N} 끝! 브라우저에서 확인해주세요."

---

## Step -1: Tool Readiness → Step 0: /kdh-project-scan → Step 0.5: Active Plans

Step -1: Codex CLI + 인증 + Gemini CLI + Helper script + UI design system + design-refs 검증. 🚩 1개라도 FAIL → 즉시 중지.
Step 0: /kdh-project-scan → project-context.yaml 캐시.
Step 0.5: _index.yaml에서 pipeline:"dev" or "all" + scope 매칭 plan 읽기.

---

## Story Dev Pipeline (4 Phase)

OLD: 7 phases. NEW: **4 phases (A→B→D→Codex)**. Browser E2E → Sprint End bug-fix.

### ★ 자동 스킬 로드 (분리된 스킬 — 반드시 Read)

<HARD-GATE>
오케스트레이터는 파이프라인 시작 시 Read tool로 반드시 읽어라:
1. Party Mode: Read ~/.claude/skills/kdh-party-mode/SKILL.md
2. Integration (Sprint End 전): Read ~/.claude/skills/kdh-integration/SKILL.md
3. UI 변경 감지 시: Read ~/.claude/skills/kdh-ui-verify/SKILL.md
읽지 않고 해당 절차 실행 = 규칙 위반.
</HARD-GATE>

### Orchestrator Flow

```
Step 0: /kdh-project-scan → project-context.yaml
Step 0.1: ★ Read ~/.claude/skills/kdh-party-mode/SKILL.md (Party Mode 규칙 로드)
Step 1: TeamCreate("{project}-story-{id}")
Step 2: Spawn: dev(Writer), winston, quinn, john (4 agents)
Step 3: Phase A → B → D → Codex (Party Mode는 Step 0.1에서 읽은 규칙대로)
  - Phase 간: context-snapshot 저장, team 유지
  - Phase D: quinn=Writer, dev+winston=Critics (역할 전환)
Step 4: bun test + tsc → Completion Checklist → commit + push
Step 5: Shutdown ALL → TeamDelete → sprint status 업데이트
```

### Phase A: Create Story

```
Team: dev(Writer) + winston, quinn, john (Critics)
Ref: _bmad/bmm/workflows/4-implementation/create-story/checklist.md

1. dev reads story requirements + checklist + template
2. dev writes story file
3. Party mode → winston(arch), quinn(testability+UI존재체크), john(product)
   > 리뷰 수용 규칙: /kdh-party-mode → "6단계 수용 프로세스" 참조
   > EARS(Requirements) + Gherkin(AC) 양립. quinn이 1:1 매핑 검증
   > UI Existence Check: quinn이 UI 참조 → 정의 여부 확인 → 없으면 auto-FAIL
4. Fix → PASS (avg >= 7) → context-snapshot 저장
```

### Phase B: Develop Story

```
Team: dev(Writer) + winston, quinn, john (Critics). UI: +sally
Ref: _bmad/bmm/workflows/4-implementation/dev-story/checklist.md

1. dev reads story + contracts (shared/src/contracts/ → import, NEVER inline)
   1b. ★ Reference Code Search 필수: gh search repos/code + npm 검색
       → party-log "## Reference Code" 섹션에 채택/기각 사유 기록
       → 검색 0건이어도 기록 ("searched: {query}, result: none")
   1c. UI Story → UI Design Gate: 오케스트레이터가 레이아웃 작성 → [GATE page-design] → CEO 승인
2. dev implements REAL working code (no stubs/mocks)
   > UI: theme from themes.ts, layout from ui-design.md
3. Party mode → winston(arch+contract), quinn(quality), john(AC), sally(UI only)
   > Critics MUST write to FILE: party-logs/story-{id}-phase-b-{name}.md (v4.4)
   > 리뷰 수용 규칙: /kdh-party-mode 참조
4. Fix → PASS → context-snapshot 저장
```

### Phase D: Test + QA

```
Team: quinn(Writer) + dev, winston, john (Critics). UI: +sally
★ 역할 전환: quinn이 Writer. 이전 Phase와 다른 관점.

1. quinn designs test strategy (EARS-Driven Scaffolding):
   - THE SYSTEM SHALL → unit test
   - WHEN [trigger] → integration test
   - IF [bad] → negative test
   - WHERE [feature] → conditional test
2. quinn writes tests (unit + integration + E2E)
   ★ 최소 1개 integration test with 실제 HTTP (mock-only = FAIL)
3. quinn runs QA checklist + verifies ALL AC
4. Party mode → dev(implementability), winston(arch coverage), john(AC met?)
   > Critics MUST write to FILE: party-logs/story-{id}-phase-d-{name}.md
5. Fix → PASS → run all tests → context-snapshot 저장
```

### Cross-Model Verification (Codex + Gemini)

```
Phase D PASS 후. 오케스트레이터 직접 실행 (에이전트 불필요).
codex-review.sh → Codex(GPT-5.4) + Gemini(3.1 Pro) 병렬.
Gemini: 3 스토리마다 1회 + Sprint End 전수.

판정:
- 둘 다 PASS → commit
- 둘 다 FAIL → 자동 진행 금지. 수정 → 재실행 (PASS까지 반복, 횟수 제한 없음)
- 하나만 FAIL + 치명 → CEO 판단
- context-irrelevant → 사유 기록 후 스킵 OK
```

### Phase Transitions + Completion

Codex PASS → bun test → tsc(cross-package) → contract compliance → Checklist 전부 [x] → commit+push → Shutdown → TeamDelete.
Checklist: Phase A+B+D PASS, Cross-Model PASS, bun test, tsc, contracts imported, real code(no stubs), compliance YAML 기록.

---

### Sprint End

```
1. bun test 전체 + tsc 전 패키지
2. ★ Read ~/.claude/skills/kdh-integration/SKILL.md → Level 2 Batch + Level 3 Sprint Integration 실행
3. Codex 일괄 리뷰 (Sprint 전체 diff)
4. ★ /kdh-bug-fix-pipeline 필수: Playwright + browser-use 전수 → 0 bugs까지
5. 5개 테마 스크린샷 (bug-fix 파이프라인이 관리)
6. CEO GATE #19: "Sprint N 끝! 브라우저에서 확인해주세요."
   → CEO "OK" → 다음 Sprint
   → CEO "이상해" → /kdh-bug-fix-pipeline 재실행
```

### Mode C: Parallel

`/kdh-dev-pipeline parallel 9-1 9-2 9-3` (max 3). Git Worktree 병렬.
독립 스토리만 (cross-dependency 없는 것). 공유 파일 → ESCALATE.
Contract 충돌 → sequential merge + tsc. Wiring Story → 같은 batch 필수.

---

## 참조 링크

| 참조 | 위치 |
|------|------|
| Party Mode Protocol | /kdh-party-mode (Sprint Dev = per-step v10.3) |
| Integration Review | /kdh-integration (Level 2 Batch + Level 3 Sprint) |
| Swarm Auto-Epic | /kdh-swarm (Mode D) |
| UI Verification | /kdh-ui-verify (Full Interaction E2E) |
| Project Scan | /kdh-project-scan |
| Agent Roster | docs/agent-roster.md |
| Model Strategy | docs/model-strategy.md |
| Directory Convention | docs/directory-convention.md |
| UI Component Workflow | docs/ui-component-workflow.md |
| Writer Template | docs/dev-writer-template.md |
| Timeouts | docs/timeouts.md |
| Output Paths | docs/output-paths.md |
| Pipeline Protocol | docs/pipeline-protocol.md |
| 리뷰 수용 규칙 | /kdh-party-mode → "6단계 수용 프로세스" |

## 훅 커버리지 메모

다음 규칙은 Phase 1 훅이 자동 강제:
- research-guard: gh search 안 하면 Edit/Write 차단
- gateguard: 첫 수정 전 조사 강제 (3단계)
- compliance-checker: 커밋 전 party-log 확인 + main push 차단
- block-no-verify: --no-verify 차단
- safety-guard: rm -rf, push --force 차단
- config-protection: 설정 파일 수정 경고
- quality-gate: Edit 후 타입 체크/린트 (async)
- verification-check: 증거 없이 완료 선언 차단
- loop-detector: 같은 파일 5번+ 수정 경고
