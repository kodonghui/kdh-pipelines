# KDH Pipeline Suite

> Universal full-auto pipelines for AI-powered software development.
> Planning, Sprint Dev, Code Review, E2E Testing, Harness Engineering.

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

## Contents

| Directory | Count | Description |
|-----------|-------|-------------|
| `skills/` | 15 kdh + 18 utility | Pipeline skills + utility commands |
| `agents/` | 33 | Specialized review/build/planning agents |
| `rules/` | 12 dirs | Language-specific coding rules |
| `hooks/` | 4 | Party Mode nudge, pipeline guard, loop detector, env verify |
| `templates/` | 2 | Feature checklist, critic rubric |
| `core/` | 6 | Pipeline core documentation |
| `docs/` | 3+ | Harness guide, research reports |
| `presets/` | 2 | Project-specific config examples |

## Key Commands

| Command | Description |
|---------|-------------|
| `/kdh-full-auto-pipeline` | Master pipeline — auto/planning/sprint/story |
| `/kdh-build` | Single story builder (TDD) |
| `/kdh-review` | Story reviewer (party mode) |
| `/kdh-research` | Deep multi-source research |
| `/save-session` / `/resume-session` | Session state persistence |

## Harness Improvements (v10.2)

1. **Loop Detector** — file edit counter, warns at 5, escalates at 8
2. **Env Verify** — auto-check DB/tsc/Bun at session start
3. **Feature Checklist** — JSON-based feature pass/fail tracking
4. **Hook Profiles** — minimal/standard/strict modes
5. **TeammateIdle Hook** — auto-nudge idle Party Mode agents

## Repository Structure

```
kdh-pipelines/
├── README.md
├── skills/
│   ├── kdh-full-auto-pipeline/    # Master pipeline (THE command)
│   ├── kdh-build/                 # Story builder (TDD)
│   ├── kdh-review/                # Story reviewer (party mode)
│   ├── kdh-sprint/                # Sprint orchestrator
│   ├── kdh-plan/                  # Planning pipeline
│   ├── kdh-e2e/                   # E2E browser testing
│   ├── kdh-gate/                  # CEO decision protocol
│   ├── kdh-research/              # Deep research
│   ├── kdh-go/                    # Entry dispatcher
│   ├── kdh-help/                  # Help & guide
│   ├── kdh-integration/           # Integration testing
│   ├── kdh-code-review-full-auto/ # Universal PR code review
│   ├── kdh-ecc-3h/                # 3h ECC session
│   ├── kdh-ecc-12h/               # 12h ECC session
│   ├── kdh-playwright-e2e-full-auto-24-7-tmux/
│   ├── save-session/              # Session persistence
│   ├── resume-session/
│   ├── kdh-discuss/               # CEO discussion partner v2
│   ├── plan/ verify/ checkpoint/
│   ├── learn/ learn-eval/ evolve/
│   ├── instinct-status/ instinct-export/ instinct-import/
│   ├── prune/ promote/ dream/ claw/ aside/ docs/
├── agents/                        # 33 specialized agents
├── rules/                         # Language coding rules
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
├── core/                          # Pipeline core docs
│   ├── party-mode.md
│   ├── scoring.md
│   ├── agent-roster.md
│   ├── project-scan.md
│   ├── e2e-gate.md
│   └── ecc-integration.md
├── docs/
│   ├── harness-guide.md
│   └── research/
│       ├── harness-adoption-analysis-2026-04-02.md
│       ├── harness-benchmarks-2026-04-02.md
│       └── harness-engineering-2026-04-02.md
└── presets/                       # Project-specific configs
```

## Party Mode (Multi-Critic Review)

Every story goes through D1-D6 rubric-enforced peer review:

```
/kdh-build (Generator)
    ↓
/kdh-review (Evaluator — different agent!)
    ├── winston: Architecture + security
    ├── quinn: QA + test quality
    └── john: Product requirements
    ↓
    Cross-talk → D1-D6 weighted score
    ≥ 7.5 → PASS | 6.0-7.5 → CONDITIONAL | < 6.0 → FAIL
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| **v10.2** | 2026-04-02 | Full sync: 33 agents, 12 rule dirs, 4 hooks, harness v10.2 |
| v10.1 | 2026-03-31 | D1-D6 rubric enforced, auto-fail gate, pipeline guard hook |
| v10.0 | 2026-03-31 | Complete redesign: 1 monolith → 15 skills, Generator≠Evaluator |

## License

MIT
