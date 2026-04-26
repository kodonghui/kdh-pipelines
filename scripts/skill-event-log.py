#!/usr/bin/env python3
"""
Skill Event Logger — board 0425-skill-ecosystem-improvement R-NOV-05

Purpose: Skill invocation 실패 / 의심 이벤트 telemetry. 결과 = JSONL 추가 (append-only)
         = ~/.claude/skill-events.jsonl. R-NOV-06 Knowledge plane consumer 입력.

Logged event types:
  - alias_miss            : skill-alias-map.yaml 에 alias 등록 X
  - blocked_path          : status=blocked alias direct invoke 시도
  - manifest_audit_fail   : R-25 manifest auditor FAIL/UNAUDITED
  - smoke_false_pass      : smoke harness PASS 했으나 후속 검증에서 결함 발견
  - frontmatter_invalid   : R-06 위반
  - invocation_surface_break : R-08 wrapper invocation surface 변경 감지

Log fields (per R-NOV-05 spec):
  event           : event type (above)
  skill_id        : 호출된 skill 명
  alias_resolution: resolver 결과 (target / fallback / blocked / null)
  manifest_state  : R-25 audit verdict (AUDITED_PASS / AUDITED_FAIL / UNAUDITED)
  timestamp       : ISO 8601 UTC

Usage:
  # 직접 호출 (manual logging)
  python3 skill-event-log.py --event alias_miss --skill-id quinn \
    --alias-resolution "no entry" --manifest-state AUDITED_PASS

  # JSON output
  python3 skill-event-log.py --event smoke_false_pass --skill-id kdh-foo \
    --alias-resolution kdh-foo --manifest-state AUDITED_PASS --json

  # tail (recent events)
  python3 skill-event-log.py --tail 10
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_LOG = Path.home() / ".claude" / "skill-events.jsonl"

VALID_EVENTS = {
    "alias_miss",
    "blocked_path",
    "manifest_audit_fail",
    "smoke_false_pass",
    "frontmatter_invalid",
    "invocation_surface_break",
    "rollback_drill",
    "rollback_actual",
    "skill_added",
    "skill_removed",
    "alias_map_revision_change",
    "manual",
}

VALID_MANIFEST_STATES = {
    "AUDITED_PASS",
    "AUDITED_FAIL",
    "UNAUDITED",
    "NOT_CHECKED",
    "UNKNOWN",
}


def append_event(log_path: Path, event: dict) -> None:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    line = json.dumps(event, ensure_ascii=False, separators=(",", ":"))
    # append-only with O_APPEND atomic on POSIX
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(line + "\n")
        f.flush()
        os.fsync(f.fileno())


def tail(log_path: Path, n: int) -> list[dict]:
    if not log_path.is_file():
        return []
    lines = log_path.read_text(encoding="utf-8").splitlines()
    out = []
    for line in lines[-n:]:
        try:
            out.append(json.loads(line))
        except json.JSONDecodeError:
            out.append({"_parse_error": line[:200]})
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description="Skill Event Logger (R-NOV-05)")
    parser.add_argument("--event", help="event type")
    parser.add_argument("--skill-id", help="skill name")
    parser.add_argument("--alias-resolution", help="resolver result")
    parser.add_argument("--manifest-state", help="R-25 audit state")
    parser.add_argument("--note", help="optional free-form note")
    parser.add_argument("--log-path", default=str(DEFAULT_LOG), help="log file path")
    parser.add_argument("--json", action="store_true", help="JSON output")
    parser.add_argument("--tail", type=int, help="show last N events instead of write")
    args = parser.parse_args()

    log_path = Path(args.log_path).expanduser()

    # tail mode
    if args.tail is not None:
        events = tail(log_path, args.tail)
        if args.json:
            print(json.dumps(events, indent=2, ensure_ascii=False))
        else:
            print(f"=== last {len(events)} events from {log_path} ===")
            for e in events:
                ts = e.get("timestamp", "?")
                ev = e.get("event", "?")
                sid = e.get("skill_id", "?")
                ar = e.get("alias_resolution", "?")
                ms = e.get("manifest_state", "?")
                print(f"  {ts} {ev} skill={sid!r} alias={ar!r} manifest={ms}")
        return 0

    # write mode
    if not args.event:
        print("ERR: --event required (or --tail N)", file=sys.stderr)
        return 2
    if args.event not in VALID_EVENTS:
        print(f"WARN: unknown event {args.event!r}, valid: {sorted(VALID_EVENTS)}", file=sys.stderr)
        # still log — fail-open for telemetry
    if args.manifest_state and args.manifest_state not in VALID_MANIFEST_STATES:
        print(f"WARN: unknown manifest_state {args.manifest_state!r}, valid: {sorted(VALID_MANIFEST_STATES)}", file=sys.stderr)

    event = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "event": args.event,
        "skill_id": args.skill_id or "",
        "alias_resolution": args.alias_resolution or "",
        "manifest_state": args.manifest_state or "NOT_CHECKED",
    }
    if args.note:
        event["note"] = args.note

    append_event(log_path, event)

    if args.json:
        print(json.dumps({"verdict": "LOGGED", "log_path": str(log_path), "event": event}, indent=2, ensure_ascii=False))
    else:
        print(f"✓ logged to {log_path}: {event['event']} skill={event['skill_id']!r}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
