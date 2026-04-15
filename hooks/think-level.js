#!/usr/bin/env node
/**
 * think-level.js — UserPromptSubmit hook
 *
 * 감지 키워드:
 *   think1 → 가벼운 사고 (10K)
 *   think2 → 중간 사고 (32K)
 *   think3 → 풀파워 사고 (128K)
 *   아오/시발/미친/병신/씨발 → think2 (CEO 짜증 = 더 신중하게)
 */

const fs = require('fs');

// stdin에서 유저 입력 읽기
let input = '';
try {
  input = fs.readFileSync('/dev/stdin', 'utf8').trim();
} catch { process.exit(0); }

// JSON 파싱 시도 (hook input이 JSON일 수 있음)
let userMessage = input;
try {
  const parsed = JSON.parse(input);
  userMessage = parsed.message || parsed.prompt || parsed.content || input;
} catch { /* plain text */ }

const msg = userMessage.toLowerCase();

// ── Think level 감지 ──
const THINK_LEVELS = {
  'think3': { tokens: 128000, label: '🔥 THINK-3 (128K)', desc: '풀파워. 모든 각도 분석. 최대 reasoning.' },
  'think2': { tokens: 64000,  label: '⚡ THINK-2 (64K)',  desc: '심층 사고. 대안 비교, 트레이드오프 분석.' },
  'think1': { tokens: 32000,  label: '💡 THINK-1 (32K)',  desc: '중간 사고. 핵심 집중.' },
};

// ── 짜증 키워드 ──
const FRUSTRATION_WORDS = ['아오', '시발', '미친', '병신', '씨발'];
const COUNTER_FILE = '/tmp/kdh-frustration-counter.json';

// Think level 체크
for (const [keyword, config] of Object.entries(THINK_LEVELS)) {
  if (msg.includes(keyword)) {
    console.log(JSON.stringify({
      result: 'continue',
      message: `${config.label}: ${config.desc} (budgetTokens: ${config.tokens})`
    }));
    process.exit(0);
  }
}

// 짜증 키워드 체크
const found = FRUSTRATION_WORDS.filter(w => msg.includes(w));
if (found.length > 0) {
  // 카운터 증가
  let counter = { total: 0, today: '', todayCount: 0 };
  try {
    counter = JSON.parse(fs.readFileSync(COUNTER_FILE, 'utf8'));
  } catch { /* first time */ }

  const today = new Date().toISOString().slice(0, 10);
  if (counter.today !== today) {
    counter.today = today;
    counter.todayCount = 0;
  }
  counter.total += found.length;
  counter.todayCount += found.length;

  try { fs.writeFileSync(COUNTER_FILE, JSON.stringify(counter)); } catch {}

  console.log(JSON.stringify({
    result: 'continue',
    message: `⚡ THINK-2 자동 전환 (감정 감지: "${found.join(', ')}") — 64K 토큰으로 더 신중하게 생각합니다. [오늘 ${counter.todayCount}회 / 누적 ${counter.total}회]`
  }));
  process.exit(0);
}

// 매칭 없으면 아무것도 안 함
process.exit(0);
