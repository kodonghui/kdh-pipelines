# Research Report: 하네스 설계 벤치마크 & 베스트 프랙티스
> Researched: 2026-04-02 | Sources: 15 | Confidence: high

## TL;DR
- **LangChain DeepAgents**: 같은 모델로 하네스만 바꿔서 52.8% → 66.5% (Terminal Bench 2.0, Top 30 → Top 5)
- **Anthropic 공식 가이드**: 2-agent 아키텍처 (Initializer + Coding Agent) + 진행 파일 + 기능 체크리스트
- **Meta-Harness**: 자동 하네스 최적화 — 모든 Opus 4.6 에이전트 중 2위, Haiku 4.5 중 1위
- **핵심 발견**: 하네스가 22점 차이, 모델은 1점 차이 — 하네스가 압도적으로 중요
- **벤치마크 대상 Top 5**: ECC (132K stars), Lobehub (75K), learn-claude-code (47K), oh-my-openagent (47K), DeepAgents (19K)

## 벤치마크 1: LangChain DeepAgents (가장 상세한 사례)

### 성과
- **Terminal Bench 2.0**: 52.8% → 66.5% (+13.7pt)
- **모델 변경 없음** (GPT-5.2-Codex 고정)
- **하네스만 수정**하여 Top 30 → Top 5 달성

### 핵심 하네스 변경 4가지

| 변경 | 설명 | 효과 |
|------|------|------|
| **자기검증 루프** | PreCompletionChecklistMiddleware — 완료 전 테스트 스펙 대비 검증 강제 | 가장 큰 효과. 에이전트가 "다했다"고 거짓말하는 패턴 방지 |
| **환경 컨텍스트 주입** | LocalContextMiddleware — 시작 시 디렉토리 구조/도구 자동 감지 | 에이전트가 환경을 이해하고 자율적으로 일함 |
| **루프 감지** | LoopDetectionMiddleware — 같은 파일 반복 수정 시 접근 변경 제안 | "죽음의 루프" (10회+ 동일 실패 반복) 방지 |
| **추론 예산 최적화** | "Reasoning Sandwich" — 계획(최대) → 구현(중간) → 검증(최대) | 전구간 최대 추론 시 53.9%, 샌드위치 시 63.6% |

### 시사점
- 자기검증이 가장 중요 (우리의 Party Mode + Codex와 유사)
- 루프 감지 (우리의 max_stalls = 3과 유사)
- 추론 예산 조절 (우리의 Grade A=opus, Grade B=sonnet과 유사)

## 벤치마크 2: Anthropic 공식 — 장시간 에이전트 하네스

### 2-Agent 아키텍처
1. **Initializer Agent**: 프로젝트 초기 설정 (1회)
2. **Coding Agent**: 반복 실행, 점진적 진행, 상태 보존

### 필수 구성 요소
| 구성 요소 | 역할 | CORTHEX 대응 |
|-----------|------|-------------|
| `init.sh` | 개발 서버 + 기본 검증 | Sprint Zero |
| `claude-progress.txt` | 작업 진행 로그 | pipeline-state.yaml |
| Git commits | 세션 간 상태 보존 | 스토리별 커밋 |
| JSON 기능 리스트 | 완료 기준 체크리스트 | Story AC (Gherkin) |
| 브라우저 자동화 테스트 | E2E 검증 | Playwright E2E |

### 안티패턴 & 해결
| 안티패턴 | 해결 | CORTHEX 대응 |
|---------|------|-------------|
| 전체를 한번에 빌드 시도 | 기능 1개씩 | Story 단위 파이프라인 |
| 테스트 없이 완료 선언 | E2E 필수 | Phase D TEA + Codex |
| 이전 세션에 상태 전달 실패 | 진행 파일 + git | context-snapshots |
| 중간에 "끝났다" 선언 | 기능 리스트가 권위적 체크리스트 | pipeline-state.yaml |

## 벤치마크 3: Meta-Harness (자동 하네스 최적화)

- 자동으로 최적 하네스 구성을 탐색
- Opus 4.6 에이전트 중 2위, Haiku 4.5 중 1위
- 평균 +4.7pt 정확도 향상 (34.1% → 38.8%)
- 5개 모델에서 일관된 개선

## 벤치마크 4: Everything Claude Code (ECC)

### 규모
- GitHub Stars: **132,508**
- 10+ 개월 실전 사용 기반
- 57+ 슬래시 커맨드
- 언어별 규칙 시스템 (TS, Python, Go, Rust, Swift, PHP)

