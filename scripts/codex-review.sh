#!/bin/bash
# Codex Cross-Model Verification Helper
# Usage: codex-review.sh <file> [prompt]
#
# 모든 kdh 명령어에서 Codex 검증 시 사용.
# Codex가 없으면 설치, 인증 실패면 에러 반환 (자동 스킵 금지).

FILE="${1:?Usage: codex-review.sh <file> [prompt]}"
PROMPT="${2:-다음 내용을 공격적으로 리뷰해라. 틀린 부분, 빠진 관점, 편향, 비현실적 가정을 찾아라. 반드시 3개 이상 이슈를 찾아라. 한국어로 답해라.}"

# Check codex installed
if ! command -v codex &> /dev/null; then
    echo "ERROR: Codex CLI not installed. Run: sudo npm install -g @openai/codex"
    exit 1
fi

# Check file exists
if [ ! -f "$FILE" ]; then
    echo "ERROR: File not found: $FILE"
    exit 1
fi

# Run Codex
echo "[Codex Review] Running GPT-5.4 cross-verification..."
cat "$FILE" | codex exec "$PROMPT" 2>&1

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo "ERROR: Codex failed with exit code $EXIT_CODE"
    echo "DO NOT auto-skip. Report to CEO."
    exit $EXIT_CODE
fi

echo "[Codex Review] Complete."
