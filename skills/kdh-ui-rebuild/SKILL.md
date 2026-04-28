---
name: kdh-ui-rebuild
description: UI Rebuild Pipeline — /app 또는 /admin 전면 UI 재빌드 1회성 이벤트 전용. sally Lead Writer + Anthropic 3-Agent 패턴 (Planner/Generator/Evaluator) + Anthropic 4 criteria 채점 + Claude Design/Chrome MCP 탐색. 사장님 명령어 — `/kdh-ui-rebuild [target=app|admin] [계속]`.
user-invocable: true
---

# KDH UI Rebuild Pipeline v1

> 부분 개선이 아닌 **전면 교체** 워크플로. 본 skill 은 1회성 이벤트 전용 — UI 폴리시는 `/kdh-bug-fix-pipeline`, 점진적 개선은 `/kdh-dev-pipeline` 을 사용한다.
>
> `/kdh-corthex-design` skill 필수 호출 + 3 테마 (Paper/Carbon/Signal) + mypqjitg/ndpk SSoT + sally verdict-only.
> Reference: `_bmad-output/audit/2026-04-21-kdh-skills-claude-design-audit-v2.md`

---

## 0. 시작 전 (Pre-flight)

- **`/kdh-corthex-design`** invoke — 브랜드 체크리스트 + tokens + preview + ui_kits/console pointers 수신.
- React pages handoff: `_bmad-output/ui-rebuild/claude-design-generate-result/<bundle>/project/reskin-react/src/routes/<Page>.tsx`
- 디자인 시스템 SSoT: `_bmad-output/ui-rebuild/claude-design-generate-result/<bundle>/colors_and_type.css` + `preview/` + `ui_kits/console/`
- pre-commit hook: design-spec artifact (CEO-owned glob) 직접 편집 금지. 변경 필요 시 `_bmad-output/design-requests/YYYY-MM-DD-<slug>.md` 에 영어 prompt block 작성 → CEO 가 claude.ai/design 사용 → 새 handoff URL 수신.

---

## Phase 0 — SAFETY (삭제 + 백업 + 승인)

목표: rebuild 시작 전 무손실 보장.

### Step 0-a · pipeline-state.yaml + rebuild_mode

```bash
# pipeline-state.yaml 에 rebuild_mode: true 설정
# current_story: rebuild-{target}
```

### Step 0-b · 삭제 대상 inventory

```bash
find packages/<target>/src/pages -type f -name '*.tsx' > /tmp/rebuild-inventory-{target}.txt
find packages/<target>/src/components -type f -name '*.tsx' >> /tmp/rebuild-inventory-{target}.txt
wc -l /tmp/rebuild-inventory-{target}.txt
```

inventory 는 단순 list — 실제 삭제 결정은 Step 3-a 에서.

### Step 0-c · refactor 브랜치 생성

```bash
git checkout main && git pull origin main
git checkout -b refactor/<target>-ui-rebuild
```

main 은 Phase 5 squash merge 까지 직접 수정 금지.

### Step 0-d · tar 백업

```bash
tar -czf /tmp/<target>-ui-pre-rebuild-$(date -u +%Y%m%d).tar.gz packages/<target>/src/
```

### Step 0-e · CEO 삭제 승인 GATE (BLOCKING)

- Phase 0 종료 전 CEO 에게 inventory + 삭제 범위 + 백업 위치 보고.
- IF CEO 미승인 → THE SYSTEM SHALL `rm` 미실행 + Phase 1 진입 금지.
- IF CEO 승인 → 다음 Phase.

EARS:
- **U-0**: THE SYSTEM SHALL produce inventory + tar backup before any `rm` call.
- **X-0**: IF CEO 승인 trailer 없음, THEN THE SYSTEM SHALL block Phase 3 entry.

---

## Phase 1 — DESIGN

목표: 디자인 SSoT + 팀 구성.

