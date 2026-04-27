---
name: kdh-codex-delegate
description: "Codex exec 위임: EARS 프롬프트, 검증, commit/push."
---

# /kdh-codex-delegate — Codex Exec Delegation v1

CEO 2026-04-21 지시: 모든 실제 코딩 Codex 위임. Claude = 프롬프트 작성 + 게이트 + commit orchestration.

## Core Directive

- **Claude 역할:** 프롬프트 작성, 파일 사전 조사, tsc/test 실행, commit/push, plan 체크박스 업데이트
- **Codex 역할:** 실제 edit/write 수행. 프롬프트대로만 실행. 지시 없이 추가 작업 금지
- **Party Mode 면제** (CEO 2026-04-21)
- **main 직접 push** (CEO 2026-04-21)
- **모든 commit "Authored by Codex" 주석 필수**

## 입력 확인

실행 전 출력:
```
Task: <id> (예: A-1-1 login handoff port)
Target file(s): <paths>
Handoff/spec ref: <path 있을 시>
Plan: _bmad-output/plans/*.md (체크박스 업데이트 대상)
```

## Execution Steps

### Step 1 — 사전 조사 (Claude)
1. Target file Read — 현재 상태 파악
2. Handoff/spec 파일 있으면 Read — 목표 상태
3. Gap 식별: 무엇을 바꿔야 하는지 구체화
4. 건드리지 말아야 할 것 식별: real-wire 로직, 외부 의존성, 테스트

### Step 2 — 프롬프트 작성 (Claude)
`/tmp/codex-queue/<task-id>.prompt` 에 5섹션 표준 작성:

```
# Task: <id> — <title>

## Context
- repo: /home/ubuntu/corthex-v3
- target file: <path> (<lines> lines, <state>)
- reference (read-only): <path>
- 관련 component/type: <path>

## Ask (EARS)
WHEN <event>
IF <precondition>
THEN <outcome>:
  - 구체 bullet 1
  - 구체 bullet 2

AND WHEN <event2>
THEN <outcome2>

## Constraints
- DO NOT modify: <list>
- DO NOT add: <list>
- Keep: <patterns>
- Style: <hints>

## Output
1. Edit <file(s)>.
2. Run: `cd /home/ubuntu/corthex-v3 && bun run --filter <pkg> type-check 2>&1 | tail -30`
3. Print tsc result.
4. Print `git diff --stat <file>`.
5. Print "DONE".
```

**프롬프트 작성 규칙:**
- 글자 제한 없음. 구체적+자세하게 (CEO feedback_no_char_limit)
- EARS 형식 필수 (WHEN/IF/THEN/AND)
- 건드리지 말 것 명시 (real-wire 로직, 외부 의존성)
- 결과 print 명령 포함 (tsc, diff)
- 마지막 "DONE" 출력 강제

### Step 3 — Codex 위임 (Claude → Codex)

```bash
timeout 600 codex exec --full-auto --skip-git-repo-check \
  --cd /home/ubuntu/corthex-v3 \
  "$(cat /tmp/codex-queue/<task-id>.prompt)" 2>&1 | tail -120
```

**타임아웃:** 10분 기본. 복잡한 task 는 15분 (`timeout 900`).
**Bash 도구:** `run_in_background: false` (결과 즉시 필요) 또는 `true` (긴 작업 + 다른 task 병행).

### Step 4 — 게이트 검증 (Claude)

Codex 출력에서 확인:
1. **tsc PASS** — `Exited with code 0` 또는 `0 errors`
2. **DONE** 출력 존재
3. **diff stat** 정상 (0 lines changed = 실패, 너무 큰 diff = 의심)

**FAIL 시 (CEO 2026-04-21 결정):**
- revert (`git checkout -- <file>`)
- 원인 분석 짧게 log
- Retry 자동 금지. 다음 task 로 skip 또는 CEO 보고

### Step 5 — Commit + Push (Claude)

```bash
git add <changed files>
git -c commit.gpgsign=false commit -m "<type>(<scope>): <subject> (<task-id>)

Authored by Codex. <1-2 line 설명>."

git push origin main
```

