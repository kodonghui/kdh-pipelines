#!/bin/bash
# ═══════════════════════════════════════════════════════════
# codex-safe.sh — Codex CLI ASCII path wrapper
#
# Purpose: Codex CLI websocket header에 cwd 들어가는데 ASCII-only.
# 한글/non-ASCII path → "UTF-8 encoding error: failed to convert header"
# 발생 후 무한 hang.
#
# Usage:
#   codex-safe.sh "<prompt>"
#   codex-safe.sh --copy <file1,file2,...> "<prompt>"   # 파일 ASCII 폴더로 cp
#
# Triggered by: 2026-04-14 user-feedback #13 🔴 (Conductor 한글 경로
# `/mnt/c/Users/USER/Desktop/고동희/kdh-conductor`에서 codex exec hang).
#
# 동작:
# 1. 현재 cwd를 LC_ALL=C ascii test → 비-ASCII면 ASCII 폴더로 우회
# 2. ASCII 폴더 = /tmp/codex-safe-<hash>/
# 3. --copy 옵션 있으면 지정 파일들 cp
# 4. 그 폴더로 cd + codex exec 실행
# ═══════════════════════════════════════════════════════════

set -e

# 인자 파싱
COPY_FILES=""
if [ "$1" = "--copy" ]; then
  COPY_FILES="$2"
  shift 2
fi

PROMPT="$1"
if [ -z "$PROMPT" ]; then
  cat <<EOF
Usage:
  codex-safe.sh "<prompt>"
  codex-safe.sh --copy <file1,file2,...> "<prompt>"

Examples:
  codex-safe.sh "review the test failure"
  codex-safe.sh --copy /path/to/log.md,/path/to/config.json "analyze these"
EOF
  exit 1
fi

# 현재 cwd ASCII 검증
CURRENT_CWD=$(pwd)
if echo "$CURRENT_CWD" | LC_ALL=C grep -q '[^[:print:]]\|[^[:ascii:]]' 2>/dev/null; then
  NEEDS_RELOCATE=1
else
  # bash가 [:ascii:] 미지원 시 alternative check
  if echo "$CURRENT_CWD" | LC_ALL=C grep -qP '[^\x00-\x7F]'; then
    NEEDS_RELOCATE=1
  else
    NEEDS_RELOCATE=0
  fi
fi

if [ "$NEEDS_RELOCATE" = "1" ]; then
  # ASCII 폴더 생성 (cwd hash)
  HASH=$(echo "$CURRENT_CWD" | sha1sum | cut -c1-8)
  ASCII_DIR="/tmp/codex-safe-$HASH"
  mkdir -p "$ASCII_DIR"

  echo "[codex-safe] non-ASCII cwd detected: $CURRENT_CWD" >&2
  echo "[codex-safe] relocating to ASCII path: $ASCII_DIR" >&2

  # --copy 옵션 처리
  if [ -n "$COPY_FILES" ]; then
    IFS=',' read -ra FILES <<< "$COPY_FILES"
    for f in "${FILES[@]}"; do
      if [ -f "$f" ]; then
        cp "$f" "$ASCII_DIR/"
        echo "[codex-safe] copied: $f -> $ASCII_DIR/" >&2
      elif [ -d "$f" ]; then
        cp -r "$f" "$ASCII_DIR/"
        echo "[codex-safe] copied dir: $f -> $ASCII_DIR/" >&2
      else
        echo "[codex-safe] WARN: not found: $f" >&2
      fi
    done
  fi

  cd "$ASCII_DIR"
fi

# Codex 실행
exec codex exec --skip-git-repo-check "$PROMPT"
