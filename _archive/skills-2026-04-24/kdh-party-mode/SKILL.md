---
name: kdh-party-mode
description: "Party Mode Protocol v10.4 — 멀티에이전트 리뷰. dev/planning/bug-fix 공통."
---

> **v2 (2026-04-17): Critic 3-Tier Routing + Wrapper Agents**
> - quinn(QA) persona 제거 (BMAD 공식 없음). QA 책임은 dev(Amelia)가 TDD로 흡수.
> - Tier 1 Opus: winston (architect), dev (writer+QA)
> - Tier 2 (비움): BMAD 해당 agent 없음
> - Tier 3 Sonnet section-only: john (PM), sally (UX)
> - Agent 소환 = Claude Code Task tool + `~/.claude/agents/{name}.md` wrapper (model frontmatter로 Opus/Sonnet 라우팅).
> - 기존 `_bmad/bmm/agents/*.md` persona 참조는 wrapper가 archive path로 forwarding (pinned SHA 6b964acd).
> - PASS 기준 v2: (1) 3 critic 평균 ≥ 7.0 AND (2) winston ≥ 7.0 AND (3) dev tsc clean + coverage ≥ 80%.

# Party Mode Protocol

> **v2 (2026-04-17): Critic 3-Tier Routing + Wrapper Agents**
> - quinn(QA) persona 제거 — BMAD 공식 없음. QA 책임은 dev(Amelia)가 TDD로 흡수.
> - **Tier 1 Opus:** winston (architect), dev (writer+QA 일체)
> - **Tier 2 (비움):** BMAD 해당 agent 없음. 필요 시 별도 plan에서 analyst/tech-writer 추가
> - **Tier 3 Sonnet section-only:** john (PM), sally (UX)
> - Agent 소환 = Claude Code Task tool + `~/.claude/agents/{name}.md` wrapper (model frontmatter로 Opus/Sonnet 라우팅).
> - persona 정의는 wrapper가 archive (`/home/ubuntu/bmad-archive`, pinned SHA 6b964acd) 경로 forwarding.
> - **PASS 기준 v2:** (1) 3 critic(winston/john/sally) 평균 ≥ 7.0 AND (2) winston ≥ 7.0 AND (3) dev(writer) tsc clean + coverage ≥ 80%.

