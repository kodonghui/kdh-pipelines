---
name: v2 Critical Failures
description: v2 failed because backend-only dev with no working frontend — CEO's #1 frustration
type: feedback
---

v2 had extensive backend (485 APIs, 86 tables) but nothing actually worked end-to-end.

**Why:** Backend was built in isolation. UI was ugly. UX and backend were never properly connected. Dead buttons everywhere. Three theme changes created 428 color remnants.

**How to apply:** Every v3 feature MUST be verified working in a real browser with real data before moving to the next feature. No stubs, no mocks. If the user can't click it and see it work, it's not done. Frontend and backend must be built together, not separately.
