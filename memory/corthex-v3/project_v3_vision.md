---
name: v3 Vision Direction
description: Balanced approach — org management + task execution. Single company, multiple divisions.
type: project
---

GATE decision (2026-03-30): Option C selected.

- Vision = "AI 조직 운영 + 업무 플랫폼" (balanced org management + task automation)
- Phase 1 = org skeleton (signup, company, departments, employees, agents)
- Phase 2 = immediately add task execution (agent engine, chat hub, handoff)
- NOT multi-tenant SaaS. Single company with multiple 본부(divisions/headquarters).

**Why:** CEO wants both — managing AI agents in org structure AND actually using them for work. Phase 1 builds the skeleton, Phase 2 makes it functional.

**How to apply:** Design data models to support multiple divisions under one company. Don't build multi-tenant isolation. Focus Phase 1 on the org loop, but keep architecture ready for Phase 2 task execution features.
