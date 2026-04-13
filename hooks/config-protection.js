#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════
// config-protection.js — PreToolUse (Edit|Write)
// 설정 파일 수정 시 경고 메시지 주입 (차단은 안 함).
// Claude가 린터/설정을 약하게 바꾸는 것 방지.
// ECC config-protection.js 패턴 기반.
//
// Phase 1 Task 1-8 (kdh-harness-refactor v2)
// ═══════════════════════════════════════════════════════════

const path = require('path');

const MAX_INPUT = 1024 * 1024;

// 보호 대상 파일 패턴
const PROTECTED_PATTERNS = [
  // 린터/포매터 설정
  /\.eslintrc/,
  /\.prettierrc/,
  /biome\.json/,
  /biome\.jsonc/,
  /\.stylelintrc/,

  // TypeScript 설정
  /tsconfig\.json/,
  /tsconfig\.\w+\.json/,

  // 패키지 설정 (직접 수정 주의)
  /package\.json$/,
  /bun\.lockb$/,
  /package-lock\.json$/,
  /pnpm-lock\.yaml$/,
  /yarn\.lock$/,

  // Claude 설정
  /\.claude\/settings\.json/,
  /\.claude\/hooks\//,
  /CLAUDE\.md$/,

  // 환경 변수
  /\.env$/,
  /\.env\.\w+$/,

  // CI/CD
  /\.github\/workflows\//,
  /Dockerfile/,
  /docker-compose/
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
  if (!['Edit', 'Write', 'MultiEdit'].includes(toolName)) return null;

  const filePath = (data.tool_input && data.tool_input.file_path) || '';
  if (!filePath) return null;

  // 보호 대상 매칭
  const isProtected = PROTECTED_PATTERNS.some(p => p.test(filePath));
  if (!isProtected) return null;

  const fileName = path.basename(filePath);

  // 경고만 (차단 아님) — additionalContext로 주입
  return {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      additionalContext:
        `설정 파일 수정 감지: ${fileName}\n` +
        '코드를 수정해서 문제를 해결하세요. 설정을 약하게 바꾸는 것은 금지입니다.\n' +
        '정말 설정 변경이 필요하면 동희님에게 확인하세요.\n' +
        '특히 주의: tsconfig strict 해제, eslint rule 비활성화, 타입 any 허용 등'
    }
  };
}

module.exports = { run };
