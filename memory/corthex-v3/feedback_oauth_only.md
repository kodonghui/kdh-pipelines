---
name: OAuth CLI Token Only
description: NEVER create separate Anthropic API keys — all services (Hermes, CORTHEX, etc.) must use Claude CLI OAuth token
type: feedback
---

별도 Anthropic API key 발급 절대 금지. Hermes, CORTHEX, 모든 서비스는 Claude CLI OAuth 토큰을 공유해서 써야 함.

**Why:** 사장님이 여러 번 반복 지시. 별도 키를 만들면 한도가 분산되어 서비스가 죽고, 키 관리도 복잡해짐. CLI OAuth 토큰 하나로 통일.

**How to apply:** 어떤 서비스든 Anthropic API 호출이 필요하면 Claude CLI OAuth 토큰을 참조하도록 설정. `ANTHROPIC_API_KEY` 환경변수에 직접 키를 넣지 말 것. CLAUDE.md 맨 위에 대문짝만하게 써놨음.
