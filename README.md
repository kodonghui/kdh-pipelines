# KDH Pipeline Suite v11.0

> 3 파이프라인 + 4 명령어 + ECC 자동화 = AI 에이전트 개발 풀스택 하네스

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    4-Command Workflow                        │
│   discuss → research → analyze → plan                       │
└───────────────────┬─────────────────────────────────────────┘
                    │
          ┌─────────▼──────────┐
          │  kdh-planning-     │  Grade A (opus)
          │  pipeline v10.5    │  CEO 승인 필요
          └─────────┬──────────┘
                    │  approved plan
          ┌─────────▼──────────┐
          │  kdh-dev-pipeline  │  Grade B (sonnet)
          │  v11.0             │  Party Mode: winston + quinn
          └─────────┬──────────┘
                    │  bugs / regressions
          ┌─────────▼──────────┐
          │  kdh-bug-fix-      │  Grade B (sonnet)
          │  pipeline v2.0     │  browser-use 중심
          └─────────┬──────────┘
                    │  escalation (complex bugs)
                    └──────────► kdh-planning-pipeline
```

The three pipelines are interconnected via `_bmad-output/pipeline-protocol.md`.
Bugs that exceed complexity thresholds escalate from bug-fix → planning for proper scoping.

---

## 3 Pipelines

| Pipeline | Command | Version | Purpose |
|----------|---------|---------|---------|
| **kdh-planning-pipeline** | `/kdh-planning-pipeline` | v10.5 | Feature planning, PRD, architecture, task breakdown. CEO approval gate. |
| **kdh-dev-pipeline** | `/kdh-dev-pipeline` | v11.0 | Story implementation. TDD + Party Mode (winston+quinn). 4-Phase A→B→D→Codex. |
| **kdh-bug-fix-pipeline** | `/kdh-bug-fix-pipeline` | v2.0 | Bug triage, browser-use E2E verification, origin classification, escalation routing. |

### Pipeline Interconnection

- Dev → Bug Fix: Sprint End triggers mandatory full sweep
- Bug Fix → Planning: Complex bugs (origin=design/spec) escalate to planning
- Planning → Dev: Approved plan → Sprint kick-off

---

## 4-Command Workflow (discuss → research → analyze → plan)

All feature work starts with 4 preparatory commands before entering a pipeline:

| Command | Skill | Purpose |
|---------|-------|---------|
| `/kdh-discuss` | `kdh-discuss` | CEO와 기능 방향 논의. 요구사항 명확화. |
| `/kdh-research` | `kdh-research` | 기술 조사. GitHub/docs/Exa 다층 검색. |
| `/kdh-analyze` | `kdh-analyze` | 코드베이스 분석. 영향 범위 + 의존성 매핑. |
| `/kdh-plan` | `kdh-plan` | 실행 계획 생성. CEO 보고 후 승인 필요. |

After `/kdh-plan` produces a plan, it must be **reported to CEO in chat** before pipeline execution begins.

---

## ECC (Everything Claude Code) Automation

Two automated maintenance cycles keep the harness sharp:

### 3h Maintenance (`/kdh-ecc-3h`)
- Runs every 3 hours
- Health checks: tsc, DB, env, hook integrity
- Auto-fix minor drift (deps, config, formatting)
- Logs to `_bmad-output/update-log/`

### 12h Learn + Evolve (`/kdh-ecc-12h`)
- Runs every 12 hours (6-phase pipeline)
- Phase 1: Session state snapshot
- Phase 2: Pattern learning from recent stories
- Phase 3: Skill gap analysis
- Phase 4: Instinct update (`instinct-export` → evolve → `instinct-import`)
- Phase 5: ECC integration test
- Phase 6: Report + promote

---

## Quick Start

```bash
# Add as git submodule to any project
git submodule add https://github.com/kodonghui/kdh-pipelines.git _pipeline

