#!/usr/bin/env python3
"""
Diagram / Spec Validator (deterministic) — board 0425-skill-ecosystem-improvement R-15

Purpose: kdh-report 가 본문에 Mermaid diagram 또는 OpenAPI spec 을 포함할 때,
         deterministic syntax check 강제. invalid → UNKNOWN + ORACLE WARNING
         (silent correction 금지 — 본 보드 R-24 reporting invariants).

Bootstrap: stdlib only — heavy validator (mmdc / openapi-validator) 의존 회피.
           최소 syntax 점검 = unknown 형식 = "validator unable to confirm syntax"
           명시 (false positive 보다 false unknown 우선).

Checks:
  Mermaid:
    - 첫 non-blank 줄이 알려진 diagram type 으로 시작 (flowchart / sequenceDiagram /
      gantt / pie / graph / classDiagram / stateDiagram / erDiagram / journey /
      mindmap / timeline / quadrantChart / xychart 등)
    - 균형잡힌 brace { } / paren ( ) 카운트
    - 빈 입력 = INVALID

  OpenAPI:
    - YAML/JSON parse 가능
    - root 에 'openapi: 3.x.x' (3.x) 또는 'swagger: 2.0' (2.x) key 존재
    - 'info' + 'paths' key 존재 (3.x)
    - 빈 입력 = INVALID

Result states:
  VALID    = 모든 check 통과
  INVALID  = 1+ check 실패
  UNKNOWN  = validator 능력 밖 (알려지지 않은 diagram type 등) — silent PASS X

Exit codes:
  0 = VALID
  1 = INVALID
  2 = UNKNOWN

Usage:
  python3 diagram-validate.py --kind mermaid <input_file>
  python3 diagram-validate.py --kind openapi <input_file>
  python3 diagram-validate.py --kind mermaid --stdin
  echo '...' | python3 diagram-validate.py --kind mermaid --stdin --json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Optional

try:
    import yaml  # type: ignore
except ImportError:
    yaml = None


# ─── Mermaid validators ───────────────────────────────────────────────

KNOWN_MERMAID_TYPES = {
    "flowchart", "graph", "sequenceDiagram", "classDiagram",
    "stateDiagram", "stateDiagram-v2", "erDiagram", "gantt",
    "pie", "journey", "gitGraph", "mindmap", "timeline",
    "quadrantChart", "xychart-beta", "sankey-beta", "block-beta",
    "C4Context", "requirementDiagram",
}


def validate_mermaid(text: str) -> tuple[str, list[str]]:
    """Returns (state, reasons). state ∈ {VALID, INVALID, UNKNOWN}."""
    reasons: list[str] = []
    if not text or not text.strip():
        return "INVALID", ["empty input"]

    # 첫 non-blank, non-comment 줄
    first = None
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("%%"):  # mermaid 주석
            continue
        first = s
        break
    if first is None:
        return "INVALID", ["no non-comment line"]

    # 첫 단어 (e.g. 'flowchart TD' → 'flowchart')
    first_word = first.split()[0] if first else ""
    # gitGraph 같은 다중 단어 type 도 first_word 로 판정
    matched_type = None
    for t in KNOWN_MERMAID_TYPES:
        if first.startswith(t):
            matched_type = t
            break
    if matched_type is None:
        # type 불명 — UNKNOWN (silent VALID 금지)
        return "UNKNOWN", [
            f"unrecognized diagram type: {first_word!r}",
            "validator scope = " + ", ".join(sorted(KNOWN_MERMAID_TYPES)),
        ]

    # 균형 카운트 — node 정의 등에서 (), [], {} 사용
    paren = brace = bracket = 0
    for ch in text:
        if ch == "(":
            paren += 1
        elif ch == ")":
            paren -= 1
        elif ch == "{":
            brace += 1
        elif ch == "}":
            brace -= 1
        elif ch == "[":
            bracket += 1
        elif ch == "]":
            bracket -= 1
        if paren < 0 or brace < 0 or bracket < 0:
            return "INVALID", [f"unbalanced delimiter mid-stream (paren={paren} brace={brace} bracket={bracket})"]
    if paren != 0:
        reasons.append(f"unbalanced parens (residual={paren})")
    if brace != 0:
        reasons.append(f"unbalanced braces (residual={brace})")
    if bracket != 0:
        reasons.append(f"unbalanced brackets (residual={bracket})")
    if reasons:
        return "INVALID", reasons

    return "VALID", [f"diagram_type={matched_type}", "delimiters balanced"]


# ─── OpenAPI validators ───────────────────────────────────────────────

_VERSION_RE = re.compile(r'^\s*(openapi|swagger)\s*:\s*[\'"]?([\d\.]+)[\'"]?', re.MULTILINE)
_INFO_KEY_RE = re.compile(r'^\s*info\s*:', re.MULTILINE)
_PATHS_KEY_RE = re.compile(r'^\s*paths\s*:', re.MULTILINE)


def validate_openapi(text: str) -> tuple[str, list[str]]:
    if not text or not text.strip():
        return "INVALID", ["empty input"]

    reasons: list[str] = []

    # JSON 시도 후 YAML 시도
    parsed = None
    parse_method = None
    if text.lstrip().startswith("{"):
        try:
            parsed = json.loads(text)
            parse_method = "json"
        except Exception as e:
            return "INVALID", [f"JSON parse error: {e}"]
    elif yaml is not None:
        try:
            parsed = yaml.safe_load(text)
            parse_method = "yaml"
        except Exception as e:
            return "INVALID", [f"YAML parse error: {e}"]
    else:
        # PyYAML 부재 — minimum regex check
        m = _VERSION_RE.search(text)
        if not m:
            return "UNKNOWN", ["PyYAML absent + no openapi/swagger version line found"]
        kind, ver = m.group(1), m.group(2)
        info_ok = bool(_INFO_KEY_RE.search(text))
        paths_ok = bool(_PATHS_KEY_RE.search(text))
        if not info_ok:
            reasons.append("missing 'info:' key")
        if not paths_ok:
            reasons.append("missing 'paths:' key")
        if reasons:
            return "INVALID", reasons
        return "VALID", [f"{kind}={ver}", "regex-mode (PyYAML absent)"]

    # parsed available
    if not isinstance(parsed, dict):
        return "INVALID", [f"root not a mapping (got {type(parsed).__name__})"]
    version = parsed.get("openapi") or parsed.get("swagger")
    if not version:
        return "INVALID", ["no 'openapi' or 'swagger' version key"]
    info = parsed.get("info")
    paths = parsed.get("paths")
    if not info:
        reasons.append("missing 'info' object")
    if paths is None:
        reasons.append("missing 'paths' object (paths={} also valid)")
    if reasons:
        return "INVALID", reasons
    return "VALID", [
        f"version={version}",
        f"parse_method={parse_method}",
        f"info.title={(info or {}).get('title', '?')!r}",
    ]


# ─── CLI ──────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="Diagram/Spec validator (R-15 deterministic)")
    parser.add_argument("--kind", required=True, choices=["mermaid", "openapi"])
    parser.add_argument("input", nargs="?", help="Input file path (omit if --stdin)")
    parser.add_argument("--stdin", action="store_true", help="Read input from stdin")
    parser.add_argument("--json", action="store_true", help="JSON output")
    args = parser.parse_args()

    if args.stdin:
        text = sys.stdin.read()
        source = "<stdin>"
    elif args.input:
        path = Path(args.input)
        if not path.is_file():
            print(f"ERR: input not found: {path}", file=sys.stderr)
            return 2
        text = path.read_text(encoding="utf-8", errors="replace")
        source = str(path)
    else:
        print("ERR: provide input file or --stdin", file=sys.stderr)
        return 2

    if args.kind == "mermaid":
        state, reasons = validate_mermaid(text)
    else:
        state, reasons = validate_openapi(text)

    output = {
        "kind": args.kind,
        "source": source,
        "state": state,
        "reasons": reasons,
        "report_directive": (
            "embed as-is" if state == "VALID"
            else "OMIT + UNKNOWN block + ORACLE WARNING" if state == "INVALID"
            else "OMIT + UNKNOWN block + ORACLE WARNING (validator scope limit)"
        ),
    }

    if args.json:
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        mark = {"VALID": "✓", "INVALID": "✗", "UNKNOWN": "?"}.get(state, "?")
        print(f"{mark} [{state}] {args.kind} {source}")
        for r in reasons:
            print(f"  - {r}")
        print(f"  → directive: {output['report_directive']}")

    if state == "VALID":
        return 0
    if state == "INVALID":
        return 1
    return 2


if __name__ == "__main__":
    sys.exit(main())
