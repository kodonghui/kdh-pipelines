---
name: kdh-report
description: "CEO 전용 법학논문형 보고서 v1 — I~VIII 번호체계 + '현재→변경' 대비 중심 + 기술용어 즉시풀이. 3회 /kdh-research (법학논문작성법/보고서작성법/모범사례) 캐시 후 board corpus 를 비개발자 친화 논증문으로 변환. 호출: /kdh-report board=<board-id> 또는 topic=\"X\" corpus=\"p1,p2\". 트리거: '보고서 써', '보고서 다시 써', '쉽게 써', 'CEO용 보고서', '평문 보고서', '/kdh-report'"
---

# /kdh-report — CEO 전용 법학논문형 보고서 v1

사용자가 `/kdh-report` 를 호출하거나 "보고서 다시 써 / 쉽게 써 / CEO용 보고서" 맥락 발언을 하면, 본 스킬 파이프라인을 실행한다. 기존 `report-renderer.py` (BRD-030 `authored_ratio ≤ 0.10` 제약) 로 만들어진 자동 렌더본을 대체하지 않고 **병존** 하는 CEO 평문본을 생성한다.

## 0. 왜 이 스킬이 필요한가

현 보고서 파이프라인의 한계:
1. `report-renderer.py` 는 저자(A) 가 쓸 수 있는 분량을 전체의 10% 로 제한 (BRD-030). 나머지 90% 는 R0~R6 원본 파일의 byte-verbatim 인용. → CEO 가 이해 가능한 평문 설명이 부족.
2. 기존 보고서는 "회의가 어떻게 진행됐나" 를 기록하는 데 최적화됨. CEO 는 "결국 뭐가 바뀌는가" 를 궁금해함. 중심축 불일치.

해결: BRD-030 제약 밖에서 동작하는 CEO 전용 보고서 파이프라인. 파일 경로 충돌 없이 `-ceo.md` 접미사로 병존.

## 1. 사용법

```
/kdh-report board=<board-id>
/kdh-report topic="<한국어 주제>" corpus="<path1>,<path2>,..."
/kdh-report board=<board-id> --refresh   # research-cache 강제 갱신
```

- `board=<id>` : `_bmad-output/boards/<id>/` 아래 consensus·signatures·rounds 자동 로드 (1순위)
- `topic=...&corpus=...` : board 가 없는 자유 주제. corpus 는 쉼표 구분 파일 경로 리스트 (2순위)
- `--refresh` : 30일 TTL 무시, 3회 /kdh-research 재실행 강제

**CEO 결정 (2026-04-23):** 중간 확인 GATE 없음. 한 번 명령하면 research + 본문 생성 + Codex 백그라운드 검증까지 자동 완주. 마음에 안 들면 "다시 써" 지시로 재생성.

## 2. 철학 3원칙 (본문 평가 기준)

1. **"현재 → 변경" 이 본문 중심축**
   CEO 가 궁금한 답은 "결국 뭐가 바뀌는가". 이 답이 첫 500자 안에 들어와야 함. as-is/to-be 4열 대비표를 III 장 + VI 장에 필수 배치.

2. **기술용어 첫 등장 시 즉시 풀이**
   영문 약어 3자 이상 (EARS/BRD/manifest/sha256/quota/rotation/jsonl 등) 은 첫 등장 시 `EARS (요구사항 작성 문법)` 형식으로 괄호 풀이. 사전: `templates/term-glossary-sidebar.md`.

3. **구체 수치·시간·사례 필수**
   "개선됨" "더 좋다" "합리적" 금지. "15분 → 5분" "월 $19.99" "주 2회 → 월 1회 미만" 처럼 구체 숫자·시간·사례로 서술.

## 3. 번호 체계 (6단계 법학논문형)

```
I. 문제의 제기           (최상위)
  1. 현재 상태           (2단계)
    (1) 구조적 원인       (3단계)
      가. 증상 A          (4단계)
        1) 세부           (5단계, 선택)
          가) 예시         (6단계, 선택)
```

