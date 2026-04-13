#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════
// observation-collector.js — PreToolUse + PostToolUse (*, async)
// 모든 도구 사용을 observations.jsonl에 실시간 기록.
// Phase 3 크론→훅 전환의 핵심 데이터 소스.
//
// ECC continuous-learning-v2 observe.sh 패턴 기반:
//   - 프로젝트별 observations.jsonl
//   - 10MB 초과 시 아카이브 로테이션
//   - 30일 지난 아카이브 자동 purge
//   - Graceful degradation (실패해도 작업 안 막음)
//
// 연동:
//   - ecc-3h: observations.jsonl에서 update-log 자동 추출
//   - ecc-12h: observations.jsonl에서 instinct 패턴 추출
//   - compliance-loop: observations.jsonl에서 Phase 순서 검증
//   - verification-check.js: 검증 명령어 실행 시 verification-log 기록
//
// Phase 1 Task 1-9 (kdh-harness-refactor v2)
// ═══════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');
const os = require('os');

const MAX_INPUT = 1024 * 1024; // 1MB
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB → 로테이션
const PURGE_DAYS = 30;
const VERIFICATION_LOG = path.join(os.tmpdir(), 'corthex-verification-log.json');

// 검증 명령어 패턴 (verification-check.js와 동기화)
const VERIFICATION_COMMANDS = [
  /\bbun\s+test\b/,
  /\bnpm\s+test\b/,
  /\bnpx\s+vitest\b/,
  /\bnpx\s+jest\b/,
  /\bnpx\s+playwright\b/,
  /\btsc\b.*--noEmit/,
  /\bnpx\s+tsc\b/,
  /\bpytest\b/,
  /\bcargo\s+test\b/,
  /\bgo\s+test\b/
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
    run(data);
  } catch (e) {
    // 파싱 실패 — 무시
  }
  // async 훅: stdout 출력 없음 (pass-through 불필요)
  process.exit(0);
});

function run(data) {
  // 환경변수로 비활성화
  if (process.env.CORTHEX_SKIP_OBSERVE === '1') return;

  const toolName = data.tool_name || '';
  const hookEvent = data.hook_event_name || detectEvent(data);
  const sessionId = data.session_id || 'unknown';
  const cwd = data.cwd || process.cwd();

  // 자기 자신 관찰 방지 (observation-collector가 observation-collector를 기록하는 무한 루프 방지)
  if (toolName === 'observation-collector') return;

  // ─── 관찰 레코드 구성 ───
  const record = {
    timestamp: new Date().toISOString(),
    event: hookEvent,
    tool: toolName,
    session: sessionId
  };

  // 도구별 핵심 정보 추출 (최소한만)
  const input = data.tool_input || {};

  switch (toolName) {
    case 'Edit':
    case 'Write':
    case 'MultiEdit':
      record.file = input.file_path || null;
      break;

    case 'Read':
      record.file = input.file_path || null;
      break;

    case 'Bash':
      // 명령어 앞 100자만 (보안: 비밀번호/토큰 노출 방지)
      record.command = scrubSecrets((input.command || '').slice(0, 100));
      // 검증 명령어 감지 → verification-log 기록
      if (input.command) {
        recordVerificationIfNeeded(input.command);
      }
      break;

    case 'Grep':
      record.pattern = (input.pattern || '').slice(0, 50);
      break;

    case 'Glob':
      record.pattern = (input.pattern || '').slice(0, 50);
      break;

    case 'Agent':
      record.description = (input.description || '').slice(0, 80);
      record.subagent_type = input.subagent_type || null;
      break;

    case 'WebSearch':
    case 'WebFetch':
      record.query = (input.query || input.url || '').slice(0, 100);
      break;

    default:
      // 기타 도구: 도구 이름만 기록
      break;
  }

  // ─── observations.jsonl에 기록 ───
  const obsDir = resolveObservationsDir(cwd);
  if (!obsDir) return;

  const obsFile = path.join(obsDir, 'observations.jsonl');

  try {
    // 디렉토리 생성
    if (!fs.existsSync(obsDir)) {
      fs.mkdirSync(obsDir, { recursive: true });
    }

    // 로테이션 체크
    rotateIfNeeded(obsFile);

    // JSONL append
    fs.appendFileSync(obsFile, JSON.stringify(record) + '\n');
  } catch (e) {
    // Graceful — 기록 실패해도 작업 안 막음
  }

  // ─── 주기적 purge (100번마다 1회) ───
  if (Math.random() < 0.01) {
    purgeOldArchives(obsDir);
  }
}

// ─── 보안: 비밀번호/토큰 스크러빙 ───
function scrubSecrets(str) {
  return str
    .replace(/(?:api[_-]?key|token|password|secret|auth)[=:]\s*\S+/gi, '$&_SCRUBBED')
    .replace(/(?:sk-|ghp_|gho_|glpat-|xoxb-)\S+/g, '[REDACTED]');
}

// ─── observations 디렉토리 결정 ───
function resolveObservationsDir(cwd) {
  // 1. 환경변수
  if (process.env.CORTHEX_OBSERVATIONS_DIR) {
    return process.env.CORTHEX_OBSERVATIONS_DIR;
  }

  // 2. 프로젝트 _bmad-output/ 탐색
  let dir = cwd;
  for (let i = 0; i < 10; i++) {
    const bmadDir = path.join(dir, '_bmad-output');
    if (fs.existsSync(bmadDir)) {
      return bmadDir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }

  // 3. 홈 디렉토리 fallback
  return path.join(os.homedir(), '.claude', 'observations');
}

// ─── 로테이션 (10MB 초과 시) ───
function rotateIfNeeded(filePath) {
  try {
    if (!fs.existsSync(filePath)) return;
    const stat = fs.statSync(filePath);
    if (stat.size < MAX_FILE_SIZE) return;

    const dateStr = new Date().toISOString().slice(0, 10);
    const archivePath = filePath.replace('.jsonl', `-${dateStr}-${Date.now()}.jsonl`);
    fs.renameSync(filePath, archivePath);
  } catch (e) { /* 무시 */ }
}

// ─── 30일 지난 아카이브 purge ───
function purgeOldArchives(dir) {
  try {
    const files = fs.readdirSync(dir);
    const now = Date.now();
    const maxAge = PURGE_DAYS * 24 * 60 * 60 * 1000;

    files.forEach(f => {
      if (!f.startsWith('observations-') || !f.endsWith('.jsonl')) return;
      const fullPath = path.join(dir, f);
      try {
        const stat = fs.statSync(fullPath);
        if (now - stat.mtimeMs > maxAge) {
          fs.unlinkSync(fullPath);
        }
      } catch (e) { /* 무시 */ }
    });
  } catch (e) { /* 무시 */ }
}

// ─── 검증 명령어 감지 → verification-log 기록 ───
function recordVerificationIfNeeded(command) {
  const isVerification = VERIFICATION_COMMANDS.some(p => p.test(command));
  if (!isVerification) return;

  try {
    const log = {
      lastVerification: Date.now(),
      command: command.slice(0, 200)
    };
    fs.writeFileSync(VERIFICATION_LOG, JSON.stringify(log));
  } catch (e) { /* 무시 */ }
}

// ─── 이벤트 타입 감지 (hook_event_name 없을 때) ───
function detectEvent(data) {
  // tool_response가 있으면 PostToolUse
  if (data.tool_response !== undefined) return 'PostToolUse';
  return 'PreToolUse';
}

module.exports = { run };
