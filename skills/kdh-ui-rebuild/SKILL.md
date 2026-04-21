---
name: 'kdh-ui-rebuild'
description: 'UI Rebuild Pipeline — /app 또는 /admin 전면 UI 재빌드 1회성 이벤트 전용. sally Lead Writer + Anthropic 3-Agent 패턴(Planner/Generator/Evaluator) + Anthropic 4 criteria 채점 + Claude Design/Chrome MCP 탐색. 사장님 명령어: /kdh-ui-rebuild [target=app|admin] [계속]'
---

# UI Rebuild Pipeline v1.0

**이 skill은 일반 Sprint 스토리가 아닌, UI 전면 재빌드 1회성 이벤트 전용입니다.**

일반 UI 스토리 → `/kdh-dev-pipeline` (Phase B에서 sally Writer)
UI 버그 수정 → `/kdh-bug-fix-pipeline` (type=ui 시 sally 조건부)
**UI 전면 재빌드 → 이 skill (5 Phase)**


## v2 Claude Design Integration (2026-04-21)

> `/kdh-corthex-design` skill 필수 호출 + 3 테마 + mypqjitg/ndpk SSoT + sally verdict-only. Reference: `_bmad-output/audit/2026-04-21-kdh-skills-claude-design-audit-v2.md`

- **Invoke `/kdh-corthex-design`** before any UI decision — returns brand checklist + tokens + preview paths + `ui_kits/console` pointers.
- **SSoT paths** (replaces `DESIGN.md` content):
  - React pages: `_bmad-output/ui-rebuild/claude-design-generate-result/2026-04-21-mypqjitg/project/reskin-react/src/routes/<Page>.tsx`
  - Design system: `_bmad-output/ui-rebuild/claude-design-generate-result/2026-04-21-ndpk/project/` (`colors_and_type.css` + `preview/` + `ui_kits/console/`)
  - Shared CSS: `packages/ui/src/styles/colors_and_type.css` (import via `@corthex/ui/styles/colors_and_type.css`)
