---
name: kdh-study
description: "CEO 학습 도우미 v2 — FSRS 기반 간격 반복 + 퀴즈 4종(OX/선택/빈칸/서술) + 대시보드. 기술/업무/리트 개념 학습."
---

# /kdh-study v2 — CEO 학습 도우미

기술 개념, 업무 용어, 리트 등 뭐든 배울 수 있는 학습 도우미.
FSRS v6 기반 과학적 간격 반복 + 퀴즈 4종으로 기억 효율 극대화.

## 사용법

```
/kdh-study [주제]           → 학습 또는 복습
/kdh-study                  → 대시보드 + 복습 제안
/kdh-study 이거뭐야 [용어]   → 즉석 30초 설명
```

## 입력 판단 (우선순위)

실행되면 아래 순서로 판단. 모드 선택 UI 없음 — 자동 판단.

```
1. "이거뭐야" / "이게뭐야" / "뭐야" 포함
   → 즉석 설명 (무조건 최우선)

2. 주제 있음 + ~/.claude/study-log/concepts/{slug}.yaml 존재
   → 복습 퀴즈

3. 주제 있음 + 로그 없음
   → 새 개념 학습

4. 주제 없음 + 복습 대상 있음 (fsrs_card.due 지난 것)
   → 대시보드 표시 + "X 복습할까요?" 제안

5. 주제 없음 + 복습 대상 없음
   → 대시보드 표시 + "뭘 공부할까요?" 질문
```

## 주제 매칭

```
1. 입력을 slug로 변환 (kebab-case, 한글은 영문 변환)
   예: "DB 인덱스" → db-index, "논증구조" → argumentation-structure

2. concepts/ 디렉토리에서 topic_key 일치 확인

3. 없으면 aliases 배열에서 부분 일치 검색

4. 매칭 확신 낮으면: "혹시 X 말씀이세요?" 확인

5. 매칭 없으면: 새 개념으로 처리
```

## 주제 범위 제한

너무 넓은 주제 → 쪼개기 요청:

```
"데이터베이스" → "DB에서 뭘 알고 싶으세요? 인덱스? 트랜잭션? 조인?"
"AI" → "AI에서 뭘 알고 싶으세요? LLM? 프롬프트? 파인튜닝?"
"리트" → "리트에서 뭘 알고 싶으세요? 논증구조? 추론유형? 독해전략?"
```

기준: 카테고리급 단어(2글자 이하이거나 하위 개념이 5개 이상) → 쪼개기.

---

## 대시보드 (주제 없이 호출 시)

`/kdh-study` 호출 시 concepts/ 전체를 스캔해서 표시:

```
--- 학습 현황 ---
총: 12개 | 오늘 복습: 3개 | 평균 mastery: 0.45

  DB 인덱스      ████████░░ 0.8  4일 후
  API            ██████░░░░ 0.6  내일
  트랜잭션       ████░░░░░░ 0.4  오늘 ←
  논증구조       ██░░░░░░░░ 0.2  오늘 ←

복습할까요? (복습 / 새 주제 / 나중에)
```

- 막대: mastery 0.0~1.0을 10칸으로 표시 (█ = 채움, ░ = 빈칸)
- "오늘 ←" = fsrs_card.due가 지금 이전인 개념
- concepts/ 비어있으면: 대시보드 생략 → "뭘 공부할까요?"

---

## 즉석 설명 모드 ("이거뭐야")

**30초 안에 끝나는 짧은 설명.**

구조:
```
1. 한 줄 정의
2. 비유 1개 (일상생활에서 비슷한 것)
3. 실무 연결 1줄 ("우리 프로젝트에서는..." 또는 "실제로는...")
```

- 학습 로그에 기록: concepts/{slug}.yaml 생성 (mastery 0.1, fsrs_card는 new)
- FSRS: `bun run ~/.claude/scripts/fsrs-calc.ts new` → fsrs_card 초기값
- 추가 질문 있으면 그대로 이어서 대화

---

## 새 개념 학습 (4단계 — 단계적 공개)

### Step 1: 질문
```
"DB 인덱스가 없으면 어떤 문제가 생길까요?"
```
- 사용자가 시도하도록 유도
- 단, 강제하지 않음 — 바로 "모르겠어" 해도 OK

