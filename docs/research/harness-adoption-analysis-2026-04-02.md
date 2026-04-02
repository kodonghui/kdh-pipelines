# 3대 하네스 심층 분석 + CORTHEX v3 접목 방안
> Researched: 2026-04-02 | Sources: 15+ | Confidence: high

## TL;DR — 접목할 것 7가지
1. **자동 루프 감지** (LangChain) — 같은 파일 N번 수정하면 경고
2. **추론 샌드위치** (LangChain) — 계획=최대, 구현=중간, 검증=최대
3. **JSON 기능 리스트** (Anthropic) — pipeline-state.yaml 구조 강화
4. **init.sh 환경 검증** (Anthropic) — 매 세션 시작 시 자동 환경 체크
5. **인스팅트 시스템** (ECC) — 세션에서 패턴 자동 추출 + 학습
6. **Hook 프로파일** (ECC) — minimal/standard/strict 모드 전환
7. **하네스 자기 최적화** (Meta-Harness) — Phase 2 에이전트 프롬프트 자동 개선

---

## 1. LangChain DeepAgents — 상세 분석

### 아키텍처
```
DeepAgents = GPT-5.2-Codex (모델 고정)
  + PreCompletionChecklistMiddleware (자기검증)
  + LocalContextMiddleware (환경 감지)
  + LoopDetectionMiddleware (루프 방지)
  + Reasoning Budget Control (추론 예산)
  + Trace Analyzer (실패 분석)
```

### 핵심 기법 상세

#### 1-1. PreCompletionChecklistMiddleware (자기검증 루프)
- 에이전트가 "다 했어요" 하기 전에 가로채서 테스트 스펙 대비 검증 강제
- 4단계: Planning → Build → Verify → Fix
- **가장 큰 효과**: 에이전트가 검증 없이 완료 선언하는 패턴 방지

**CORTHEX 현재**: Party Mode + Codex가 이 역할
**접목 가능**: Phase D(TEA) 자동 실행을 pre-completion 미들웨어로 강화

#### 1-2. LoopDetectionMiddleware (루프 감지)
- 파일별 수정 횟수 추적 (tool call hooks)
- N회 초과 시 "다른 접근법 고려해봐" 프롬프트 자동 주입
- 10회+ 동일 파일 수정 = "죽음의 루프" 방지

**CORTHEX 현재**: max_stalls = 3, stall_threshold = 5min
**접목 가능**: 파일별 수정 카운터 추가 → 같은 파일 5회 수정 시 경고

#### 1-3. Reasoning Sandwich (추론 예산 최적화)
| 단계 | 추론 수준 | 결과 |
|------|----------|------|
| 계획 | xhigh (최대) | 방향을 잘 잡음 |
| 구현 | high (중간) | 속도 + 비용 절감 |
| 검증 | xhigh (최대) | 꼼꼼한 체크 |

- xhigh 전구간: 53.9% (타임아웃 문제)
- high 전구간: 63.6%
- **샌드위치: 66.5%** (최고)

**CORTHEX 현재**: Grade A=opus critics, Grade B=sonnet
**접목 가능**: Phase A(계획)=opus, Phase B(구현)=sonnet, Phase D(검증)=opus — 이미 비슷하지만 더 명시적으로

#### 1-4. Trace Analyzer (실패 분석 자동화)
- LangSmith에서 실행 트레이스 수집
- 병렬 에러 분석 에이전트 소환
- 실패 패턴 종합 → 하네스 수정 제안

**CORTHEX 현재**: retrospective(수동)
**접목 가능**: 파이프라인 실패 로그 자동 분석 → fixes 제안 (Phase 2 고려)

---

## 2. Anthropic 공식 가이드 — 상세 분석

### 아키텍처
```
2-Agent System:
  Initializer Agent (1회) → init.sh + progress file + feature list + git init
  Coding Agent (반복) → read state → work 1 feature → commit → update progress
```

### 핵심 기법 상세

#### 2-1. init.sh (환경 자동 검증)
- 개발 서버 시작 커맨드
- 기본 E2E 테스트 시퀀스
- 환경 설정 확인
- "에이전트가 매 세션마다 환경을 새로 파악할 필요 없음"

**CORTHEX 현재**: project-context.yaml (정적 캐시)
**접목 가능**: `verify-env.sh` 스크립트 추가
```bash
#!/bin/bash
# 매 세션 시작 시 실행
bun --version          # Bun 설치 확인
cd packages/server && bun run type_check  # tsc 통과 확인
cd packages/admin && bun run type_check   # tsc 통과 확인
psql $DATABASE_URL -c "SELECT 1"          # DB 연결 확인
echo "Environment OK"
```

#### 2-2. JSON Feature List (기능 체크리스트)
```json
{
  "category": "functional",
  "description": "사용자가 이메일/비밀번호로 가입할 수 있다",
  "steps": [
    "가입 페이지 접속",
    "이메일/비밀번호 입력 후 제출",
    "자동 로그인 확인",
    "새로고침 후 세션 유지 확인"
  ],
  "passes": false
}
```
- **JSON이 Markdown보다 좋은 이유**: 모델이 JSON은 함부로 수정 안 함, Markdown은 덮어쓰기 위험
- 200+ 기능 항목 권장
- passes 필드만 수정 가능하도록 제한

