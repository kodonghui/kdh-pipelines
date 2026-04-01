---
name: Swarm must keep party mode
description: CEO explicitly demands party mode in Swarm — never skip critic review for speed
type: feedback
---

Swarm 모드에서 party mode (4명 리뷰) 절대 생략 금지.

**Why:** CEO가 "파티모드 누가 생략하래 ㅅㅂ 처음부터 다시해"라고 격노. v2 실패 원인이 백엔드-프론트엔드 미연결이었고, party mode 없으면 같은 실수 반복. 속도보다 품질이 우선.

**How to apply:** Swarm Worker가 구현 후 반드시 winston/quinn/john critic 리뷰를 거쳐야 함. self-review만으로는 부족. 파이프라인 개선해서 Swarm + party mode 결합 구조 만들어야 함.
