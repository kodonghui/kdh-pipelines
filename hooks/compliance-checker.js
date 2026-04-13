#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════
// compliance-checker.js — PreToolUse (Bash)
// 파이프라인 규칙 실시간 감시:
//   1. git commit 시 party-log 개수 확인 → 부족하면 차단
//   2. git push to main/master → 차단 (PR 사용 강제)
//   3. 위반 기록 → compliance-violations.jsonl
//
// 기존 pipeline-guard.sh를 대체 (경고→차단으로 강화).
// Phase 1 Task 1-5 (kdh-harness-refactor v2)
// ═══════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');
const os = require('os');

const MAX_INPUT = 1024 * 1024;

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
  const cwd = data.cwd || process.cwd();

  // ─── git push to main/master 차단 ───
  if (/git\s+push/.test(command)) {
    const pushToMain = /git\s+push\s+\S+\s+(main|master)\b/.test(command)
      || (/git\s+push\b/.test(command) && !/-u\s/.test(command) && !/origin\s+\S+/.test(command));

    if (/git\s+push\s+\S+\s+(main|master)\b/.test(command)) {
      logViolation(cwd, 'push-to-main', command);
      return deny('main/master에 직접 push 금지. PR을 사용하세요.');
    }
  }

  // ─── git commit 시 party-log 확인 ───
  if (/git\s+commit/.test(command)) {
    const projectRoot = findProjectRoot(cwd);
    if (!projectRoot) return null; // 프로젝트 루트 못 찾으면 통과

    // pipeline-state.yaml 읽기
    const stateFile = path.join(projectRoot, '_bmad-output', 'pipeline-state.yaml');
    if (!fs.existsSync(stateFile)) return null; // 상태 파일 없으면 통과 (파이프라인 미사용)

    try {
      const stateContent = fs.readFileSync(stateFile, 'utf8');

      // current_story 추출 (간이 YAML 파싱)
      const storyMatch = stateContent.match(/current_story:\s*["']?([^"'\n]+)/);
      if (!storyMatch) return null;
      const story = storyMatch[1].trim();

      // party-log 디렉토리에서 현재 스토리 관련 로그 개수 확인
      const partyDir = path.join(projectRoot, '_bmad-output', 'party-logs');
      if (!fs.existsSync(partyDir)) {
        logViolation(cwd, 'commit-without-partylog', `story=${story}, party-logs dir missing`);
        return deny(
          `Story ${story}의 party-log 디렉토리가 없습니다.\n` +
          'Party Mode를 실행하고 critic 리뷰를 받으세요.'
        );
      }

      // story ID로 매칭되는 party-log 파일 개수
      const files = fs.readdirSync(partyDir);
      const storyLogs = files.filter(f =>
        f.includes(`story-${story}`) || f.includes(`bugfix-${story}`)
      );

      const MIN_LOGS = 2; // winston + quinn 최소

      if (storyLogs.length < MIN_LOGS) {
        logViolation(cwd, 'commit-without-partylog',
          `story=${story}, logs=${storyLogs.length}, min=${MIN_LOGS}`);
        return deny(
          `Story ${story}의 party-log가 ${storyLogs.length}개입니다 (최소 ${MIN_LOGS}개 필요).\n` +
          '커밋 차단. Party Mode 리뷰를 완료하세요.\n' +
          `현재 로그: ${storyLogs.join(', ') || '없음'}`
        );
      }

      // Codex status 확인
      const codexMatch = stateContent.match(/codex[\s\S]*?status:\s*["']?(\w+)/);
      if (codexMatch && codexMatch[1] !== 'pass') {
        logViolation(cwd, 'commit-without-codex', `story=${story}, codex=${codexMatch[1]}`);
        return deny(
          `Story ${story}의 Codex 검증이 pass가 아닙니다 (현재: ${codexMatch[1]}).\n` +
          'Codex 검증을 통과한 후 커밋하세요.'
        );
      }
    } catch (e) {
      // 상태 파일 파싱 에러 → pass-through (작업 안 막음)
      return null;
    }
  }

  return null;
}

function deny(reason) {
  return {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: reason
    }
  };
}

function findProjectRoot(cwd) {
  // _bmad-output 또는 package.json이 있는 상위 디렉토리 찾기
  let dir = cwd;
  for (let i = 0; i < 10; i++) {
    if (fs.existsSync(path.join(dir, '_bmad-output')) ||
        fs.existsSync(path.join(dir, 'package.json'))) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return null;
}

function logViolation(cwd, type, detail) {
  try {
    const projectRoot = findProjectRoot(cwd) || cwd;
    const logDir = path.join(projectRoot, '_bmad-output');
    if (!fs.existsSync(logDir)) return;

    const logFile = path.join(logDir, 'compliance-violations.jsonl');
    const entry = JSON.stringify({
      timestamp: new Date().toISOString(),
      type: type,
      detail: detail
    }) + '\n';

    fs.appendFileSync(logFile, entry);
  } catch (e) { /* 로그 실패 무시 */ }
}

module.exports = { run };