<HARD-GATE>
- 조건부 PASS 금지 (Rule 37)
- DA는 fresh instance 필수 (Rule 38)
- Cross-Validation 순서 변경 금지 (Rule 39)
- Critic 전문 영역 무시 금지 (Rule 40)
- 오케스트레이터가 직접 party-log 작성 = 기만 행위. 절대 금지.
- Critic은 페르소나 파일 first read 필수 (AP #4) — Read _bmad/bmm/agents/*.md가 첫 행동
- Cross-talk ## 섹션 필수 (AP #11) — 로그에 Cross-talk 없으면 REJECT
- Score stdev < 0.3 = inflation 의심 (AP #8) — 오케스트레이터가 재채점 경고
- DA skip 시 compliance YAML에 da_skipped: true + da_skip_reason 필수 (AP #16)
</HARD-GATE>


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

## Red Flags

| 패턴 | 판정 |
|------|------|
| "오케스트레이터가 직접 party-log 쓰면 빠름" | 기만. 실제 critic 리뷰 필수 |
| "scores 올랐으니 PASS" | self-enhancement bias |
| "이전 에이전트에게 SendMessage로 이어서" | fresh context 필수 |

---

## Agent Roster (v2 — wrapper + tier)

v2부터 페르소나 소환은 Claude Code Task tool + `~/.claude/agents/*.md` wrapper 사용. wrapper frontmatter의 `model:` 필드로 Opus/Sonnet 라우팅. wrapper body는 BMAD archive (`/home/ubuntu/bmad-archive @ 6b964acd`) persona 경로 forwarding.

| Spawn Name | Wrapper | Archive Source | Tier | Model | Role |
|-----------|---------|---------------|------|-------|------|
| `winston` | `~/.claude/agents/winston.md` | `bmad-agent-architect` | **1** | opus | Architecture critic. Phase A/B |
| `dev` | `~/.claude/agents/dev.md` | `bmad-agent-dev` | **1** | opus | Phase B writer + Phase D test writer + QA coverage owner (v2 quinn 흡수) |
| `john` | `~/.claude/agents/john.md` | `bmad-agent-pm` | **3** | sonnet (section only) | PM critic. Requirements/AC surface review |
| `sally` | `~/.claude/agents/sally.md` | `bmad-agent-ux-designer` | **3** | sonnet (section only) | UX critic. UI design surface review (UI stories only) |

**폐기 persona (v2):**
- `quinn` — BMAD 공식 없음. dev가 QA 흡수.
- `bob` / `analyst` / `tech-writer` — Party Mode scope 밖. 필요 시 별도 plan으로 재도입.

PROHIBITION: Never spawn agents as `critic-a`, `critic-b`, `critic-c` or any generic name.

### Agent Spawn Template

Every agent MUST be spawned with this structure:

**MANDATORY party-log rule (v4.4):**
Critics MUST write their review to a party-log FILE using the Write tool BEFORE sending SendMessage.
Path: `_bmad-output/phase-{N}/party-logs/story-{id}-phase-{phase}-{critic-name}.md`
Include: D1-D6 scores with rationale, referenced file paths from the diff, inline code quotes (`backticks`), verdict.
Minimum: 1500B, 20+ lines, 3+ D-score references, 2+ code quotes.
SendMessage는 party-log 파일 경로만 전달. 리뷰 내용은 파일에.
오케스트레이터가 직접 party-log를 작성하면 = 기만 행위. 절대 금지.

```
# v2 소환 template — Claude Code Task tool 사용
Task(
  subagent_type: "{winston|dev|john|sally}",   # model은 wrapper frontmatter가 결정
  description: "{3-5 word summary}",
  prompt: """
You are {NAME} in team \"{team_name}\". Role: {Writer|Critic}.
Expertise: wrapper가 archive persona 참조.
Rubric: _bmad-output/critic-rubric.md v2.0 (10점 척도, PASS ≥ 7.0).
Refs: {요약된 필요 파일들만. Tier 3은 section prompt만 inline}.
Output: Write party-log to _bmad-output/phase-{N}/party-logs/story-{id}-phase-{x}-{name}.md
        with D1-D7 scores + rationale + file:line refs + verdict.
"""
)
```

※ v2부터 `_bmad/bmm/agents/*.md` 직접 Read 지시 금지. wrapper가 자체 persona 정의를 포함하고 있음.
※ Tier 1 (winston/dev): full context 주입 가능.
※ Tier 3 (john/sally): **full file read 금지**. 섹션 prompt만 inline (requirements/AC for john, screen-layout/interaction for sally).

---

## Grade별 리뷰 구성

**Grade-differentiated model assignment:**

| Role | Model | Rationale |
|------|-------|-----------|
| Orchestrator (kdh-go, pipeline) | opus | Complex judgment, state management, CEO communication |
| Dev agent (builder) | sonnet | Best coding model, fast, validated in Sprint 0 |
| Critics — Grade A (Planning) | opus | winston(Arch, Tier 1 Opus) + dev(writer+QA, Tier 1 Opus) + john(PM, Tier 3 Sonnet section only), 3명 병렬. DA = fresh instance (기존 3명 겸임 금지) |
| Critics — Grade B (Planning) | sonnet | winston(Tier 1 Opus) + dev(Tier 1 Opus) + john(Tier 3 Sonnet section only), 3명. 일괄 리뷰 |
| Critics — Grade A (Sprint Dev) | opus | 기존 유지 (3명) |
| Critics — Grade B (Sprint Dev) | sonnet | 기존 유지 (3명) |
| Critics — Grade C (setup) | N/A | Writer Solo, no critics |
| Codex (second opinion) | GPT-5.4 | External model, independent perspective |
| Gemini (second opinion) | Gemini 3.1 Pro | Parallel with Codex, additional perspective |

**haiku 절대 금지 (CEO 규칙).**

| Grade | Max Retries | When |
|-------|-------------|------|
| **A** (critical) | 3 | Core decisions, functional/nonfunctional reqs, architecture patterns |
| **B** (important) | 2 | Most content steps |
| **C** (setup) | 1 | init, complete, routine validation |

**Grade C = Writer Solo.** Grade C steps (init, complete) skip party mode entirely. Writer executes alone, no critic review needed.

---

## Planning Mode: Stage-Batch (v10.4)

**v10.4 변경 (CEO 승인 2026-04-03):** 기존 "step당 party mode"에서 "stage 일괄 작성 + 일괄 리뷰"로 전환.
근거: Stage 0~2 회고 결과, step당 7~12회 agent spawn이 오케스트레이터 병목 유발.

```
Phase A: Stage Worker가 전체 steps 작성 (spawn 1회)
  - BMAD step file 순서대로 읽고 → output doc에 APPEND
  - frontmatter stepsCompleted 매 step 업데이트
  - GATE steps 도달 시: [GATE] 마크 → 오케스트레이터가 CEO에게 전달
  - 완료 후 SendMessage [Stage Draft Complete]

Phase B: 병렬 독립 리뷰 (spawn 3회, 한 메시지로 동시)
  - winston(Arch, **Tier 1 Opus**, ~/.claude/agents/winston.md): 아키텍처 정합성, 스키마 정확성, 일관성
  - dev(writer+QA, **Tier 1 Opus**, ~/.claude/agents/dev.md): Phase B에서는 writer. Phase B 재검토 시에는 self-review(tsc clean + coverage ≥80%) + 엣지케이스/보안. (v2: 기존 quinn QA 흡수)
  - john(PM, **Tier 3 Sonnet** section-only, ~/.claude/agents/john.md): 제품 요구사항 커버리지, AC 추적, 사용자 가치 — Requirements + AC 섹션만 prompt inline (full file read 금지)
  - 각자 party-log 작성 (D1-D6 scoring, 전문 영역 집중)
  - ★ 리뷰 중 서로 대화 없음 (독립성 보장 = 편향 방지)

Phase C: 상호 검증 — Cross-Validation (spawn 추가 없음)
  - 각 critic이 다른 2명의 party-log 파일을 Read tool로 읽기
  - 자신의 party-log에 "## Cross-Validation" 섹션 추가:
    - 동의하는 발견 1개 (구체적 근거 + 라인 참조)
    - 반박하는 발견 1개 (구체적 근거 + 대안)
  - ★ 파일 기반 — SendMessage 불필요, 오케스트레이터 중계 불필요

Phase D: 오케스트레이터 후처리 (spawn 0)
  - 3개 party-log 읽기 → 이슈 우선순위 정리
  - Score 계산: avg >= threshold?
  - FAIL: fixes 목록 작성 → Stage Worker에게 전달 (SendMessage)
    → Stage Worker fixes 적용 → Phase B 반복 (max retries: Grade A=2, Grade B=1)
  - PASS: Phase E로 (Grade A) 또는 Phase F로 (Grade B)
  ★ Planning Grade A 1-cycle 예외: Cycle 1 avg ≥ 8.0 PASS 시, Cycle 2 스킵하고 Phase E(DA)로 바로 진행 가능.
    단, compliance YAML에 `single_cycle_pass: true` + `ceo_approved: [날짜]` 기록 필수.
    Sprint Dev에는 적용 안 됨 — Sprint Dev Grade A는 무조건 2 cycles.

Phase E: DA — Grade A만 (spawn 1회, ★ FRESH INSTANCE 필수)
  - ★ 기존 3명(winston/dev/john) 중 아무도 아닌 완전히 새로운 에이전트 (v2: quinn 폐기)
  - ★ 이전 리뷰 결과 접근 금지 (party-log 읽기 금지)
  - PRD EARS 요구사항 + DoD 기준으로만 검증
  - ≥3 이슈 필수 (0 이슈 = suspicious, 오케스트레이터 직접 리뷰)
  - DA fixes → Stage Worker 적용

Phase F: 최종 검증 + 커밋 (spawn 0)
  오케스트레이터 직접 파일 확인 (Grep + Read):
  - [ ] steps content 완전, stepsCompleted 완전
  - [ ] 3개 party-log 존재 + ## Cross-Validation 섹션 각각 존재
  - [ ] Grade A: DA 파일 존재 (≥3 이슈)
  - [ ] fixes.md 존재, avg >= threshold (A: 8.0 / B: 7.5)
  - [ ] GATE decisions + Context snapshot + Compliance YAML 기록됨
  - [ ] 연속 Stage 위반 체크 완료
  Stage commit: `docs(planning): Stage N complete — avg X.XX, fixes N rounds, agreement N/3`
  → 모든 체크 통과 → git commit → 다음 Stage
  → 하나라도 실패 → REJECT (조건부 PASS 금지)
```

---

## Sprint Dev Mode: Per-Step (v10.3)

Sprint Dev(Story 단위) 실행 시에는 기존 per-step 프로토콜 유지.
Planning(Stage 단위)만 v10.4 적용.
각 Story의 Phase A/B/C/D/F별로 party mode 실행 (step 단위).

---

## Party-log Rules

**MANDATORY (v4.4):**
- Critics MUST write party-log FILE with Write tool BEFORE SendMessage
- Path: `_bmad-output/phase-{N}/party-logs/story-{id}-phase-{phase}-{critic-name}.md`
- Minimum: 1500B, 20+ lines, 3+ D-score references, 2+ code quotes
- SendMessage는 party-log 파일 경로만 전달

**Phase transition verification (v4.4):**
오케스트레이터는 Phase 전환 전에 반드시:
1. 해당 Phase의 모든 critic party-log 파일 존재 확인 (Glob)
2. 각 파일이 1500B 이상인지 확인
3. 파일이 없거나 크기 부족 → critic에게 재작성 요청
4. 오케스트레이터가 직접 party-log를 작성하면 = 기만 행위. 절대 금지.

---

## Party-log Naming Standard (v10.1)

Two patterns only. Everything else is wrong.

**Story Dev (Sprint execution):**
```
story-{story-id}-phase-{a|b|c|d|f}-{critic-name}.md     # critic review
story-{story-id}-phase-{X}-fixes.md                      # Writer fixes
story-{story-id}-phase-{X}-devils-advocate.md             # DA cycle
story-{story-id}-codex.md                                 # Codex result
```
Examples: `story-1-1-phase-b-winston.md`, `story-1-1-phase-d-fixes.md`

**Planning (Stages 0-8):**
```
stage-{N}-step-{NN}-{critic-name}.md                     # critic review
stage-{N}-step-{NN}-fixes.md                             # Writer fixes
stage-{N}-step-{NN}-gate-draft.md                        # GATE draft
```
Examples: `stage-0-step-02-winston.md`, `stage-2-step-05-fixes.md`

Pre-commit hook validates these patterns. Non-conforming filenames are ignored by the hook.

---

## Party-log Verification (v9.1)

Orchestrator validates ALL critic logs + fixes.md exist before accepting [Step Complete]:
```
1. For each critic in team: check file exists using naming standard above
2. Check fixes log exists
3. If ANY file missing → REJECT [Step Complete], request missing critic to write their log
4. Only accept [Step Complete] when ALL files verified
```

---

## 리뷰 수용 규칙 (superpowers receiving-code-review 기반)

critic 피드백을 받으면 반드시 6단계를 따른다:

1. 전체 읽기
2. 내 말로 정리
3. 코드베이스 검증 (Grep, Read)
4. 기술적 평가
5. 수용 or 반박 (근거 필수)
6. 구현

<HARD-GATE>
critic 피드백을 검증 없이 무조건 수용 금지.
"네 맞아요 고치겠습니다"만으로는 안 됨. 코드베이스 검증(3번) 결과로 설명해야 함.
critic 피드백을 무시하는 것도 금지. 반박하려면 기술적 평가(4번) 근거 필수.
</HARD-GATE>

---

## Spawn 수 비교 (v10.3 vs v10.4)

| Grade | v10.3 (per-step) | v10.4 (per-stage) | 감소 |
|-------|-----------------|-------------------|------|
| C | 0 | 0 | — |
| B (6 steps) | 6×7=42 | 1+3+1=5 | 88% |
| A (4 steps) | 4×12=48 | 1+3+3+1+1=9 | 81% |

---

## 절대 규칙 (v10.4)

37. **조건부 PASS 금지.** avg < threshold = FAIL. "다음 Stage에서 해결" 미루기 금지.
38. **DA는 반드시 fresh instance.** 기존 critic(winston/dev/john/sally) 겸임 금지. 이전 리뷰 맥락 0인 새 에이전트만. DA 미실행 시 compliance YAML에 `da_skipped: true` + `da_skip_reason` 필수 기록. (v2 2026-04-17: quinn 폐기)
39. **Cross-Validation은 독립 리뷰 후.** 리뷰 중 대화(cross-talk) 금지. 독립 리뷰 완료 → 파일 기반 상호 검증.
40. **Critic 전문 영역 집중.** winston=아키텍처, dev=구현+QA/coverage (v2 quinn 흡수), john=제품/요구사항/AC, sally=UX/UI(UI stories only).