최대 4단계 (`가.` 까지) 가 표준. 5-6단계는 특히 상세 필요 시 예외.

## 4. 문서 뼈대 I~VIII (필수 구조)

| 장 | 제목 | 목적 | 특기 |
|---|---|---|---|
| I | 문제의 제기 | 현재 상태 + 왜 문제인가 | 첫 500자 안에 "지금 X → 변경 후 Y" 한 줄 요약 **필수** |
| II | 배경·조사 근거 | /kdh-research 3회 + board corpus 요약 | 각 인용에 출처 1줄 |
| III | 제안 | as-is/to-be 4열 대비표 **필수** | 여러 안이면 A안/B안 병렬 |
| IV | 조작적 정의와 사례 | 구체 시나리오 3개 | 각 "현재 ↔ 변경 후" 동작 서술 |
| V | 제외·예외 기준 | 범위 밖 명시 | "왜 제외했나" 이유 1줄 |
| VI | 현재→변경 영향 분석 | 비용·시간·리스크 표 | 3열 `항목 \| 이전 \| 이후` + CEO 체감 별도 하위절 |
| VII | 논증 | claim-evidence-explanation 3단 블록 | 주장→근거(≥2)→설명 |
| VIII | 향후 일정·Todo | 구체 일자 + CEO 결재 대기 항목 | 표 + 하위 리스트 |

전 뼈대 상세: `templates/skeleton-I-VIII.md`. 표 포맷: `templates/as-is-to-be-table.md`. 논증: `templates/claim-evidence-block.md`. 용어 사전: `templates/term-glossary-sidebar.md`.

## 5. 실행 파이프라인 (6 Step · 자동 완주)

### Step 0 — Preflight
1. 인자 파싱 (`board=<id>` 또는 `topic=...` + `corpus=...`).
2. Board 존재 검증: `ls _bmad-output/boards/<id>/publish/manifest.json`.
3. `cache-manifest.yaml` 읽어서 TTL 체크: `expires_utc < now` 이면 Step 1 에서 해당 주제만 재실행.
4. `--refresh` 플래그 시 전면 재실행 예약.
5. 오늘 날짜 MMDD 산출, 출력 파일명 결정: `{MMDD}-{slug}-ceo.md`.
6. 도구: Bash (ls/date), Read (cache-manifest).

### Step 1 — Research 3회 (병렬 · 캐시)
고정 주제 3개:
1. "법학 논문 I~VIII 작성 방식과 한국 법학 논문 번호체계 관례 — 조문 인용·각주·논증 기본 단위"
2. "임원 보고서 작성법 — 비개발자 친화 한국어, 현재→변경 대비 중심, 3-5분 내 본질 파악 가능한 구조"
3. "모범 보고 사례 — before/after 표, 용어 첫등장 풀이, 구체 수치·소요시간·사례 활용"

실행 규칙:
- 각 주제별 `cache-manifest.yaml` TTL 확인. Hit → 캐시 재사용, Miss → `/kdh-research` 호출.
- 3회 호출은 **병렬 백그라운드**. Step 1 총 wall-clock 은 가장 느린 1회와 같음 (약 5-10분).
- 결과 저장: `research-cache/legal-writing.md` / `exec-report.md` / `best-practices.md`.
- `cache-manifest.yaml.topics.*.last_run_utc` + `expires_utc` (= last_run + 30d) 갱신.
- 캐시 hit 3회이면 Step 1 wall-clock ≈ 0.

도구: `/kdh-research` (Skill tool × 3 병렬), Read, Write (cache-manifest).

### Step 2 — Benchmark + Corpus 로드
Benchmark 3 파일 (읽기 전용 · 모범 사례):
- `C:\Users\USER\Desktop\고동희\kdh-conductor\reports\0422-topic1-v2-spec.md` (구조 벤치마크)
- `C:\Users\USER\Desktop\고동희\kdh-conductor\_bmad-output\boards\0418-v3-prd\deliverables\polytank-phase3-release-note.md` (비개발자 한국어 벤치마크)
- `C:\Users\USER\Desktop\고동희\kdh-conductor\reports\0418-v3-prd.md` §I.2 (현재↔변경 표 벤치마크)

