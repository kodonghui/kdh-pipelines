#!/usr/bin/env bash
set -u

WIKI_DIR="_bmad-output/wiki"
REPORT=""

for arg in "$@"; do
  case "$arg" in
    --wiki-dir=*) WIKI_DIR="${arg#--wiki-dir=}" ;;
    --report=*) REPORT="${arg#--report=}" ;;
    -h|--help)
      cat <<'USAGE'
Usage: scan.sh [--wiki-dir=_bmad-output/wiki] [--report=/tmp/wiki-scan.md]
USAGE
      exit 0
      ;;
    *)
      echo "unknown argument: $arg" >&2
      exit 64
      ;;
  esac
done

if [ -z "$REPORT" ]; then
  REPORT="/tmp/wiki-scan-$(date -u +%Y%m%dT%H%M%SZ).md"
fi

overall="PASS"
exit_code=0

fail() {
  overall="FAIL"
  local code="$1"
  if [ "$exit_code" -eq 0 ] || [ "$code" -lt "$exit_code" ]; then
    exit_code="$code"
  fi
}

join_lines() {
  if [ "$#" -eq 0 ]; then
    printf 'none\n'
  else
    printf '%s\n' "$@"
  fi
}

allowed_files=("decision-index.md" "glossary.md" "home.md" "log.md")
actual_files=()
missing=()
extras=()
file_status="PASS"

if [ ! -d "$WIKI_DIR" ]; then
  file_status="FAIL"
  fail 1
  extras+=("wiki dir missing: $WIKI_DIR")
else
  while IFS= read -r path; do
    actual_files+=("$(basename "$path")")
  done < <(find "$WIKI_DIR" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort)

  for expected in "${allowed_files[@]}"; do
    found=0
    for actual in "${actual_files[@]}"; do
      [ "$actual" = "$expected" ] && found=1
    done
    [ "$found" -eq 0 ] && missing+=("$expected")
  done

  for actual in "${actual_files[@]}"; do
    allowed=0
    for expected in "${allowed_files[@]}"; do
      [ "$actual" = "$expected" ] && allowed=1
    done
    [ "$allowed" -eq 0 ] && extras+=("$actual")
  done

  if [ "${#actual_files[@]}" -ne 4 ] || [ "${#missing[@]}" -gt 0 ] || [ "${#extras[@]}" -gt 0 ]; then
    file_status="FAIL"
    fail 1
  fi
fi

log_status="PASS"
events_parsed=0
log_errors=()
prev_size=""
prev_count=""
mono_status="PASS"
mono_errors=()

log_file="$WIKI_DIR/log.md"
event_types=" INGEST QUERY BUILD CONSOLIDATE ARCHIVE LOCK SANDBOX_POC "

if [ ! -f "$log_file" ]; then
  log_status="FAIL"
  fail 2
  log_errors+=("log.md missing")
else
  line_no=0
  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))
    case "$line" in
      ""|\#*|\>*|---*) continue ;;
    esac

    if [[ ! "$line" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z[[:space:]]event=([^[:space:]]+)([[:space:]].*)?$ ]]; then
      log_status="FAIL"
      fail 2
      log_errors+=("line $line_no: invalid event format")
      continue
    fi

    event="${BASH_REMATCH[1]}"
    fields=" ${BASH_REMATCH[2]-} "
    events_parsed=$((events_parsed + 1))

    if [[ "$event_types" != *" $event "* ]]; then
      log_status="FAIL"
      fail 2
      log_errors+=("line $line_no: invalid event type $event")
      continue
    fi

    require_field() {
      local key="$1"
      if [[ "$fields" != *" $key="* ]]; then
        log_status="FAIL"
        fail 2
        log_errors+=("line $line_no: $event missing $key")
      fi
    }

    case "$event" in
      INGEST)
        require_field source
        require_field entry_count_delta
        require_field wiki_size_bytes
        require_field wiki_entry_count
        ;;
      QUERY)
        require_field query
        require_field hits
        require_field latency_ms
        ;;
      BUILD)
        require_field sha
        require_field page_size_bytes
        require_field wiki_size_bytes
        require_field wiki_entry_count
        ;;
      CONSOLIDATE)
        require_field merged
        require_field dropped
        require_field wiki_size_bytes
        require_field wiki_entry_count
        ;;
      ARCHIVE)
        require_field target
        require_field wiki_size_bytes
        require_field wiki_entry_count
        ;;
      LOCK)
        require_field action
        if [[ "$fields" == *" action=release"* ]]; then
          require_field duration_ms
        fi
        ;;
      SANDBOX_POC)
        require_field sandbox_sha
        require_field smoke_result
        if [[ "$fields" == *" smoke_result="* ]] && [[ ! "$fields" =~ [[:space:]]smoke_result=(PASS|FAIL)([[:space:]]|$) ]]; then
          log_status="FAIL"
          fail 2
          log_errors+=("line $line_no: SANDBOX_POC smoke_result must be PASS or FAIL")
        fi
        ;;
    esac

    size=""
    count=""
    if [[ "$fields" =~ [[:space:]]wiki_size_bytes=([0-9]+) ]]; then
      size="${BASH_REMATCH[1]}"
    fi
    if [[ "$fields" =~ [[:space:]]wiki_entry_count=([0-9]+) ]]; then
      count="${BASH_REMATCH[1]}"
    fi

    if [ -n "$size" ]; then
      if [ -n "$prev_size" ] && [ "$size" -lt "$prev_size" ] && [ "$event" != "CONSOLIDATE" ] && [ "$event" != "ARCHIVE" ]; then
        mono_status="FAIL"
        fail 4
        mono_errors+=("line $line_no: wiki_size_bytes regressed $prev_size -> $size at $event")
      fi
      prev_size="$size"
    fi

    if [ -n "$count" ]; then
      if [ -n "$prev_count" ] && [ "$count" -lt "$prev_count" ] && [ "$event" != "ARCHIVE" ] && ! { [ "$event" = "CONSOLIDATE" ] && [[ "$fields" =~ [[:space:]]merged=([1-9][0-9]*)([[:space:]]|$) ]]; }; then
        mono_status="FAIL"
        fail 4
        mono_errors+=("line $line_no: wiki_entry_count regressed $prev_count -> $count at $event")
      fi
      prev_count="$count"
    fi
  done < "$log_file"
