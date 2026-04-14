#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════
// block-no-verify.js — PreToolUse (Bash)
// --no-verify, --no-gpg-sign 차단.
// ECC block-no-verify.js 패턴 기반.
//
// Phase 1 Task 1-3 (kdh-harness-refactor v2)
// ═══════════════════════════════════════════════════════════

const MAX_INPUT = 1024 * 1024;

// 차단 패턴
// -n 단축은 git의 특정 하위 명령에서만 --no-verify 의미를 가짐
// (commit/merge/rebase/cherry-pick/am). 다른 맥락의 -n (grep -n 등)은 false positive 방지
const BLOCKED_FLAGS = [
  /--no-verify/,
  /--no-gpg-sign/,
  /\bgit\s+(commit|merge|rebase|cherry-pick|am)\b[^|&;]*\s-n\b/
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
  const toolName = data.tool_name || '';
  if (toolName !== 'Bash') return null;

  const command = (data.tool_input && data.tool_input.command) || '';

  // git 명령어가 아니면 무시
  if (!/\bgit\b/.test(command)) return null;

  // 차단 패턴 매칭
  const blocked = BLOCKED_FLAGS.some(p => p.test(command));
  if (!blocked) return null;

  return {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason:
        '--no-verify 금지. git hook을 우회할 수 없습니다.\n' +
        'hook이 실패하면 원인을 조사하고 수정하세요.'
    }
  };
}

module.exports = { run };
