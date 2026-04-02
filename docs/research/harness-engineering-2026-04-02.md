# Research Report: 하네스 설계 (Agent Harness Engineering)
> Researched: 2026-04-02 | Sources: 12 | Confidence: high

## TL;DR
- **하네스 = AI 에이전트를 감싸는 운영 인프라** (도구, 권한, 검증, 피드백 루프 전체)
- 2026년 업계 최대 트렌드: "모델은 엔진, 하네스는 자동차" — 엔진(AI 모델)만으로는 제품이 안 됨
- Claude Code 자체가 하네스의 대표적 구현: CLAUDE.md + skills + hooks + sub-agents + 권한 관리
- CORTHEX v3의 파이프라인(kdh-full-auto-pipeline)도 하네스 설계의 한 형태
- 핵심 공식: **코딩 에이전트 = AI 모델 + 하네스**

## 하네스란 무엇인가

### 비유로 이해하기
- AI 모델 = **엔진** (힘은 있지만 방향이 없음)
- 하네스 = **자동차** (핸들, 브레이크, 계기판, 도로 규칙 전부 포함)
- 최고의 엔진도 핸들과 브레이크 없이는 쓸모없다

### 정의
하네스(harness)는 AI 모델을 감싸서 실제 업무에 사용할 수 있게 만드는 **모든 인프라**:
- 어떤 도구를 쓸 수 있는지 (Tools)
- 뭘 알고 있어야 하는지 (Knowledge / Context)
- 어디까지 할 수 있는지 (Permissions)
- 실수하면 어떻게 잡아내는지 (Verification)
- 사람이 언제 개입하는지 (Human-in-the-loop)

## 6가지 핵심 구성 요소

| 구성 요소 | 설명 | Claude Code 예시 |
|-----------|------|------------------|
| **도구 관리** | 에이전트가 쓸 수 있는 도구 정의 | Read, Write, Edit, Bash, Grep, Glob |
| **권한 관리** | 어디까지 허용할지 | allowedTools, permission mode, sandbox |
| **지식 주입** | 에이전트에게 알려줄 정보 | CLAUDE.md, skills, context snapshots |
| **검증 루프** | 결과물 자동 검증 | tsc --noEmit, pre-commit hooks, Codex |
| **사람 개입** | 중요 결정은 사람이 확인 | GATE protocol, plan mode |
| **수명 관리** | 시작, 상태 저장, 복구, 종료 | session save/resume, pipeline-state.yaml |

## 2026년 업계 현황

### 왜 지금 중요한가
- 2025년: AI 모델 경쟁 (누가 더 똑똑한 모델을 만드나)
- 2026년: 하네스 경쟁 (같은 모델로 누가 더 잘 쓰나)
- **모델은 범용화(commodity)** — Claude, GPT, Gemini 성능 비슷
- **하네스가 차별화** — 같은 모델도 하네스에 따라 결과가 10배 차이

### 실제 사례
- **Manus**: 같은 모델로 하네스를 5번 다시 만들어서 성능 향상
- **Vercel**: 에이전트 도구 80%를 제거하니 오히려 성능 향상 (less = more)
- **LangChain**: Deep Research 하네스를 1년간 4번 재설계

### GitHub 주요 프로젝트
| 프로젝트 | 설명 |
|---------|------|
| everything-claude-code | Claude Code 하네스 최적화 시스템 (skills, instincts, memory) |
| learn-claude-code | Claude Code 같은 하네스를 0부터 만드는 교육 프로젝트 |
| lobehub | 멀티 에이전트 하네스 플랫폼 |
| deepagents (LangChain) | LangGraph 기반 하네스 (planning + subagent) |

## CORTHEX v3와의 관계

### 우리가 이미 하고 있는 하네스 설계

CORTHEX v3의 파이프라인 시스템이 곧 하네스 설계입니다:

| CORTHEX v3 요소 | 하네스 개념 |
|----------------|-----------|
| `CLAUDE.md` | 지식 주입 (Knowledge) |
| `kdh-full-auto-pipeline` | 도구 관리 + 수명 관리 |
| `pipeline-state.yaml` | 상태 관리 (State) |
| GATE protocol | 사람 개입 (Human-in-the-loop) |
| Party Mode (critics) | 검증 루프 (Verification) |
| Pre-commit hooks | 자동 검증 게이트 |
| Codex (GPT-5.4) | 외부 검증 (Second opinion) |
| TeamCreate + SendMessage | 서브에이전트 조정 |
| context-snapshots | 컨텍스트 관리 |

### Phase 2에서의 활용 가능성

CORTHEX v3가 AI 에이전트 조직 관리 플랫폼이라면, **Phase 2의 에이전트 실행 엔진이 곧 하네스**입니다:

1. **에이전트별 하네스 설정**: 각 AI 에이전트(팀원)에게 다른 도구/권한/지식을 부여
2. **조직 기반 권한**: 본부장 에이전트 vs 팀원 에이전트 — 할 수 있는 일이 다름
3. **실행 감시**: 에이전트가 뭘 하는지 실시간 모니터링 (가상 사무실)
4. **검증 루프**: 에이전트 결과물을 자동 검증하는 시스템
5. **핸드오프 프로토콜**: 에이전트 간 업무 이전 규칙

이것이 CORTHEX v3의 핵심 가치 — "에이전트 하네스를 비개발자가 설정할 수 있게 만드는 플랫폼"

## 설계 3원칙

1. **최소 개입 (Minimal Intervention)**: 꼭 필요한 곳에만 제한. 모델이 스스로 교정할 수 있으면 간섭하지 않음
2. **점진적 공개 (Progressive Disclosure)**: 처음엔 적은 권한 → 필요할 때만 확장
3. **빠른 실패 + 복구 (Fail-fast with Recovery)**: 실수를 빨리 잡고, 복구 경로 제공. 조용히 실패하면 안 됨

## Sources
1. [Aakash Gupta - 2025 Was Agents, 2026 Is Agent Harnesses](https://aakashgupta.medium.com/2025-was-agents-2026-is-agent-harnesses-heres-why-that-changes-everything-073e9877655e)
2. [HumanLayer - Skill Issue: Harness Engineering for Coding Agents](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents)
3. [NxCode - What Is Harness Engineering? Complete Guide 2026](https://www.nxcode.io/resources/news/what-is-harness-engineering-complete-guide-2026)
4. [Agent Engineering - Harness Engineering in 2026](https://www.agent-engineering.dev/article/harness-engineering-in-2026-the-discipline-that-makes-ai-agents-production-ready)
5. [Harness Engineering AI - Agent Harness Complete Guide](https://harness-engineering.ai/blog/agent-harness-complete-guide/)
6. [Epsilla - Harness Engineering: Focus Shifting from Models to Agent Control](https://www.epsilla.com/blogs/2026-03-12-harness-engineering)
7. [Shane Zhong - Your AI Agent Isn't the Problem](https://medium.com/@shane.zhong/your-ai-agent-isnt-the-problem-the-infrastructure-around-it-is-051fa969826f)
8. [arXiv - Natural-Language Agent Harnesses](https://arxiv.org/html/2603.25723v1)
9. [GitHub - everything-claude-code](https://github.com/affaan-m/everything-claude-code)
10. [GitHub - learn-claude-code](https://github.com/shareAI-lab/learn-claude-code)
11. [GitHub - deepagents (LangChain)](https://github.com/langchain-ai/deepagents)
12. [Anthropic - Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
