---
name: kdh-codex-lifecycle
description: "Codex-led lifecycle harness: planning/dev/bugfix/night/QA runs through corthex-v4 life:* with Claude/Gemini/overdesign gates."
---

# kdh-codex-lifecycle

Use this skill when work must run through the CORTHEX V4 program-enforced team lifecycle instead of solo implementation.

## Source Of Truth

- Skill source: `/home/ubuntu/kdh-pipelines/skills/kdh-codex-lifecycle/SKILL.md`.
- Runtime install: `/home/ubuntu/.claude/skills/kdh-codex-lifecycle/SKILL.md`.
- Runner source: `/home/ubuntu/corthex-v4/scripts/lifecycle-runner.ts`.
- Active repo entry point: `/home/ubuntu/corthex-v4/WORKFLOW.md`.

`kdh-codex-delegate` is a legacy CORTHEX v3 Codex exec delegation skill. Keep it available while live references remain.

## Start

```bash
cd /home/ubuntu/corthex-v4
sed -n '1,220p' AGENTS.md
sed -n '1,260p' WORKFLOW.md
git status --short --branch
```

For an existing lifecycle run:

```bash
bun run life:status -- --id <run-id>
bun run life:doctor -- --id <run-id>
bun run life:next -- --id <run-id>
```

For a new lifecycle run:

```bash
bun run life:init -- --id <run-id> --mode full|planning|dev|bugfix|night|qa-loop --goal "<goal>"
```

## Command Surface

- `life:list`: read-only list of lifecycle runs.
- `life:status`: current state, next legal command, missing artifacts.
- `life:doctor`: read-only integrity and stale/degraded diagnostics.
- `life:recover`: explicit state/event recovery and lock-contention promotion.
- `life:handoff`: write or send the next role prompt.
- `life:complete`: complete the active step with evidence.
- `life:stale`: mark the active step stale with reason/action.
- `life:stop`: abort a run at an explicit stop condition.
- `life:night-check`: apply night stale halt when approved by diagnostics.
- `life:gate-check`: validate CEO-gated architecture/runtime/resource changes.
- `life:coverage`: compare board PROPOSED rows against implementation coverage.
- `life:validate`: final completion gate for a lifecycle run.

## Team Contract

- Codex owns conductor, implementation, integration, runner changes, and verification logs.
- Claude owns architecture, design synthesis, Claude Design reasoning, and documentation synthesis.
- Gemini owns adversarial review, QA sweep, edge cases, and contradiction hunting.
- overdesign-critic owns simplicity review and blocks premature ceremony.

Do not fabricate Claude, Gemini, or overdesign party logs. If real reviewer artifacts are unavailable, use an explicit `solo-skip` note and explain why.

Reviewer party logs for non-solo completion include:

```md
## Agent Context
instance_id: <provider-session-or-agent-id>
timestamp: <ISO8601>
runner_session_correlation: <run-id>/<step-id>/<agent>
```

## Stop Conditions

Stop and report before:

- deployment, DB/domain, publishing, trading, stock work, or production action,
- real provider OAuth/runtime execution without a separate CEO gate,
- destructive filesystem operations,
- repeated verification failure,
- missing required lifecycle evidence,
- state/event mismatch that `life:doctor` or `life:recover` cannot resolve.

## Deferred

Do not promote these without a separate board or CEO gate:

- `life:watch`
- `life:hooks-export`
- rollback automation
- heartbeat daemon
- PKI/global ledger
