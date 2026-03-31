# KDH Pipeline Suite v10.1

**AI-powered software development pipelines for Claude Code.** Built on [BMAD Method](https://github.com/bmadcode/BMAD-METHOD) + [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) + latest research (Superpowers, GSD, Ralph Wiggum, revfactory/harness).

10 modular skills that automate the entire software lifecycle — from product brief to E2E testing — using multi-agent teams with D1-D6 rubric-enforced peer review.

---

## v10: Complete Redesign

v9.x had one 1,060-line monolith skill that was too large for AI to follow reliably. v10 splits it into 7 focused skills (100-300 lines each), with key improvements from 5 research reports:

| Source | What We Took |
|--------|-------------|
| [Superpowers](https://github.com/obra/superpowers) (127k stars) | TDD enforcement (RED-GREEN-REFACTOR) |
| [GSD Framework](https://www.mindstudio.ai/blog/gsd-framework) | Clean context per phase, file-based state |
| [Ralph Wiggum Loop](https://github.com/ErikBjare/are-you-better-than-a-mass-produced-agent) (14.1k stars) | Fresh agent spawn per story |
| [revfactory/harness](https://github.com/revfactory/harness) (1k stars) | 6 team patterns (Pipeline, Producer-Reviewer, etc.) |
| [Anthropic 3-Agent](https://docs.anthropic.com/en/docs/agents) | Generator ≠ Evaluator separation |

### Key Changes from v9.x

| Problem | v9.x | v10 |
|---------|------|-----|
| AI can't follow 1060-line skill | 1 monolith | 7 skills, 100-300 lines each |
| Swarm skipped party mode | Structural flaw | Party mode in dedicated /kdh-review |
| Self-review bias | Same agent builds + reviews | Generator ≠ Evaluator (separate agents) |
| Context pollution | Long-running sessions | Fresh agent per story (Ralph Loop) |
| No E2E verification | Manual only | Automated /kdh-e2e at sprint end |
| User needs 6 commands | 6 skills to learn | `/kdh-go` — one command |

---

## Skills

| Skill | Lines | Pattern | What It Does |
|-------|-------|---------|-------------|
| **`/kdh-go`** | 195 | Dispatcher | **One command to rule them all.** Auto-detects state + CONDITIONAL reviews. |
| **`/kdh-plan`** | 234 | Pipeline | BMAD Stage 0-8 planning with party mode + GATE steps |
| **`/kdh-build`** | 227 | Producer | TDD story implementation (Generator role) + review state pre-check |
| **`/kdh-review`** | 339 | Producer-Reviewer | **D1-D6 rubric-enforced** party mode review + auto-fail gate + re-review loop |
| **`/kdh-sprint`** | 206 | Supervisor | Sprint orchestration + CONDITIONAL hard-blocking + review summary |
| **`/kdh-e2e`** | 243 | Evaluator | Playwright browser testing — 5 user journeys per sprint |
| **`/kdh-gate`** | 86 | Human-in-loop | CEO decision points + review escalation + sprint review reporting |
| **`/kdh-research`** | 59 | Research | Deep multi-source research with citations |
| **`/kdh-code-review-full-auto`** | 1029 | 8-Phase | Universal PR-level code review + auto-fix (separate from /kdh-review) |
| **`/kdh-playwright-e2e-full-auto-24-7-tmux`** | 639 | 24/7 Loop | Continuous E2E testing loop (legacy, use /kdh-e2e for sprints) |

### Skill Interaction Flow

```
/kdh-go (entry point)
  │
  ├─ Planning not done? → /kdh-plan (Stage 0-8, party mode)
  │                          └─ /kdh-gate (CEO decisions)
  │
  └─ Sprint N pending? → /kdh-sprint N
                            │
                            ├─ For each story:
                            │   /kdh-build (TDD: RED→GREEN→REFACTOR)
                            │       ↓
                            │   /kdh-review (3 critics: winston/quinn/john)
                            │       ↓
                            │   PASS → next story
                            │   CONDITIONAL → fix → re-review
                            │   FAIL → escalate
                            │
                            └─ Sprint done → /kdh-e2e (Playwright)
                                               └─ /kdh-gate (CEO browser check)
```

---

## Usage

### For the CEO (2 commands)

```bash
# Daytime — runs next task, pauses at decisions
/kdh-go

# Overnight — auto-selects all decisions, runs until done
/kdh-go 계속
```

### For Developers (individual skills)

```bash
/kdh-plan              # Run planning pipeline
/kdh-build 1-1         # Build story 1-1 with TDD
/kdh-review 1-1        # Review story 1-1 with party mode
/kdh-sprint 1          # Run entire Sprint 1
/kdh-e2e               # Run E2E browser tests
/kdh-research topic    # Deep research on any topic
```

### Overnight Execution (Ralph Loop)

For maximum stability — fresh context every iteration:

```bash
while true; do claude -p "/kdh-go 계속"; sleep 5; done
```

---

## Party Mode (Multi-Critic Review)

Every story goes through structured peer review by BMAD agents:

```
/kdh-build (dev implements)     ← Generator
    ↓ (terminates)
/kdh-review (fresh agents)      ← Evaluator (different agent!)
    ↓
    ├── winston: Architecture review
    ├── quinn: QA + test quality review
    └── john: Product requirements review
    ↓
    Cross-talk (critics discuss disagreements — empty = REJECTED)
    ↓
    D1-D6 weighted average ≥ 7.5 → PASS
    6.0-7.5 → CONDITIONAL (fix → re-review, max 3 attempts)
    < 6.0 → FAIL
    Any dimension < 3 → AUTO-FAIL
    Auto-fail conditions (hallucination, security, build break) → AUTO-FAIL
```

### v10.1: D1-D6 Rubric Enforcement

v10.0 had a generic `Score: X/10` template. Reviewers invented custom dimensions. v10.1 forces the exact 6-dimension rubric from `critic-rubric.md`:

| Dimension | Code Review Focus | Winston (A) | Quinn (B) | John (C) |
|-----------|------------------|-------------|----------|---------|
| D1 Specificity | Test names, error codes, line refs | 15% | 10% | **20%** |
| D2 Completeness | All ACs met, edge cases tested | 15% | **25%** | **20%** |
| D3 Accuracy | Types match contracts, DB matches schema | **25%** | 15% | 15% |
| D4 Implementability | tsc passes, tests pass, wiring works | **20%** | 10% | 15% |
| D5 Consistency | Contract imports, naming conventions | 15% | 15% | 10% |
| D6 Risk Awareness | Security, scalability, deployment | 10% | **25%** | **20%** |

**Key principle: Generator ≠ Evaluator.** The agent that writes code NEVER reviews its own code. This eliminates self-bias (confirmed by Anthropic's 3-agent research).

---

## BMAD Agents

| Agent | Persona | Review Focus |
|-------|---------|-------------|
| `winston` | Architect | API design, DB queries, scalability, security |
| `quinn` | QA Engineer | Test coverage, edge cases, error handling |
| `john` | Product Manager | Requirements, user stories, acceptance criteria |
| `sally` | UX Designer | Interaction design, accessibility |
| `bob` | Scrum Master | Sprint planning, delivery risk |
| `dev` | Developer | Implementation, code quality |
| `analyst` | Analyst | Research, data analysis |

---

## Contract Compliance (v9.4+)

All API types must be defined in `packages/shared/src/contracts/` and imported — never defined inline. This prevents the #1 cause of integration bugs (29 bugs in v2 from type drift).

```typescript
// ✅ ALLOWED
import { Company, CreateCompanyRequest } from '@corthex/shared'

// ❌ FORBIDDEN (auto-FAIL in /kdh-review)
interface Company { id: string; name: string }
```

---

## Repository Structure

```
kdh-pipelines/
├── README.md
├── skills/                       # v10 skill definitions (Claude Code SKILL.md format)
│   ├── kdh-go/SKILL.md          # Entry point — one command
│   ├── kdh-plan/SKILL.md        # Planning pipeline (Stage 0-8)
│   ├── kdh-build/SKILL.md       # Story builder (Generator, TDD)
│   ├── kdh-review/SKILL.md      # Story reviewer (Evaluator, party mode)
│   ├── kdh-sprint/SKILL.md      # Sprint orchestrator
│   ├── kdh-e2e/SKILL.md         # E2E browser testing
│   ├── kdh-gate/SKILL.md        # CEO decision protocol
│   ├── kdh-research/SKILL.md    # Deep research
│   ├── kdh-code-review-full-auto/SKILL.md  # Universal PR-level code review
│   └── kdh-playwright-e2e-full-auto-24-7-tmux/SKILL.md  # 24/7 E2E loop (legacy)
├── core/                         # Shared protocols (referenced by skills)
│   ├── party-mode.md
│   ├── scoring.md
│   ├── agent-roster.md
│   ├── project-scan.md
│   ├── e2e-gate.md
│   └── ecc-integration.md
└── presets/                      # Project-specific configurations
    ├── example.yaml
    └── corthex.yaml
```

---

## Installation

### As Git Submodule (recommended)

```bash
# In your project root
git submodule add https://github.com/kodonghui/kdh-pipelines.git .kdh-pipelines

# Symlink skills to Claude Code skills directory
for skill in .kdh-pipelines/skills/*/; do
  name=$(basename "$skill")
  ln -sf "$(pwd)/$skill" "$HOME/.claude/skills/$name"
done
```

### Direct Copy

```bash
git clone https://github.com/kodonghui/kdh-pipelines.git
cp -r kdh-pipelines/skills/* ~/.claude/skills/
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| **v10.1** | 2026-03-31 | Quality gate overhaul: D1-D6 rubric enforced, auto-fail gate, CONDITIONAL hard-blocking, cross-talk rejection, review summary reporting. 10 skills. |
| v10.0 | 2026-03-31 | Complete redesign: 1 monolith → 7 skills. Generator≠Evaluator. Fresh context. TDD. /kdh-go one-command. |
| v9.4 | 2026-03-30 | EARS requirements, Contract Stage 6.5, Wiring Stories, Hono RPC |
| v9.2 | 2026-03-22 | Minimum Cycle Check, Devil's Advocate, Score Variance |
| v9.1 | 2026-03-18 | Party-log verification, Anti-patterns 7-12 |
| v9.0 | 2026-03-10 | Full rewrite: BMAD real names, party mode per step |

---

## Research Reports

v10 design was informed by 5 deep research reports:

1. [Agent Harness Engineering](_research/agent-harness-analysis-2026-03-31.md) — Model=CPU, Context=RAM, Harness=OS
2. [Superpowers + GSD + Awesome](_research/superpowers-gsd-awesome-analysis-2026-03-31.md) — TDD, clean context, ecosystem
3. [revfactory/harness](_research/revfactory-harness-analysis-2026-03-31.md) — 6 team patterns, +60% quality
4. [Hermes Agent](_research/hermes-agent-analysis-2026-03-31.md) — Self-improving agent, Telegram integration
5. [Pretext](_research/pretext-analysis-2026-03-31.md) — DOM-free text layout (Phase 2)

---

## Production Results

**CORTHEX v2** (8 packages, 82 routes, ~543 endpoints):
- 29 epics, 167 stories completed
- 10,154+ tests generated via TDD
- 29 integration bugs found → led to Contract Stage 6.5
- 3-theme UXUI redesign (43/43 pages PASS)

**CORTHEX v3** (in progress):
- 7 epics, 47 stories planned (Phase 1)
- 60+ shared contract types defined
- 6 sprints with automated party mode review

---

## License

MIT

---

## Credits

- [BMAD Method](https://github.com/bmadcode/BMAD-METHOD) — Multi-agent development methodology
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) — ECC skills and agents
- [Superpowers](https://github.com/obra/superpowers) — TDD + verification patterns
- [revfactory/harness](https://github.com/revfactory/harness) — Team pattern architecture
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — Anthropic's CLI for Claude