**CORTHEX 현재**: pipeline-state.yaml (YAML, 구조적이지만 기능 리스트 아님)
**접목 가능**: `feature-checklist.json` 추가 — Sprint별 기능 목록 + 테스트 단계 + pass/fail

#### 2-3. Progress File (세션 간 기억)
- 세션별 작업 로그
- 완료된 기능 목록
- 현재 앱 상태 요약
- "프로젝트 끝났다" 조기 선언 방지

**CORTHEX 현재**: pipeline-state.yaml + context-snapshots + session save/resume
**접목 가능**: claude-progress.txt 형태의 서사적 진행 로그 추가 (yaml이 아닌 자연어)

#### 2-4. 1 Feature Per Session (세션당 1기능)
- "이 접근법이 결정적이었다" — Anthropic 공식 평가
- 전체를 한번에 만들면 100% 실패
- 기능 1개 완료 → git commit → 다음 세션

**CORTHEX 현재**: 이미 Story 단위로 실행 중 ✅
**접목 불필요**: 이미 가장 좋은 패턴 사용 중

#### 2-5. 안티패턴 대응

| Anthropic 안티패턴 | CORTHEX 대응 | 추가 필요 |
|-------------------|-------------|----------|
| 전체 한번에 빌드 | Story 단위 ✅ | 없음 |
| 테스트 없이 완료 선언 | Phase D + Codex ✅ | 없음 |
| 상태 전달 실패 | context-snapshots ✅ | 서사적 진행 로그 추가 |
| "끝났다" 조기 선언 | pipeline-state.yaml ✅ | JSON 기능 체크리스트 추가 |
| 환경 재파악 시간 낭비 | project-context.yaml | init.sh 추가 |

---

## 3. ECC (Everything Claude Code) — 상세 분석

### 아키텍처
```
ECC = 36 Agents + 151 Skills + 68 Commands + Hooks + Rules + Memory
  Rules:    common/ + typescript/ + python/ + golang/ + ...
  Skills:   도메인별 지식 번들 (progressive disclosure)
  Hooks:    PreToolUse + PostToolUse + Stop
  Agents:   planner, code-reviewer, tdd-guide, security-reviewer, ...
  Memory:   instincts (자동 학습) + sessions (이력)
  Eval:     harness-audit, quality-gate, model-route
```

### 핵심 기법 상세

#### 3-1. Instinct System (자동 학습)
```
세션 관찰 → 패턴 추출 → confidence 점수 → 승격/삭제
- 프로젝트 스코프 인스팅트: 특정 프로젝트에서만 유효
- 글로벌 인스팅트: 모든 프로젝트에 적용
- /learn: 세션에서 패턴 추출
- /evolve: 인스팅트 분석 + 진화
- /prune: 30일 이상 미사용 삭제
```

**CORTHEX 현재**: MEMORY.md (수동 저장)
**접목 가능**: 
- Party Mode 리뷰에서 반복 지적 패턴 자동 추출
- "Session 3번 연속 같은 이슈 발견" → 인스팅트로 승격
- pipeline retrospective에서 자동 학습

#### 3-2. Hook Runtime Controls
```bash
ECC_HOOK_PROFILE=minimal    # 최소 검증 (빠른 개발)
ECC_HOOK_PROFILE=standard   # 기본 (일반 작업)
ECC_HOOK_PROFILE=strict     # 최대 검증 (프로덕션)

ECC_DISABLED_HOOKS="pre:bash:tmux-reminder,post:edit:typecheck"
```

**CORTHEX 현재**: pre-commit hook v3 (고정, 항상 strict)
**접목 가능**: 
- `계속` 모드 = standard (빠른 진행)
- 일반 모드 = strict (전체 검증)
- 개발 중 = minimal (tsc만)

#### 3-3. Harness Optimizer Agent
- 하네스 자체를 분석하고 개선 제안
- `/harness-audit`: 현재 설정 점수 매기기
- `/quality-gate`: 품질 임계치 검증
- `/model-route`: 작업별 최적 모델 선택

**CORTHEX 현재**: retrospective(수동), model strategy(Grade A/B/C)
**접목 가능**: 자동 하네스 감사 — 파이프라인 실행 후 자동으로 "이번 Sprint에서 뭐가 잘 됐고 뭐가 안 됐는지" 분석

#### 3-4. Session Management
- SQLite 기반 세션 상태 저장
- 쿼리 CLI로 이전 세션 검색
- 구조화된 세션 녹화 (adapter pattern)

**CORTHEX 현재**: ~/.claude/session-data/ (파일 기반)
**접목 가능**: 장기적으로 구조화된 세션 DB 고려 (Phase 2+)