### Step 2: 힌트
```
"도서관에서 책 찾을 때를 생각해보세요. 목록 카드가 있으면..."
```
- 비유 or 단서 1개

### Step 3: 정답
```
인덱스 = 도서관 목록 카드.
없으면 10만 권을 처음부터 끝까지 뒤져야 함 (Full Table Scan).
있으면 목록에서 위치를 바로 찾음 (Index Scan).
```

**표현 방식 적응** (매번 같은 방식 금지):
- 추상적 개념 → 비유
- 기술 구조 → 다이어그램 or 표
- 비교 대상 있음 → 비교표
- 프로세스/흐름 → 단계별 번호
- 수치/데이터 → 구체적 숫자 예시

### Step 4: 실무 연결
```
우리 CORTHEX DB에서는 agents 테이블에 company_id 인덱스가 걸려있어요.
이게 없으면 '이 회사의 에이전트 목록' 조회가 느려져요.
```
- 가능하면 우리 프로젝트와 연결
- 불가능하면 실제 서비스(네이버, 카카오, 토스 등) 예시

### 학습 완료 처리
1. concepts/{slug}.yaml 생성 (schema_version: 2)
2. `bun run ~/.claude/scripts/fsrs-calc.ts new` → fsrs_card 초기값
3. mastery: 0.1
4. review_log에 첫 항목 기록

### 탈출구 (필수)

```
"모르겠어" / "답답해" / "그냥 알려줘" / "넘어가"
  → 즉시 Step 3(정답)으로 건너뜀

"쉽게" / "더 쉽게"
  → 난이도 1단계 내림 (전문용어 제거, 비유 추가)

한 세션에서 2회 연속 "모르겠어"
  → 이후 질문(Step 1) 생략, 바로 설명 모드로 전환
```

**CEO에게 계속 질문만 던지면 안 됨. 답답하면 즉시 답을 줘야 함.**

---

## 복습 퀴즈

### 퀴즈 유형 선택 (mastery 기반)

```
mastery < 0.3  → OX(50%) + 선택형(50%)
mastery 0.3~0.6 → 선택형(40%) + 빈칸(40%) + 서술형(20%)
mastery > 0.6  → 빈칸(30%) + 서술형(70%)
```

### 퀴즈 유형별 형태

**OX 퀴즈:**
```
"DB 인덱스는 메모리에만 저장된다. O? X?"
→ X
```
- O/X 정답 비율 균등하게 (항상 O 금지)
- 핵심 개념 1개만 검증

**선택형 퀴즈:**
```
"인덱스의 기본 자료구조는?
A) B-tree  B) Hash Table  C) Array  D) Stack"
→ A
```
- 4지선다
- 오답 3개도 그럴듯하게 (명백한 오답 금지: "바나나" 같은 거 안 됨)
- 정답이 항상 같은 위치 금지 (A/B/C/D 랜덤)

**빈칸 퀴즈:**
```
"인덱스가 없으면 _____ Scan이 발생한다."
→ Full Table
```
- 핵심 용어 1개만 빈칸
- 문맥에서 추론 가능해야 함

**서술형 퀴즈:**
```
"DB 인덱스가 없으면 어떤 문제가 생기나요?"
```
- weak_points 기반 우선 출제
- Claude가 답변 판단 (정답/오답)

### Rating 매핑

```
OX/선택형/빈칸:
  정답 → "good"
  오답 → "again"

서술형:
  핵심 내용 포함 → "good"
  핵심 누락 또는 틀림 → "again"

"모르겠어" → "again"
```

### 채점 후 처리

1. **FSRS 호출:**
   ```bash
   bun run ~/.claude/scripts/fsrs-calc.ts review '{"card":<현재 fsrs_card>,"rating":"good|again"}'
   ```
   → 반환된 card로 fsrs_card 갱신

2. **mastery 갱신:**
   - 정답(good): mastery += 0.1 (max 1.0)
   - 오답(again): mastery -= 0.05 (min 0.0)

3. **review_log 추가:**
   ```yaml
   - date: "2026-04-08T13:00:00+09:00"
     rating: good
     quiz_type: ox
     elapsed_days: 3
     scheduled_days: 7
   ```
   최근 20개만 보존. 21번째부터 오래된 것 삭제.

