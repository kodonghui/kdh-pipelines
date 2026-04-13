#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════
// research-flag-setter.js — PostToolUse (Bash|WebSearch|WebFetch)
// gh search, WebSearch, WebFetch 실행 시 research 플래그 기록.
// research-guard.js의 보조 훅.
//
// Phase 1 Task 1-10 (kdh-harness-refactor v2)
// ═══════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');
const os = require('os');

const MAX_INPUT = 1024 * 1024;
const FLAG_DIR = path.join(os.homedir(), '.research-guard');

// 검색 명령 패턴
const SEARCH_PATTERNS = [
  /gh\s+search/i,
  /gh\s+api/i,
  /npm\s+search/i,
  /npx\s+.*search/i
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
    // 무시 — 보조 훅이므로 실패해도 OK
  }
  process.stdout.write(raw); // 항상 pass-through
  process.exit(0);
});

function run(data) {
  const toolName = data.tool_name || '';
  const sessionId = data.session_id || 'unknown';

  let isSearch = false;

  // WebSearch, WebFetch → 무조건 검색
  if (['WebSearch', 'WebFetch'].includes(toolName)) {
    isSearch = true;
  }

  // Bash → 명령어에 검색 패턴 포함 여부
  if (toolName === 'Bash') {
    const command = (data.tool_input && data.tool_input.command) || '';
    isSearch = SEARCH_PATTERNS.some(p => p.test(command));
  }

  if (!isSearch) return;

  // 플래그 파일 기록 (원자적: temp → rename)
  try {
    if (!fs.existsSync(FLAG_DIR)) {
      fs.mkdirSync(FLAG_DIR, { recursive: true });
    }

    const flagFile = path.join(FLAG_DIR, `state-${sessionId}.json`);
    const tempFile = flagFile + '.tmp';
    const payload = JSON.stringify({
      researched: true,
      timestamp: new Date().toISOString(),
      tool: toolName,
      query: toolName === 'Bash'
        ? (data.tool_input && data.tool_input.command || '').slice(0, 200)
        : (data.tool_input && data.tool_input.query || '').slice(0, 200)
    });

    fs.writeFileSync(tempFile, payload);
    fs.renameSync(tempFile, flagFile);
  } catch (e) {
    // 플래그 기록 실패 — 다음에 다시 시도. 작업 안 막음.
  }
}

module.exports = { run };
