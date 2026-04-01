---
name: Working Features First
description: Build features that work end-to-end, not just backend APIs
type: feedback
---

Always build frontend + backend together for each feature. Never build backend-only and move on.

**Why:** v2 built 485 API endpoints but the CEO couldn't use any of them because the frontend was broken, disconnected, or ugly. The entire v2 was archived because of this.

**How to apply:** For every story/feature: implement backend API → build frontend UI → connect them → verify in browser → THEN move to next feature. The CLAUDE.md rule "기능 하나 끝나면 → 브라우저에서 직접 확인 → 작동하면 다음" is absolute.