### Step 1-a · `/DESIGN.md` 또는 corthex-design-system 재확인

- `/DESIGN.md` 가 stub 상태이면 (CEO SKIPPED 정책), `corthex-design-system/project/SKILL.md` + `colors_and_type.css` 가 SSoT.
- `/kdh-corthex-design` invoke 결과를 prompt context 에 포함.

### Step 1-b · 팀 구성

- **sally** — Lead Writer (디자인 spec 작성 + 페이지별 expand)
- **winston** — Architect Critic (구조 / 의존성 / 라우팅 검증)
- **quinn** — QA Critic (Playwright/Chrome MCP 시나리오 작성)
- **john** — PM Critic (요구사항 매핑 / OOS 검증)
- **dev_executor** — Codex CLI 위임 (D3 룰: packages/ Edit/Write 는 Codex 전담)

EARS:
- **U-1**: THE SYSTEM SHALL designate sally as Lead Writer; orchestrator SHALL NOT directly author UI code.
- **X-1**: IF orchestrator attempts direct `packages/<target>/src` Edit, THEN pre-commit hook SHALL fail per CLAUDE.md D3.

---

## Phase 2 — 탐색 (Discovery)

목표: 디자인 옵션 3 개 → CEO 선택.

### Step 2-a · Claude Design 사용 가능 (KR 접속 OK)

- codebase + `/DESIGN.md` 또는 `corthex-design-system/` 업로드
- claude.ai/design 에 영어 prompt 5 sections (Context / Constraint / Ask / Target file / Acceptance) 입력
- handoff URL 수신 → `_bmad-output/ui-rebuild/claude-design-generate-result/YYYY-MM-DD-<slug>/`

### Step 2-b · 3 프로토타입 옵션 생성

- **Option A** — Linear/Vercel 톤 (minimal/grid)
- **Option B** — Toss/Notion 톤 (소비자 친화)
- **Option C** — Bloomberg/Stripe 톤 (operator-dense)

### Step 2-c · Claude Design 불가 (백업)

- Chrome MCP 로 Linear / Vercel / Stripe / Raycast / Github 직접 탐색
- 캡쳐 + sally 가 직접 spec 작성 (Phase 1-b 의 4 critic 검증)

### Step 2-d · CEO 대면 GATE

- 3 옵션 비교 시각 자료 + sally 의 권장 + winston 의 구조적 평가 + quinn 의 a11y 평가 → CEO 선택.
- IF CEO 가 자율 위임 ("너가 판단해") → orchestrator 가 sally + winston 권장 우선.
- IF CEO 직접 선택 → 해당 옵션 채택.

EARS:
- **E-2**: WHEN Phase 2 ends, THE SYSTEM SHALL log selected_option_id in pipeline-state.yaml.

---

## Phase 3 — 구현 (Anthropic 3-Agent 패턴)

목표: 페이지 단위 iteration. 1 페이지 단위 = Planner → Generator → Evaluator → 다음.

### Step 3-a · 삭제 실행 (Phase 0 inventory + CEO 승인 후)

```bash
# inventory 의 rm 대상만 실제 삭제
xargs -a /tmp/rebuild-{target}-deletion-confirmed.txt rm -f
git add -A && git commit -m "chore(rebuild): drop legacy <target> UI pages per Phase 0 inventory"
```

### Step 3-b · sally Planner — 페이지별 spec 확장

- 각 페이지에 대해 Phase 2 선택 옵션 기반 Detail spec 작성:
  - 레이아웃 (grid / spacing / 8px baseline)
  - 컴포넌트 트리 + props 시그니처
  - 데이터 흐름 (useAuth / useFetch / SSE)
  - 토큰 사용 (`hsl(var(--*))` 만)

### Step 3-c · dev Generator — 코드 구현 (Codex CLI 위임)

