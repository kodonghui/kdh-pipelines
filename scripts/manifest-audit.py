#!/usr/bin/env python3
"""
Manifest Auditor — board 0425-skill-ecosystem-improvement R-25

Purpose: pipeline entrypoint 도달 시 frozen publish manifest sha 무결성 +
         skill-alias-map.yaml content sha + schema version + previous sha
         검증. 위반 = UNAUDITED 마킹 → downstream gate block (publish/
         deploy/sign-off, NOT warn-only).

Behavior (R-25):
  - async-friendly: 전체 audit 가 늦으면 UNAUDITED 마킹 후 downstream block
  - smoke harness (R-23) 통합 hook 우선 — 별 skill 신설 X
  - fail-closed: 임의 실패 = UNAUDITED, 절대 silent PASS X

Audit targets:
  1. Topic 5 publish/manifest.json     sha 9417e9efa60ba76512...
  2. Topic 5 SKILL_CONTRACT_MATRIX.yaml sha 1b0678f7591998666422...
  3. Topic 5 POST_SEAL_CORRECTION_PACK  sha 15cb6142c71ecdcd6e0c...
  4. Topic 3 publish/manifest.json     sha 5bd487ef81464675d081...
  5. skill-alias-map.yaml              sha matches sidecar .sha256
  6. schema_version                    valid (1.0.0 family)
  7. prev_revision                     valid (null for v1, or sha for v2+)

Usage:
  python3 manifest-audit.py                  # 전체 audit
  python3 manifest-audit.py --json           # machine-readable
  python3 manifest-audit.py --hook           # hook mode (silent on PASS, exit 1 on FAIL)

Exit codes:
  0  = AUDITED + PASS
  1  = AUDITED + FAIL (1+ sha mismatch / schema invalid)
  2  = UNAUDITED (input absent, network/IO error, async timeout)
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from pathlib import Path
from typing import Optional

try:
    import yaml  # type: ignore
except ImportError:
    yaml = None


# ─── Frozen sha registry (R-25 source of truth) ───────────────────────
# 본 dict 변경 = revision 변경 + alias map prev_revision 갱신 동반.

FROZEN_MANIFESTS = {
    "topic5_publish_manifest": {
        "path": "_bmad-output/boards/0425-topic5-final-trio-harness/publish/manifest.json",
        "sha256": "9417e9efa60ba7651282b2798acc819fb42822c8c757b2fd8223acd192d8a0e6",
        "label": "Topic 5 Final Trio Harness publish manifest",
    },
    "topic3_publish_manifest": {
        "path": "_bmad-output/boards/0424-topic3-trio-harness-workflow/publish/manifest.json",
        "sha256": "5bd487ef81464675d081aa522966f31a713ba5accba851cc56a7d8d3fa5b891f",
        "label": "Topic 3 Trio Harness Workflow publish manifest",
    },
}
# 2 건만 frozen target. SKILL_CONTRACT_MATRIX + POST_SEAL_CORRECTION 두 항목은
# Topic 5 publish/manifest.json.canonical_files 에 등록 안 됨 = Topic 5 봉인의
# 일부 X. skill-eco 보드 (0425-skill-ecosystem-improvement) 의 작성 시점에
# correction-manifest-pointer.json + decision.yaml 에 잘못 인용됨.
# alias map revision 2 (sha 정정) 와 동일 revision 에서 본 dict 도 정정.

VALID_SCHEMA_VERSIONS = {"1.0.0"}  # 1.x family — backward compat 유지
VALID_REVISIONS = {1, 2}  # v1 (initial) + v2 (frozen target 정정)


class AuditState:
    AUDITED_PASS = "AUDITED_PASS"
    AUDITED_FAIL = "AUDITED_FAIL"
    UNAUDITED = "UNAUDITED"


def _sha256_file(path: Path) -> Optional[str]:
    try:
        return hashlib.sha256(path.read_bytes()).hexdigest()
    except (FileNotFoundError, PermissionError, OSError) as e:
        return None


def _parse_yaml(text: str):
    if yaml is not None:
        try:
            return yaml.safe_load(text)
        except Exception:
            return None
    # minimal stdlib fallback — only fields we care about
    result = {}
    for line in text.splitlines():
        if not line or line.startswith("#"):
            continue
        m = re.match(r'^(\S+):\s*(.*)$', line)
        if m:
            key = m.group(1).strip()
            val = m.group(2).strip().strip('"').strip("'")
            if val.lower() == "null":
                val = None
            elif val.isdigit():
                val = int(val)
            result[key] = val
    return result


def audit_frozen_manifests(conductor_root: Path) -> list[dict]:
    """Topic 5/3 frozen sha 검증. 부재 = UNAUDITED (not FAIL)."""
    findings = []
    for key, spec in FROZEN_MANIFESTS.items():
        path = conductor_root / spec["path"]
        if not path.is_file():
            findings.append({
                "target": key,
                "label": spec["label"],
                "state": AuditState.UNAUDITED,
                "detail": f"file absent: {path}",
                "expected": spec["sha256"][:16] + "...",
            })
            continue
        actual = _sha256_file(path)
        if actual is None:
            findings.append({
                "target": key,
                "label": spec["label"],
                "state": AuditState.UNAUDITED,
                "detail": "I/O error reading file",
                "expected": spec["sha256"][:16] + "...",
            })
            continue
        match = (actual == spec["sha256"])
        findings.append({
            "target": key,
            "label": spec["label"],
            "state": AuditState.AUDITED_PASS if match else AuditState.AUDITED_FAIL,
            "detail": "sha match" if match else "SHA MISMATCH (frozen manifest tampered)",
            "expected": spec["sha256"][:16] + "...",
            "actual": actual[:16] + "...",
        })
    return findings


def audit_alias_map(alias_map_path: Path) -> list[dict]:
    """skill-alias-map.yaml content sha + schema version + prev_revision."""
    findings = []
    if not alias_map_path.is_file():
        return [{
            "target": "alias_map",
            "label": "skill-alias-map.yaml",
            "state": AuditState.UNAUDITED,
            "detail": f"alias map absent: {alias_map_path}",
        }]
    sidecar = alias_map_path.with_suffix(alias_map_path.suffix + ".sha256")
    if not sidecar.is_file():
        findings.append({
            "target": "alias_map.sidecar",
            "label": "skill-alias-map.yaml.sha256",
            "state": AuditState.UNAUDITED,
            "detail": "sidecar absent — cannot verify content sha",
        })
        return findings
    expected = sidecar.read_text(encoding="utf-8").strip().split()[0]
    actual = _sha256_file(alias_map_path)
    if actual is None:
        findings.append({
            "target": "alias_map.content_sha",
            "label": "alias map content sha",
            "state": AuditState.UNAUDITED,
            "detail": "I/O error",
        })
        return findings
    match = (actual == expected)
    findings.append({
        "target": "alias_map.content_sha",
        "label": "alias map content sha vs sidecar",
        "state": AuditState.AUDITED_PASS if match else AuditState.AUDITED_FAIL,
        "detail": "sha match" if match else "alias map tampered (sidecar mismatch)",
        "expected": expected[:16] + "...",
        "actual": actual[:16] + "...",
    })
    if not match:
        return findings  # 다음 단계 의미 없음

    # parse + schema version + revision
    parsed = _parse_yaml(alias_map_path.read_text(encoding="utf-8"))
    if not isinstance(parsed, dict):
        findings.append({
            "target": "alias_map.parse",
            "label": "alias map parse",
            "state": AuditState.UNAUDITED,
            "detail": "parse failure",
        })
        return findings

    sv = parsed.get("schema_version")
    findings.append({
        "target": "alias_map.schema_version",
        "label": f"schema_version={sv!r}",
        "state": AuditState.AUDITED_PASS if sv in VALID_SCHEMA_VERSIONS else AuditState.AUDITED_FAIL,
        "detail": f"valid set={sorted(VALID_SCHEMA_VERSIONS)}",
    })

    rev = parsed.get("revision")
    findings.append({
        "target": "alias_map.revision",
        "label": f"revision={rev!r}",
        "state": AuditState.AUDITED_PASS if rev in VALID_REVISIONS else AuditState.AUDITED_FAIL,
        "detail": f"valid set={sorted(VALID_REVISIONS)}",
    })

    prev = parsed.get("prev_revision")
    # revision 1 → prev_revision must be null. revision 2+ → prev_revision must be valid sha (64 hex).
    if rev == 1:
        prev_ok = (prev is None)
    elif isinstance(rev, int) and rev >= 2 and isinstance(prev, str) and len(prev) == 64 and all(c in "0123456789abcdef" for c in prev.lower()):
        prev_ok = True
    else:
        prev_ok = False
    findings.append({
        "target": "alias_map.prev_revision",
        "label": f"prev_revision={prev!r}",
        "state": AuditState.AUDITED_PASS if prev_ok else AuditState.AUDITED_FAIL,
        "detail": "v1 → null required; v2+ → 64-hex sha256 required",
    })

    return findings


def overall_state(findings: list[dict]) -> str:
    if not findings:
        return AuditState.UNAUDITED
    if any(f["state"] == AuditState.UNAUDITED for f in findings):
        return AuditState.UNAUDITED
    if any(f["state"] == AuditState.AUDITED_FAIL for f in findings):
        return AuditState.AUDITED_FAIL
    return AuditState.AUDITED_PASS


def main() -> int:
    parser = argparse.ArgumentParser(description="Manifest Auditor (R-25)")
    parser.add_argument(
        "--conductor-root",
        default=str(Path.home() / "kdh-conductor"),
        help="kdh-conductor repo root (default: ~/kdh-conductor)",
    )
    parser.add_argument(
        "--alias-map",
        default=None,
        help="skill-alias-map.yaml path (default: ~/.claude/skill-alias-map.yaml)",
    )
    parser.add_argument("--json", action="store_true", help="JSON output")
    parser.add_argument(
        "--hook",
        action="store_true",
        help="Hook mode: silent on PASS, exit non-zero on FAIL/UNAUDITED",
    )
    args = parser.parse_args()

    conductor_root = Path(args.conductor_root)
    alias_map_path = Path(args.alias_map) if args.alias_map else (Path.home() / ".claude" / "skill-alias-map.yaml")

    findings = []
    findings.extend(audit_frozen_manifests(conductor_root))
    findings.extend(audit_alias_map(alias_map_path))
    state = overall_state(findings)

    output = {
        "verdict": state,
        "findings": findings,
        "downstream_gate": "BLOCK" if state != AuditState.AUDITED_PASS else "OPEN",
        "frozen_manifest_count": len(FROZEN_MANIFESTS),
        "audit_count": len(findings),
    }

    if args.hook and state == AuditState.AUDITED_PASS:
        return 0  # silent

    if args.json:
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        print(f"=== Manifest Audit — {state} ===")
        print(f"downstream gate: {output['downstream_gate']}")
        print(f"findings: {len(findings)}")
        print()
        for f in findings:
            mark = {"AUDITED_PASS": "✓", "AUDITED_FAIL": "✗", "UNAUDITED": "?"}.get(f["state"], "?")
            print(f"  {mark} [{f['state']}] {f['target']}: {f['label']}")
            if f.get("detail"):
                print(f"      detail: {f['detail']}")
            if "expected" in f and "actual" in f:
                print(f"      expected={f['expected']}  actual={f['actual']}")

    if state == AuditState.AUDITED_PASS:
        return 0
    if state == AuditState.AUDITED_FAIL:
        return 1
    return 2


if __name__ == "__main__":
    sys.exit(main())
