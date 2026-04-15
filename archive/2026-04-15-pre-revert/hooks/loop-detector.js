#!/usr/bin/env node
// CORTHEX v3 — 루프 감지기 (Harness Improvement #3)
// PostToolUse hook: Edit/Write 도구 호출 시 파일별 수정 카운터 추적
// 출처: LangChain DeepAgents LoopDetectionMiddleware
//
// 사용법: .claude/settings.json의 hooks에 등록
// "postToolUse": [{ "matcher": "Edit|Write", "command": "node scripts/loop-detector.js" }]

const fs = require('fs');
const path = require('path');

const projectName = path.basename(process.cwd()).replace(/[^a-z0-9-]/gi, '-');
const COUNTER_FILE = `/tmp/${projectName}-edit-counter.json`;
const WARN_THRESHOLD = 5;
const ESCALATE_THRESHOLD = 8;

// stdin에서 hook 데이터 읽기
let input = '';
process.stdin.on('data', (chunk) => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const hookData = JSON.parse(input);
    const toolName = hookData.tool_name || '';
    const filePath = hookData.tool_input?.file_path || '';

    // Edit/Write 도구만 추적
    if (!['Edit', 'Write'].includes(toolName) || !filePath) {
      process.exit(0);
    }

    // 카운터 로드
    let counters = {};
    if (fs.existsSync(COUNTER_FILE)) {
      try {
        counters = JSON.parse(fs.readFileSync(COUNTER_FILE, 'utf8'));
      } catch {
        counters = {};
      }
    }

    // 카운터 증가
    const relPath = path.relative(process.cwd(), filePath);
    counters[relPath] = (counters[relPath] || 0) + 1;
    const count = counters[relPath];

    // 카운터 저장
    fs.writeFileSync(COUNTER_FILE, JSON.stringify(counters, null, 2));

    // 경고/에스컬레이트
    if (count === ESCALATE_THRESHOLD) {
      process.stderr.write(
        `\n🚨 루프 감지: ${relPath}을(를) ${count}번째 수정 중입니다.\n` +
        `   근본적으로 다른 접근법을 고려하세요.\n` +
        `   오케스트레이터에게 ESCALATE를 권장합니다.\n\n`
      );
    } else if (count === WARN_THRESHOLD) {
      process.stderr.write(
        `\n⚠️  루프 경고: ${relPath}을(를) ${count}번째 수정 중입니다.\n` +
        `   같은 파일을 반복 수정하고 있습니다. 다른 접근법을 고려해보세요.\n\n`
      );
    }

    process.exit(0);
  } catch (e) {
    // hook 실패가 작업을 막으면 안 됨
    process.exit(0);
  }
});

// stdin이 없으면 (직접 실행 시) 리셋 모드
if (!process.stdin.isTTY === undefined) {
  setTimeout(() => {
    // 5초 후 입력 없으면 리셋
    if (input === '') {
      if (process.argv.includes('--reset')) {
        if (fs.existsSync(COUNTER_FILE)) {
          fs.unlinkSync(COUNTER_FILE);
          console.log('루프 카운터 리셋 완료.');
        }
      } else if (process.argv.includes('--status')) {
        if (fs.existsSync(COUNTER_FILE)) {
          const counters = JSON.parse(fs.readFileSync(COUNTER_FILE, 'utf8'));
          console.log('파일별 수정 횟수:');
          Object.entries(counters)
            .sort((a, b) => b[1] - a[1])
            .forEach(([file, count]) => {
              const marker = count >= ESCALATE_THRESHOLD ? '🚨' : count >= WARN_THRESHOLD ? '⚠️' : '  ';
              console.log(`  ${marker} ${file}: ${count}회`);
            });
        } else {
          console.log('추적 데이터 없음.');
        }
      }
      process.exit(0);
    }
  }, 100);
}
