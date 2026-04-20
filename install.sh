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

# ── 1. 글로벌 디렉토리 생성 ──
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/rules"

# ── 2. 스킬 설치 ──
echo "[1/7] 스킬 설치..."
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
echo "[2/7] 에이전트 설치..."
AGENT_COUNT=0
for agent_file in "$SCRIPT_DIR"/agents/*.md; do
  if [ -f "$agent_file" ]; then
    cp "$agent_file" "$CLAUDE_DIR/agents/"
    AGENT_COUNT=$((AGENT_COUNT + 1))
  fi
done
echo "  ✅ $AGENT_COUNT 에이전트 설치 완료"

# ── 4. 규칙 설치 ──
echo "[3/7] 규칙 설치..."
RULE_COUNT=0
for rule_dir in "$SCRIPT_DIR"/rules/*/; do
  if [ -d "$rule_dir" ]; then
    name=$(basename "$rule_dir")
    cp -r "$rule_dir" "$CLAUDE_DIR/rules/$name"
    RULE_COUNT=$((RULE_COUNT + 1))
  fi
done
echo "  ✅ $RULE_COUNT 규칙 세트 설치 완료"

# ── 5. BMAD 에이전트 persona 설치 (파티모드용) ──
echo "[4/7] BMAD 에이전트 persona 설치..."
if [ -d "$SCRIPT_DIR/bmad-agents" ]; then
  mkdir -p bmad-agents
  cp "$SCRIPT_DIR"/bmad-agents/*.md bmad-agents/ 2>/dev/null || true
  BMAD_COUNT=$(ls bmad-agents/*.md 2>/dev/null | wc -l)
  echo "  ✅ $BMAD_COUNT BMAD persona → bmad-agents/"
fi

# ── 6. 산출물 디렉토리 생성 ──
echo "[5/7] 산출물 디렉토리 생성..."
mkdir -p _bmad-output/kdh-plans
mkdir -p _bmad-output/party-logs
mkdir -p _bmad-output/update-log
mkdir -p _bmad-output/compliance
mkdir -p _bmad-output/bug-fix/party-logs
mkdir -p _bmad-output/planning-artifacts
mkdir -p _bmad-output/implementation-artifacts
mkdir -p _bmad-output/a11y
mkdir -p _bmad-output/deploy-verify
mkdir -p _bmad-output/design-review
mkdir -p _bmad-output/e2e-screenshots/visual-diff
mkdir -p _bmad-output/e2e-screenshots/bug-fix
echo "  ✅ _bmad-output/ 디렉토리 구조 생성"

# ── 7. Hooks 설치 (프로젝트 디렉토리에) ──
echo "[6/7] Hooks 설치..."
if [ -d "$SCRIPT_DIR/hooks" ]; then
  mkdir -p .claude/hooks
  cp "$SCRIPT_DIR"/hooks/* .claude/hooks/ 2>/dev/null || true
  chmod +x .claude/hooks/*.sh .claude/hooks/*.js 2>/dev/null || true
  mkdir -p "$CLAUDE_DIR/hooks"
  cp "$SCRIPT_DIR"/hooks/* "$CLAUDE_DIR/hooks/" 2>/dev/null || true
  chmod +x "$CLAUDE_DIR"/hooks/*.sh "$CLAUDE_DIR"/hooks/*.js 2>/dev/null || true
  echo "  ✅ Hooks → .claude/hooks/ + ~/.claude/hooks/"
fi

# ── 8. settings.json 설정 (Opus 1M + Max 추론) ──
echo "[7/7] Claude 설정 (Opus + Max 추론)..."

if [ -f "$SETTINGS" ]; then
  python3 -c "
import json

with open('$SETTINGS') as f:
    d = json.load(f)

d['effortLevel'] = 'max'

d.setdefault('env', {})
d['env']['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'

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

# ── 9. 템플릿 설치 (프로젝트 + 글로벌) ──
if [ -d "$SCRIPT_DIR/templates" ]; then
  mkdir -p .claude/templates
  cp "$SCRIPT_DIR"/templates/* .claude/templates/ 2>/dev/null || true
  mkdir -p "$CLAUDE_DIR/templates"
  cp "$SCRIPT_DIR"/templates/* "$CLAUDE_DIR/templates/" 2>/dev/null || true
fi

echo ""
echo "═══════════════════════════════════════"
echo " 설치 완료!"
echo ""
echo " 스킬:        $SKILL_COUNT개"
echo " 에이전트:     $AGENT_COUNT개"
echo " BMAD persona: $(ls "$SCRIPT_DIR"/bmad-agents/*.md 2>/dev/null | wc -l)개"
echo " 규칙:        $RULE_COUNT개 세트"
echo " 추론:        Max (Extended Thinking 최대)"
echo " 팀:          Agent Teams 활성화"
echo " 산출물:      _bmad-output/ 디렉토리 생성됨"
echo ""
echo " 사용법: claude 실행 → /kdh-dev-pipeline"
echo "═══════════════════════════════════════"
