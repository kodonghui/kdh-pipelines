# CORTHEX v3 하네스 가이드

> 2026-04-02 CEO 승인. 3대 벤치마크(LangChain/Anthropic/ECC) 기반.
> 리서치: `_research/harness-adoption-analysis-2026-04-02.md`

---

## 1. 기능 체크리스트 (feature-checklist.json)

**위치:** `_bmad-output/implementation-artifacts/feature-checklist.json`

**용도:** Phase 1 기능 5개 + 통합 테스트의 pass/fail 추적. 에이전트가 "다 했다"고 거짓말하는 것 방지.

**사용법:**
```bash
# 현재 상태 확인
cat _bmad-output/implementation-artifacts/feature-checklist.json | jq '.[].name, .[].passes'

# Sprint End에서 자동 확인 (파이프라인에 통합)
# 모든 passes = true 일 때만 Sprint 완료 인정
```

**파이프라인 통합:**
- Sprint End GATE #19 전에 feature-checklist.json 전체 passes 확인
- passes = false 항목 있으면 → Sprint 완료 거부
- CEO 브라우저 확인 후 → verified_by = "CEO" 업데이트

---

## 2. 환경 자동 체크 (verify-env.sh)

**위치:** `scripts/verify-env.sh`

**용도:** 매 세션 시작 시 환경 건강 검진. DB, tsc, Bun, 미커밋 파일 체크.

**사용법:**
```bash
# 직접 실행
./scripts/verify-env.sh

# 파이프라인 auto 모드에서 자동 실행 (Step 0)
# ❌ 하나라도 FAIL → 파이프라인 시작 전 수정
# ⚠️ 경고만 있으면 → 계속 진행
```

**출력 예시:**
```
═══════════════════════════════════════
 CORTHEX v3 — 환경 검증
 2026-04-02 20:00:00 KST
═══════════════════════════════════════

  [1/6] Bun 설치                     ✅
  [2/6] Server 타입체크               ✅
  [3/6] Admin 타입체크                ✅
  [4/6] DB 연결                      ⚠️  (경고, 계속 진행)
  [5/6] 미커밋 변경                   ⚠️  5개 파일 미커밋
  [6/6] Pipeline State               ✅

═══════════════════════════════════════
 결과: ✅ PASS (4개 통과, 2개 경고)
 → 작업 시작 가능
```

---

## 3. 루프 감지기 (loop-detector.js)

**위치:** `scripts/loop-detector.js`

**용도:** 같은 파일을 반복 수정하는 "죽음의 루프" 감지.

**사용법:**
```bash
# 현재 수정 횟수 확인
node scripts/loop-detector.js --status

# 카운터 리셋 (새 스토리 시작 시)
node scripts/loop-detector.js --reset
```

**자동 동작:**
- Edit/Write 도구 호출 시 자동으로 파일별 카운터 증가
- 5회 → ⚠️ 경고 메시지
- 8회 → 🚨 ESCALATE 권장

**파이프라인 통합:**
- 각 Story Phase 시작 시 자동 리셋
- Phase B(구현) 중 루프 감지 시 → Orchestrator에게 보고

**설정 (선택사항 — .claude/settings.json):**
```json
{
  "hooks": {
    "postToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "node scripts/loop-detector.js"
      }
    ]
  }
}
```

---

## 4. Hook 프로파일 (pre-commit hook v3.1)

**위치:** `.git/hooks/pre-commit` (v3 → v3.1 업그레이드)

**용도:** 상황에 맞게 검증 강도 조절. 밤새 모드는 빠르게, 일반은 꼼꼼하게.

**사용법:**
```bash
# 기본값: strict (전체 검증)
git commit -m "feat: ..."

# 밤새 자동 모드: standard (파일 존재만 확인, 내용 검증 스킵)
export CORTHEX_HOOK_PROFILE=standard
/kdh-full-auto-pipeline 계속

# 빠른 디버깅: minimal (tsc만)
export CORTHEX_HOOK_PROFILE=minimal
git commit -m "fix: quick hotfix"

# 다시 strict로 복귀
unset CORTHEX_HOOK_PROFILE
```

**3가지 모드 비교:**

| 검증 항목 | minimal | standard | strict |
|----------|---------|----------|--------|
| tsc --noEmit | ✅ | ✅ | ✅ |
| Story/Phase 파일 존재 | ❌ | ✅ | ✅ |
| Critic 로그 존재 | ❌ | ✅ | ✅ |
| Cross-talk 내용 (3줄+) | ❌ | ❌ | ✅ |
| DA 로그 존재 | ❌ | ✅ | ✅ |
| Codex PASS | ❌ | ✅ | ✅ |
| TeamCreate | ❌ | ✅ | ✅ |

**파이프라인 통합:**
- `/kdh-full-auto-pipeline` 일반 모드 → strict (변경 없음)
- `/kdh-full-auto-pipeline 계속` → 자동으로 standard 설정
- 수동 커밋 → 환경변수로 직접 선택

---

## 향후 추가 예정 (Sprint 1 후)

### 5. 인스팅트 시스템
- party-logs에서 반복 패턴 자동 추출
- 다음 Sprint 에이전트 프롬프트에 자동 주입

### 6. 자동 회고
- Sprint 완료 시 자동 분석 보고서 생성
- 가장 오래 걸린 스토리, 반복 지적 Top 5, 교훈

### 7. 프롬프트 자동 개선 (Phase 2)
- 에이전트 실행 결과 + CEO 피드백 → 시스템 프롬프트 자동 개선
