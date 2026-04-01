---
name: Phase 2 Runtime Decision — Hermes Agent
description: CORTHEX Phase 2 AI agent runtime will use Hermes Agent (NousResearch) with Profiles for multi-tenant, Credential Pools for OAuth tokens
type: project
---

Phase 2 AI 에이전트 런타임으로 **Hermes Agent**를 사용하기로 결정. CEO 제안 + 리서치로 확정.

**Why:** Hermes Agent(20K stars, MIT, ICLR 2026)가 CEO 비전에 정확히 맞음:
- **Profiles** = 직원별 에이전트 격리 (config, memory, skills, gateway 전부 독립)
- **Credential Pools** = 직원별 OAuth 토큰 관리 + 로테이션
- **자동 진화** = 백그라운드 스킬 생성 + GEPA 최적화
- 이미 이 VPS에 설치되어 Telegram으로 동작 중 (`~/.hermes/`)

**How to apply:**
- 직원의 AI 에이전트 생성 = Hermes Profile 생성
- 직원의 모든 에이전트가 해당 직원의 Claude OAuth 토큰을 credential_pool로 공유
- OpenClaw 불필요 (Hermes가 상위호환, 마이그레이션 도구 내장)
- Claude Agent SDK는 보완재 (코드 작업 시 Hermes 내부에서 활용)
- 리서치 리포트: `_research/hermes-openclaw-agent-runtime-2026-03-31.md`
