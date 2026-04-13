---
name: 'kdh-parallel'
description: '병렬 팀 분할 — 의존성 분석 → worktree + branch + save-session 생성. /kdh-parallel [dev|bugfix] ID1 ID2 [ID3]'
---

# /kdh-parallel — 세션 분할 병렬 실행 도구

독립 작업 N개를 의존성 분석 후, 각각 별도 세션에서 정식 파이프라인을 돌릴 수 있도록 save-session 파일을 생성하는 도구.

**이 스킬은 파이프라인을 직접 실행하지 않음. 세션 파일 + worktree + branch만 생성.**

## 사용법

```
/kdh-parallel [pipeline] ID1 ID2 [ID3]

pipeline: dev | bugfix | 생략 (auto — pipeline-state.yaml에서 감지)
ID: 스토리 ID (dev) 또는 버그 ID (bugfix)
max: 3팀
```

예시:
```
/kdh-parallel B.2.1 B.6 B.7-W          # auto → dev 감지
/kdh-parallel dev B.2.1 B.6             # dev 명시
/kdh-parallel bugfix BUG-001 BUG-002   # bugfix 명시
```

---

## Step 0: Validation (입력 검증 — 실패 시 즉시 중단)

```
1. 입력 파싱:
   - 첫 토큰이 dev|bugfix → pipeline 확정, 나머지 = ID 목록
   - 첫 토큰이 ID 형태 → pipeline-state.yaml의 mode에서 자동 감지
   - auto 감지 시 mode가 sprint* → dev, bugfix* → bugfix

2. 중단 조건 (하나라도 해당 → 즉시 중지 + CEO 보고):
   - ID 1개 이하 → "병렬 불필요. /kdh-dev-pipeline {ID} 계속 사용하세요."
   - ID 4개 이상 → "max 3팀. ID를 3개 이하로 줄여주세요."
   - 중복 ID 존재 → "중복 ID: {중복}. 제거 후 재실행."
   - pipeline auto-detect 실패 (mode 없거나 ambiguous) → "pipeline 명시 필요."
   - dev+bugfix ID 혼합 → "같은 pipeline ID만 입력."

3. ID 존재 확인:
   IF pipeline == dev:
     epics-and-stories.md에서 각 ID의 Story 헤더 검색
     IF ID 없음 → "Story {ID} 미발견. epics-and-stories.md 확인."
   IF pipeline == bugfix:
     bug-fix-state.yaml에서 각 ID 검색
     IF ID 없음 → "Bug {ID} 미발견. bug-fix-state.yaml 확인."

4. 기존 산출물 확인:
   - ~/.claude/session-data/*-team-*-session.tmp 중 같은 ID → "기존 세션 파일 존재: {path}. 덮어쓸까요?"
   - git worktree list에 ../corthex-v3-{team} 존재 → "기존 worktree 존재: {path}. 삭제 후 재실행하거나 --cleanup."

팀 이름 배정:
  - 2개: alpha, beta
  - 3개: alpha, beta, gamma
```

## Step 1: Dependency Analysis (파일 경로 교차 분석)

```
v1 원칙: 파일 경로 교차만 본다. 함수/심볼 수준 분석 하지 않음.
교차 발견 시 무조건 MERGE_WARN (보수적). PARALLEL은 교차 0일 때만.

IF pipeline == dev:
  1. epics-and-stories.md에서 각 Story 섹션 읽기
  2. 각 Story의 영향 파일 추출:
     - AC에서 명시된 파일 경로 (packages/*/src/*.tsx 등)
     - "MODIFY", "CREATE" 키워드 뒤의 파일 경로
     - 같은 Epic의 이전 완료 Story가 건드린 파일 (git log --name-only {commit} -- packages/)
  3. contract 파일 교차: 같은 contracts/*.ts → SEQUENTIAL 권고

IF pipeline == bugfix:
  1. bug-fix-state.yaml에서 각 버그의 origin/affected 파일 경로 추출
  2. 같은 파일 → 같은 팀 권고

교차 분석:
  files_per_id = { "B.2.1": ["App.tsx", "divisions.tsx"], "B.6": ["App.tsx", "members.tsx"] }
  shared_files = 교차 집합

  IF shared_files 비어있음 → PARALLEL
  IF shared_files 있음 → MERGE_WARN
  IF shared_files 5개 이상 → SEQUENTIAL 강제 ("교차 파일 과다. 병렬 부적합.")

  분석 실패 (파싱 오류 등) → UNKNOWN → 보수적으로 SEQUENTIAL 처리 + CEO 보고
```