Board corpus 자동 로드 (`board=<id>` 지정 시):
- `_bmad-output/boards/<id>/publish/manifest.json` → canonical 파일 경로 확보
- `_bmad-output/boards/<id>/consensus/requirements.jsonl` → REQ 리스트
- `_bmad-output/boards/<id>/consensus/signatures.jsonl` → 합의 수준
- `_bmad-output/boards/<id>/events/issues.jsonl` → R3 CRITICAL/HIGH 이슈
- `_bmad-output/boards/<id>/rounds/R*.md` 샘플 (토론 맥락)
- 기존 `reports/<slug>.md` (자동 렌더본 · 참고용)

도구: Glob, Read.

### Step 3 — I~VIII 본문 생성 (LLM authored)
뼈대 (`templates/skeleton-I-VIII.md`) 채우기. 각 장의 placeholder `{{...}}` 를 실제 corpus + research 근거로 치환.

자체 검증 규칙 (생성 후 즉시):
- [ ] 첫 500자 안에 "지금 X, 변경 후 Y" 문장 1개 이상 — 없으면 재작성
- [ ] III 장 + VI 장에 4열 as-is/to-be 표 각 ≥1 + "CEO 체감 차이" 열 비칸 0
- [ ] VII 장에 claim-evidence-explanation 블록 ≥2
- [ ] 번호 체계 `I. → 1. → (1) → 가.` 4단계 최소 1회

위 규칙 위반 시 자체 재작성 (CEO 대기 없음).

도구: 내부 생성 (LLM).

### Step 4 — 용어 풀이 스캔
1. 생성 본문에서 영문 약어 3자 이상 regex 탐지 (`\b[A-Z]{3,}\b`) + 기술용어 리스트 매칭.
2. 사전 (`templates/term-glossary-sidebar.md`) 과 교차 참조.
3. 첫 등장 시 풀이 없으면 `EARS (요구사항 작성 문법)` 형식 자동 삽입.
4. 사전 미등재 신조어 발견 시 경고 로그 (`research-cache/{slug}-term-warnings.log`) 남기고 진행. **자동 완주 유지** (CEO 결정).

도구: Grep, Edit.

### Step 5 — 저장 + `_index.yaml` 등재
2곳 저장:
1. `C:\Users\USER\Desktop\고동희\kdh-conductor\reports\{MMDD}-{slug}-ceo.md` (CEO 열람용, 루트 reports/)
2. `C:\Users\USER\Desktop\고동희\kdh-conductor\_bmad-output\kdh-plans\{MMDD}-report-{slug}.md` (아카이브)

`_bmad-output/_index.yaml` 에 entry append:
```yaml
- path: "reports/{MMDD}-{slug}-ceo.md"
  type: ceo-report
  source: kdh-report
  board_ref: "<board-id>"
  generated_utc: "<ISO8601>"
```

**절대 금지 (봉인 체인 보호):**
- 원본 `reports/<slug>.md` (자동 렌더본) 미변경
- `_bmad-output/boards/<id>/publish/manifest.json` 미변경
- `_bmad-output/boards/<id>/publish/decision.yaml` 미변경
- `_bmad-output/boards/<id>/publish/READY_TO_SHIP.token` 미변경
- `_bmad-output/boards/<id>/consensus/signatures.jsonl` 미변경

`cache-manifest.yaml.boards[]` 에 이번 호출 append (board_id / generated_utc / cache_hit 개수).

도구: Write, Edit.

### Step 6 — Codex 검증 (백그라운드 · CEO 대기 없음)
백그라운드 실행:
```bash
codex exec --full-auto --sandbox workspace-write -a never <<EOF
다음 보고서가 비개발자 CEO 에게 얼마나 이해되는지 1-10점으로 평가하고,
기술용어 풀이 누락 개수, as-is/to-be 대비 명확도 (1-10), 구체 수치 밀도 (줄당)
를 계산해서 research-cache/{slug}-codex-score.md 에 저장해.
보고서 경로: reports/{MMDD}-{slug}-ceo.md
EOF
```
결과는 비동기 저장. CEO 에게는 Step 5 완료 직후 "보고서 생성 완료. Codex 점수는 백그라운드 계산 중 (3-5분)" 보고하고 종료.

