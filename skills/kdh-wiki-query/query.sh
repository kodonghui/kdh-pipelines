#!/usr/bin/env bash
# kdh-wiki-query/query.sh — read-only wiki query reference implementation
# Reference: 0417-board-v2-discussions/topic-6-rounds/R4/A.md OWK-011/012/014/015

set -euo pipefail

WIKI_DIR="${WIKI_DIR:-_bmad-output/wiki}"
SEED_FILES=(home.md glossary.md decision-index.md log.md)

MODE=""
TERM=""
PROV_KIND=""
PROV_PATH=""
PROV_ID=""
PROV_VERSION=""
LINK_PAGE=""
LINK_DEPTH=2
EVENT_TYPE=""

usage() {
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) MODE="list"; shift ;;
    --term=*) MODE="search"; TERM="${1#*=}"; shift ;;
    --provenance) MODE="provenance"; shift
      while [[ $# -gt 0 && "$1" == *"="* ]]; do
        case "$1" in
          kind=*) PROV_KIND="${1#*=}" ;;
          path=*) PROV_PATH="${1#*=}" ;;
          id=*) PROV_ID="${1#*=}" ;;
          version=*) PROV_VERSION="${1#*=}" ;;
        esac
        shift
      done ;;
    --link-graph) MODE="link"; LINK_PAGE="${2:-home.md}"; shift 2 ;;
    --depth=*) LINK_DEPTH="${1#*=}"; shift ;;
    --events) MODE="events"; EVENT_TYPE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) [[ -z "$MODE" ]] && { MODE="search"; TERM="$1"; }; shift ;;
  esac
done

[[ -d "$WIKI_DIR" ]] || { echo "WIKI_DIR not found: $WIKI_DIR" >&2; exit 1; }

# Validate OWK-015 file count regardless of mode
count=0
for f in "${SEED_FILES[@]}"; do
  [[ -f "$WIKI_DIR/$f" ]] && count=$((count + 1))
done
if [[ "$count" -ne 4 ]]; then
  echo "OWK-015 violation: expected 4 seed files, found $count" >&2
  exit 3
fi

case "$MODE" in
  list)
    for f in "${SEED_FILES[@]}"; do
      size=$(wc -c < "$WIKI_DIR/$f")
      echo "$f  $size bytes"
    done
    ;;

  search)
    [[ -z "$TERM" ]] && { echo "no term"; exit 2; }
    for f in "${SEED_FILES[@]}"; do
      grep -niE "$TERM" "$WIKI_DIR/$f" | sed "s|^|$f:|" || true
    done
    ;;

  provenance)
    # OWK-014: all-4-match for positive hit. Partial match = candidates.
    # Scan log.md event=INGEST / BUILD with matching fields.
    hits=0
    while IFS= read -r line; do
      match=1
      [[ -n "$PROV_KIND"    && "$line" != *"source_kind=$PROV_KIND"* ]] && match=0
      [[ -n "$PROV_PATH"    && "$line" != *"source_path=$PROV_PATH"* && "$line" != *"source=$PROV_PATH"* ]] && match=0
      [[ -n "$PROV_ID"      && "$line" != *"source_id=$PROV_ID"* ]] && match=0
      [[ -n "$PROV_VERSION" && "$line" != *"source_version=$PROV_VERSION"* ]] && match=0
      if [[ "$match" -eq 1 ]]; then
        echo "$line"
        hits=$((hits + 1))
      fi
    done < "$WIKI_DIR/log.md"
    if [[ "$hits" -eq 0 ]]; then
      echo "no provenance match — safe to create new page"
      exit 0
    elif [[ "$hits" -gt 1 ]]; then
      echo "fail-closed: $hits matches found (OWK-014)" >&2
      exit 1
    fi
    ;;

  link)
    # BFS traversal of [[wikilink]] and [text](file.md) refs
    declare -A visited
    queue=("$LINK_PAGE")
    depth=0
    while [[ ${#queue[@]} -gt 0 && "$depth" -lt "$LINK_DEPTH" ]]; do
      next_queue=()
      for page in "${queue[@]}"; do
        [[ -n "${visited[$page]:-}" ]] && continue
        visited[$page]=1
        echo "$page:"
        [[ ! -f "$WIKI_DIR/$page" ]] && { echo "  (not found)"; continue; }

        # wikilinks [[name]]
        grep -oE '\[\[[^]]+\]\]' "$WIKI_DIR/$page" 2>/dev/null | sed 's/\[\[//; s/\]\]//' | while read -r t; do
          echo "  → $t (wikilink)"
        done

        # markdown links [text](file.md)
        grep -oE '\]\([^)]+\.md\)' "$WIKI_DIR/$page" 2>/dev/null | sed 's/](//; s/)//' | while read -r t; do
          base=$(basename "$t")
          echo "  → $base (md-link)"
          next_queue+=("$base")
        done
      done
      queue=("${next_queue[@]}")
      depth=$((depth + 1))
    done
    ;;

  events)
    [[ -z "$EVENT_TYPE" ]] && { grep -oE 'event=[A-Z_]+' "$WIKI_DIR/log.md" | sort -u; exit 0; }
    grep "event=$EVENT_TYPE" "$WIKI_DIR/log.md" || echo "no events of type $EVENT_TYPE"
    ;;

  *)
    usage
    exit 2
    ;;
esac
