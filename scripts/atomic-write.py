#!/usr/bin/env python3
"""
Atomic Write Helper — board 0425-skill-ecosystem-improvement R-32

Purpose: per-story lock + temp-then-rename atomic write pattern. 다중 actor
         동시 쓰기 차단 + partial write 차단 + crash recovery.

Pattern:
  1. lock 획득 (flock + TTL stale detection)
  2. content 를 same-dir temp file 에 쓰기
  3. temp → target rename (POSIX rename(2) 의 atomic guarantee)
  4. lock 해제

Usage:
  # 인자 mode
  python3 atomic-write.py --target <path> --lock-key <key> --content-from <staging-file>

  # stdin mode
  cat content.md | python3 atomic-write.py --target <path> --lock-key <key> --stdin

  # JSON output
  python3 atomic-write.py --target ... --lock-key ... --content-from ... --json

Lock file location: ~/.cache/kdh-atomic-write/<sanitized-lock-key>.lock
Lock TTL: 600 seconds (10 min). Stale lock auto-broken with warning.

Exit codes:
  0 = success (atomic write completed)
  1 = lock contention (TTL not yet expired, another process active)
  2 = input error (target missing, content-from absent, etc.)
  3 = I/O error (rename failed, permission, etc.)
"""

from __future__ import annotations

import argparse
import errno
import fcntl
import json
import os
import re
import sys
import time
from pathlib import Path

LOCK_DIR = Path.home() / ".cache" / "kdh-atomic-write"
DEFAULT_TTL_SECONDS = 600  # 10 min


def _sanitize_key(key: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "_", key)[:120]


def _ensure_lock_dir() -> None:
    LOCK_DIR.mkdir(parents=True, exist_ok=True)


def _acquire_lock(lock_path: Path, ttl_seconds: int) -> tuple[bool, str, int]:
    """Returns (acquired, reason, fd). fd = -1 on failure."""
    _ensure_lock_dir()

    # stale detection: lock file mtime older than TTL → break
    if lock_path.exists():
        try:
            age = time.time() - lock_path.stat().st_mtime
            if age > ttl_seconds:
                # stale — break (warning included in reason)
                lock_path.unlink()
        except FileNotFoundError:
            pass

    try:
        fd = os.open(str(lock_path), os.O_CREAT | os.O_RDWR, 0o644)
    except OSError as e:
        return False, f"lock open failed: {e}", -1

    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError as e:
        os.close(fd)
        if e.errno in (errno.EWOULDBLOCK, errno.EAGAIN):
            # 이미 다른 프로세스가 잠금 보유
            return False, "lock contention (other process holds lock)", -1
        return False, f"flock error: {e}", -1

    # 잠금 정보 기록 (디버깅용)
    try:
        os.write(fd, f"pid={os.getpid()} ts={int(time.time())}\n".encode())
        os.fsync(fd)
    except OSError:
        pass

    return True, "lock acquired", fd


def _release_lock(fd: int, lock_path: Path) -> None:
    try:
        fcntl.flock(fd, fcntl.LOCK_UN)
    except OSError:
        pass
    try:
        os.close(fd)
    except OSError:
        pass
    try:
        lock_path.unlink()
    except FileNotFoundError:
        pass


def atomic_write(target: Path, content: bytes) -> tuple[bool, str]:
    """temp-then-rename within same directory. Returns (ok, detail)."""
    target_dir = target.parent
    if not target_dir.is_dir():
        try:
            target_dir.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            return False, f"target dir create failed: {e}"

    # same-dir temp 보장 — POSIX rename atomic guarantee 위함
    temp_name = f".{target.name}.tmp.{os.getpid()}.{int(time.time() * 1000)}"
    temp_path = target_dir / temp_name

    try:
        fd = os.open(str(temp_path), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
        try:
            os.write(fd, content)
            os.fsync(fd)
        finally:
            os.close(fd)
    except OSError as e:
        if temp_path.exists():
            try:
                temp_path.unlink()
            except OSError:
                pass
        return False, f"temp write failed: {e}"

    try:
        os.rename(str(temp_path), str(target))
    except OSError as e:
        try:
            temp_path.unlink()
        except OSError:
            pass
        return False, f"rename failed: {e}"

    # parent dir fsync (POSIX durability)
    try:
        dir_fd = os.open(str(target_dir), os.O_RDONLY)
        try:
            os.fsync(dir_fd)
        finally:
            os.close(dir_fd)
    except OSError:
        pass

    return True, f"wrote {target} ({len(content)} bytes) atomically"


def main() -> int:
    parser = argparse.ArgumentParser(description="Atomic write with per-key lock (R-32)")
    parser.add_argument("--target", required=True, help="Target file path")
    parser.add_argument("--lock-key", required=True, help="Lock key (sanitized to filename)")
    parser.add_argument("--content-from", help="Read content from this file")
    parser.add_argument("--stdin", action="store_true", help="Read content from stdin")
    parser.add_argument("--ttl", type=int, default=DEFAULT_TTL_SECONDS,
                        help=f"Lock TTL seconds (default {DEFAULT_TTL_SECONDS})")
    parser.add_argument("--json", action="store_true", help="JSON output")
    args = parser.parse_args()

    target = Path(args.target).expanduser().resolve()

    # content 수집
    if args.stdin:
        content = sys.stdin.buffer.read()
        source_label = "<stdin>"
    elif args.content_from:
        src = Path(args.content_from).expanduser()
        if not src.is_file():
            print(f"ERR: content-from absent: {src}", file=sys.stderr)
            return 2
        content = src.read_bytes()
        source_label = str(src)
    else:
        print("ERR: --content-from <file> 또는 --stdin 필요", file=sys.stderr)
        return 2

    lock_key_safe = _sanitize_key(args.lock_key)
    lock_path = LOCK_DIR / f"{lock_key_safe}.lock"

    acquired, reason, fd = _acquire_lock(lock_path, args.ttl)
    if not acquired:
        out = {
            "verdict": "LOCK_CONTENTION",
            "lock_key": args.lock_key,
            "lock_path": str(lock_path),
            "reason": reason,
        }
        if args.json:
            print(json.dumps(out, indent=2, ensure_ascii=False))
        else:
            print(f"✗ LOCK_CONTENTION: {reason}", file=sys.stderr)
        return 1

    try:
        ok, detail = atomic_write(target, content)
    finally:
        _release_lock(fd, lock_path)

    out = {
        "verdict": "WRITE_OK" if ok else "WRITE_FAIL",
        "target": str(target),
        "source": source_label,
        "size_bytes": len(content),
        "lock_key": args.lock_key,
        "detail": detail,
    }

    if args.json:
        print(json.dumps(out, indent=2, ensure_ascii=False))
    else:
        mark = "✓" if ok else "✗"
        print(f"{mark} {out['verdict']}: {detail}")

    return 0 if ok else 3


if __name__ == "__main__":
    sys.exit(main())
