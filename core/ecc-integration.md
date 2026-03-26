# ECC Integration Protocol — KDH Pipeline Series

Version: 1.0
Date: 2026-03-26

## Purpose

KDH 파이프라인 5개에 ECC v1.9.0의 agent/skill/command를 통합하여 품질을 높이는 프로토콜.
핵심: 코드 리뷰 + 적대적 검증 + 자동 학습으로 "토스트만 띄우고 실제 동작 안 하는" 류의 버그 방지.

---

## 1. kdh-full-auto-pipeline v9.2 + ECC

### Planning 단계
| 추가 | ECC 컴포넌트 | 역할 |
|------|-------------|------|
| + | `search-first` 스킬 | 코딩 전 기존 라이브러리/패턴 먼저 조사 |
| + | `architecture-decision-records` 스킬 | 설계 결정 자동 ADR 기록 |
| + | `planner` 에이전트 | ECC 표준 계획 수립 |

### Dev-Story 단계
| 추가 | ECC 컴포넌트 | 역할 |
|------|-------------|------|
| + | `tdd-workflow` 스킬 | TDD 강제 (테스트 먼저 → 구현) |
| + | `tdd-guide` 에이전트 | TDD 감시 + 80%+ 커버리지 강제 |
| + | `coding-standards` 규칙 | TypeScript 코딩 표준 자동 적용 |
| + | `security-review` 스킬 | 인증/입력/API 보안 체크리스트 |

### Code Review 단계 (Party Mode)
| 추가 | ECC 컴포넌트 | 역할 |
|------|-------------|------|
| + | `code-reviewer` 에이전트 | ECC 표준 코드 리뷰 |
| + | `typescript-reviewer` 에이전트 | TS 전문 리뷰 |
| + | `security-reviewer` 에이전트 | OWASP Top 10 자동 체크 |
| + | `database-reviewer` 에이전트 | SQL/쿼리 리뷰 |
| + | **`santa-method` 스킬** | **적대적 2-에이전트 검증** — 독립 에이전트 2개가 각각 리뷰, 둘 다 PASS해야 통과 |

### E2E Gate 단계 (신규)
| 추가 | ECC 컴포넌트 | 역할 |
|------|-------------|------|
| + | `e2e-runner` 에이전트 | Playwright E2E 자동 생성+실행 |
| + | `e2e-testing` 스킬 | POM 패턴, CI/CD 연동 |
| + | `verification-loop` 스킬 | 빌드+타입+린트+테스트 종합 검증 |
| + | `click-path-audit` 스킬 | 버튼 상태 추적 (Phantom Success 감지) |

### 완료 후
| 추가 | ECC 컴포넌트 | 역할 |
|------|-------------|------|
| + | `/learn-eval` 커맨드 | 세션 패턴 자동 추출 |
| + | `/checkpoint` 커맨드 | 저장점 생성 |

---

## 2. kdh-code-review-full-auto v4.0 + ECC

### Static Gate
| + | `quality-gate` 커맨드 | 포맷+린트 자동 체크 |
| + | `plankton-code-quality` 스킬 | 편집 시 실시간 품질 강제 |

### Visual/E2E Phase
| + | `socrates-functional` 에이전트 | CRUD/폼/네비게이션 검증 |
| + | `socrates-visual` 에이전트 | 레이아웃/디자인 토큰 검증 |
| + | `socrates-edge` 에이전트 | 보안/콘솔에러/빈상태 검증 |
| + | `socrates-regression` 에이전트 | 사이드바/테마/공유컴포넌트 |
| + | `e2e-runner` 에이전트 | 자동 테스트 생성 |
| + | `browser-qa` 스킬 | 레이아웃/폼/인터랙션 검증 |

### 3-Critic Party
| + | `code-reviewer` 에이전트 | 범용 리뷰 |
| + | `typescript-reviewer` 에이전트 | TS 전문 |
| + | `security-reviewer` 에이전트 | 보안 전문 |
| + | **`santa-method` 스킬** | 적대적 검증 (2개 독립 에이전트) |

