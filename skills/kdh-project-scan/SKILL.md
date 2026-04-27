---
name: kdh-project-scan
description: "프로젝트 context.yaml 자동 스캔/cache."
---

# Project Auto-Scan

## Step 0 (ALL Modes): Project Auto-Scan

Run this BEFORE any other step. Results are cached in `project-context.yaml` at project root.

```
1. Read package.json → detect:
   - Package manager: check for bun.lockb (bun), pnpm-lock.yaml (pnpm), yarn.lock (yarn), else npm
   - Project name, version, scripts (dev, build, test, lint)

2. Find ALL tsconfig.json files:
   - glob("**/tsconfig.json", ignore node_modules)
   - If monorepo: find the root tsconfig AND each package tsconfig
   - Build tsc command list: ["npx tsc --noEmit -p {path}" for each tsconfig]
   - If zero found: tsc_enabled = false

3. Detect monorepo structure:
   - turbo.json → Turborepo
   - pnpm-workspace.yaml → pnpm workspace
   - lerna.json → Lerna
   - workspaces in package.json → npm/yarn workspaces
   - None found → single-package project

4. Find test runner config:
   - vitest.config.* → "npx vitest run"
   - jest.config.* or jest in package.json → "npx jest"
   - "bun:test" in files → "bun test"
   - playwright.config.* → playwright_enabled = true
   - cypress.config.* → cypress_enabled = true
   - None found → test_enabled = false

5. Detect BMAD:
   - Check if _bmad/ directory exists → bmad_enabled = true/false
   - If true: locate workflow dirs, agent files, templates
   - If false: use simplified workflow (see "Non-BMAD Workflow" section)

6b. Detect Hono RPC capability (v9.4):
   - Check for 'hono' in package.json dependencies (any package in monorepo)
   - If Hono found AND monorepo with shared types package: hono_rpc_eligible = true
   - Save to project-context.yaml:
     hono:
       detected: true/false
       rpc_eligible: true/false
       server_package: "{path}" | null

6. Detect UI framework:
   - Check for: React (react-dom), Vue, Svelte, Angular, Next.js, Nuxt, Remix, Astro
   - Find dev server command from package.json scripts
   - Check for Playwright config → vrt_enabled = true/false
   - Check for Tailwind/CSS framework config

7. Detect architecture docs (any of these):
   - _bmad-output/planning-artifacts/architecture.md
   - docs/architecture.md, docs/ARCHITECTURE.md
   - ARCHITECTURE.md at root
   - Any file matching **/architecture*.md
   - Store path or null

8. Detect existing feature spec (any of these):
   - _bmad-output/planning-artifacts/*feature-spec*
   - docs/*feature-spec*, docs/*features*
   - Any file matching **/*feature-spec*.md
   - Store path or null

9. Detect existing PRD (any of these):
   - _bmad-output/planning-artifacts/prd.md
   - docs/prd.md, docs/PRD.md
   - Any file matching **/prd*.md
   - Store path or null

10. Save results to project-context.yaml
```
