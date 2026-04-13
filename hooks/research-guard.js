#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════
// research-guard.js — PreToolUse (Edit|Write)
// gh search 또는 WebSearch 없이 코드 수정 시도 시 차단.
// 연동: research-flag-setter.js (PostToolUse, Bash)가 플래그 기록.
//
// ECC gateguard-fact-force.js 패턴 기반.
// Phase 1 Task 1-1 (kdh-harness-refactor v2)
// ═══════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');
const os = require('os');

const MAX_INPUT = 1024 * 1024; // 1MB
const FLAG_DIR = path.join(os.homedir(), '.research-guard');
const FLAG_TTL_MS = 30 * 60 * 1000; // 30분

// ─── stdin 읽기 ───
let raw = '';
process.stdin.on('data', chunk => {
  raw += chunk;
  if (raw.length > MAX_INPUT) raw = raw.slice(0, MAX_INPUT);
});

process.stdin.on('end', () => {
  try {
    const data = JSON.parse(raw);
    const result = run(data);
    if (result) {
      process.stdout.write(JSON.stringify(result));
    } else {
      process.stdout.write(raw); // pass-through
    }
    process.exit(0);
  } catch (e) {
    // Graceful degradation — 에러 시 pass-through
    process.stdout.write(raw);
    process.exit(0);
  }
});

function run(data) {
  // 환경변수로 비활성화 가능 (학습 세션용)
  if (process.env.CORTHEX_SKIP_RESEARCH_GUARD === '1') return null;

  const toolName = data.tool_name || '';
  // Edit, Write, MultiEdit만 감시
  if (!['Edit', 'Write', 'MultiEdit'].includes(toolName)) return null;

  // 세션 ID 추출
  const sessionId = data.session_id || 'unknown';
  const flagFile = path.join(FLAG_DIR, `state-${sessionId}.json`);

  // 플래그 파일 확인
  try {
    if (fs.existsSync(flagFile)) {
      const stat = fs.statSync(flagFile);
      const age = Date.now() - stat.mtimeMs;
      if (age < FLAG_TTL_MS) {
        // 30분 이내 검색 완료 → 통과
        return null;
      }
      // 만료 → 삭제
      fs.unlinkSync(flagFile);
    }
  } catch (e) {
    // 파일 I/O 에러 → pass-through (작업 안 막음)
    return null;
  }

  // 플래그 없음 → 차단
  return {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason:
        '코드 수정 전에 먼저 검색하세요.\n' +
        '다음 중 하나를 실행하면 통과됩니다:\n' +
        '  - gh search code "{키워드}"\n' +
        '  - gh search repos "{키워드}"\n' +
        '  - WebSearch 도구 사용\n' +
        '검색 후 다시 시도하면 자동 통과됩니다.'
    }
  };
}

module.exports = { run };