### Auto-Fix Phase
| + | `build-error-resolver` 에이전트 | 빌드 에러 자동 수정 |
| + | `refactor-cleaner` 에이전트 | 데드 코드 정리 |
| + | `ai-regression-testing` 스킬 | AI 코드 회귀 방지 |

---

## 3. kdh-playwright-e2e-full-auto-24-7-tmux v2.0 + ECC

### Agent 프롬프트 강화
| Agent | + ECC |
|-------|-------|
| Agent A (Functional) | `socrates-functional` 에이전트 프롬프트 통합 |
| Agent B (Visual) | `socrates-visual` + `design-system` 스킬 |
| Agent C (Edge) | `socrates-edge` + `security-review` 스킬 |
| Agent D (Regression) | `socrates-regression` + `click-path-audit` 스킬 |

### Fixer 강화
| + | `build-error-resolver` 에이전트 | 자동 수정 |
| + | `ai-regression-testing` 스킬 | AI 코드 회귀 방지 |
| + | `verification-loop` 스킬 | 수정 후 종합 검증 |

### 완료 후
| + | `/learn-eval` | E2E에서 배운 패턴 저장 |

---

## 4. kdh-uxui-redesign-full-auto-pipeline v7.0 + ECC

### 디자인 시스템 Phase
| + | `design-system` 스킬 | 디자인 시스템 생성/감사 |
| + | `design-principles` 스킬 | 시각 디자인 원칙 적용 |
| + | `design-masters` 스킬 | 전설적 디자이너 패턴 참고 |

### 구현 Phase
| + | `frontend-patterns` 스킬 | React 패턴 |
| + | `coding-standards` 규칙 | TS 표준 |
| + | `tdd-workflow` 스킬 | 컴포넌트 TDD |

### 리뷰 Phase
| + | `synthesis-master` 에이전트 | 통합 UI/UX 분석 |
| + | `/libre-ui-critique` 커맨드 | 디자인 피드백 |
| + | `/libre-a11y-audit` 커맨드 | 접근성 감사 |
| + | `/libre-ui-responsive` 커맨드 | 반응형 체크 |

---

## Santa Method 통합 상세

### 개념
코드 리뷰 단계에서 2개 독립 에이전트가 **서로 모르는 상태로** 동일 코드를 리뷰.
둘 다 PASS해야 통과. 하나라도 FAIL이면 수정 필요.

### 적용 조건
- **모든 Story**: 기본 code-reviewer 1명 + santa-method 검증
- **Grade A Story** (critical): santa-method + security-reviewer 추가
- **UXUI 변경**: santa-method + socrates-visual 추가

### 비용 영향
| 단계 | Before | After (santa) | 증가 |
|------|--------|---------------|------|
| 코드 리뷰 | 3 Critic | 3 Critic + 2 Santa | ~40% |
| 총 파이프라인 | 1x | ~1.3x | 적정 |

### 왜 필요한가
온보딩 토스트 버그 = 3 Critic이 놓친 것. Santa는 독립 관점이라 한쪽이 "toast만 보고 OK" 해도 다른 쪽이 "DB 쓰기 없음" 잡을 확률 높음.

---

## 자동 학습 루프 (모든 파이프라인 공통)

```
파이프라인 실행
  → continuous-learning-v2 observe hook (자동)
  → instinct 생성 (PreToolUse/PostToolUse에서)
  → 파이프라인 완료 시 /learn-eval (자동)
  → 3시간마다 /kdh-ecc-3h (dream + prune)
  → 12시간마다 /kdh-ecc-12h (evolve → 새 스킬)
  → 다음 파이프라인에서 진화된 스킬 자동 적용
```

이것이 ECC의 **자기강화 사이클**. 파이프라인을 돌릴수록 Claude가 강해짐.
