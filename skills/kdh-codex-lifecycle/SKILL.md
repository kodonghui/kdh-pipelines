---
name: kdh-codex-lifecycle
description: "Codex-led lifecycle harness: planning/dev/bugfix/night/QA runs through corthex-v4 life:* with Claude/Gemini/overdesign gates."
---

# kdh-codex-lifecycle

Use this skill when work must run through the CORTHEX V4 program-enforced team lifecycle instead of solo implementation.

## Session Hygiene

- Spawn lifecycle workers in high-autonomy mode: Claude in auto mode, Gemini in YOLO/no-sandbox mode, and Codex workers with `codex exec --full-auto` only when Codex worker delegation is explicitly authorized.
- Spawned lifecycle workers must not create recurring cron/scheduled tasks, invoke conductor resume/save bootstraps, or run conductor SSH/tracking updates unless the handoff explicitly asks for that work. The conductor owns persistence and orchestration state.
- Treat each lifecycle cycle as disposable. When a cycle finishes, save the artifact and party-log, kill or exit the spawned worker session, then respawn a fresh worker for the next cycle.
- Do not keep long-lived worker sessions across cycles and do not rely on resume context for the next cycle; context-window drift is a correctness risk.
- Watcher and dispatcher are deterministic programs. LLMs are used only as bounded, disposable lifecycle workers that write artifact files.
- User-facing conductor chat injection is not the normal wakeup path. Use `watch-events.jsonl` and `life:dispatch` for machine notification and worker launch.

## Source Of Truth

- Skill source: `/home/ubuntu/kdh-pipelines/skills/kdh-codex-lifecycle/SKILL.md`.
- Runtime install: `/home/ubuntu/.claude/skills/kdh-codex-lifecycle/SKILL.md`.
- Runner entrypoint: `/home/ubuntu/corthex-v4/scripts/lifecycle-runner.ts`.
- Runner modules: `/home/ubuntu/corthex-v4/scripts/lifecycle/`.
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
- `life:quality`: record the conductor-owned quality scorecard for a step.
- `life:complete`: complete the active step with evidence after reviewer, Agent Context, browser, and quality gates pass.
- `life:watch`: deterministic current-step router; reports lead/review/ready/blocked states, writes `watch-events.jsonl`, may delegate the compatibility flag `--auto-dispatch-reviewers` to `life:dispatch --once`, and never auto-completes.
- `life:dispatch`: deterministic queue consumer; reads `review_pending` watch events, dedupes by notification hash and agent, creates handoff contracts, and starts missing reviewer workers from `.agents/team-lifecycle/agent-roster.json`.
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

For non-solo completion, the conductor must also run `life:quality` before `life:complete`. The scorecard is the lifecycle equivalent of the older planning-pipeline critic rubric: it records score, verdict, blockers, amendments, source, evidence, `review_cycle`, and `minimum_review_cycles`. Team-required lifecycle steps use the global plus-one round policy: at least two quality review cycles are required before `life:complete`. `life:complete` also blocks when the scorecard is missing, score is below 7, verdict is `fail`, blockers remain, or the recorded review cycle is below the policy minimum. Extra review rounds are still driven by this scorecard, not by a fixed round count alone.

Planning-mode Grade A steps are `prd`, `validate`, `architecture`, and `readiness`. Grade A handoffs must include the selected persona profile, input artifacts, rubric dimensions, required evidence, and a must-find risk checklist. Personas are selected by step; do not spawn every persona everywhere.

Grade A `life:quality` must use the v2 scorecard fields: reviewer list, rubric dimensions, per-reviewer scores, convergence signal, blocker list, cross-validation evidence paths, DA evidence or `da_skipped` plus a concrete reason, conductor decision, and final pass/fail. `life:complete` blocks Grade A when any of those are missing, unresolved, or blocked. Historical v1 scorecards remain evidence, but they do not satisfy new Grade A completion.

`life:watch` is a conductor-side router, not a worker hook or worker cron. It observes the active lifecycle run and distinguishes:

- `lead_pending`: lead artifact is missing.
- `review_pending`: lead artifact exists, but reviewer party-logs are missing. This emits `LIFECYCLE_LEAD_READY ... action=dispatch_reviewers`.
- `blocked`: artifacts exist, but Agent Context or browser evidence gates fail.
- `ready`: lead and reviewer artifacts exist and gates pass. Routine steps emit `action=review_then_quality_cycles_then_complete`; Grade A emits `action=quality_cross_validation_da_review_cycles_then_complete`.

`watch-events.jsonl` is the machine notification channel. `life:watch` may notify a tmux target passively, but it must not type into the user-facing conductor chat as the normal wakeup path.

`--auto-dispatch-reviewers` remains as a compatibility flag only. It delegates to `life:dispatch --once`; it does not run reviewer handoffs inside the watcher.

`life:dispatch` launches only `review_pending` missing reviewer workers. It must not launch workers for `ready`; `ready` stays conductor-owned review followed by `life:quality` plus `life:complete` or `life:stale`.

Dispatcher workers are one-assignment sessions. Their durable memory is the expected artifact and party-log files. If a worker exits without the expected artifact, dispatcher records `DISPATCH_FAILED` and leaves the lifecycle step incomplete.

For active Batch C, resume at `architecture` only after `life:doctor` has no unexplained mismatch. The architecture handoff must include PRD/validate artifacts and quality findings. If architecture cannot absorb those amendments, stop and recommend PRD redo instead of silently continuing.

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

- `life:hooks-export`
- rollback automation
- heartbeat daemon
- PKI/global ledger
