#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════
// verification-check.js — Stop hook
// Claude가 "완료" 선언 시, 검증 명령어(test, tsc, lint) 실행 여부 확인.
// 증거 없이 완료 선언 → 차단 + 검증 요구.
// superpowers verification-before-completion 패턴 기반.
//
// Phase 1 Task 1-7 (kdh-harness-refactor v2)
// ═══════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');
const os = require('os');

const MAX_INPUT = 1024 * 1024;
const VERIFICATION_LOG = path.join(os.tmpdir(), 'corthex-verification-log.json');

// 완료 표현 패턴
const COMPLETION_PATTERNS = [
  /완료/,
  /수정\s*완료/,
  /구현했습니다/,
  /끝났습니다/,
  /작업\s*완료/,
  /모두\s*완료/,
  /처리했습니다/,
  /반영했습니다/,
  /적용했습니다/,
  /커밋.*했습니다/,
  /push.*했습니다/,
  /done/i,
  /completed/i,
  /finished/i,
  /all\s*(?:tasks?|items?)\s*(?:done|completed)/i
];

// 검증 명령어 패턴
const VERIFICATION_COMMANDS = [
  /\bbun\s+test\b/,
  /\bnpm\s+test\b/,
  /\bnpx\s+vitest\b/,
  /\bnpx\s+jest\b/,
  /\bnpx\s+playwright\b/,
  /\btsc\b.*--noEmit/,
  /\bnpx\s+tsc\b/,
  /\bpytest\b/,
  /\bpython.*-m\s+pytest\b/,
  /\bnpx\s+eslint\b/,
  /\bnpx\s+@biomejs\/biome\b/,
  /\bcargo\s+test\b/,
  /\bgo\s+test\b/
];

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
      process.stdout.write(raw);
    }
    process.exit(0);
  } catch (e) {
    process.stdout.write(raw);
    process.exit(0);
  }
});

function run(data) {
  // Stop hook: data에 stop_hook_active 또는 last_assistant_message 포함
  const message = data.last_assistant_message
    || data.stop_reason
    || '';

  if (!message) return null;

  // 완료 표현 감지
  const hasCompletion = COMPLETION_PATTERNS.some(p => p.test(message));
  if (!hasCompletion) return null;

  // 검증 명령어 실행 이력 확인
  const hasVerification = checkVerificationLog();
  if (hasVerification) return null;

  // 완료 표현 있는데 검증 없음 → 차단
  return {
    hookSpecificOutput: {
      hookEventName: 'Stop',
      decision: 'block',
      additionalContext:
        '완료를 선언하기 전에 검증 명령어를 실행하세요.\n' +
        '증거 없는 완료 선언은 허용되지 않습니다.\n' +
        '다음 중 하나 이상을 실행하세요:\n' +
        '  - bun test (또는 npm test)\n' +
        '  - npx tsc --noEmit\n' +
        '  - npx playwright test\n' +
        '검증 통과 후 다시 완료를 선언하세요.'
    }
  };
}

function checkVerificationLog() {
  try {
    if (!fs.existsSync(VERIFICATION_LOG)) return false;

    const content = fs.readFileSync(VERIFICATION_LOG, 'utf8');
    const log = JSON.parse(content);

    // 최근 10분 이내 검증 명령어 실행 여부
    const tenMinAgo = Date.now() - 10 * 60 * 1000;
    if (log.lastVerification && log.lastVerification > tenMinAgo) {
      return true;
    }

    return false;
  } catch (e) {
    return false;
  }
}

// 이 함수는 PostToolUse(Bash)에서 호출되어 검증 명령어 실행을 기록
// observation-collector 또는 별도 훅에서 호출
function recordVerification(command) {
  try {
    const isVerification = VERIFICATION_COMMANDS.some(p => p.test(command));
    if (!isVerification) return;

    const log = { lastVerification: Date.now(), command: command.slice(0, 200) };
    fs.writeFileSync(VERIFICATION_LOG, JSON.stringify(log));
  } catch (e) { /* 무시 */ }
}

module.exports = { run, recordVerification, VERIFICATION_COMMANDS };
