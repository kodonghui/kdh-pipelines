#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════
// safety-guard.js — PreToolUse (Bash)
// 파괴적 명령 차단: rm -rf, git push --force, DROP TABLE 등.
// ECC safety-guard 패턴 기반.
//
// Phase 1 Task 1-4 (kdh-harness-refactor v2)
// ═══════════════════════════════════════════════════════════

const MAX_INPUT = 1024 * 1024;

// 차단 패턴 (정규식)
const DESTRUCTIVE_PATTERNS = [
  // 파일시스템 파괴
  { pattern: /rm\s+-rf\s+\/(?!\w)/, desc: 'rm -rf / (루트 삭제)' },
  { pattern: /rm\s+-rf\s+~/, desc: 'rm -rf ~ (홈 삭제)' },
  { pattern: /rm\s+-rf\s+\.\s/, desc: 'rm -rf . (현재 디렉토리 삭제)' },
  { pattern: /rm\s+-rf\s+\*/, desc: 'rm -rf * (와일드카드 삭제)' },

  // Git 파괴
  { pattern: /git\s+push\s+.*--force(?!-)/, desc: 'git push --force' },
  { pattern: /git\s+push\s+-f\b/, desc: 'git push -f' },
  { pattern: /git\s+reset\s+--hard/, desc: 'git reset --hard' },
  { pattern: /git\s+clean\s+-fd/, desc: 'git clean -fd' },

  // 데이터베이스 파괴
  { pattern: /DROP\s+TABLE/i, desc: 'DROP TABLE' },
  { pattern: /DROP\s+DATABASE/i, desc: 'DROP DATABASE' },
  { pattern: /TRUNCATE\s+TABLE/i, desc: 'TRUNCATE TABLE' },
  { pattern: /DELETE\s+FROM\s+\w+\s*;/i, desc: 'DELETE FROM (조건 없음)' },

  // 시스템 파괴
  { pattern: /kill\s+-9\s+1\b/, desc: 'kill -9 1 (init 종료)' },
  { pattern: /chmod\s+777\s+\//, desc: 'chmod 777 / (루트 권한 개방)' },
  { pattern: /mkfs\./, desc: 'mkfs (디스크 포맷)' },
  { pattern: />\s*\/dev\/sd/, desc: '> /dev/sd (디스크 직접 쓰기)' },

  // 환경 파괴
  { pattern: /unset\s+(PATH|HOME|USER)\b/, desc: '환경변수 삭제' },
  { pattern: /export\s+PATH\s*=\s*$/, desc: 'PATH 비우기' }
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

  // 차단 패턴 매칭
  for (const { pattern, desc } of DESTRUCTIVE_PATTERNS) {
    if (pattern.test(command)) {
      return {
        hookSpecificOutput: {
          hookEventName: 'PreToolUse',
          permissionDecision: 'deny',
          permissionDecisionReason:
            `파괴적 명령 차단: ${desc}\n` +
            '동희님에게 확인하세요. 이 명령은 자동 실행할 수 없습니다.'
        }
      };
    }
  }

  return null;
}

module.exports = { run };
