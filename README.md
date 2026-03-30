# KDH Pipeline Suite

**AI-powered software development pipelines for Claude Code.** Built on [BMAD Method](https://github.com/bmadcode/BMAD-METHOD) + [Everything Claude Code](https://github.com/affaan-m/everything-claude-code).

5 pipelines that automate the entire software lifecycle — from product brief to E2E testing — using multi-agent teams with real-time peer review.

---

## Why This Exists

AI coding tools are great at writing individual features. But they consistently fail at **integration** — connecting features across packages, maintaining type contracts, and catching bugs that only appear when components interact.

After building 167 features (29 epics) for a production monorepo, we found 29 integration bugs that unit tests and `tsc` couldn't catch. Every bug had the same root cause: **no enforced contract between frontend and backend**.

These pipelines solve that by treating AI development like a real engineering team — with planning, peer review, adversarial testing, and automated quality gates at every step.

---

## Pipelines

| Pipeline | Version | Command | What It Does |
|----------|---------|---------|-------------|
| **Full Auto** | v9.4 | `/kdh-full-auto-pipeline` | Complete lifecycle: Planning (9 stages) → Story Dev (6 phases) → Parallel → Swarm |
| **UXUI Redesign** | v7.1 | `/kdh-uxui-redesign-full-auto-pipeline` | Design system generation → page rebuild → visual verification. Multi-theme. |
| **Code Review** | v4.1 | `/kdh-code-review-full-auto` | 8-phase review: Static → Visual → Risk → 3-Critic Party → Santa Method → Fix |
| **E2E Testing (tmux)** | v2.2 | `/kdh-playwright-e2e-full-auto-24-7-tmux` | 4-agent parallel E2E loop. Socrates methodology + 12-Dimension scenarios. |
| **E2E Testing (VS)** | v2.1 | `/kdh-playwright-e2e-full-auto-24-7-vs` | Single-agent sequential E2E. Click-path audit + browser QA. |

### Full Auto Pipeline v9.4 — Highlights

The flagship pipeline. 4 execution modes:

| Mode | Usage | When |
|------|-------|------|
| `planning` | `/kdh-full-auto-pipeline planning` | New project or epic — runs 9 planning stages with party mode |
| `story-ID` | `/kdh-full-auto-pipeline 9-1` | Single story dev — 6 phases (create → dev → simplify → test → QA → review) |
| `parallel` | `/kdh-full-auto-pipeline parallel 9-1 9-2 9-3` | Up to 3 stories in parallel via git worktrees |
| `swarm` | `/kdh-full-auto-pipeline swarm epic-9` | Auto-epic: 3 self-organizing teams, dependency-aware task claiming |

**v9.4 additions:**
- **EARS requirements** — unambiguous requirement syntax in Brief, PRD, Story, and Test phases
- **Contract Stage 6.5** — all API types defined in shared package BEFORE coding begins
- **Wiring Stories** — auto-generated stories for cross-package connections
- **Integration Gate** — cross-package `tsc` + contract compliance check before commit
- **Hono RPC auto-detect** — if your server uses Hono, types flow automatically via `hc<AppType>()`

---

## How It Works

### Party Mode (Multi-Critic Review)

Every important step goes through structured peer review:

```
Writer writes section
    ↓
3-5 Critics review independently (party-logs/*.md)
    ↓
Critics cross-talk: discuss disagreements with peers
    ↓
Writer applies fixes → critics verify → score (1-10)
    ↓
Average >= threshold → PASS
```

- **Grade A** (critical): avg ≥ 8.0, 2 cycles minimum, Devil's Advocate
- **Grade B** (important): avg ≥ 7.5, 1 cycle + cross-talk
- **Grade C** (setup): Writer Solo, no review

### BMAD Agents

All agents use real personas with specialized expertise — not generic "critic-a/b/c":

| Agent | Role | Focus |
|-------|------|-------|
| `winston` | Architect | Distributed systems, API design, scalability |
| `quinn` | QA Engineer | Testing, edge cases, coverage analysis |
| `john` | Product Manager | Requirements, user value, stakeholder alignment |
| `sally` | UX Designer | Interaction design, accessibility, user research |
| `bob` | Scrum Master | Sprint planning, delivery risk, velocity |
| `dev` | Developer | Implementation, code quality, performance |
| `analyst` | Analyst | Research synthesis, data interpretation |
| `tech-writer` | Tech Writer | Documentation, specification clarity |

### Anti-Pattern Defense

14 production-verified failure patterns with automatic prevention:

| # | Pattern | How It's Prevented |
|---|---------|-------------------|
| 1 | Writer calls Skill tool (bypasses review) | Prohibition in spawn prompt |
| 2 | Writer batches steps (skips per-step review) | One step → party mode → next |
| 3 | Generic agent names (loses expertise) | Real BMAD names enforced |
| 4 | Score convergence (rubber-stamp) | Stdev < 0.5 triggers re-scoring |
| 5 | Single-cycle pass (no Devil's Advocate) | Grade A requires 2 cycles minimum |
| 6 | Cross-talk skipped | Logs without `## Cross-talk` = REJECT |
| 7 | Missing party-log files | Orchestrator verifies before ACCEPT |
| 13 | Inline API type duplication | Contract compliance check in Phase F |
| 14 | Missing wiring (module created, never connected) | Wiring Stories auto-generated |

Full list in [pipelines/kdh-full-auto-pipeline.md](pipelines/kdh-full-auto-pipeline.md).

---

## ECC Integration

All pipelines are enhanced with [Everything Claude Code v1.9.0](https://github.com/affaan-m/everything-claude-code) components:

| Component | Purpose | Used By |
|-----------|---------|---------|
| `santa-method` | 2-agent adversarial review (context-isolated) | Full-Auto, Code-Review |
| `click-path-audit` | Phantom Success detection (toast without DB write) | All pipelines |
| `verification-loop` | 6-phase deterministic gate (Build→Type→Lint→Test→Security→Diff) | Full-Auto, Code-Review |
| `tdd-workflow` | RED→GREEN→REFACTOR, 80%+ coverage | Full-Auto, UXUI |
| `browser-qa` | 4-phase browser testing protocol | Code-Review, UXUI, E2E |
| `security-review` | 46+ vulnerability patterns, OWASP Top 10 | Code-Review, Full-Auto |
| `continuous-learning-v2` | Automatic pattern extraction → instinct → skill evolution | All pipelines |
| `design-system` | Visual audit + AI slop detection | UXUI, E2E |

### Phantom Success Defense (6 Layers)

Prevents "UI shows success but nothing actually happened":

| Layer | Where | How |
|-------|-------|-----|
| L1 | Writer Prompt | API Wiring Checklist: success UI must have preceding API call |
| L2 | Pre-commit Hook | `toast-without-api-check.sh` blocks commit |
| L3 | E2E Gate | CRUD → API GET → verify DB persistence |
| L4 | Code Review | Santa Method + Phantom Success rubric |
| L5 | 24/7 E2E | Network request verification on every action |
| L6 | Learning Loop | Pattern → `bug-patterns.yaml` → future prompt injection |

Details in [core/ecc-integration.md](core/ecc-integration.md).

---

## Repository Structure

```
kdh-pipelines/
├── README.md
├── core/                         # Shared protocols (all pipelines reference these)
│   ├── party-mode.md             # Multi-critic review protocol
│   ├── scoring.md                # Grade A/B/C + 6-dimension scoring rubric
│   ├── agent-roster.md           # BMAD agent registry + spawn template
│   ├── project-scan.md           # Step 0: Universal project auto-scan
│   ├── e2e-gate.md               # Story-level browser verification gate
│   └── ecc-integration.md        # ECC v1.9.0 integration mapping
├── pipelines/                    # Pipeline definitions (Claude Code slash commands)
│   ├── kdh-full-auto-pipeline.md           # v9.4 — Planning + Story Dev + Parallel + Swarm
│   ├── kdh-uxui-redesign-full-auto-pipeline.md  # v7.1 — Design system + page rebuild
│   ├── kdh-code-review-full-auto.md        # v4.1 — 8-phase review + Santa Method
│   ├── kdh-playwright-e2e-full-auto-24-7-tmux.md  # v2.2 — 4-agent parallel E2E
│   └── kdh-playwright-e2e-full-auto-24-7-vs.md    # v2.1 — Single-agent sequential E2E
└── presets/                      # Project-specific configurations
    ├── example.yaml              # Template — copy and customize
    └── corthex.yaml              # CORTHEX v2 preset
```

---

## Quick Start

### Prerequisites

1. **Claude Code** (CLI or Desktop) — [Install](https://docs.anthropic.com/en/docs/claude-code)
2. **BMAD Method** (optional but recommended) — `npx bmad init`
3. **Playwright MCP** (for E2E/UXUI pipelines) — configure in `.mcp.json`

### Installation

```bash
# Clone the repo
git clone https://github.com/kodonghui/kdh-pipelines.git

# Copy pipeline files to your Claude Code commands directory
cp kdh-pipelines/pipelines/*.md ~/.claude/commands/

# (Optional) Copy core docs for reference
cp -r kdh-pipelines/core/ ~/.claude/skills/kdh-core/
```

### First Run

```bash
# In your project directory, run Claude Code
claude

# Start planning a new project
> /kdh-full-auto-pipeline planning

# Or develop a specific story
> /kdh-full-auto-pipeline 3-1

# Or run a code review
> /kdh-code-review-full-auto
```

### Project Configuration

```bash
# Copy and customize the preset template
cp kdh-pipelines/presets/example.yaml presets/my-project.yaml
```

The pipeline auto-detects most project settings (Step 0: Project Auto-Scan), but presets let you customize credentials, URLs, and pipeline-specific options.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| **v9.4** | 2026-03-30 | EARS requirements, Contract Stage 6.5, Wiring Stories, Integration Gate, Hono RPC auto-detect |
| v9.2 | 2026-03-22 | Minimum Cycle Check, Devil's Advocate, Score Variance, Orchestrator Checklist |
| v9.1 | 2026-03-18 | Party-log verification, Score convergence detection, Anti-patterns 7-12 |
| v9.0 | 2026-03-10 | Full rewrite: BMAD real names, party mode per step, user gates |

---

## Production Results

Tested on [CORTHEX v2](https://github.com/kodonghui/corthex-v2) — a monorepo with 8 packages, 82 route files, ~543 API endpoints:

- **29 epics, 167 stories** completed through the pipeline
- **10,154+ tests** generated via TDD workflow
- **29 integration bugs** found and fixed (root cause → led to v9.4 Contract Stage)
- **3-theme UXUI redesign** with mobile responsive (43/43 pages PASS)
- **Chrome E2E**: 15-part test suite, all bugs resolved

---

## License

MIT

---

## Credits

- [BMAD Method](https://github.com/bmadcode/BMAD-METHOD) — Multi-agent development methodology
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) — ECC skills and agents
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — Anthropic's CLI for Claude