#### 3-5. Verification Loops (검증 패턴)
| 패턴 | 설명 | CORTHEX |
|------|------|---------|
| Checkpoint eval | 특정 단계에서 검증 | Phase D(TEA) ✅ |
| Continuous eval | 매 도구 호출 후 검증 | PostToolUse hook |
| Pass@k | k번 시도 중 1번 성공 | max_retry ✅ |
| Grader types | 정확도/스타일/보안 별도 평가 | D1-D6 rubric ✅ |

---

## 4. Meta-Harness — 상세 분석 (보너스)

### 핵심 혁신
- 하네스 자체를 자동 최적화하는 메타 시스템
- 10M 토큰 진단 컨텍스트 (기존 방법의 400배)
- 실행 트레이스 + 소스코드 + 점수를 전부 다음 시도에 제공

### 성과
| 벤치마크 | 기존 최고 | Meta-Harness | 비고 |
|---------|----------|-------------|------|
| 텍스트 분류 | 40.9% (ACE) | **48.6%** | +7.7pt, 컨텍스트 4배 절약 |
| 수학 추론 | 37.5% (BM25) | **38.8%** | 5개 모델에서 일관 개선 |
| 코딩 (Opus) | 75.3% (Capy) | **76.4%** | Opus 4.6 중 2위 |
| 코딩 (Haiku) | 35.5% (Goose) | **37.6%** | Haiku 4.5 중 1위 |

**CORTHEX Phase 2 접목**:
- 에이전트 시스템 프롬프트를 자동 최적화
- 에이전트 실행 결과 → 트레이스 수집 → 프롬프트 개선 루프
- "사장님이 만든 에이전트가 시간이 갈수록 알아서 더 잘하게 되는" 시스템

---

## 종합: CORTHEX v3 접목 로드맵

### 즉시 적용 가능 (Phase 1 진행 중)

| # | 기법 | 출처 | 구현 난이도 | 효과 |
|---|------|------|-----------|------|
| 1 | **루프 감지 카운터** | LangChain | 낮음 | pre-commit hook에 파일별 수정 횟수 추적 추가 |
| 2 | **verify-env.sh** | Anthropic | 낮음 | 세션 시작 시 tsc+DB+서버 자동 확인 |
| 3 | **feature-checklist.json** | Anthropic | 낮음 | Phase 1 기능 5개 + 테스트 단계 + pass/fail |
| 4 | **Hook 프로파일** | ECC | 중간 | 계속/일반/개발 모드별 검증 수준 조절 |

### Sprint 완료 후 적용 (Planning 보강 후)

| # | 기법 | 출처 | 구현 난이도 | 효과 |
|---|------|------|-----------|------|
| 5 | **인스팅트 시스템** | ECC | 중간 | Party Mode 반복 지적 자동 학습 |
| 6 | **서사적 진행 로그** | Anthropic | 낮음 | pipeline-state.yaml 보완, 자연어 진행 기록 |
| 7 | **자동 하네스 감사** | ECC | 중간 | Sprint 종료 시 자동 파이프라인 효과 분석 |

### Phase 2 에이전트 엔진에 적용

| # | 기법 | 출처 | 구현 난이도 | 효과 |
|---|------|------|-----------|------|
| 8 | **추론 샌드위치** | LangChain | 낮음 | 에이전트 실행 시 단계별 추론 예산 조절 |
| 9 | **자기 최적화 루프** | Meta-Harness | 높음 | 에이전트 프롬프트 자동 개선 |
| 10 | **Trace Analyzer** | LangChain | 높음 | 에이전트 실패 자동 분석 + 개선 제안 |

---

## 우리가 이미 업계 최고 수준인 부분

| 기법 | 업계 | CORTHEX v3 | 비교 |
|------|------|-----------|------|
| 자기검증 | PreCompletionChecklist (1단계) | Party Mode 3-4명 + Codex 외부검증 | **CORTHEX 압도** |
| 모델 라우팅 | model-route 커맨드 | Grade A=opus, B=sonnet, C=solo | 동등 |
| 사람 개입 | HITL (binary approve/reject) | GATE 19개 (BIZ/TECH 분류) | **CORTHEX 압도** |
| 상태 관리 | progress.txt | pipeline-state.yaml + context-snapshots | **CORTHEX 우위** |
| 1기능/세션 | "결정적" (Anthropic 강조) | Story 단위 파이프라인 | 동등 |
| 보안 검증 | AgentShield (102 규칙) | pre-commit hook + security-reviewer | 동등 |

---

## Sources
1. [LangChain - Improving Deep Agents](https://blog.langchain.com/improving-deep-agents-with-harness-engineering/)
2. [Anthropic - Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
3. [GitHub - everything-claude-code](https://github.com/affaan-m/everything-claude-code) (132K stars)
4. [Meta-Harness](https://yoonholee.com/meta-harness/)
5. [Philipp Schmid - Agent Harness 2026](https://www.philschmid.de/agent-harness-2026)
6. [HumanLayer - Skill Issue](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents)
7. [LangChain State of Agent Engineering](https://www.langchain.com/state-of-agent-engineering)
