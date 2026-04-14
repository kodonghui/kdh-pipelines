---
name: star-gt-mission
description: "GT 미션 부트스트랩. 폴더+로그+프롬프트 뼈대+INDEX/CLAUDE 갱신 원스톱. 지표 독립적 설계."
---

# /star-gt-mission - GT 미션 부트스트랩

새 GT 미션을 시작할 때 필요한 모든 것을 한 번에 세팅한다.
폴더 생성 → 로그 초기화 → 프롬프트 뼈대 → INDEX.md + CLAUDE.md 갱신.

## 사용법

```
/star-gt-mission                              ← 대화형 (변수 물어봄)
/star-gt-mission verification 정합성          ← 지표명+한글명 직접 지정
/star-gt-mission routable-negative 연결성     ← 변형 미션명 가능
```

인수 없으면 대화형. 인수 있으면 지표명+한글명으로 바로 시작.

## 사전 탐색: star-docs-chain 연결

실행 시 가장 먼저 `docs/reports/` 에서 최근 노션 TODO 파일을 탐색한다.

```
1. Glob "docs/reports/*-notion-*.md" → 최신 파일
2. 파일 내에서 <!-- gt-action: {지표} {한글명} --> 마커 검색
3. 마커 발견 시:
   "최근 회의에서 {지표}({한글명}) GT 제작 항목이 있습니다. 이 미션을 시작할까요?"
   → 사용자 "응" → 지표명+한글명 자동 채움
   → 사용자 "아니" → 평소대로 대화형 진행
4. 마커 없으면: 이 Step 스킵, 바로 Step 1로
```

## 실행 흐름

### Step 1: 변수 수집

**인수가 있으면** 파싱:
- 첫 번째 인수 = 지표명 (영문, 폴더명에 사용)
- 두 번째 인수 = 한글명 (문서에 사용)

**인수가 없으면** 사용자에게 질문:

```
어떤 지표의 GT 미션을 시작할까요?
1. routable (연결성)
2. request (요청)
3. verification (정합성)
4. 직접 입력 (새 지표)
```

추가 질문:
```
미션 목적을 한 줄로 알려주세요.
예: "정합성 지표 True GT 15건 제작"
```

**자동 결정 변수:**
- `MMDD`: 오늘 날짜 (CLAUDE.md 규칙)
- `데이터 소스`: `data/0407-chunked-decomposed-dataset.jsonl` (기본값, 사용자 변경 가능)

### Step 2: results/ 하위 구조 선택

```
results/ 하위 폴더를 어떻게 구성할까요?
a) true-gt/fail-gt → 하위에 유형별 (요청 GT 방식)
b) subcategory별: summarization/extraction/reasoning (연결성 GT 방식)
c) 직접 지정
```

사용자가 a를 선택하면:
```
true-gt/fail-gt 아래 하위 폴더 이름을 알려주세요.
예: coverage, frame, prohibition
(쉼표로 구분, 없으면 Enter)
```

사용자가 b를 선택하면:
```
results/summarization/
results/extraction/
results/reasoning/
```

### Step 3: 선택 폴더 (analysis/, tools/)

```
추가 폴더가 필요한가요?
- [ ] analysis/ (전처리 데이터 저장)
- [ ] tools/ (검수 도구 등)
- [ ] 둘 다 불필요
```

### Step 4: Dry-run 미리보기

생성될 전체 구조를 미리보기로 출력한다.

```
## 미리보기: gt/MMDD-{지표}/

gt/MMDD-{지표}/
├── prompts/
│   └── MMDD-{유형}-prompt.md        ← 프롬프트 뼈대 (9섹션)
├── results/
│   ├── {사용자 선택 구조}
│   └── ...
├── log/
│   └── MMDD-{지표}-gt-log.md        ← 로그 템플릿
├── [analysis/]                       ← 선택 시
└── [tools/]                          ← 선택 시

+ INDEX.md Active 테이블에 추가
+ CLAUDE.md 현재 GT 작업 현황에 추가

이대로 생성할까요?
```

**승인 없이 생성 금지.**

### Step 5: 생성 실행

승인 후 실제 파일/폴더를 생성한다.

#### 5-1: 폴더 생성

```bash
mkdir -p "gt/MMDD-{지표}/prompts"
mkdir -p "gt/MMDD-{지표}/results/{하위구조}"
mkdir -p "gt/MMDD-{지표}/log"
# 선택 폴더
mkdir -p "gt/MMDD-{지표}/analysis"   # 선택 시
mkdir -p "gt/MMDD-{지표}/tools"      # 선택 시
```

#### 5-2: 로그 템플릿 생성

파일: `gt/MMDD-{지표}/log/MMDD-{지표}-gt-log.md`

```markdown
# {한글명} GT 작업 로그

**시작일**: {오늘 날짜 YYYY-MM-DD}
**작성자**: 고동희 (DA)
**목적**: {미션 목적}
**관련 폴더**: gt/MMDD-{지표}/

---

## 작업 이력

### {오늘 날짜}

- 미션 폴더 생성 (/star-gt-mission)
- 프롬프트 뼈대 작성

---

## 대상 ID

| # | ID | subcategory | 상태 | 비고 |
|---|------|-------------|------|------|
<!-- 대상 ID 추가 -->

---

## 변경 이력

| 날짜 | 변경 내용 | 이유 |
|------|----------|------|
| {오늘} | 미션 생성 | 초기 세팅 |
```

#### 5-3: 프롬프트 뼈대 생성

파일: `gt/MMDD-{지표}/prompts/MMDD-true-gt-prompt.md`

이전 미션 프롬프트를 **참조 링크**로 제공하고, 공통 9섹션 뼈대를 생성한다.