## Step 2: Group Classification

```
결과 구조:

groups:
  - team: alpha
    ids: ["B.2.1"]
    verdict: PARALLEL | MERGE_WARN | SEQUENTIAL
    branch: parallel/alpha-B-2.1
    worktree: ../corthex-v3-alpha
    shared_files: []  # or ["App.tsx"]
  - team: beta
    ids: ["B.6"]
    verdict: PARALLEL
    branch: parallel/beta-B-6
    worktree: ../corthex-v3-beta
    shared_files: []

merge_owner: alpha (첫 번째 팀 = 머지 담당)

SEQUENTIAL 발견 시:
  → CEO에게 보고: "{ID-A}와 {ID-B}가 {N}개 파일을 공유합니다."
  → 선택지: (A) 같은 팀으로 묶기 (B) 순차 실행 권고 (C) 그래도 병렬 (MERGE_WARN)
```

## Step 3: Branch + Worktree 생성

```
현재 브랜치 확인:
  base_branch = $(git branch --show-current)  # e.g. ui-rebuild

팀별 생성:
  for each group:
    branch_name = parallel/{team}-{storyId}  # e.g. parallel/alpha-B-2.1
    worktree_path = ../corthex-v3-{team}     # e.g. ../corthex-v3-alpha

    git worktree add -b {branch_name} {worktree_path} {base_branch}

    IF 실패 → cleanup (이미 생성된 worktree/branch 제거) + CEO 보고

bun install 확인:
  각 worktree에서 node_modules 심링크/설치 필요 여부:
  - bun의 경우 워크스페이스 루트의 node_modules가 심링크됨
  - 확인: ls {worktree_path}/node_modules
  - 없으면: cd {worktree_path} && bun install
```

## Step 4: Generate Save-Sessions

```
팀별 save-session 파일 생성:
  경로: ~/.claude/session-data/{date}-team-{name}-{storyId}-{shortId}-session.tmp
  shortId: 8자 랜덤 hex (재실행 시 파일명 충돌 방지)

각 파일에 포함:

  # Session: {date} — Team {Name} ({storyId} {title})
  **Project:** {worktree_path}  ← 메인 repo가 아닌 worktree 경로!
  **Topic:** Sprint {N} Story {ID}
  **Previous:** 현재 세션 save-session 경로

  ## ★ 실행 방법
  /kdh-{dev-pipeline|bug-fix-pipeline} {ID} 계속

  ## ★ 이 세션은 worktree에서 작업합니다
  작업 디렉토리: {worktree_path}
  브랜치: {branch_name}
  완료 후 머지는 {merge_owner} 세션이 담당합니다.

  ## Story/Bug Requirements
  {epics-and-stories.md 또는 bug-fix-state.yaml에서 해당 ID 섹션 자동 추출}

  ## Contract Types
  {관련 contracts/*.ts 파일 경로 목록 — 내용은 세션에서 Read}

  ## 충돌 경고
  {MERGE_WARN인 경우: 교차 파일 목록 + "이 파일은 다른 팀도 수정합니다. 머지 시 충돌 예상."}
  {PARALLEL이면: "교차 파일 없음. 안전하게 병렬 가능."}

  ## What Did NOT Work
  {현재 세션의 실패 이력 — 대화 맥락에서 추출. 없으면 "없음"}

  ## Blockers
  {알려진 블로커. 없으면 "없음"}

  ## Exact Next Step
  /kdh-{pipeline} {ID} 계속
```

## Step 5: Report to CEO

