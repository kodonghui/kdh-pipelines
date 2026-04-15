#!/usr/bin/env node
/**
 * think-level.js — UserPromptSubmit hook
 *
 * 감지 키워드:
 *   think1 → 32K thinking
 *   think2 → 64K thinking
 *   think3 → 128K thinking (풀파워)
 *   아오/시발/미친/병신/씨발 → think2 자동 전환 + 카운터
 *
 * stdin으로 JSON 받아서 transcript_path에서 마지막 유저 메시지 추출
 */

const fs = require('fs');
const readline = require('readline');

// stdin에서 hook 메타데이터 읽기
let hookData = {};
try {
  const raw = fs.readFileSync('/dev/stdin', 'utf8').trim();
  hookData = JSON.parse(raw);
} catch { process.exit(0); }

// transcript에서 마지막 유저 메시지 추출
let userMessage = '';
const transcriptPath = hookData.transcript_path;

if (transcriptPath && fs.existsSync(transcriptPath)) {
  try {
    const lines = fs.readFileSync(transcriptPath, 'utf8').trim().split('\n');
    // 뒤에서부터 human 메시지 찾기
    for (let i = lines.length - 1; i >= 0; i--) {
      try {
        const entry = JSON.parse(lines[i]);
        if (entry.type === 'human' || entry.role === 'human' || entry.role === 'user') {
          // 메시지 내용 추출
          if (typeof entry.message === 'string') {
            userMessage = entry.message;
          } else if (entry.message && entry.message.content) {
            if (typeof entry.message.content === 'string') {
              userMessage = entry.message.content;
            } else if (Array.isArray(entry.message.content)) {
              userMessage = entry.message.content
                .filter(c => c.type === 'text')
                .map(c => c.text)
                .join(' ');
            }
          } else if (typeof entry.content === 'string') {
            userMessage = entry.content;
          }
          break;
        }
      } catch { continue; }
    }
  } catch { /* transcript read failed */ }
}

if (!userMessage) process.exit(0);

const msg = userMessage.toLowerCase();

// ── Think level 감지 ──
const THINK_LEVELS = {
  'think3': { tokens: 128000, label: '🔥 THINK-3 (128K)', desc: '풀파워. 모든 각도 분석. 최대 reasoning.' },
  'think2': { tokens: 64000,  label: '⚡ THINK-2 (64K)',  desc: '심층 사고. 대안 비교, 트레이드오프 분석.' },
  'think1': { tokens: 32000,  label: '💡 THINK-1 (32K)',  desc: '중간 사고. 핵심 집중.' },
};

for (const [keyword, config] of Object.entries(THINK_LEVELS)) {
  if (msg.includes(keyword)) {
    console.log(JSON.stringify({
      result: 'continue',
      message: `${config.label}: ${config.desc} (budgetTokens: ${config.tokens})`
    }));
    process.exit(0);
  }
}

// ── 짜증 키워드 ──
const FRUSTRATION_WORDS = ['아오', '시발', '미친', '병신', '씨발'];
const COUNTER_FILE = '/tmp/kdh-frustration-counter.json';
const LOG_DIR = (hookData.cwd || process.cwd()) + '/_bmad-output/frustration-logs';

const found = FRUSTRATION_WORDS.filter(w => msg.includes(w));
if (found.length > 0) {
  // 카운터
  let counter = { total: 0, today: '', todayCount: 0 };
  try {
    counter = JSON.parse(fs.readFileSync(COUNTER_FILE, 'utf8'));
  } catch { /* first time */ }

  const now = new Date();
  const today = now.toISOString().slice(0, 10);
  if (counter.today !== today) {
    counter.today = today;
    counter.todayCount = 0;
  }
  counter.total += found.length;
  counter.todayCount += found.length;

  try { fs.writeFileSync(COUNTER_FILE, JSON.stringify(counter)); } catch {}

  // 상세 로그 파일 저장
  try {
    fs.mkdirSync(LOG_DIR, { recursive: true });
    const logFile = `${LOG_DIR}/${today}.jsonl`;
    const logEntry = JSON.stringify({
      ts: now.toISOString(),
      keywords: found,
      message: userMessage.slice(0, 500),
      session_id: hookData.session_id || 'unknown',
      cwd: hookData.cwd || process.cwd(),
      todayCount: counter.todayCount,
      total: counter.total
    });
    fs.appendFileSync(logFile, logEntry + '\n');
  } catch { /* log write failed — non-fatal */ }

  console.log(JSON.stringify({
    result: 'continue',
    message: `⚡ THINK-2 자동 전환 (감정 감지: "${found.join(', ')}") — 64K 토큰으로 더 신중하게 생각합니다. [오늘 ${counter.todayCount}회 / 누적 ${counter.total}회]`
  }));
  process.exit(0);
}

process.exit(0);