도구: Bash (`run_in_background: true`).

## 6. 출력 스펙

### 파일명 규칙
- Board 호출: `reports/{MMDD}-{board-slug}-ceo.md`
  - 예: `board=0422-topic2-trio-harness` → `reports/0423-topic2-trio-harness-ceo.md`
- Topic 호출: `reports/{MMDD}-{slug-from-topic}-ceo.md`
  - slug 는 topic 한글 → ASCII 정규화 + 공백→hyphen. 실패 시 timestamp 폴백.

### 표지 블록 (문서 상단 필수)
```markdown
# <주제 한국어 제목> — CEO 보고서

**일자:** YYYY-MM-DD
**Board ID:** <id 또는 "topic-only">
**한 줄 요약:** 지금 X, 변경 후 Y.
**CEO 결재 대기:** N건 (VIII 장 참조)
```

### 말미 블록 (문서 하단 필수)
```markdown
---
*본 보고서는 /kdh-report v1 로 생성. 원본 자동 렌더본 `reports/<slug>.md` 는 별도 보관 (봉인 무간섭). 재작성 필요 시 "보고서 다시 써" 지시.*
*Codex 평가 점수: research-cache/<slug>-codex-score.md (생성 후 3-5분 내 확인 가능)*
```

## 7. 실패 모드 & 복구

| 실패 | 원인 | 복구 |
|---|---|---|
| Board 경로 없음 | `board=<id>` 오타 또는 reorg 이동 | stderr 출력 + `ls _bmad-output/boards/` 결과 제시. 종료 |
| `/kdh-research` 타임아웃 | 외부 API 장애 | 캐시 있으면 재사용, 없으면 해당 주제 research 결과를 "skipped: <이유>" 로 기록 + 본문 생성은 진행. 경고 로그 |
| 첫 500자 "지금→변경" 검증 3회 실패 | corpus 에 실제 변경 정보 부재 | CEO 에게 "board 에 as-is/to-be 정보가 없어 요약 불가. 근거 파일 추가 지정?" 보고 후 종료 |
| 자체 검증 규칙 위반 시 재작성 무한 루프 | LLM 주장 불안정 | 최대 3회 재작성, 이후 통과분만 저장 + 실패 항목 경고 로그 |
| Codex 백그라운드 실패 | Codex 세션 미가용 | research-cache/{slug}-codex-score.md 에 "unavailable: <reason>" 기록. 보고서 자체는 유효 |

## 8. 재사용되는 기존 스킬·파일

- **`/kdh-research`** — `C:\Users\USER\.claude\skills\kdh-research\SKILL.md`. Step 1 3회 호출. Skill tool 로 invoke.
- **벤치마크 3파일** — §Step 2 절대 경로 3개. Read-only 참조.
- **템플릿 4파일** — `~/.claude/skills/kdh-report/templates/` 하위. Step 3 에서 구조 가이드로 참조.

## 9. v2 후보 (BACKLOG)

- `kdh-board-publish` 가 publish 직후 `/kdh-report` 자동 호출 → 모든 board publish 가 2 파일(자동본 + 평문본) 동시 생성. Topic 2/3 실전 검증 후 결정.
- Benchmark 3파일 최신화 루틴 (월 1회 리뷰)
- 다국어 보고서 (영어 판 CEO 확장 시)

---

*SKILL.md authored 2026-04-23 for v1. 근거: CEO 지시 "보고서 뭐라는지 하나도 모르겠어;;; 법학 논문 작성 방식으로 I. 문제의 제기 II. ... 1. a. 2. ... III... 현재에서 어떻게 바뀌는지를 위주로". Plan: `C:\Users\USER\.claude\plans\scalable-whistling-moonbeam.md`.*