# Install skills
cp -r _pipeline/skills/* ~/.claude/skills/

# Install agents
cp -r _pipeline/agents/* ~/.claude/agents/

# Install rules (pick your language)
cp -r _pipeline/rules/common ~/.claude/rules/common
cp -r _pipeline/rules/typescript ~/.claude/rules/typescript

# Install hooks
cp _pipeline/hooks/* .claude/hooks/
```

---

## Skills Inventory

### Core Pipelines (3)

| Skill | Version | Description |
|-------|---------|-------------|
| `kdh-planning-pipeline` | v10.5 | Feature planning — PRD, arch, task list. Grade A critics. |
| `kdh-dev-pipeline` | v11.0 | Story dev — A→B→D→Codex phases. Anti-Pattern guards. |
| `kdh-bug-fix-pipeline` | v2.0 | Bug triage + browser-use E2E. Loop detection, dedup, metrics. |

### 4-Command Workflow (4)

| Skill | Description |
|-------|-------------|
| `kdh-discuss` | CEO discussion partner. Direction clarification. |
| `kdh-research` | Multi-source research (GitHub → docs → Exa). |
| `kdh-analyze` | Codebase analysis. Impact + dependency mapping. |
| `kdh-plan` | Plan generation. CEO report required before execution. |

### ECC Automation (2)

| Skill | Description |
|-------|-------------|
| `kdh-ecc-3h` | 3h maintenance cycle. Health checks + auto-fix. |
| `kdh-ecc-12h` | 12h learn+evolve cycle. 6-phase instinct pipeline. |

### Utility Commands (6)

| Skill | Description |
|-------|-------------|
| `kdh-help` | Help and command guide. |
| `kdh-study` | FSRS-based learning. Quiz 4-type + dashboard. |
| `kdh-claude-md` | CLAUDE.md authoring + enforcement. |
| `kdh-folder-organize` | Project structure organization. |
| `save-session` | Session state persistence. |
| `resume-session` | Session state restore. |

### Learning & Instinct (6)

| Skill | Description |
|-------|-------------|
| `learn` | Pattern extraction from story outcomes. |
| `learn-eval` | Learning quality evaluation. |
| `evolve` | Instinct evolution from learned patterns. |
| `instinct-status` | Current instinct state dashboard. |
| `instinct-export` | Export instincts to file. |
| `instinct-import` | Import instincts from file. |

### Management Utilities (7)

| Skill | Description |
|-------|-------------|
| `plan` | Low-level plan primitive. |
| `verify` | Verification gate. |
| `checkpoint` | Mid-story checkpoint. |
| `promote` | Promote pattern to instinct. |
| `prune` | Remove stale instincts/patterns. |
| `aside` | Side-channel note capture. |
| `claw` | Deep codebase analysis. |
| `dream` | Creative/exploratory ideation. |
| `docs` | Documentation generation. |

### Project-Specific (1)

| Skill | Description |
|-------|-------------|
| `corthex-v3-patterns` | CORTHEX v3 project patterns reference. |

---

## Party Mode

Every story's Phase B and D require 2-critic party mode review:

```
/kdh-dev-pipeline (Generator — Phase A: implement)
    ↓
Phase B (Party Review — 2 critics required)
    ├── winston: Architecture + security
    └── quinn: QA + test quality
    ↓
    Cross-talk → D1-D6 weighted score
    ≥ 7.5 → PASS | 6.0-7.5 → FAIL (CONDITIONAL_PASS banned)
    ↓
Phase D (Party Review — 2 critics required, same format)
    ↓
Codex (mandatory, 1 per story)
```

**Rules:**
- CONDITIONAL_PASS is banned — score must be ≥ 7.5 or it's a FAIL
- Planning critics: Grade A (opus)
- Dev/Bug Fix critics: Grade B (sonnet)
- `john` (product critic) was removed — 2 critics only (winston + quinn)
- Party logs without 2 named critics block the pre-commit hook

---

## Pre-Commit Hook (v4.2)

The hook enforces pipeline integrity on every commit:

| Check | Blocks If |
|-------|-----------|
| Party Mode | `<2` named critics in party-log |
| Codex | No PASS log for current story |
| UI stories | No `subframe-design.md` |
| TypeScript | `tsc` fails on any package |
| CLAUDE.md | File modified without explicit plan |
| State | `pipeline-state.yaml` missing or null story |

`--no-verify` is banned. No bypass exists.

---

## Repository Structure

```
kdh-pipelines/
├── README.md
├── skills/
│   ├── kdh-planning-pipeline/   # Planning pipeline v10.5
│   ├── kdh-dev-pipeline/        # Dev pipeline v11.0
│   ├── kdh-bug-fix-pipeline/    # Bug fix pipeline v2.0
│   ├── kdh-discuss/             # 4-cmd: discuss
│   ├── kdh-research/            # 4-cmd: research
│   ├── kdh-analyze/             # 4-cmd: analyze
│   ├── kdh-plan/                # 4-cmd: plan
│   ├── kdh-ecc-3h/              # ECC 3h maintenance
│   ├── kdh-ecc-12h/             # ECC 12h learn+evolve
│   ├── kdh-help/                # Help & guide
│   ├── kdh-study/               # FSRS learning
│   ├── kdh-claude-md/           # CLAUDE.md authoring
│   ├── kdh-folder-organize/     # Folder structure
│   ├── save-session/            # Session persistence
│   ├── resume-session/          # Session restore
│   ├── learn/ learn-eval/ evolve/
│   ├── instinct-status/ instinct-export/ instinct-import/
│   ├── plan/ verify/ checkpoint/
│   ├── promote/ prune/ aside/ claw/ dream/ docs/
│   ├── corthex-v3-patterns/     # Project patterns
│   └── kdh-full-auto-pipeline/  # [LEGACY — do not use]
├── agents/                      # 33 specialized agents
├── rules/                       # Language coding rules
│   ├── common/
│   ├── typescript/ python/ golang/ rust/
│   ├── swift/ kotlin/ java/ cpp/ php/ perl/ csharp/
├── hooks/
│   ├── party-mode-nudge.sh
│   ├── pipeline-guard.sh
│   ├── loop-detector.js
│   └── verify-env.sh
├── templates/
│   ├── feature-checklist.json
│   └── critic-rubric.md
├── core/
│   ├── party-mode.md
│   ├── scoring.md
│   ├── agent-roster.md
│   ├── project-scan.md
│   ├── e2e-gate.md
│   └── ecc-integration.md
├── docs/
│   └── research/
└── presets/
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| **v11.0** | 2026-04-08 | 3-pipeline interconnection via protocol doc; kdh-bug-fix-pipeline v2.0 (origin classification, escalation routing, loop detection, dedup, metrics); kdh-planning-pipeline v10.5 (Anti-Pattern #15/#16, bias detection, trajectory log); kdh-dev-pipeline v11.0 (Anti-Pattern #6/#7, trajectory checklist); 4-cmd workflow hardened; ECC v2 (6-phase 12h); CONDITIONAL_PASS banned; john critic removed |
| v10.2 | 2026-04-02 | Full sync: 33 agents, 12 rule dirs, 4 hooks, harness v10.2 |
| v10.1 | 2026-03-31 | D1-D6 rubric enforced, auto-fail gate, pipeline guard hook |
| v10.0 | 2026-03-31 | Complete redesign: 1 monolith → 15 skills, Generator≠Evaluator |

---

## License

MIT
