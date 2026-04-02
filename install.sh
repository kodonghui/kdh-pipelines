#!/bin/bash
# ═══════════════════════════════════════════════════════════
# KDH Pipeline Suite — 원클릭 설치
# 어디서든 이 깃만 가져오면 Opus 1M + Max 추론 + 전체 환경 세팅
# ═══════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

echo ""
echo "═══════════════════════════════════════"
echo " KDH Pipeline Suite — 설치"
echo "═══════════════════════════════════════"
echo ""

# ── 1. 디렉토리 생성 ──
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/rules"

# ── 2. 스킬 설치 ──
echo "[1/6] 스킬 설치..."
SKILL_COUNT=0
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
  if [ -f "$skill_dir/SKILL.md" ]; then
    name=$(basename "$skill_dir")
    mkdir -p "$CLAUDE_DIR/skills/$name"
    cp "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$name/SKILL.md"
    SKILL_COUNT=$((SKILL_COUNT + 1))
  fi
done
echo "  ✅ $SKILL_COUNT 스킬 설치 완료"

# ── 3. 에이전트 설치 ──
echo "[2/6] 에이전트 설치..."
AGENT_COUNT=0
for agent_file in "$SCRIPT_DIR"/agents/*.md; do
  if [ -f "$agent_file" ]; then
    cp "$agent_file" "$CLAUDE_DIR/agents/"
    AGENT_COUNT=$((AGENT_COUNT + 1))
  fi
done
echo "  ✅ $AGENT_COUNT 에이전트 설치 완료"

# ── 4. 규칙 설치 ──
echo "[3/6] 규칙 설치..."
RULE_COUNT=0
for rule_dir in "$SCRIPT_DIR"/rules/*/; do
  if [ -d "$rule_dir" ]; then
    name=$(basename "$rule_dir")
    cp -r "$rule_dir" "$CLAUDE_DIR/rules/$name"
    RULE_COUNT=$((RULE_COUNT + 1))
  fi
done
echo "  ✅ $RULE_COUNT 규칙 세트 설치 완료"

# ── 5. Hooks 설치 (프로젝트 디렉토리에) ──
echo "[4/6] Hooks 설치..."
if [ -d "$SCRIPT_DIR/hooks" ]; then
  mkdir -p .claude/hooks
  cp "$SCRIPT_DIR"/hooks/* .claude/hooks/ 2>/dev/null || true
  chmod +x .claude/hooks/*.sh 2>/dev/null || true
  echo "  ✅ Hooks → .claude/hooks/"
fi

# ── 6. settings.json 설정 (Opus 1M + Max 추론) ──
echo "[5/6] Claude 설정 (Opus + Max 추론)..."

if [ -f "$SETTINGS" ]; then
  # 기존 settings.json이 있으면 키만 추가/업데이트
  python3 -c "
import json

with open('$SETTINGS') as f:
    d = json.load(f)

# Opus 1M + Max 추론
d['effortLevel'] = 'max'

# Agent Teams 활성화
d.setdefault('env', {})
d['env']['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'

# TeammateIdle hook 추가
d.setdefault('hooks', {})
if 'TeammateIdle' not in d['hooks']:
    d['hooks']['TeammateIdle'] = [{
        'hooks': [{
            'type': 'command',
            'command': 'bash .claude/hooks/party-mode-nudge.sh',
            'timeout': 10
        }]
    }]

with open('$SETTINGS', 'w') as f:
    json.dump(d, f, indent=2)

print('  ✅ 기존 settings.json 업데이트')
" 2>/dev/null || echo "  ⚠️ settings.json 자동 업데이트 실패 — 수동 설정 필요"
else
  # settings.json이 없으면 새로 생성
  cat > "$SETTINGS" << 'SETTINGS_EOF'
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": [
      "Bash(*)", "Read(*)", "Write(*)", "Edit(*)",
      "Glob(*)", "Grep(*)", "Agent(*)", "Skill(*)",
      "TeamCreate(*)", "TeamDelete(*)", "SendMessage(*)",
      "TaskCreate(*)", "TaskGet(*)", "TaskList(*)",
      "TaskOutput(*)", "TaskStop(*)", "TaskUpdate(*)",
      "WebFetch(*)", "WebSearch(*)", "ToolSearch(*)"
    ]
  },
  "effortLevel": "max",
  "hooks": {
    "TeammateIdle": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/party-mode-nudge.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF
  echo "  ✅ settings.json 새로 생성"
fi

# ── 7. 템플릿 설치 ──
echo "[6/6] 템플릿 설치..."
if [ -d "$SCRIPT_DIR/templates" ]; then
  mkdir -p .claude/templates
  cp "$SCRIPT_DIR"/templates/* .claude/templates/ 2>/dev/null || true
  echo "  ✅ 템플릿 → .claude/templates/"
fi

echo ""
echo "═══════════════════════════════════════"
echo " 설치 완료!"
echo ""
echo " 스킬:     $SKILL_COUNT개"
echo " 에이전트:  $AGENT_COUNT개"
echo " 규칙:     $RULE_COUNT개 세트"
echo " 추론:     Max (Extended Thinking 최대)"
echo " 팀:       Agent Teams 활성화"
echo ""
echo " 사용법: claude 실행 → /kdh-full-auto-pipeline"
echo "═══════════════════════════════════════"
