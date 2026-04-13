#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════
// quality-gate.js — PostToolUse (Edit|Write) [async: true]
// 파일 수정 후 타입 체크/린트 자동 실행.
// ECC quality-gate.js 패턴 기반.
// 에러 → stderr 경고 (async이므로 차단은 안 함, 다음 턴에 Claude 인지).
//
// Phase 1 Task 1-6 (kdh-harness-refactor v2)
// ═══════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const MAX_INPUT = 1024 * 1024;

let raw = '';
process.stdin.on('data', chunk => {
  raw += chunk;
  if (raw.length > MAX_INPUT) raw = raw.slice(0, MAX_INPUT);
});

process.stdin.on('end', () => {
  try {
    const data = JSON.parse(raw);
    run(data);
  } catch (e) { /* 무시 */ }
  process.stdout.write(raw); // 항상 pass-through
  process.exit(0);
});

function run(data) {
  const toolName = data.tool_name || '';
  if (!['Edit', 'Write', 'MultiEdit'].includes(toolName)) return;

  const filePath = (data.tool_input && data.tool_input.file_path) || '';
  if (!filePath) return;

  const ext = path.extname(filePath).toLowerCase();
  const cwd = data.cwd || process.cwd();

  // 확장자별 체크
  try {
    if (['.ts', '.tsx'].includes(ext)) {
      checkTypeScript(filePath, cwd);
    } else if (['.js', '.jsx'].includes(ext)) {
      checkJavaScript(filePath, cwd);
    } else if (['.json'].includes(ext)) {
      checkJson(filePath);
    }
  } catch (e) {
    // async 훅이므로 에러 무시
  }
}

function checkTypeScript(filePath, cwd) {
  // tsconfig.json 존재 확인
  const tsconfig = findUp('tsconfig.json', cwd);
  if (!tsconfig) return;

  try {
    execSync(`npx tsc --noEmit -p "${tsconfig}" 2>&1`, {
      cwd: path.dirname(tsconfig),
      timeout: 20000,
      encoding: 'utf8'
    });
  } catch (e) {
    const output = (e.stdout || '') + (e.stderr || '');
    // 현재 파일 관련 에러만 필터
    const relPath = path.basename(filePath);
    const relevant = output.split('\n')
      .filter(l => l.includes(relPath) || l.includes('error TS'))
      .slice(0, 5)
      .join('\n');

    if (relevant.trim()) {
      process.stderr.write(
        `\n⚠️ TypeScript 에러 (${relPath}):\n${relevant}\n\n`
      );
    }
  }
}

function checkJavaScript(filePath, cwd) {
  // biome.json 또는 .eslintrc 존재 확인
  const biomeConfig = findUp('biome.json', cwd) || findUp('biome.jsonc', cwd);
  if (biomeConfig) {
    try {
      execSync(`npx @biomejs/biome check "${filePath}" 2>&1`, {
        cwd: path.dirname(biomeConfig),
        timeout: 10000,
        encoding: 'utf8'
      });
    } catch (e) {
      const output = ((e.stdout || '') + (e.stderr || '')).trim();
      if (output) {
        process.stderr.write(`\n⚠️ Biome lint (${path.basename(filePath)}):\n${output.slice(0, 500)}\n\n`);
      }
    }
    return;
  }

  const eslintConfig = findUp('.eslintrc.js', cwd) || findUp('.eslintrc.json', cwd) || findUp('.eslintrc.yml', cwd);
  if (eslintConfig) {
    try {
      execSync(`npx eslint "${filePath}" 2>&1`, {
        cwd: path.dirname(eslintConfig),
        timeout: 10000,
        encoding: 'utf8'
      });
    } catch (e) {
      const output = ((e.stdout || '') + (e.stderr || '')).trim();
      if (output) {
        process.stderr.write(`\n⚠️ ESLint (${path.basename(filePath)}):\n${output.slice(0, 500)}\n\n`);
      }
    }
  }
}

function checkJson(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    JSON.parse(content);
  } catch (e) {
    process.stderr.write(`\n⚠️ JSON 파싱 에러 (${path.basename(filePath)}): ${e.message}\n\n`);
  }
}

function findUp(filename, startDir) {
  let dir = startDir;
  for (let i = 0; i < 10; i++) {
    const target = path.join(dir, filename);
    if (fs.existsSync(target)) return target;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return null;
}

module.exports = { run };
