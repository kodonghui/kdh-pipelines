#!/usr/bin/env python3
"""Small deterministic helpers for kdh board automation scripts."""

from __future__ import annotations

import hashlib
import json
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def atomic_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent))
    tmp = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(text)
            f.flush()
            os.fsync(f.fileno())
        tmp.replace(path)
    finally:
        if tmp.exists():
            tmp.unlink()


def atomic_write_json(path: Path, data: Any) -> None:
    atomic_write_text(path, json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + "\n")


def append_jsonl(path: Path, row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return data


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if not path.exists():
        return rows
    for idx, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if not stripped:
            continue
        data = json.loads(stripped)
        if not isinstance(data, dict):
            raise ValueError(f"{path}:{idx} must contain a JSON object")
        rows.append(data)
    return rows


def resolve_board(root: Path, board_id: str) -> Path:
    candidate = Path(board_id).expanduser()
    if candidate.is_absolute() and candidate.exists():
        return candidate.resolve()
    if (root / candidate).exists():
        return (root / candidate).resolve()

    search_roots = [
        root / "_bmad-output" / "boards",
        root / "_bmad-output" / "kdh-plans",
        Path.home() / "kdh-conductor" / "_bmad-output" / "boards",
        Path.home() / "kdh-conductor" / "_bmad-output" / "kdh-plans",
    ]
    matches: list[Path] = []
    for base in search_roots:
        if not base.exists():
            continue
        direct = base / board_id
        if direct.exists():
            matches.append(direct.resolve())
        matches.extend(p.resolve() for p in base.glob(f"*{board_id}*") if p.is_dir())

    unique = sorted({p for p in matches})
    if len(unique) == 1:
        return unique[0]
    if len(unique) > 1:
        rendered = "\n".join(str(p) for p in unique)
        raise SystemExit(f"Ambiguous board id {board_id!r}; pass a full path:\n{rendered}")
    raise SystemExit(f"Board not found: {board_id}")


def relative_to_board(board: Path, path: Path) -> str:
    return path.resolve().relative_to(board.resolve()).as_posix()


def canonical_files(board: Path) -> list[Path]:
    patterns = [
        "consensus/*.jsonl",
        "events/issues.jsonl",
        "events/board-events.jsonl",
        "ledger/*.jsonl",
        "rounds/**/*.md",
        "rounds/**/*.jsonl",
        "sources/**/*",
        "reports/*.md",
        "RENDERED.md",
    ]
    files: list[Path] = []
    for pattern in patterns:
        files.extend(p for p in board.glob(pattern) if p.is_file())
    excluded_parts = {"publish", ".board-archive"}
    return sorted({p for p in files if not (set(p.relative_to(board).parts) & excluded_parts)})


def manifest_for(board: Path) -> dict[str, str]:
    return {relative_to_board(board, p): sha256_file(p) for p in canonical_files(board)}


def latest_report(board: Path) -> Path | None:
    reports = sorted((board / "reports").glob("*.md"))
    if reports:
        return reports[-1]
    rendered = board / "RENDERED.md"
    return rendered if rendered.exists() else None


def load_manifest(board: Path) -> dict[str, Any]:
    manifest_path = board / "publish" / "manifest.json"
    if not manifest_path.exists():
        raise SystemExit(f"Missing manifest: {manifest_path}")
    return read_json(manifest_path)


def verify_manifest_files(board: Path) -> tuple[bool, list[str], dict[str, Any]]:
    manifest = load_manifest(board)
    canonical_inputs = manifest.get("canonical_inputs")
    if not isinstance(canonical_inputs, dict):
        return False, ["manifest canonical_inputs must be an object"], manifest

    failures: list[str] = []
    for rel_path, expected_sha in sorted(canonical_inputs.items()):
        if not isinstance(rel_path, str) or not isinstance(expected_sha, str):
            failures.append(f"invalid manifest entry: {rel_path!r}")
            continue
        path = board / rel_path
        if not path.exists():
            failures.append(f"missing canonical file: {rel_path}")
            continue
        actual_sha = sha256_file(path)
        if actual_sha != expected_sha:
            failures.append(f"sha mismatch: {rel_path}")

    current_paths = set(manifest_for(board))
    manifest_paths = {str(p) for p in canonical_inputs}
    missing_from_manifest = sorted(current_paths - manifest_paths)
    if missing_from_manifest:
        failures.append("canonical files missing from manifest: " + ", ".join(missing_from_manifest))

    return not failures, failures, manifest