**Commit message 규칙:**
- Conventional commits (feat/fix/refactor/docs/chore/perf/test/ci)
- scope: 패키지명 (admin / app / server / shared)
- subject: 영어, 명령형, 50자 이내
- body: "Authored by Codex." 필수 + 변경 요약 2줄 이내
- CEO/Claude co-author 금지 (attribution disabled globally)

### Step 6 — Plan 체크박스 업데이트

```bash
sed -i 's|- \[ \] <task-id> <title>|- [x] <task-id> <title>|' \
  _bmad-output/plans/<plan-file>.md

git add _bmad-output/plans/<plan-file>.md
git -c commit.gpgsign=false commit -m "chore(plan): mark <task-id> [x]"
git push origin main
```

### Step 7 — 보고 (Claude → CEO)

CEO 에 한 줄 보고 (caveman mode 허용):
```
<task-id> PASS. tsc OK. commit <hash>. push OK. 다음 = <next-task-id>.
```

## Invoke 패턴 요약

| Env | Value |
|-----|-------|
| Codex CLI | `/usr/bin/codex` 0.118.0 |
| Base flags | `--full-auto --skip-git-repo-check --cd /home/ubuntu/corthex-v3` |
| Timeout | 600s 기본, 900s 복잡 task |
| Prompt store | `/tmp/codex-queue/<id>.prompt` |
| Git push | `origin main` 직접 (branch 없음) |

## Party Mode 면제 근거

CEO 지시 2026-04-21: "Codex 전담 overnight loop. Party Mode 면제. main 직접 push."
- hook v4.4 부재 지속. tsc + test 게이트만.
- 일반 기능 개발은 `/kdh-dev-pipeline` 사용 (Party Mode 필수).
- 이 스킬은 Codex 전담 모드 한정.

## Codex FAIL 처리

- **tsc FAIL** — revert → log → skip. CEO 기상 후 수동 조사.
- **타임아웃** — 프로세스 kill → log → skip.
- **Codex 가 지시 이탈** (건드리지 말라 한 파일 수정) — revert 전체 → 프롬프트 재작성 → 1회 재시도.
- **재시도 2회 연속 FAIL** — task skip. CEO 에 명시 보고.

## 체크리스트 — Codex 위임 전 필수 확인

- [ ] Target file Read 완료
- [ ] Handoff/spec 파일 Read 완료 (있을 시)
- [ ] Gap 식별 명확
- [ ] 프롬프트 5섹션 전부 작성
- [ ] EARS WHEN/IF/THEN 포함
- [ ] Constraints "DO NOT" 명시
- [ ] Output tsc + diff + DONE 명령 포함
- [ ] Prompt 파일 `/tmp/codex-queue/` 저장

## 환경 참조

- **Codex CLI:** `/usr/bin/codex` (version 0.118.0)
- **Master plan 예:** `_bmad-output/plans/2026-04-22-codex-overnight-master.md`
- **Prompt templates:** `/tmp/codex-queue/*.prompt` (재사용 가능)
- **TypeScript type-check:** `bun run --filter @corthex/<pkg> type-check`
- **Test:** `bun test packages/<pkg>/src/**/__tests__/**`
- **Deploy worktree:** `/home/ubuntu/corthex-v3-deploy` (자동 동기화)

## 선행 조건

- Codex CLI 로그인 완료 (`codex login` 완료 상태)
- `/tmp/codex-queue/` 디렉토리 존재 (없으면 `mkdir -p`)
- `.codex` gitignored (plan main 에 이미 반영)
- `/permissions` 로 `codex exec` 승인 완료 (CEO 수동)

## 종료 조건

- 단일 task 완료 → Step 7 보고 후 종료
- Loop 모드 (cron `5c149d2e` 가 부름) → 다음 task pick 하여 재진입
- CEO 수동 중단: `CronDelete <id>` + 현재 task 커밋 강제 종료

---

## 사용 예시

**CEO 호출:** "A-1-2 signup handoff port codex 위임해"
**또는:** `/kdh-codex-delegate A-1-2`

**Claude 응답 (caveman mode):**
```
A-1-2 signup handoff port 착수. 사전 조사 중.
```

→ Step 1~7 순차 실행 → 완료 보고.
