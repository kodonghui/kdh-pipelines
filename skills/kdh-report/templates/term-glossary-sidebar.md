# 기술용어 풀이 사전 (seed)

> `/kdh-report` Step 4 (용어 풀이 스캔) 에서 참조.
> 규칙: 본문 첫 등장 시 괄호로 풀이 삽입 (`EARS (요구사항 작성 문법)` 형식). 2회 이상 등장 시에는 풀이 생략.
> 신조어가 본 사전에 없으면 Step 4 가 경고 로그 남기고 진행 (CEO 결정: 자동 완주 유지).

## 프로토콜·방법론

- **EARS** — 요구사항 작성 문법. "시스템은 언제 이런 조건에서 이렇게 행동한다" 식 정형 문장 규약
- **BRD** — Board Requirement Document. 이사회 회의에서 합의된 요구사항 1건을 뜻하는 번호 (예: BRD-031 = 31번째 합의)
- **REQ** — Requirement. BRD 와 거의 동의어. 한 요구사항 1개
- **PRD** — Product Requirement Document. 제품 요구사항 명세서
- **DAG** — Directed Acyclic Graph. 작업 간 의존성을 화살표로 그린 순서도

## 파일 무결성·봉인

- **sha256** — 파일 내용을 64자 지문으로 만드는 계산법. 1 byte 만 바뀌어도 지문이 완전히 달라져서 변조 탐지 가능
- **manifest** — 여러 파일의 sha256 지문을 한 표에 모은 명세서. 이사회 결과물의 "봉인"
- **READY_TO_SHIP.token** — "이 보드 출력물은 봉인되어 CEO 결재 준비 완료" 라는 표식 파일. manifest 가 바뀌면 자동 삭제됨
- **봉인 체인** — manifest 와 decision.yaml, READY_TO_SHIP.token 의 sha256 이 전부 일치해야 유효한 상태

## 로그·이벤트

- **jsonl** — JSON 줄 단위 파일 포맷. 한 줄에 한 이벤트 기록 (예: `{"time":"...", "actor":"A"}`). `.jsonl` 확장자
- **hook** — 특정 사건(파일 쓰기·세션 시작 등) 이 발생할 때마다 자동으로 실행되는 작은 스크립트
- **dead-letter** — 정상 처리 실패한 로그가 쌓이는 별도 큐. 나중에 원인 분석용

## 에이전트·세션

- **actor** — 이사회에서 발언하는 주체. A (의장, Opus 4.7) · B (CTO, Codex) · C (CIO, Gemini) 3명
- **rotation** — 매 라운드 pass 1 에서 누가 먼저 말하는지 순서. A→B→C 로 한 칸씩 돌림 (공정성)
- **quota** — 한 세션에서 쓸 수 있는 토큰 잔량. 고갈 시 일부 라운드 축소(degraded mode)
- **session_id** — 한 CC 세션마다 부여되는 UUID 식별자. 이벤트 추적용
- **sandbox** — 에이전트가 파일 쓰기·명령 실행을 할 수 있는 범위를 제한하는 안전 울타리
- **subscription** — Anthropic Claude Max / OpenAI ChatGPT Pro / Google AI Pro 같은 월 정액 구독

## 보드 운영

- **round** — 이사회 한 차례의 토의 구간. R0 (리서치) · R1~R4 (의견·반박 2-pass) · R5 (EARS 서명) · R6 (최종 합의)
- **pass** — 한 라운드 안의 발언 회차. pass 1 = 첫 발언, pass 2 = 반박·확장
- **degraded mode** — 토큰 부족으로 2-pass 를 1-pass 로 축소하는 비상 모드. 발생 시 CEO 서명 필요
- **override** — CEO 가 이사회 결정을 상위에서 뒤집는 명령. TTL 1800초 제한
- **dispatch** — 라운드 시작 시 각 actor 에게 "이거 써라" 지시문을 보내는 행위

## 보고서 렌더링

- **renderer** — 원본 라운드 파일들을 합쳐서 최종 보고서 .md 파일을 만드는 프로그램 (`report-renderer.py`)
- **authored_ratio** — 전체 보고서 중 저자(A) 가 직접 쓴 분량의 비율. BRD-030 에 따라 ≤ 0.10 (10%) 제한
- **verbatim** — 원문 그대로 복사. 보고서의 I./II./III. 섹션은 라운드 파일에서 **바이트 단위 복사** (변형 금지)
- **byte-extract** — 원본 파일의 특정 부분을 바이트 단위로 떼어낸 인용

## 검증·게이트

- **validator** — 보고서가 규칙을 지켰는지 자동 검사하는 작은 프로그램. 10여 개 존재 (citation_resolver / strength / fairness 등)
- **GATE** — 다음 단계로 넘어가기 전에 통과해야 하는 자동 검사 체크포인트
- **ACK** — Acknowledgement. "읽었고 이상 없다" 는 서명 한 줄
- **DISSENT** — "반대한다" 는 공식 서명. 1건이라도 발생하면 extension-round 자동 생성

## 인프라

- **tmux** — 한 터미널에 여러 세션을 동시에 띄우는 도구. CC 3개 (conductor/B/C) 를 동시에 굴릴 때 사용
- **WSL** — Windows 안에 리눅스를 내장 실행하는 Microsoft 기능
- **ssh** — 원격 서버에 안전하게 접속하는 프로토콜
- **systemd** — 리눅스 서비스 관리자. 프로세스가 죽으면 자동 재시작
- **cron** — 정해진 시간에 자동으로 명령을 실행하는 스케줄러