- `/kdh-codex-delegate` 5-section EARS prompt 사용
- D3 룰: orchestrator 직접 Edit/Write 금지
- 1 페이지 = 1 commit, prefix `feat(<target>): rebuild <page> per <option>` + Task-ID trailer

### Step 3-d · quinn Evaluator — Playwright/Chrome MCP QA

- 페이지 단위 시나리오 작성:
  - Render OK + 0 console errors
  - 3 테마 전환 OK
  - 키보드 navigation 100% OK
  - 모바일 레이아웃 OK
  - 핵심 인터랙션 (form submit / link click / SSE 연결 등) 동작

### Step 3-e · 페이지 단위 iteration 순서

1. login (인증 entry)
2. hub / dashboard (홈)
3. chat / agent-detail (핵심 인터랙션)
4. profile (사용자 setting)
5. 나머지 페이지

EARS:
- **U-3**: THE SYSTEM SHALL commit exactly one page per atomic commit during Phase 3.
- **X-3**: IF tsc fails for any committed page, THEN dev_executor SHALL be re-dispatched with full error trace.

---

## Phase 4 — 검증

목표: Anthropic 4 criteria 채점 + visual regression + CEO 최종 GATE.

### Step 4-a · Chrome MCP 자율 탐색

- `/kdh-bug-fix-pipeline` Phase 1 Step 0.5 (자율 탐색) 재사용.
- 3 provider sweep (claude / openai / gemini) 으로 phantom UI / 콘솔 에러 / 회귀 발견.

### Step 4-b · 5 테마 × N 페이지 스크린샷

- ~3 테마 (Paper/Carbon/Signal) × N 페이지 = 3N 스크린샷~ (3 테마 정책 반영)
- 저장: `_bmad-output/e2e/<rebuild-slug>/<page>-<theme>.png`

### Step 4-c · Anthropic 4 criteria 채점 (0-5 Likert)

| Criterion | 정의 | Pass 기준 |
|-----------|------|-----------|
| **Design** | 시각적 완성도, brand 충실도 | avg ≥ 4.0/5 |
| **Originality** | 기존 v3 UI 또는 generic shadcn 와 구분되는가 | avg ≥ 4.0/5 |
| **Craft** | 디테일 (spacing / typography / micro-interaction) | avg ≥ 4.0/5 |
| **Functionality** | 실제 동작 (mock 금지, real wire) | avg ≥ 4.0/5 |

채점은 sally + winston + quinn 합의. 각 critic 0-5 점수 → 평균.

### Step 4-d · Visual Regression Test

- baseline = `_bmad-output/visual-baseline/<previous-bundle>/`
- 비교: pixelmatch / odiff. 임계 = 픽셀 diff ≥ 5% → 검토 대상.
- 신규 페이지는 baseline 미존재 → 본 cycle 결과를 baseline 으로 설정.

### Step 4-e · CEO 대면 최종 GATE

- 4 criteria 점수표 + 스크린샷 thumbnail + 알려진 잔여 issue → CEO.
- IF CEO 자율 위임 → orchestrator 가 4 criteria PASS + bug-fix 0 outstanding 시 자동 PASS.
- IF 4 criteria 중 하나라도 < 3/5 → auto-FAIL → sally 재소환 (max 2 retry). 2 회 fail = Phase 4 중단 + 브랜치 폐기 + CEO 보고.

EARS:
- **U-4**: THE SYSTEM SHALL score every criterion ≥ 3.0/5 before allowing Phase 5.
- **X-4**: IF any criterion < 3.0/5, THEN THE SYSTEM SHALL re-summon sally (≤ 2 retries) and on second failure abort.

---

## Phase 5 — 병합 + 배포

목표: refactor 브랜치 → main → prod, 무손실 전환.

### Step 5-a · refactor → main squash merge

```bash
git checkout main && git pull origin main
git merge --squash refactor/<target>-ui-rebuild
git commit -m "feat(<target>): rebuild UI per Claude Design <bundle>" -m "<summary of pages + critics + criteria scores>"
```

