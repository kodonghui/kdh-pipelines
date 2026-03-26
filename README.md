# KDH Pipeline Suite

Universal full-auto pipelines for AI-powered software development. Built on the BMAD Method + Claude Code.

## Pipelines

| Pipeline | Command | Description |
|----------|---------|-------------|
| Full Auto | `/kdh-full-auto-pipeline` | Planning → Story Dev → Parallel → Swarm. 9-stage BMAD planning with party mode. |
| UXUI Redesign | `/kdh-uxui-redesign-full-auto-pipeline` | 6-phase design system generation + page rebuild. Multi-theme. |
| Code Review | `/kdh-code-review-full-auto` | 8-phase review: Static → Visual → Risk → 3-Critic Party → Fix → Re-Review. |
| E2E Testing (TMUX) | `/kdh-playwright-e2e-full-auto-24-7-tmux` | 4-agent parallel E2E testing loop. For VPS/tmux. |
| E2E Testing (VS) | `/kdh-playwright-e2e-full-auto-24-7-vs` | Single-agent sequential E2E testing loop. For VSCode. |

## Prerequisites

1. **Claude Code** (CLI) — [Install](https://docs.anthropic.com/en/docs/claude-code)
2. **BMAD Method** — `npx bmad init` in your project
3. **Playwright MCP** (optional) — for E2E/UXUI pipelines. Configure in `.mcp.json`

## Installation

### Option A: Clone into your project
```bash
git clone https://github.com/kodonghui/kdh-pipelines.git
# Copy pipelines/ and core/ to your .claude/skills/ or project root
```

### Option B: Direct copy
Download and extract to your project's skill directory.

## Project Setup

1. Copy `presets/example.yaml` to `presets/my-project.yaml`
2. Fill in your project-specific values (site URL, credentials, theme keywords)
3. Run any pipeline: `/kdh-full-auto-pipeline planning`

## Architecture

```
kdh-pipelines/
  core/                    # Shared protocols (referenced by all pipelines)
    party-mode.md          # Party Mode: cross-talk, scoring, Devil's Advocate
    scoring.md             # Grade A/B/C system + Score Variance Check
    agent-roster.md        # BMAD agent name mapping
    project-scan.md        # Step 0: Universal project auto-scan
    ecc-integration.md     # ECC v1.9.0 integration mapping (NEW)
  pipelines/               # Individual pipeline definitions
    full-auto.md
    uxui-redesign.md
    code-review.md
    e2e-tmux.md
    e2e-vs.md
  presets/                 # Project-specific configurations
    example.yaml           # Template — copy and customize
  README.md
```

## Core Concepts

### Party Mode
Every critical step goes through multi-critic review:
1. Writer writes → sends [Review Request]
2. 3-5 Critics review independently → write party-logs
3. Cross-talk round: critics discuss disagreements
4. Writer applies fixes → critics verify → score
5. Score >= threshold → PASS

### Step Grades
- **Grade A** (critical): 3 retries, 2 review cycles minimum, Devil's Advocate
- **Grade B** (important): 2 retries, 1 cycle + cross-talk
- **Grade C** (setup): Writer Solo, no review needed

### BMAD Agents
All agents use real BMAD personas (not generic names):
- `winston` — Architect (distributed systems, API design)
- `quinn` — QA Engineer (testing, edge cases, coverage)
- `john` — Product Manager (requirements, user value)
- `sally` — UX Designer (interaction design, accessibility)
- `bob` — Scrum Master (sprint planning, delivery risk)
- `dev` — Developer (implementation, code quality)

## ECC Integration (v1.9.0)

All pipelines are enhanced with [ECC v1.9.0](https://github.com/affaan-m/everything-claude-code) components:

| ECC Component | Pipelines | Purpose |
|--------------|-----------|---------|
| `santa-method` | Full-Auto, Code-Review | Adversarial 2-agent verification after party mode PASS |
| `click-path-audit` | All | Detect Phantom Success (toast without DB write), Sequential Undo |
| `verification-loop` | Full-Auto, Code-Review | 6-phase deterministic gate (Build→Type→Lint→Test→Security→Diff) |
| `search-first` | Full-Auto | Research existing solutions before writing new code |
| `tdd-workflow` | Full-Auto, UXUI | RED→GREEN→REFACTOR, 80%+ coverage enforcement |
| `browser-qa` | Code-Review, UXUI, E2E | 4-phase browser testing protocol |
| `security-review` | Code-Review, Full-Auto | 46+ vulnerability patterns, OWASP Top 10 |
| `build-error-resolver` | Code-Review, E2E | Minimal-diff automated build error resolution |
| `continuous-learning-v2` | All | Automatic pattern extraction → instinct → evolved skills |
| `design-system` | UXUI | Visual audit + AI slop detection |
| `synthesis-master` | UXUI | LibreUIUX plugin orchestration |

ECC enhancements are **additive** — they supplement BMAD agents and party mode, never replace them. For details, see [core/ecc-integration.md](core/ecc-integration.md).

## License

MIT