```
출력 형식:

┌──────────────────────────────────────────┐
│ /kdh-parallel {IDs}                      │
├──────────┬────────────┬──────────────────┤
│ Team     │ ID         │ 판정             │
├──────────┼────────────┼──────────────────┤
│ alpha    │ {ID}       │ PARALLEL ✅      │
│ beta     │ {ID}       │ PARALLEL ✅      │
│ gamma    │ {ID}       │ MERGE_WARN ⚠️   │
├──────────┴────────────┴──────────────────┤
│ Branch: parallel/{team}-{id}             │
│ Worktree: ../corthex-v3-{team}           │
├──────────────────────────────────────────┤
│ ⚠️ 충돌 경고 (있으면):                  │
│   App.tsx — alpha + gamma 모두 수정 예상 │
│   머지 담당: alpha 세션                  │
├──────────────────────────────────────────┤
│ 세이브세션:                              │
│  team-alpha-{id}-session.tmp             │
│  team-beta-{id}-session.tmp              │
│  team-gamma-{id}-session.tmp             │
├──────────────────────────────────────────┤
│ 실행 방법:                               │
│  이 세션: /resume-session team-alpha     │
│  새 터미널: claude → /resume-session     │
│            team-beta                     │
│  새 터미널: claude → /resume-session     │
│            team-gamma                    │
├──────────────────────────────────────────┤
│ 머지 (전부 완료 후, alpha 세션에서):     │
│  cd /home/ubuntu/corthex-v3              │
│  git merge --no-ff parallel/alpha-{id}   │
│  git merge --no-ff parallel/beta-{id}    │
│  git merge --no-ff parallel/gamma-{id}   │
│  npx tsc --noEmit -p packages/admin/...  │
│  bun test                                │
│  git worktree remove ../corthex-v3-*     │
│  git branch -d parallel/*               │
└──────────────────────────────────────────┘
```

## --cleanup 옵션

```
/kdh-parallel --cleanup

1. git worktree list → ../corthex-v3-{alpha|beta|gamma} 찾기
2. 각 worktree에 uncommitted 변경 확인:
   - 있으면 → "⚠️ {path}에 uncommitted 변경 있음. 강제 삭제하시겠습니까?"
   - 없으면 → 삭제
3. git worktree remove {path}
4. git branch -d parallel/{team}-{id} (머지 안 된 브랜치 → -D 대신 경고)
5. session 파일 삭제: ~/.claude/session-data/*-team-{name}-*-session.tmp
6. 보고: "정리 완료. worktree N개, branch N개, session N개 삭제."
```

## 중단 조건 (6개)

1. pipeline auto-detect 실패 or ID 패턴 불일치 → 즉시 중단
2. ID 미존재 or 중복 → 즉시 중단
3. epics-and-stories.md / bug-fix-state.yaml 파싱 실패 → 즉시 중단
4. 파일 영향 분석 결과 UNKNOWN 비율 50%+ → 즉시 중단 + CEO 보고
5. 기존 worktree/branch/session 충돌 + 덮어쓰기 미승인 → 즉시 중단
6. git 상태 부적합 (uncommitted 변경, detached HEAD 등) → 즉시 중단

## 롤백 (부분 실패 시)

```
cleanup_on_failure():
  1. 생성된 save-session 파일 삭제
  2. 생성된 worktree 삭제 (git worktree remove)
  3. 생성된 branch 삭제 (git branch -d)
  4. CEO에게 "부분 실패. 정리 완료. 원인: {error}" 보고
```

## 수락 기준 (EARS — 6개)

1. WHEN `/kdh-parallel dev ID1 ID2` 실행 with valid IDs, THE SYSTEM SHALL 팀별 save-session 파일 N개를 deterministic 경로에 생성
2. WHEN pipeline 생략 and 모든 ID가 하나의 pipeline에 매칭, THE SYSTEM SHALL 해당 pipeline을 추론하고 추론 결과를 보고에 표시
3. IF pipeline 추론이 ambiguous or mixed, THEN THE SYSTEM SHALL 세션 파일 생성 없이 중단하고 사유 보고
4. WHEN 교차 파일 감지, THE SYSTEM SHALL 해당 쌍을 MERGE_WARN 또는 SEQUENTIAL로 분류하고 근거를 보고에 포함
5. IF 출력 경로가 이미 존재하고 덮어쓰기 미승인, THEN THE SYSTEM SHALL 부분 산출물 생성 없이 중단
6. WHEN 생성 완료, THE SYSTEM SHALL 실행에 필요한 정확한 branch/worktree/session 이름을 출력
