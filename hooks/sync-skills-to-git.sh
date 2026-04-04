#!/bin/bash
# Sync kdh skills to kdh-pipelines git repo
# Triggered after SKILL.md files are edited

TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"
SKILLS_DIR="$HOME/.claude/skills"
REPO_DIR="$HOME/kdh-pipelines"

# Only trigger on SKILL.md edits in kdh-* skills
if echo "$TOOL_INPUT" | grep -q "kdh-.*SKILL.md" 2>/dev/null; then
  if [ -d "$REPO_DIR" ]; then
    # Sync all kdh skills
    for skill in "$SKILLS_DIR"/kdh-*/; do
      name=$(basename "$skill")
      mkdir -p "$REPO_DIR/skills/$name"
      cp "$skill/SKILL.md" "$REPO_DIR/skills/$name/SKILL.md" 2>/dev/null
      cp "$skill/SKILL.md" "$REPO_DIR/skills/${name}.md" 2>/dev/null
    done

    # Auto-commit and push
    cd "$REPO_DIR" && \
    git add -A && \
    git diff --cached --quiet || \
    (git commit -m "auto-sync: kdh skills updated $(date +%Y-%m-%d)" && git push origin main 2>/dev/null)

    echo "[Skills Sync] kdh-pipelines updated"
  fi
fi
exit 0