fi

lock_status="PASS"
lock_notes=()
lock_file="$WIKI_DIR/.writer.lock"

if [ -d "$WIKI_DIR" ]; then
  while IFS= read -r path; do
    base="$(basename "$path")"
    if [ "$base" != ".writer.lock" ]; then
      lock_status="FAIL"
      fail 3
      lock_notes+=("unexpected lock path: $path")
    fi
  done < <(find "$WIKI_DIR" -type f -name '*.lock' -print)
fi

if [ -f "$lock_file" ]; then
  now="$(date +%s)"
  mtime="$(stat -c %Y "$lock_file")"
  age=$((now - mtime))
  if [ "$age" -ge 600 ]; then
    lock_status="FAIL"
    fail 3
    lock_notes+=("stale lock age_seconds=$age path=$lock_file")
  else
    lock_notes+=("lock present age_seconds=$age")
  fi
else
  lock_notes+=("lock absent")
fi

sync_status="OK"
sync_note="none"
source_dir="$HOME/kdh-pipelines/skills/kdh-wiki-scan"
runtime_dir="$HOME/.claude/skills/kdh-wiki-scan"
if [ -d "$source_dir" ] && [ -d "$runtime_dir" ]; then
  if ! diff -qr "$source_dir" "$runtime_dir" >/tmp/kdh-wiki-scan-diff.$$ 2>&1; then
    sync_status="DRIFT"
    sync_note="$(cat /tmp/kdh-wiki-scan-diff.$$)"
  fi
  rm -f /tmp/kdh-wiki-scan-diff.$$
else
  sync_status="DRIFT"
  sync_note="source or runtime dir missing"
fi

{
  echo "# Wiki Scan Report — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "**Target**: $WIKI_DIR"
  echo "**Overall**: $overall"
  echo
  echo "## Check 1: OWK-015 file count"
  echo "- Status: $file_status"
  echo "- Expected: 4 files (home, glossary, decision-index, log)"
  echo "- Actual: ${#actual_files[@]} files"
  echo "- Missing:"
  join_lines "${missing[@]}" | sed 's/^/  - /'
  echo "- Extras:"
  join_lines "${extras[@]}" | sed 's/^/  - /'
  echo
  echo "## Check 2: OWK-011 log schema"
  echo "- Status: $log_status"
  echo "- Events parsed: $events_parsed"
  echo "- Errors:"
  join_lines "${log_errors[@]}" | sed 's/^/  - /'
  echo
  echo "## Check 3: OWK-018 lock hygiene"
  echo "- Status: $lock_status"
  echo "- Notes:"
  join_lines "${lock_notes[@]}" | sed 's/^/  - /'
  echo
  echo "## Check 4: Monotonicity"
  echo "- Status: $mono_status"
  echo "- Regressions:"
  join_lines "${mono_errors[@]}" | sed 's/^/  - /'
  echo
  echo "## Check 5: Skill sync (advisory)"
  echo "- Status: $sync_status"
  echo "- Source: ~/kdh-pipelines/skills/kdh-wiki-scan/"
  echo "- Runtime: ~/.claude/skills/kdh-wiki-scan/"
  echo "- Diff:"
  printf '%s\n' "$sync_note" | sed 's/^/  - /'
} > "$REPORT"

echo "$REPORT"
exit "$exit_code"