### Step 5-b · 배포 (CI 또는 manual fallback)

- 기본: `git push origin main` → GitHub Actions → deploy.sh
- CI 잠금 시 fallback (CLAUDE.md):
  ```bash
  git -C ~/corthex-v3-deploy fetch origin main
  git -C ~/corthex-v3-deploy reset --hard origin/main
  bash /home/ubuntu/corthex-v3-deploy/scripts/deploy.sh
  systemctl is-active corthex-v3
  curl -sI https://corthex-hq.com/api/health
  ```

### Step 5-c · 프로덕션 Chrome MCP 재확인

- 배포 후 1 차 sweep (claude only) 으로 새 bundle 동작 확인.
- 0 product bug → Phase 5 완료. >0 bug → `/kdh-bug-fix-pipeline` 으로 즉시 분기.

### Step 5-d · pipeline-state.yaml 정리

```yaml
rebuild_mode: false
current_story: null
last_rebuild:
  target: <app|admin>
  bundle: <handoff-id>
  completed: <ISO timestamp>
  commit: <sha>
```

EARS:
- **U-5**: THE SYSTEM SHALL set rebuild_mode false only after smoke + post-deploy sweep PASS.

---

## 6. 명령어 표면

### 진입
- `/kdh-ui-rebuild target=app` — /app 재빌드 시작
- `/kdh-ui-rebuild target=admin` — /admin 재빌드 시작
- `/kdh-ui-rebuild 계속` — 마지막 cycle 의 다음 Phase 재개

### 중단
- `/kdh-ui-rebuild abort` — 현 Phase 중단 + refactor 브랜치 보존 (수동 정리)
- `/kdh-ui-rebuild rollback` — refactor 브랜치 폐기 + main 무변경 확인

### 점검
- `/kdh-ui-rebuild status` — 현 Phase + 점수 + 다음 Step

---

## 7. 위험 요약 (Pre-mortem)

| # | 시나리오 | 확률 | 영향 | 예방 |
|---|----------|------|------|------|
| 1 | Phase 0-e CEO 미승인 → Phase 진행 차단 | 낮 | 높 | inventory + tar 백업 사전 완료 |
| 2 | Phase 3 dev_executor (Codex) 일관성 부족 | 중 | 중 | sally Planner spec 의 명확성 + tsc 자동 게이트 |
| 3 | Phase 4 4 criteria 미달 2 회 → 브랜치 폐기 | 낮 | 매우 높 | Phase 2 옵션 다양화 + sally 재소환 시 다른 angle |
| 4 | Phase 5 squash merge 충돌 (main drift) | 중 | 중 | refactor 시작 시 `git pull --rebase` + Phase 5-a 직전 재 rebase |
| 5 | CI 잠금 → 배포 지연 | 중 | 중 | manual fallback 명문화 (Step 5-b 참조) |

---

## 8. 본 skill 가 호출하는 다른 skills

- `/kdh-corthex-design` — design SSoT 조회 (필수, 매 phase)
- `/kdh-codex-delegate` — Phase 3-c dev 구현 위임 (D3 룰 준수)
- `/kdh-bug-fix-pipeline` — Phase 5-c 발견 bug 처리 분기
- `/kdh-party-mode` — 4 critic 합의 (Phase 1-b / Phase 4-c)

---

## 9. 본 skill 가 NOT 다루는 것 (OOS)

- 점진적 UI 개선 (→ `/kdh-dev-pipeline`)
- 단일 컴포넌트 폴리시 (→ `/kdh-bug-fix-pipeline`)
- Backend API 신규 엔드포인트 (→ `/kdh-dev-pipeline` Phase B)
- DB 마이그레이션 (→ `/kdh-planning-pipeline`)

---

**END OF SKILL** · 본 skill 은 1회성 전면 재빌드 이벤트 전용. 폴리시/개선은 다른 skill 사용.
