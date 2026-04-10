#!/bin/bash
# Cross-Model Verification Helper (Codex + Gemini 병렬)
# Usage: codex-review.sh <file> [prompt]
#
# 모든 kdh 명령어에서 교차 모델 검증 시 사용.
# Codex(GPT-5.4) + Gemini 병렬 실행 → 결과 합산.
# 둘 다 실패하면 CEO 보고 (자동 스킵 금지).

FILE="${1:?Usage: codex-review.sh <file> [prompt]}"
PROMPT="${2:-다음 내용을 공격적으로 리뷰해라. 틀린 부분, 빠진 관점, 편향, 비현실적 가정을 찾아라. 반드시 3개 이상 이슈를 찾아라. 한국어로 답해라.}"

# Check file exists
if [ ! -f "$FILE" ]; then
    echo "ERROR: File not found: $FILE"
    exit 1
fi

CODEX_OK=false
GEMINI_OK=false
CODEX_OUT=$(mktemp)
GEMINI_OUT=$(mktemp)

# ── Codex (GPT-5.4) ──
run_codex() {
    if ! command -v codex &> /dev/null; then
        echo "WARNING: Codex CLI not installed" > "$CODEX_OUT"
        return 1
    fi
    echo "[Codex] Running GPT-5.4..." >&2
    cat "$FILE" | codex exec "$PROMPT" > "$CODEX_OUT" 2>&1
    return $?
}

# ── Gemini ──
run_gemini() {
    if ! command -v gemini &> /dev/null; then
        echo "WARNING: Gemini CLI not installed" > "$GEMINI_OUT"
        return 1
    fi
    echo "[Gemini] Running Gemini..." >&2
    cat "$FILE" | gemini -p "$PROMPT" > "$GEMINI_OUT" 2>&1
    return $?
}

# ── 병렬 실행 ──
run_codex &
CODEX_PID=$!

run_gemini &
GEMINI_PID=$!

# ── 결과 수집 ──
wait $CODEX_PID && CODEX_OK=true
wait $GEMINI_PID && GEMINI_OK=true

echo ""
echo "════════════════════════════════════════"
echo "[Cross-Model Review] Results"
echo "════════════════════════════════════════"

if [ "$CODEX_OK" = true ]; then
    echo ""
    echo "── Codex (GPT-5.4) ──"
    cat "$CODEX_OUT"
else
    echo ""
    echo "── Codex: FAILED ──"
    cat "$CODEX_OUT"
fi

if [ "$GEMINI_OK" = true ]; then
    echo ""
    echo "── Gemini ──"
    cat "$GEMINI_OUT"
else
    echo ""
    echo "── Gemini: FAILED ──"
    cat "$GEMINI_OUT"
fi

echo ""
echo "════════════════════════════════════════"

# Cleanup
rm -f "$CODEX_OUT" "$GEMINI_OUT"

# 둘 다 실패 = 차단
if [ "$CODEX_OK" = false ] && [ "$GEMINI_OK" = false ]; then
    echo "ERROR: Both Codex and Gemini failed. DO NOT auto-skip. Report to CEO."
    exit 1
fi

# 하나라도 성공 = 결과 출력 완료
echo "[Cross-Model Review] Complete. Codex:$([ "$CODEX_OK" = true ] && echo PASS || echo FAIL) Gemini:$([ "$GEMINI_OK" = true ] && echo PASS || echo FAIL)"
