#!/usr/bin/env bash
# kdh-wiki-build/build.sh — atomic wiki rebuild with flock + OWK-011 log emission
# Reference: 0420-topic6-graphify-integration.md §12 Fix v2-3
# Exit codes: 0 OK / 1 lock timeout / 2 scan fail / 3 build error / 4 monotonicity violation

set -euo pipefail

WIKI_DIR="${WIKI_DIR:-_bmad-output/wiki}"
LOCK_FILE="$WIKI_DIR/.writer.lock"
META_FILE="$WIKI_DIR/.writer.lock.meta"
LOG_FILE="$WIKI_DIR/log.md"

DRY_RUN=0
NO_CONSOLIDATE=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-consolidate) NO_CONSOLIDATE=1 ;;
    --force) FORCE=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
done

[ -d "$WIKI_DIR" ] || { echo "WIKI_DIR not found: $WIKI_DIR" >&2; exit 3; }

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

log_event() {
  local payload="$1"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] would log: $(ts) $payload"
  else
    echo "$(ts) $payload" >> "$LOG_FILE"
  fi
}

emit_lock_acquire() {
  local dur_ms="$1"
  log_event "event=LOCK action=acquire duration_ms=$dur_ms"
}
emit_lock_release() {
  local dur_ms="$1"
  log_event "event=LOCK action=release duration_ms=$dur_ms"
}
emit_build() {
  local sha="$1" page_size="$2" wiki_size="$3" entry_count="$4"
  log_event "event=BUILD sha=$sha page_size_bytes=$page_size wiki_size_bytes=$wiki_size wiki_entry_count=$entry_count"
}

# ---- VALIDATE ----
if command -v kdh-wiki-scan >/dev/null 2>&1; then
  if ! kdh-wiki-scan --wiki-dir="$WIKI_DIR" --report=/tmp/pre-build-scan.md >/dev/null 2>&1; then
    echo "wiki-scan FAIL — see /tmp/pre-build-scan.md" >&2
    exit 2
  fi
fi

# ---- LOCK ----
LOCK_START=$(date +%s%N)
exec 9>"$LOCK_FILE"
if ! flock -w 30 -x 9; then
  if [ -f "$LOCK_FILE" ]; then
    STALE=$(find "$LOCK_FILE" -mmin +10 | wc -l || echo 0)
    if [ "$STALE" -gt 0 ]; then
      echo "stale lock >10min — removing" >&2
      rm -f "$LOCK_FILE"
      exec 9>"$LOCK_FILE"
      flock -w 5 -x 9 || exit 1
    else
      exit 1
    fi
  else
    exit 1
  fi
fi
LOCK_END=$(date +%s%N)
LOCK_ACQ_MS=$(( (LOCK_END - LOCK_START) / 1000000 ))
emit_lock_acquire "$LOCK_ACQ_MS"

# Release trap
cleanup() {
  local rc=$?
  LOCK_REL_END=$(date +%s%N)
  LOCK_REL_MS=$(( (LOCK_REL_END - LOCK_END) / 1000000 ))
  flock -u 9 2>/dev/null || true
  emit_lock_release "$LOCK_REL_MS"
  exit $rc
}
trap cleanup EXIT

# ---- SOURCE HASH ----
SRC_HASH=$(cat \
  conductorA/STATUS.md \
  conductorA/DECISIONS.md \
  conductorA/MASTER-ROADMAP.md \
  _bmad-output/kdh-plans/_index.yaml \
  2>/dev/null | sha256sum | awk '{print $1}' | cut -c1-12)

PREV_HASH=""
[ -f "$META_FILE" ] && PREV_HASH=$(grep '^src_hash=' "$META_FILE" | cut -d= -f2-)

if [ "$SRC_HASH" = "$PREV_HASH" ] && [ "$FORCE" -ne 1 ]; then
  echo "sources unchanged (hash $SRC_HASH) — skipping build (use --force to rebuild)"
  exit 0
fi

# ---- BUILD (simplified: emit BUILD event only; real regeneration is skill-consumer responsibility) ----
# Compute sizes
PAGE_SIZE=$(cat "$WIKI_DIR"/home.md "$WIKI_DIR"/glossary.md "$WIKI_DIR"/decision-index.md 2>/dev/null | wc -c)
LOG_SIZE=$(wc -c < "$LOG_FILE")
WIKI_SIZE=$((PAGE_SIZE + LOG_SIZE))
ENTRY_COUNT=$(grep -cE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$LOG_FILE" || echo 0)

# Monotonicity check (if META has previous values)
if [ -f "$META_FILE" ]; then
  PREV_WIKI_SIZE=$(grep '^wiki_size_bytes=' "$META_FILE" | cut -d= -f2- || echo 0)
  PREV_ENTRY_COUNT=$(grep '^wiki_entry_count=' "$META_FILE" | cut -d= -f2- || echo 0)
  if [ "$WIKI_SIZE" -lt "$PREV_WIKI_SIZE" ] && [ "$NO_CONSOLIDATE" -eq 1 ]; then
    echo "monotonicity violation: wiki_size regressed without CONSOLIDATE" >&2
    exit 4
  fi
fi

# Get git SHA
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")

emit_build "$GIT_SHA" "$PAGE_SIZE" "$WIKI_SIZE" "$ENTRY_COUNT"

# ---- Per-page SHA (OWK-020 fast-path integrity) + Provenance 4-field (OWK-012) ----
for page in home.md glossary.md decision-index.md; do
  page_path="$WIKI_DIR/$page"
  [ ! -f "$page_path" ] && continue
  page_sha=$(sha256sum "$page_path" | awk '{print $1}' | cut -c1-16)
  # OWK-012 provenance: source_kind = derived, source_path = page, source_id = git sha, source_version = page_sha
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] would log: $(ts) event=INGEST source_kind=derived source_path=_bmad-output/wiki/$page source_id=$GIT_SHA source_version=$page_sha sha256=$page_sha"
  else
    echo "$(ts) event=INGEST source_kind=derived source_path=_bmad-output/wiki/$page source_id=$GIT_SHA source_version=$page_sha sha256=$page_sha" >> "$LOG_FILE"
  fi
done

# ---- META UPDATE ----
if [ "$DRY_RUN" -eq 0 ]; then
  cat > "$META_FILE" <<EOF
last_build_ts=$(ts)
src_hash=$SRC_HASH
git_sha=$GIT_SHA
wiki_size_bytes=$WIKI_SIZE
wiki_entry_count=$ENTRY_COUNT
EOF
fi

echo "wiki-build complete: sha=$GIT_SHA size=$WIKI_SIZE entries=$ENTRY_COUNT"
exit 0