### 핵심 구조
```
ECC Harness
├── Rules (코딩 스타일, git, 테스트, 보안)
├── Skills (도메인별 지식 번들)
├── Hooks (자동 포맷, 검증, 알림)
├── Agents (플래너, 리뷰어, TDD, 보안)
├── Memory (세션 간 지속 학습)
└── Instincts (패턴 자동 추출)
```

### CORTHEX v3와의 비교
| ECC | CORTHEX v3 파이프라인 | 비고 |
|-----|---------------------|------|
| Rules (CLAUDE.md) | CLAUDE.md + pipeline-enforcement.md | 유사 |
| Skills (57+ commands) | kdh-full-auto-pipeline + 하위 스킬 | 유사 |
| Hooks (pre/post tool) | Pre-commit hook v3 | 유사 |
| Agents (planner, reviewer) | Party Mode (winston, quinn, john, sally, bob) | CORTHEX가 더 정교 |
| Memory (instincts) | context-snapshots + session save/resume | 유사 |
| Eval (benchmarks) | Codex + critic rubric D1-D6 | CORTHEX가 더 체계적 |

## 벤치마크 5: GitHub Top 하네스 프로젝트

| 프로젝트 | Stars | 특징 |
|---------|-------|------|
| everything-claude-code | 132,508 | 스킬/메모리/인스팅트 통합 |
| lobehub | 74,643 | 멀티에이전트 협업 하네스 |
| learn-claude-code | 46,955 | 하네스를 0부터 만드는 교육 |
| oh-my-openagent | 46,753 | 범용 에이전트 하네스 |
| deepagents (LangChain) | 18,720 | 계획+서브에이전트+파일시스템 |

## 핵심 수치: 하네스 vs 모델 영향

```
하네스 변경 효과:  22점 차이 (scaffold accounts for 22-point swing)
모델 변경 효과:    ~1점 차이 (model swaps account for ~1 point at frontier)
비율:            하네스가 22배 더 중요
```

## CORTHEX v3 벤치마크 대상 추천

### 1순위: LangChain DeepAgents
- 이유: 하네스 변경만으로 가장 큰 성과, 기법이 구체적, 우리 파이프라인에 바로 적용 가능
- 참고: 자기검증 루프, 루프 감지, 추론 예산 패턴

### 2순위: Anthropic 공식 가이드
- 이유: Claude 기반이므로 직접 적용 가능, 2-agent 아키텍처가 Phase 2 에이전트 엔진에 적합
- 참고: init.sh + progress file + feature list 패턴

### 3순위: ECC (Everything Claude Code)
- 이유: 우리가 이미 많은 부분을 사용 중, 부족한 부분(instincts, eval)을 보완할 수 있음
- 참고: 인스팅트 시스템, eval harness, skill 구조

## Sources
1. [Anthropic - Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
2. [LangChain - Improving Deep Agents with Harness Engineering](https://blog.langchain.com/improving-deep-agents-with-harness-engineering/)
3. [Philipp Schmid - The Importance of Agent Harness in 2026](https://www.philschmid.de/agent-harness-2026)
4. [Meta-Harness: End-to-End Optimization of Model Harnesses](https://yoonholee.com/meta-harness/)
5. [Rick Hightower - LangChain's From Top 30 to Top 5](https://medium.com/@richardhightower/langchains-harness-engineering-from-top-30-to-top-5-on-terminal-bench-2-0-8895dbab4932)
6. [GitHub - everything-claude-code](https://github.com/affaan-m/everything-claude-code) (132K stars)
7. [GitHub - lobehub](https://github.com/lobehub/lobehub) (75K stars)
8. [GitHub - learn-claude-code](https://github.com/shareAI-lab/learn-claude-code) (47K stars)
9. [GitHub - deepagents](https://github.com/langchain-ai/deepagents) (19K stars)
10. [HumanLayer - Skill Issue: Harness Engineering](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents)
11. [Aakash Gupta - 2026 Is Agent Harnesses](https://aakashgupta.medium.com/2025-was-agents-2026-is-agent-harnesses-heres-why-that-changes-everything-073e9877655e)
12. [Neo4j - AI Agent Case Studies](https://neo4j.com/blog/agentic-ai/ai-agent-useful-case-studies/)
13. [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
14. [Trail of Bits - Claude Code Config](https://github.com/trailofbits/claude-code-config)
15. [Anthropic - Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