- **3 themes only**: Paper (default light) / Carbon (dark) / Signal (burnt-sienna accent). Selector = `[data-theme="paper|carbon|signal"]` on `<html>`. Retired theme names **forbidden**: `theme-brand` / `theme-green` / `theme-toss-light` / `theme-toss-dark` / `theme-cherry-blossom`.
- **sally role** = verdict verifier only (visual drift vs mypqjitg). Sally authoring (Operator's Atelier / 9-section UX spec) is treated as FAIL → fresh-agent re-review.
- **DESIGN.md** = 26-line stub (CEO SKIPPED restore, 2026-04-21 T1-5). Do not read content; dereference to `/kdh-corthex-design` skill.
- **corthex-design-system artifacts** = CEO-owned. No direct edits by Claude. Use `_bmad-output/design-requests/YYYY-MM-DD-<slug>.md` with ready-to-paste English prompt block (5 sections: Context / Constraint / Ask / Target file / Acceptance).

## 출시 배경 (2026-04-18)

CEO 빡침 → `/app` 하나도 안 예쁘고 안 작동 → 근본 원인 8가지 (0418-report-ui-workflow-redesign.md §III) → 4-Layer 스택 도입 (루트 /DESIGN.md + frontend-design SKILL.md + Claude Design + Claude Code) → 이 skill은 Layer 4(구현)를 "전면 재빌드 이벤트" 모드로 묶음.

근거 문서:
- 0418-research-design-md-convention.md (VoltAgent 9-section 57.9k⭐)
- 0418-research-claude-design-new-release.md (Anthropic Labs Claude Design + frontend-design SKILL.md 119k⭐ + Harness 4 criteria)
- 0418-report-ui-workflow-redesign.md (설계 근간)
- 0418-plan-app-ui-rebuild.md (실행 계획, Codex PASS)

---

## Mode Selection

- **`[target=app]`** (기본): packages/app 재빌드
- **`[target=admin]`**: packages/admin 재빌드
- **`[target=both]`**: 둘 다 (Phase 3에서 순차)
- **`계속`**: 밤새 모드 — **Phase 0-e, 2-d, 4-e CEO GATE는 자동 통과 금지**. 나머지 자동 진행.

### 출력 보고 형식 (preset gate.language, 번호 목차 필수)
```
시작: "/{target} UI 재빌드 시작합니다."
Phase 0: "안전 장치 설정 중. 브랜치 + 백업 + CEO 삭제 승인 대기."
Phase 1: "sally /DESIGN.md 재확인 완료. 9 섹션 모두 현재 반영됨."
Phase 2: "프로토타입 3 옵션 생성. CEO 선택 대기."
Phase 3: "페이지 {n}/{m} 구현 중. sally Planner + dev Generator + quinn Evaluator."
Phase 4: "검증 완료. Anthropic 4 criteria avg X.X/5."
Phase 5: "프로덕션 배포 완료."
```

---

## Step -1: Tool Readiness Check

**파이프라인 시작 전 필수 도구 검증. 하나라도 안 되면 즉시 중지.**

```
1. Claude Code 버전 + 모델:
   - `claude --version` → 2.1.112+ 확인
   - settings.json 확인: `"model": "claude-opus-4-7"` lock (T2 산출물)
   - 안 되면 → 🚩 BLOCK

2. frontend-design SKILL.md 설치 확인:
   - `test -f ~/.claude/skills/frontend-design/SKILL.md`
   - 안 되면 → 🚩 BLOCK. T1 재실행 요청.

3. 루트 /DESIGN.md 존재 확인:
   - `test -f /home/ubuntu/corthex-v3/DESIGN.md`
   - 안 되면 → 🚩 BLOCK. T4(/kdh-planning-pipeline Stage 5 또는 sally 소환) 먼저.

4. Playwright MCP + Chrome MCP 확인 (Phase 4 QA용):
   - ToolSearch로 `mcp__claude-in-chrome__*` 도구 로드 가능한지
   - 안 되면 → ⚠️ WARNING (BLOCK 아님, fallback 가능)

5. Dev 서버:
   - `curl -sf http://localhost:4820` (admin dev) 또는 4821 (app dev)
   - 안 되면 → 자동 시작 시도

6. pre-commit hook v4.5+:
   - `test -x /home/ubuntu/corthex-v3/.git/hooks/pre-commit`
   - 안 되면 → 🚩 BLOCK (main 보호 실패 위험)

7. Codex CLI:
   - `which codex && codex exec "echo ok"`
   - 안 되면 → 🚩 BLOCK

출력:
  ✅/🚩 Claude Code 2.1.112 + Opus 4.7 lock
  ✅/🚩 frontend-design SKILL.md
  ✅/🚩 루트 /DESIGN.md
  ✅/⚠️ Chrome MCP
  ✅/🚩 Dev 서버
  ✅/🚩 pre-commit hook
  ✅/🚩 Codex CLI

판정:
  → 🚩 0개 → Phase 0 진행
  → 🚩 1개라도 → 즉시 중지 + CEO 보고
```

---

## Phase 0: SAFETY — 삭제 전 안전 장치

```
팀 구성: 오케스트레이터 직접 (에이전트 소환 없음)

Step 0-a: pipeline-state.yaml 설정
  - current_story: null (일반 스토리 아님)
  - rebuild_mode: true  ← pre-commit hook이 packages/* 수정 허용
  - rebuild_target: {target}  (app | admin | both)
  - rebuild_started: {timestamp}

Step 0-b: 삭제 대상 파일 inventory 생성
  - packages/{target}/src/pages/*.tsx (전부)
  - packages/{target}/src/components/{hub|chat|layout|admin-pages}/**/*.tsx (전부)
  - packages/{target}/src/components/*/__tests__/*.tsx (UI 테스트만)
  - packages/{target}/src/index.css (색 값만 재작성, 구조 유지)
  유지 대상 (삭제 금지):
  - packages/{target}/src/components/ui/*.tsx (shadcn primitives)
  - packages/{target}/src/context/*.tsx
  - packages/{target}/src/hooks/*.ts
  - packages/{target}/src/lib/*.ts
  - packages/{target}/src/components/{oauth,error-boundary}/*.tsx
  - package.json, vite.config.ts, tsconfig.json
  저장: _bmad-output/ui-rebuild/inventory-{target}-{date}.md

Step 0-c: 브랜치 생성
  - git fetch origin main
  - git checkout -b refactor/{target}-ui-rebuild origin/main
  - 이미 있으면 → 현재 브랜치 유지, 단 base가 origin/main인지 확인

Step 0-d: tar 백업
  - tar czf /tmp/{target}-ui-pre-rebuild-{YYYYMMDD-HHMMSS}.tar.gz \
      packages/{target}/src/pages/ \
      packages/{target}/src/components/ \
      packages/{target}/src/index.css
  - 백업 크기 확인 (>100KB 기대, <10MB 한계)

Step 0-e: CEO 삭제 승인 GATE (BLOCKING)
  - inventory + 백업 경로 + 브랜치 명시
  - CEO에게 "이 파일들 삭제 시작합니다. 브랜치 {branch}, 백업 {tar}. OK?"
  - CEO "OK" → rm 실행 (한 번에)
  - CEO "잠깐" or 무응답 → 중단
  - ★ 계속 모드에서도 이 GATE는 자동 통과 금지 (삭제는 되돌리기 복잡)

Step 0-f: 실제 삭제 실행 (CEO OK 후)
  - inventory 기준 `git rm` (파일 tracking 제거)
  - packages/{target}/src/index.css는 **수정**만 (5 테마 색 값 placeholder 주석 처리)
  - git status 확인 — 삭제된 파일만 staged, 다른 변경 없음

Step 0-g: Safety 완료 커밋 (임시)
  - git commit -m "chore(ui-rebuild): delete {target} UI files for rebuild (T8 Phase 0)"
  - push 하지 않음 (main 보호)
```

---

## Phase 1: DESIGN — /DESIGN.md 재확인

```
팀 구성: sally (Writer, opus) solo — 재작성 아님, 재확인만

Step 1-a: 현재 /DESIGN.md 상태 확인
  - `test -f /home/ubuntu/corthex-v3/DESIGN.md`
  - 없으면 → 🚩 BLOCK. T4 재실행.

Step 1-b: sally 소환 (light check, no Party Mode)
  - TeamCreate("{project}-ui-rebuild-phase-1")
  - Agent spawn sally (bmad-agent-ux-designer, opus)
  - Task: "Read /DESIGN.md + 오늘 날짜 기준 stale 여부 확인. 9 섹션 모두 존재? theme 정의 완료? Agent Prompt Guide 블록 현재 {target}에 맞게 정비됐나?"
  - sally output: "OK" or "needs update: X, Y"

Step 1-c: 업데이트 필요 시
  - sally가 해당 섹션 수정 (diff 최소)
  - 단독 작업 (critics 없음, Phase 1 = 확인용)
  - 수정 완료 → git commit "docs(design): DESIGN.md refresh for {target} rebuild"

Step 1-d: sally shutdown + TeamDelete

★ Phase 1 짧게 끝내라 (15~30분). 대규모 재작성은 /kdh-planning-pipeline Stage 5.
```

---

## Phase 2: 탐색 — Claude Design or Chrome MCP 레퍼런스

**목적**: CEO가 시각으로 승인할 수 있는 프로토타입 3 옵션 생성.

```
팀 구성: 오케스트레이터 직접 (Chrome MCP 사용)

Step 2-a: Claude Design 가용성 확인
  - mcp__claude-in-chrome__tabs_context_mcp로 claude.ai/design 접근 가능 여부 확인
  - CEO Max 플랜 Claude Design 탭 노출 확인
  - 안 되면 → Step 2-b-alt로

Step 2-b: Claude Design 경로 (primary)
  1. 새 탭 claude.ai/design 열기
  2. "Set up design system" 클릭
  3. Company blurb 자동 입력 (corthex-v3 설명 + /DESIGN.md §1 방향 요약, Chrome MCP form_input)
  4. Any other notes에 /DESIGN.md 전체 내용 또는 §1~§4+§9 핵심 붙여넣기
  5. GitHub URL — public repo 가능 시 kodonghui/corthex-v3 입력, private면 생략
  6. ★ "Continue to generation" 버튼은 CEO 승인 시에만 클릭 (계속 모드에서도 자동 클릭 금지)
  7. 생성 완료 → URL로 링크 + 프로토타입 3 옵션 (target 페이지별)

Step 2-b-alt: Chrome MCP 레퍼런스 경로 (fallback)
  - Claude Design 접속 불가 시
  - Linear (linear.app), Vercel (vercel.com/dashboard), Stripe Dashboard, Raycast, Notion 을 순차 방문
  - 각 사이트의 /DESIGN.md §1 방향에 정합하는 요소 스크린샷 캡처
  - sally에게 스크린샷 전달 → 3 옵션 초안 wireframe (text 기반) 생성
  - 저장: _bmad-output/ui-rebuild/phase-2-exploration/

Step 2-c: 3 옵션 정리
  - Option A, B, C 각각 (target 페이지 전부 포함)
  - 주요 페이지: login / hub / chat / profile (app) 또는 dashboard / agents / members / audit / conversations (admin)
  - 각 옵션의 differentiating factor 명시 (1 문장)
  - 각 옵션의 trade-off 명시 (pros + cons)

Step 2-d: CEO 대면 GATE (BLOCKING)
  - 3 옵션 + URL (Claude Design 경로) 또는 스크린샷 (Chrome MCP 경로) CEO에게 제시
  - "A/B/C 중 어느 걸로?" 질문
  - CEO 선택 → rebuild_state.yaml에 chosen_option 기록
  - ★ 계속 모드에서도 자동 선택 금지 (방향 결정은 Business)
```

---

## Phase 3: 구현 — Anthropic 3-Agent 패턴

```
팀 구성:
  TeamCreate("{project}-ui-rebuild-phase-3")
  - sally (Planner, opus) — 페이지별 spec 확장
  - dev (Generator, opus for UI taste, sonnet 가능) — 코드 구현
  - quinn (Evaluator, opus with Playwright MCP access) — QA

Grade: A (avg ≥ 4.0/5, 4 criteria each ≥ 3/5)
Model: sally=opus, dev=opus (UI taste 중요), quinn=opus

페이지 순서 (app 기준): login → hub → chat → profile
페이지 순서 (admin 기준): dashboard → agents → members → audit → conversations

각 페이지마다:
━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 3-a: sally PLANNER (spec 확장)
  - 해당 페이지의 /DESIGN.md Agent Prompt Guide 블록 읽기
  - chosen_option (Phase 2-d)의 해당 페이지 디테일 참조
  - 세부 spec 작성: _bmad-output/ui-rebuild/phase-3-plans/{page}-spec.md
  - 포함:
    - 컴포넌트 트리 (shadcn primitives + 도메인 컴포넌트)
    - State machine (loading/error/empty/success/session-expired)
    - 데이터 의존성 (hooks, API endpoints — 백엔드 변경 금지)
    - 라우팅 (기존 경로 유지)
    - 3 테마 호환 (Paper/Carbon/Signal — /DESIGN.md §2 참조)
    - EARS 수락 기준 ≥ 5개
  - Party review (winston + quinn, 간단) avg ≥ 3.5/5
  - PASS → Step 3-b로

Step 3-b: dev GENERATOR (코드 구현)
  - sally spec을 input으로
  - 실제 코드 작성:
    - packages/{target}/src/pages/{page}.tsx (신규)
    - packages/{target}/src/components/{domain}/*.tsx (필요한 것)
  - shadcn/ui primitives 재사용 (기존 ui/*.tsx)
  - @import "@/components/ui/*" 경로
  - Tailwind CSS variable 기반 (`bg-background`, `text-foreground`, …)
  - stub/mock 금지 — 실제 API 연결 (hooks/lib 재사용)
  - NEVER-list 준수 (Inter/Roboto/Arial/보라 그라디언트 금지)
  - Pretendard + JetBrains Mono (또는 /DESIGN.md §3 사양)
  - tsc --noEmit 통과 필수

Step 3-c: quinn EVALUATOR (Playwright MCP QA)
  - dev 완료 후 spawn (fresh instance)
  - Playwright MCP로 실제 페이지 로드 → **critic-rubric.md D8~D11** (Anthropic 4 criteria) 채점:
    D8 Design Quality (0-5): color/typography/layout coherence
    D9 Originality (0-5): custom vs AI slop 증거
    D10 Craft (0-5): typography hierarchy, spacing, focus ring, transitions
    D11 Functionality (0-5): FR-UI mapping, dead button 0, keyboard nav 100%
  - + 기존 D1-D7 (구체성/완전성/정확성/실행가능성/일관성/리스크/디자인품질 전반)
  - 각 D score avg 계산 (0-5 스케일로 통일 변환)
  - **PASS 규칙 (critic-rubric.md §"4 Criteria 종합 PASS 규칙" 참조)**:
    - D8~D11 각각 avg ≥ 4/5 → PASS
    - 하나라도 < 3/5 → auto-FAIL
    - 전체 avg < 4/5 → FAIL
  - **FAIL 피드백 루프**:
    - quinn이 FAIL 판정 시, 구체적 이슈 리스트 작성 (파일 경로 + 라인 + 수정 지시)
    - 이슈 리스트 → sally Planner에게 전달 → sally가 spec 업데이트 (Option: Phase 3-a 재실행)
    - 또는 sally 건드리지 않고 dev Generator 직접 수정 (단순 craft 이슈)
    - 판단 기준: D8/D9/D11 FAIL = sally spec 재작성 필요. D10 FAIL = dev 수정 가능.
    - max 3 retry per page. 초과 시 skip + CEO 보고.

Step 3-d: 페이지 완료 시
  - rebuild_state.yaml에 해당 페이지 completed 기록
  - scores 기록 (D1~D12 각각)
  - git commit "feat({target}): {page} page rebuild — D9-D12 avg X.X"
  - 다음 페이지로

모든 페이지 완료 → Phase 4로
━━━━━━━━━━━━━━━━━━━━━━━━━━━

★ Retry 초과 (per page max 3) 시:
  - CEO 보고 + 현재 페이지 skip + 다음 페이지 계속
  - rebuild_state.yaml에 failed_pages 기록
  - Phase 5 병합 전 CEO 최종 판단
```

---

## Phase 4: 검증 — 4 criteria + VRT + CEO GATE

```
팀 구성: quinn Writer (opus) + dev + winston Critics (opus)
  TeamCreate("{project}-ui-rebuild-phase-4")

Step 4-a: Chrome MCP 자율 탐색
  - kdh-bug-fix-pipeline Phase 1 Step 0.5 재사용
  - 5 테마 아니라 /DESIGN.md §2 theme 개수만큼 (Paper/Carbon/Signal = 3 themes)
  - 각 테마 × 각 페이지 = N 화면 자율 탐색
  - 모든 버튼/dropdown/form 인터랙션
  - empty/error/loading/session-expired 상태 전부
  - 모바일 뷰포트 (resize_window 375x667)
  - console 에러 수집
  - network 실패 수집
  - 탐색 시간 페이지당 15분 제한

Step 4-b: 스크린샷 매트릭스
  - {theme} × {page} = 9~12장 (app=4 pages × 3 themes = 12)
  - 저장: _bmad-output/ui-rebuild/phase-4-screenshots/{theme}-{page}.png
  - 이전 baseline 있으면 diff 생성

Step 4-c: Anthropic 4 criteria 종합 채점 (critic-rubric.md D8~D11)
  - Step 3-c 페이지별 점수 종합 (평균)
  - quinn이 Playwright MCP로 재채점 (fresh perspective, 페이지별 아닌 전체 통합)
  - critic-rubric.md §"UI Rebuild 추가 차원 D8~D11" 기준 적용:
    D8 Design Quality: 3 테마 × 모든 페이지 color/typography/layout 통합 coherence
    D9 Originality: AI slop 패턴 0건 (Inter/Roboto/Arial/purple on white)
    D10 Craft: Focus ring/hover/transition 일관성
    D11 Functionality: FR → UI mapping matrix 완성도
  - PASS 규칙: 4 criteria 각 ≥ 4/5, 하나라도 < 3/5 auto-FAIL, 전체 avg < 4/5 FAIL
  - 파일: _bmad-output/ui-rebuild/phase-4-criteria-report.md (D8~D11 표 포함)

Step 4-d: Visual Regression Test (VRT)
  - 있으면 _bmad-output/ui-rebuild/baseline/ 과 diff (pixelmatch)
  - diff > 5% 구간 자동 flag (이건 의도된 변경이므로 flag만, block 아님)
  - 첫 재빌드 이벤트라 baseline 없으면 현재 스크린샷을 baseline으로 등록

Step 4-e: CEO 대면 최종 GATE (BLOCKING)
  - criteria report + 스크린샷 매트릭스 + 탐색 console log CEO 제시
  - "이 정도면 예쁘냐?" 질문
  - CEO "OK" → Phase 5로
  - CEO "여기 이상해" → 구체적 이슈 목록 → Phase 3 해당 페이지 재진입 (max 2 retry 전체)
  - ★ 계속 모드에서도 이 GATE는 CEO 대면 필수 (디자인 승인은 Business)
  - CEO 부재 시 대기 (max 24시간)

FAIL retry 2회 모두 실패 시:
  - refactor/{target}-ui-rebuild 브랜치 폐기 옵션 CEO에게 제시
  - main 무손실 확인 (git log origin/main = commit 수 변화 없음)
  - rebuild_state.yaml에 aborted 기록
  - tar 백업 복구 경로 안내 (`tar xzf /tmp/{target}-ui-pre-rebuild-*.tar.gz -C /home/ubuntu/corthex-v3/`)
```

---

## Phase 5: 병합 + 배포

```
팀 구성: 오케스트레이터 직접

Step 5-a: tsc + bun test 전체 통과 확인
  - cd / && bun run type-check
  - bun test 전체
  - 하나라도 FAIL → Phase 3 해당 영역 재진입

Step 5-b: Codex + Gemini 병렬 리뷰 (필수)
  - git diff origin/main...HEAD -- packages/{target}/ > /tmp/ui-rebuild-diff.patch
  - bash ~/.claude/scripts/codex-review.sh /tmp/ui-rebuild-diff.patch \
      "이 {target} UI 재빌드 diff를 Anthropic 4 criteria 관점에서 독립 채점해라. AI slop 패턴 감지 (Inter/Roboto/Arial/purple on white). 한국어로."
  - Codex PASS + Gemini PASS → Step 5-c
  - 하나라도 FAIL → 이슈 반영 후 재실행

Step 5-c: Squash merge to main
  - gh pr create --title "refactor({target}): UI 전면 재빌드 — /kdh-ui-rebuild 완주" --body "..."
  - gh api PUT /repos/{owner}/{repo}/pulls/{N}/merge -f merge_method=squash
  - ★ git push origin main 직접 금지 (pre-commit hook 차단)

Step 5-d: Deploy 대기
  - gh run list --repo kodonghui/corthex-v3 --branch main --limit 3
  - 최신 run status == "success" 대기

Step 5-e: 프로덕션 Chrome MCP 재확인
  - mcp__claude-in-chrome__tabs_create_mcp https://corthex-hq.com/{target}
  - 로그인 (SWEEP_EMAIL/PASSWORD from .env)
  - 각 페이지 방문 + console error 수집
  - 0 critical + 0 console error → T9 PASS
  - critical 있으면 → hotfix 또는 revert

Step 5-f: 정리
  - pipeline-state.yaml: rebuild_mode: false
  - TeamDelete (모든 team)
  - rebuild_state.yaml 최종 상태 저장 (성공/실패 + 스크린샷 경로 + 점수)
```

---

## Agent Roster (UI Rebuild 전용)

| Spawn Name | Persona | Role | Model | Phase 참여 |
|------------|---------|------|-------|-----------|
| sally | bmad-agents/ux-designer.md | **Lead Writer** / Planner | opus | 1, 3 |
| dev | bmad-agents/dev.md | Generator | opus | 3 |
| quinn | bmad-agents/qa.md | Evaluator | opus | 3, 4 |
| winston | bmad-agents/architect.md | Critic (secondary) | opus | 1, 3, 4 (quinn 보조) |
| john | bmad-agents/pm.md | Critic (secondary) | opus | 4 (CEO readability) |

**Primary: sally.** 일반 dev-pipeline과 **결정적 차이** — 오케스트레이터가 ui-design.md 작성 금지, sally가 spec+planning 총괄.

**haiku 절대 금지.**

---

## Core Rules

1. **sally = Lead Writer, 오케스트레이터 직접 코딩 금지.** Phase 3 코드 작성은 dev 에이전트만.
2. **Anthropic 4 criteria 채점 필수** (D9~D12). 하나라도 < 3/5 auto-FAIL.
3. **4 criteria avg ≥ 4/5 PASS** (Grade A). <4/5 = retry.
4. **CEO GATE 3회** (0-e 삭제 / 2-d 프로토타입 선택 / 4-e 최종 승인). 계속 모드에서도 자동 통과 금지.
5. **refactor 브랜치 고립.** main 수정 금지 (pre-commit hook 차단).
6. **tar 백업 필수** (Phase 0-d). 삭제 전.
7. **frontend-design SKILL.md 로드 확인** (Step -1). Anthropic NEVER 목록 준수.
8. **Pretendard + JetBrains Mono** (또는 /DESIGN.md §3 사양). Inter/Roboto/Arial 금지.
9. **shadcn primitives 재사용** — 삭제 금지 (Phase 0-b 유지 목록).
10. **백엔드 변경 금지** — packages/server / packages/shared 건드리지 않음.
11. **stub/mock 금지** — 실제 API 연결.
12. **5 retry 초과 = 중단** — 페이지당 Phase 3 max 3, 전체 Phase 4 max 2.
13. **Codex + Gemini 병렬 리뷰 필수** (Phase 5-b). FAIL 자동 스킵 금지.
14. **계속 모드에서도 CEO 대면 GATE는 자동 통과 금지** (0-e, 2-d, 4-e).
15. **tsc cross-package + bun test 통과** Phase 5-a 필수.
16. **rebuild_state.yaml 항상 멀티라인 YAML.** 인라인 금지.
17. **TeamDelete 필수** Phase 5-f 정리.
18. **party-log 파일 필수** (v4.4 규칙). 오케스트레이터 직접 party-log 작성 = 기만 행위.

---

## State Management: rebuild_state.yaml

```yaml
project: corthex-v3
pipeline: ui-rebuild
version: v1.0
target: app  # app | admin | both
branch: refactor/app-ui-rebuild
started: "2026-04-18T..."
rebuild_mode: true

current_phase: phase_0  # [phase_0 | phase_1 | phase_2 | phase_3 | phase_4 | phase_5 | complete | aborted]

phase_0:
  inventory_file: _bmad-output/ui-rebuild/inventory-app-20260418.md
  backup_file: /tmp/app-ui-pre-rebuild-20260418-120000.tar.gz
  ceo_deletion_approved: false
  deleted_at: null

phase_1:
  design_md_status: ok  # ok | updated | failed
  sally_run_id: null

phase_2:
  method: claude_design  # claude_design | chrome_mcp_fallback
  options_generated: 3
  chosen_option: null  # A | B | C
  ceo_selected_at: null
  url_or_path: null

phase_3:
  pages_total: 4
  pages_completed: 0
  pages_failed: []
  per_page_scores:
    login:
      D1_D8_avg: null
      D9_design_quality: null
      D10_originality: null
      D11_craft: null
      D12_functionality: null
      retry_count: 0
    hub: {...}
    chat: {...}
    profile: {...}

phase_4:
  chrome_sweep_complete: false
  screenshot_count: 0
  criteria_avg:
    D9: null
    D10: null
    D11: null
    D12: null
    overall: null
  vrt_baseline_registered: false
  ceo_final_approved: false
  retry_count: 0

phase_5:
  tsc_passed: false
  bun_test_passed: false
  codex_result: null
  gemini_result: null
  pr_number: null
  merged_commit: null
  deploy_run_id: null
  production_chrome_check: null
```

---

## Entry / Exit Criteria

### Entry (이 파이프라인을 언제 쓰는가)

- CEO가 /app 또는 /admin UI 전면 재빌드를 명시 승인 (Business 결정)
- 일반 스토리로 못 잡히는 구조적 시각 품질 문제 감지 (예: CEO "하나도 안 예쁨" 호소)
- Phase 전환 시점 (예: Phase 3 → Phase 4로 넘어가기 전 /app 정비)
- `/kdh-dev-pipeline`이 다루기엔 범위가 너무 큼 (> 10 파일 재작성)

### Exit (언제 끝나는가)

- Phase 4 4 criteria avg ≥ 4/5 + CEO 최종 승인
- Phase 5 tsc + bun test + Codex + Gemini 모두 PASS
- 프로덕션 Chrome MCP 0 critical + 0 console error
- rebuild_state.yaml current_phase: complete

### Abort (중단 시점)

- Phase 0-e CEO 삭제 승인 FAIL
- Phase 3 특정 페이지 max retry (3) 초과 AND CEO 중단 판단
- Phase 4 max retry (2) 모두 실패 → 브랜치 폐기
- 중단 시 tar 백업으로 복구 가능. main 무손실.

---

## Anti-Patterns

1. **오케스트레이터가 ui-design.md 직접 작성** — kdh-dev-pipeline Phase B에서 수정된 규칙 위반. FIX: sally만 작성.
2. **Claude Design에서 "Continue to generation" 자동 클릭** — 계속 모드에서도 금지 (방향 결정은 Business GATE).
3. **tar 백업 생략** — 삭제 전 필수. 없으면 Phase 0 미완 간주.
4. **shadcn primitives 삭제** — 재사용 자산. Phase 0-b 유지 목록 위반.
5. **백엔드 변경** — packages/server 또는 shared 수정. 스코프 밖.
6. **main에 직접 push** — pre-commit hook 차단됨. squash merge API 경로만.
7. **refactor 브랜치 장기 고립** — 7일 초과 시 main에서 fetch + rebase 필요 (Conflict 증가).
8. **계속 모드에서 Phase 4-e 자동 통과** — 디자인 최종 승인은 CEO 대면 필수. 규칙 14 위반.
9. **Anthropic NEVER 목록 위반** — Inter/Roboto/Arial/보라 그라디언트 커밋 발견 시 pre-commit block 추가 검토.
10. **기존 5테마 값 재사용** — 사장님 Q1 결정에 따라 값 전면 폐기. /DESIGN.md §2 새 theme만 사용.

---

## Pipeline Interconnection

### kdh-planning-pipeline → kdh-ui-rebuild
Stage 5 UX 완료 + /DESIGN.md 업데이트 → CEO가 /kdh-ui-rebuild 호출 시 Phase 1에서 /DESIGN.md 참조.

### kdh-dev-pipeline ↔ kdh-ui-rebuild
kdh-dev-pipeline은 **일반 Sprint 스토리**. UI 전면 재빌드는 이 skill.
병존: 재빌드 완료 후 일반 스토리는 /kdh-dev-pipeline으로 돌아감.

### kdh-bug-fix-pipeline ↔ kdh-ui-rebuild
버그 수정이 >5개 페이지 거대하면 /kdh-ui-rebuild 재빌드 이벤트로 에스컬레이션 고려.
rebuild 완료 후 남은 minor 버그는 /kdh-bug-fix-pipeline으로.

참조: `_bmad-output/pipeline-protocol.md`

---

## Codex 검증 (필수)

### 본 SKILL.md 작성 시
```bash
bash ~/.claude/scripts/codex-review.sh ~/.claude/skills/kdh-ui-rebuild/SKILL.md \
  "이 skill의 5 Phase 로직 검증. 누락 step? 무한 루프? sally/dev/quinn 역할 충돌? EARS 준수? CEO GATE 자동 통과 방지? 한국어로."
```
(run_in_background: true)

### Phase 3 구현 완료 시
```bash
git diff refactor/{target}-ui-rebuild HEAD -- packages/{target}/ > /tmp/ui-rebuild-diff.patch
bash ~/.claude/scripts/codex-review.sh /tmp/ui-rebuild-diff.patch \
  "Anthropic 4 criteria + AI slop 패턴 독립 채점. 한국어로."
```

Codex FAIL = 자동 진행 금지 (CLAUDE.md 규칙).

---

## Version History

- **v1.0 (2026-04-18)**: 최초 출시. 0418-plan-app-ui-rebuild T5 산출물. sally Lead + Anthropic 3-Agent + 4 criteria 채점 + Claude Design/Chrome MCP 탐색 + refactor 브랜치 격리.
