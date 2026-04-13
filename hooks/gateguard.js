#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════
// gateguard.js — PreToolUse (Edit|Write|MultiEdit|Bash)
// 파일 첫 수정 시 조사 강제 (3단계 fact-forcing).
// ECC gateguard-fact-force.js 패턴 기반 (A/B 테스트 +2.25점).
//
// Stage 1: DENY — 첫 수정 → 차단
// Stage 2: FORCE — additionalContext로 조사 요구
// Stage 3: ALLOW — 두 번째 시도 → 통과
//
// Phase 1 Task 1-2 (kdh-harness-refactor v2)
// ═══════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');
const os = require('os');

const MAX_INPUT = 1024 * 1024;
const STATE_DIR = path.join(os.homedir(), '.gateguard');
const STATE_TTL_MS = 30 * 60 * 1000; // 30분

// Bash에서 파일 수정 명령 감지 패턴
const DESTRUCTIVE_BASH = [
  /\bsed\s+-i/,
  /\bawk\b.*>/,
  /\bcat\b.*>(?!>)/,
  /\becho\b.*>/,
  /\btee\b/,
  /\btruncate\b/,
  /\bdd\b.*of=/
];

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
      process.stdout.write(raw);
    }
    process.exit(0);
  } catch (e) {
    process.stdout.write(raw);
    process.exit(0);
  }
});

function run(data) {
  // 환경변수로 비활성화
  if (process.env.CORTHEX_SKIP_GATEGUARD === '1') return null;

  const toolName = data.tool_name || '';
  const sessionId = data.session_id || 'unknown';
  const stateFile = path.join(STATE_DIR, `state-${sessionId}.json`);

  // 감시 대상 파일 경로 추출
  let filePath = null;

  if (['Edit', 'Write', 'MultiEdit'].includes(toolName)) {
    filePath = (data.tool_input && data.tool_input.file_path) || null;
  } else if (toolName === 'Bash') {
    const command = (data.tool_input && data.tool_input.command) || '';
    // 파일 수정 명령인지 확인
    const isDestructive = DESTRUCTIVE_BASH.some(p => p.test(command));
    if (!isDestructive) return null; // 일반 Bash → 통과
    // 명령어 해시를 key로 사용
    filePath = `bash:${simpleHash(command)}`;
  } else {
    return null;
  }

  if (!filePath) return null;

  // .gateguard.yml 제외 경로 확인
  try {
    const cwd = data.cwd || process.cwd();
    const excludeFile = path.join(cwd, '.gateguard.yml');
    if (fs.existsSync(excludeFile)) {
      const content = fs.readFileSync(excludeFile, 'utf8');
      const excludes = content.split('\n')
        .filter(l => l.trim() && !l.startsWith('#'))
        .map(l => l.trim());
      if (excludes.some(ex => filePath.includes(ex))) return null;
    }
  } catch (e) { /* 무시 */ }

  // 상태 로드
  let state = {};
  try {
    if (fs.existsSync(stateFile)) {
      const raw = fs.readFileSync(stateFile, 'utf8');
      state = JSON.parse(raw);
      // TTL 체크
      if (state._updated && (Date.now() - state._updated > STATE_TTL_MS)) {
        state = {};
      }
    }
  } catch (e) {
    state = {};
  }

  const fileKey = filePath.replace(/[^a-zA-Z0-9/_.-]/g, '_');

  // 이미 확인한 파일 → 통과
  if (state[fileKey] && state[fileKey].checked) {
    return null;
  }

  // 첫 시도 → 차단 + 조사 요구
  if (!state[fileKey]) {
    // 상태 기록 (조사 요구 중)
    state[fileKey] = { checked: false, firstAttempt: Date.now() };
    saveState(stateFile, state);

    return {
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason:
          '이 파일을 처음 수정합니다. 먼저 조사하세요:\n' +
          '① 이 파일을 import/require하는 파일 전부 (Grep 사용)\n' +
          '② 영향 받는 public 함수/클래스 목록\n' +
          '③ 데이터 파일이면 필드명과 포맷 확인\n' +
          '④ 동희님의 현재 지시를 그대로 인용\n' +
          '\n조사 완료 후 다시 시도하면 통과됩니다.'
      }
    };
  }

  // 두 번째 시도 → 허용 + 상태 기록
  state[fileKey] = { checked: true, checkedAt: Date.now() };
  saveState(stateFile, state);
  return null;
}

function saveState(filePath, state) {
  try {
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    state._updated = Date.now();
    const tempFile = filePath + '.tmp';
    fs.writeFileSync(tempFile, JSON.stringify(state, null, 2));
    fs.renameSync(tempFile, filePath);
  } catch (e) { /* Graceful — 상태 저장 실패해도 작업 안 막음 */ }
}

function simpleHash(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const chr = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + chr;
    hash |= 0;
  }
  return Math.abs(hash).toString(36);
}

module.exports = { run };
