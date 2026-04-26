#!/usr/bin/env python3
"""Validate the minimum Round 0 ACK gate for a KDH board workspace."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from board_common import atomic_write_json, resolve_board, sha256_file, utc_now


def _nonempty_file(path: Path) -> bool:
    return path.exists() and path.is_file() and path.read_text(encoding="utf-8").strip() != ""


def _has_source(board: Path) -> bool:
    source_dirs = [
        board / "sources",
        board / "rounds" / "R0" / "corpus-supplement",
    ]
    for source_dir in source_dirs:
        if source_dir.exists() and any(p.is_file() and p.stat().st_size > 0 for p in source_dir.rglob("*")):
            return True
    return False


def validate_round0(board: Path) -> tuple[bool, list[str], dict[str, str]]:
    required_content_files = [
        board / "rounds" / "R0" / "research-summary.md",
        board / "rounds" / "R0" / "EARS-skeleton.md",
    ]
    required_flag_files = [
        board / "inbox" / "round-0" / "A-DONE-R0.flag",
        board / "inbox" / "round-0" / "B-ACK-R0.flag",
        board / "inbox" / "round-0" / "C-ACK-R0.flag",
    ]
    failures: list[str] = []
    artifacts: dict[str, str] = {}

    for path in required_content_files:
        rel = path.relative_to(board).as_posix()
        if not _nonempty_file(path):
            failures.append(f"missing or empty required artifact: {rel}")
            continue
        artifacts[rel] = sha256_file(path)

    for path in required_flag_files:
        rel = path.relative_to(board).as_posix()
        if not path.exists() or not path.is_file():
            failures.append(f"missing required flag: {rel}")
            continue
        artifacts[rel] = sha256_file(path)

    invalid_flag = board / "inbox" / "round-0" / "R0-INVALID.flag"
    if invalid_flag.exists():
        failures.append("R0-INVALID.flag exists")

    if not _has_source(board):
        failures.append("no source corpus found in sources/ or rounds/R0/corpus-supplement/")

    ears = board / "rounds" / "R0" / "EARS-skeleton.md"
    if ears.exists():
        text = ears.read_text(encoding="utf-8")
        for marker in ("A", "B", "C", "Conclusion"):
            if marker not in text:
                failures.append(f"EARS skeleton missing marker: {marker}")

    return not failures, failures, artifacts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("board_id", help="Board path or id under _bmad-output/boards")
    parser.add_argument("--root", default=".", help="Repository root used for board lookup")
    parser.add_argument("--no-write", action="store_true", help="Validate only; do not write gate artifact")
    args = parser.parse_args()

    root = Path(args.root).expanduser().resolve()
    board = resolve_board(root, args.board_id)
    ok, failures, artifacts = validate_round0(board)

    gate = {
        "phase": 0,
        "phase_name": "Round 0 ACK gate",
        "completed_at_utc": utc_now(),
        "plan_id": board.name,
        "pass_artifacts_sha256": artifacts,
        "validator_run_id": f"round0-validator:{utc_now()}",
        "validator_result": {
            "rule_id": "BRD-025/BRD-031-minimum",
            "status": "pass" if ok else "fail",
            "detail": "Round 0 artifacts and A/B/C ACK flags verified" if ok else "; ".join(failures),
        },
        "ceo_approvals": [],
        "next_phase": {
            "phase": 1,
            "phase_name": "R1 deliberation",
            "blocker": None if ok else "Round 0 gate failed",
        },
        "notes": [
            "Minimum executable gate. Full BRD-031 five-section semantic validation remains manual.",
        ],
    }

    if ok and not args.no_write:
        atomic_write_json(board / "gates" / "phase-r0-pass.json", gate)

    print(json.dumps(gate, ensure_ascii=False, indent=2, sort_keys=True))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