```markdown
# {한글명} 지표 True GT 프롬프트

> 이전 미션 참고:
> - 연결성: gt/0402-routable-26sample/prompts/gt-pass-prompt-unified.md
> - 요청: gt/0406-request/prompts/0407-true-gt-prompt.md

## 작업 흐름

1. "작업할 ID를 알려주세요." 라고 물어본다
2. 사용자가 ID를 주면 해당 데이터를 로드한다
3. 판정 절차에 따라 평가한다
4. JSON 결과를 저장한다
5. 결과를 보여주고 다음 ID를 물어본다

**절대 여러 건을 한 번에 자의적으로 처리하지 말 것.**

## 역할

<!-- 1줄 역할 정의. 예: "당신은 {한글명} 지표의 GT 라벨러입니다." -->

## 데이터 소스

- 원본: `{데이터 소스 경로}`
- 추가 참조: <!-- 필요 시 추가 -->

## 결과 저장

- 경로: `gt/MMDD-{지표}/results/`
- 파일명 규칙: `{id}_result.json`

## 대상 ID

| # | ID | subcategory | 비고 |
|---|------|-------------|------|
<!-- 대상 ID는 나중에 추가 -->

## 출력 JSON 형식

```json
{
  "id": "k2-nia-long-context-XXXX"
  // JSON 스키마 정의
}
```

## 판정 기준

### 요약 (summarization)

<!-- 요약 태스크 판정 기준 -->

### 정보추출 (extraction)

<!-- 정보추출 태스크 판정 기준 -->

### 추론 (reasoning)

<!-- 추론 태스크 판정 기준 -->

## 주의사항

- [ ] 한 번에 1건만 작업. 사용자 지정 ID만 처리
- [ ] subcategory 순서: 요약 - 정보추출 - 추론
- [ ] em dash 사용 금지
- [ ] 결과 JSON은 `results/` 하위 적절한 폴더에 저장
```

### Step 6: INDEX.md + CLAUDE.md 갱신

#### INDEX.md 갱신

**Active 테이블**에 행 추가:
```
| `gt/MMDD-{지표}/` | {미션 목적} | 0 | 진행 중 |
```

**Folder Tree**의 `gt/` 섹션에 추가:
```
│   └── MMDD-{지표}/
│       ├── prompts/          (뼈대 1종)
│       ├── results/          ({하위구조 설명})
│       └── log/              (MMDD-{지표}-gt-log.md)
```

#### CLAUDE.md 갱신

**현재 GT 작업 현황** 테이블에 행 추가:
```
| {한글명} ({지표}) | `gt/MMDD-{지표}/` | 진행 중 | {비고} |
```

**갱신 전 미리보기를 보여주고 승인 받기.**

### Step 7: 완료 보고

```
## 미션 생성 완료: gt/MMDD-{지표}/

생성된 파일:
- gt/MMDD-{지표}/prompts/MMDD-true-gt-prompt.md (뼈대)
- gt/MMDD-{지표}/log/MMDD-{지표}-gt-log.md (템플릿)
- gt/MMDD-{지표}/results/{하위구조}/ (빈 폴더)

갱신된 파일:
- INDEX.md (Active 테이블 + Folder Tree)
- CLAUDE.md (GT 작업 현황)

다음 단계:
1. 프롬프트 뼈대 내용 채우기 (gt/MMDD-{지표}/prompts/)
2. 대상 ID 선정 + 로그에 기록
3. GT 작업 시작
```

## 공통 규칙

### CLAUDE.md 준수 사항 (GT 작업 규칙에서)
- 미션 = 하나의 GT 작업 단위. `gt/MMDD-{지표}/` 폴더 1개 대응
- 프롬프트 파일이 미션의 설계서: 데이터 소스, 결과 경로, 출력 포맷 전부 포함
- 데이터 소스/경로를 CLAUDE.md에 하드코딩하지 말 것 → 프롬프트에 명시
- 폴더/파일 생성 시 INDEX.md 반드시 갱신
- subcategory 순서: 요약 - 정보추출 - 추론

### 파일 네이밍
- MMDD prefix + kebab-case
- 한국어 폴더명 허용

### 안전 원칙
- 기존 폴더가 이미 있으면 **중단 + 사용자 확인** (덮어쓰기 금지)
- 승인 없이 파일 생성/수정 금지

## Quality Self-Check

- [ ] 지표명과 한글명이 일치하는가?
- [ ] 폴더 구조가 미리보기와 동일한가?
- [ ] 로그 템플릿에 시작일/작성자/목적이 있는가?
- [ ] 프롬프트 뼈대에 9개 섹션이 모두 있는가?
- [ ] 프롬프트에 "1건씩 작업" 원칙이 명시되어 있는가?
- [ ] 프롬프트에 데이터 소스 경로가 명시되어 있는가?
- [ ] INDEX.md Active 테이블에 추가되었는가?
- [ ] INDEX.md Folder Tree에 추가되었는가?
- [ ] CLAUDE.md 현재 GT 작업 현황에 추가되었는가?
- [ ] 기존 폴더 충돌 체크를 했는가?

## 유기성

### ← star-docs-chain 연결
`docs/reports/*-notion-*.md` 에서 `<!-- gt-action: {지표} {한글명} -->` 마커를 탐색.
마커가 있으면 지표명/한글명을 자동 제안. 없으면 평소대로 대화형.

### → GT 작업 연결
미션 생성 후 프롬프트를 읽으면 CLAUDE.md GT 작업 규칙에 따라:
"작업할 ID를 알려주세요." 로 시작하는 1건씩 작업 루프.
이 루프는 별도 스킬이 아니라 프롬프트 자체에 내장된 워크플로우.