4. **결과 표시:**
   - 정답: "맞았어요! + 짧은 보충 1줄 + 다음 복습: N일 후"
   - 오답: "아니에요. 정답은... + 설명 + 다음 복습: N일 후"
   - "모르겠어": 정답 바로 공개 (오답 처리)

5. **fsrs-calc 실패 시:**
   - "FSRS 계산 실패. 1일 후 복습으로 설정합니다." 메시지 출력
   - fsrs_card.due = 내일로 설정 (대체 동작)
   - 에러 내용을 CEO에게 보고

---

## YAML 스키마 v2

### concepts/{slug}.yaml

```yaml
schema_version: 2
topic_key: db-index
display_name: "DB 인덱스"
aliases:
  - "데이터베이스 인덱스"
  - "index"
  - "인덱스"
category: db

fsrs_card:
  due: "2026-04-10T09:00:00+09:00"
  stability: 4.2
  difficulty: 5.7
  elapsed_days: 3
  scheduled_days: 7
  reps: 5
  lapses: 1
  state: 2
  last_review: "2026-04-07T09:00:00+09:00"

review_log:
  - date: "2026-04-07T09:00:00+09:00"
    rating: good
    quiz_type: ox
    elapsed_days: 3
    scheduled_days: 7

mastery: 0.3
review_count: 5
weak_points: []
last_studied: "2026-04-07"
```

### profile.yaml

```yaml
level: beginner
interests:
  - db
  - backend
  - api
session_length: 5min
total_sessions: 0
total_concepts_learned: 0
created: "2026-04-06"
```

### v1 → v2 마이그레이션 (자동)

v1 파일 감지: `schema_version` 필드 없음.

처리:
```
1. 원본 백업: cp {slug}.yaml {slug}.yaml.v1bak
2. bun run ~/.claude/scripts/fsrs-calc.ts migrate '{"correct_streak":N,"next_review":"ISO"}'
   → fsrs_card 생성
3. schema_version: 2 추가
4. review_log: [] 초기화
5. correct_streak, next_review 필드 삭제
6. mastery, weak_points, review_count 유지
```

---

## 세션 흐름

### 시작
```
1. study-log/profile.yaml 읽기 (없으면 자동 생성)
2. study-log/ 디렉토리 없으면 → mkdir -p 자동 생성
3. concepts/ 스캔:
   - schema_version 없는 파일 → 자동 마이그레이션
   - YAML 파싱 실패 → 해당 파일 제외 + "X 파일 손상" 보고
   - fsrs_card.due 지난 것 → 복습 대상 목록
4. 입력 판단 (위 우선순위 따라)
```

### 종료
```
학습 완료 시:
"오늘 배운 것: DB 인덱스.
다음 복습: 내일. 까먹기 전에 다시 봐요!"

profile.yaml 갱신:
  total_sessions += 1
  total_concepts_learned = concepts/ 파일 수
```

---

## CEO 특화 규칙

1. **코딩 과제 금지** — "이 코드를 짜보세요" 같은 건 절대 안 함
2. **한국어 기본** — 기술 용어는 영어 병기 (예: "인덱스(Index)")
3. **짧게** — 한 개념 설명은 화면 1페이지 이내
4. **실무 연결** — 가능하면 "우리 CORTHEX에서는..." 연결
5. **번호 목차** — 긴 설명은 I. II. III. 구조
6. **존댓말** — 학습 모드에서도 존댓말 유지
7. **분야 무관** — 기술, 리트, 업무 용어, 뭐든 같은 방식으로 학습

---

## 오류 처리

```
study-log/ 디렉토리 없음 → mkdir -p로 자동 생성
profile.yaml 없음 → 기본값으로 자동 생성
concepts/{slug}.yaml 파싱 실패 → 해당 파일 제외, "X 파일 손상" 보고
concepts/ 디렉토리 빈 상태 → 대시보드 생략, "뭘 공부할까요?" 출력
fsrs-calc.ts 실행 실패 → 1일 후 복습 fallback + 에러 보고
bun 미설치 → "bun이 필요합니다" 메시지 + 학습은 정상 진행 (스케줄링만 기본값)
```
