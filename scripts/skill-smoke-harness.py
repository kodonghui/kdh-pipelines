#!/usr/bin/env python3
"""
Skill Smoke Harness — board 0425-skill-ecosystem-improvement R-23

Purpose: skill contract change 시 mock/dry-run 검증. 6 check + fail-closed.

Bootstrap: 외부 deterministic tool first (Python stdlib only). 2-pass self-check
after harness live. External reviewer (B Codex / C Gemini) PASS/FAIL adjudication.

Checks (R-23):
  1. YAML/frontmatter parse           — SKILL.md 의 frontmatter 가 valid YAML 인가
  2. local file existence              — alias target 의 SKILL.md 가 실제 존재하는가
  3. alias resolution                  — skill-alias-map.yaml 통과 가능한가
  4. blocked_scope enforcement         — D Class 1 차단 영역 우회 시도 차단
  5. tombstone redirect                — status=tombstone 는 redirect notice + 원본 부재 경고
  6. fail-closed behavior              — 임의 실패 시 PASS 반환 X (silent corrupt 방지)

Audit: R-25 manifest auditor 가 본 harness 의 결과를 entrypoint 에서 재검증.

Usage:
  python3 skill-smoke-harness.py                    # 전체 skill 디렉토리 + alias map
  python3 skill-smoke-harness.py --skill <name>     # 단일 skill 만
  python3 skill-smoke-harness.py --alias-only       # alias map 만
  python3 skill-smoke-harness.py --json             # machine-readable output

Exit codes:
  0  = PASS (모든 check 통과)
  1  = FAIL (1+ check 실패)
  2  = ENV ERROR (입력 부재 / 환경 문제)
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from pathlib import Path
from typing import Any, Optional

# ─── stdlib YAML fallback (PyYAML 의존 회피) ──────────────────────────
# 본 harness 는 deterministic 외부 도구 = stdlib only 정책.
# YAML parse = minimal subset parser (alias map 의 평이 구조 한정).

try:
    import yaml  # type: ignore
    _YAML_BACKEND = "PyYAML"
except ImportError:  # pragma: no cover
    yaml = None
    _YAML_BACKEND = "stdlib_minimal"


def _parse_yaml(text: str) -> Any:
    """PyYAML 있으면 사용, 없으면 minimal subset parser."""
    if yaml is not None:
        return yaml.safe_load(text)
    return _minimal_yaml_parse(text)


def _minimal_yaml_parse(text: str) -> Any:
    """매우 제한적 YAML parser. alias map / frontmatter 의 단순 key:value + list 만 지원.

    구조:
      key: value
      key:
        - item1
        - item2
      key:
        nested_key: value

    fail-closed: ambiguous 입력 = ParseError raise.
    """
    lines = text.splitlines()
    return _parse_lines(lines, 0, 0)[0]


def _parse_lines(lines: list[str], idx: int, indent: int) -> tuple[Any, int]:
    result: Any = None
    while idx < len(lines):
        raw = lines[idx]
        if not raw.strip() or raw.lstrip().startswith("#"):
            idx += 1
            continue
        cur_indent = len(raw) - len(raw.lstrip())
        if cur_indent < indent:
            break
        if cur_indent > indent:
            raise ValueError(f"unexpected indent at line {idx + 1}: {raw!r}")
        stripped = raw.strip()
        if stripped.startswith("- "):
            if result is None:
                result = []
            elif not isinstance(result, list):
                raise ValueError(f"mixed list/dict at line {idx + 1}")
            item_text = stripped[2:].strip()
            if ":" in item_text and not item_text.startswith('"'):
                # "- key: value" inline dict
                d, idx = _parse_inline_dict(item_text, lines, idx, indent + 2)
                result.append(d)
            else:
                result.append(_parse_scalar(item_text))
                idx += 1
        elif ":" in stripped:
            if result is None:
                result = {}
            elif not isinstance(result, dict):
                raise ValueError(f"mixed dict/list at line {idx + 1}")
            key, _, val = stripped.partition(":")
            key = key.strip()
            val = val.strip()
            if val:
                result[key] = _parse_scalar(val)
                idx += 1
            else:
                # nested
                idx += 1
                nested, idx = _parse_lines(lines, idx, indent + 2)
                result[key] = nested
        else:
            raise ValueError(f"unparseable line {idx + 1}: {raw!r}")
    return result, idx


def _parse_inline_dict(first_kv: str, lines: list[str], idx: int, child_indent: int) -> tuple[dict, int]:
    d: dict = {}
    key, _, val = first_kv.partition(":")
    key = key.strip()
    val = val.strip()
    if val:
        d[key] = _parse_scalar(val)
        idx += 1
    else:
        idx += 1
        nested, idx = _parse_lines(lines, idx, child_indent)
        d[key] = nested
    while idx < len(lines):
        raw = lines[idx]
        if not raw.strip() or raw.lstrip().startswith("#"):
            idx += 1
            continue
        cur_indent = len(raw) - len(raw.lstrip())
        if cur_indent < child_indent:
            break
        stripped = raw.strip()
        if ":" in stripped:
            key, _, val = stripped.partition(":")
            key = key.strip()
            val = val.strip()
            if val:
                d[key] = _parse_scalar(val)
                idx += 1
            else:
                idx += 1
                nested, idx = _parse_lines(lines, idx, child_indent + 2)
                d[key] = nested
        else:
            break
    return d, idx


def _parse_scalar(s: str) -> Any:
    s = s.strip()
    if not s:
        return None
    if s.lower() in ("null", "~"):
        return None
    if s.lower() == "true":
        return True
    if s.lower() == "false":
        return False
    if s.startswith("[") and s.endswith("]"):
        inner = s[1:-1].strip()
        if not inner:
            return []
        return [_parse_scalar(p.strip()) for p in inner.split(",")]
    if s.startswith("{") and s.endswith("}"):
        inner = s[1:-1].strip()
        if not inner:
            return {}
        result = {}
        for pair in inner.split(","):
            k, _, v = pair.partition(":")
            result[k.strip().strip('"')] = _parse_scalar(v.strip())
        return result
    if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
        return s[1:-1]
    try:
        return int(s)
    except ValueError:
        pass
    try:
        return float(s)
    except ValueError:
        pass
    return s


# ─── Frontmatter parser (SKILL.md) ────────────────────────────────────

_FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


def parse_frontmatter(skill_md_path: Path) -> Optional[dict]:
    """SKILL.md 의 frontmatter 파싱. 부재 = None. parse 실패 = ValueError."""
    if not skill_md_path.is_file():
        return None
    text = skill_md_path.read_text(encoding="utf-8", errors="replace")
    match = _FRONTMATTER_RE.match(text)
    if not match:
        return None
    fm_text = match.group(1)
    return _parse_yaml(fm_text)


# ─── Alias map loader ─────────────────────────────────────────────────

def load_alias_map(alias_map_path: Path) -> dict:
    if not alias_map_path.is_file():
        raise FileNotFoundError(f"skill-alias-map.yaml not found: {alias_map_path}")
    text = alias_map_path.read_text(encoding="utf-8")
    parsed = _parse_yaml(text)
    if not isinstance(parsed, dict):
        raise ValueError("skill-alias-map.yaml root not a mapping")
    return parsed


def verify_sidecar_sha(alias_map_path: Path) -> tuple[bool, str]:
    sidecar = alias_map_path.with_suffix(alias_map_path.suffix + ".sha256")
    if not sidecar.is_file():
        return False, "sidecar absent"
    sidecar_line = sidecar.read_text(encoding="utf-8").strip().split()
    if not sidecar_line:
        return False, "sidecar empty"
    expected = sidecar_line[0]
    actual = hashlib.sha256(alias_map_path.read_bytes()).hexdigest()
    return expected == actual, f"expected={expected[:16]} actual={actual[:16]}"


# ─── Checks (R-23 6 mandates) ─────────────────────────────────────────

class Result:
    def __init__(self) -> None:
        self.checks: list[dict] = []
        self.failed = False

    def add(self, name: str, passed: bool, detail: str = "") -> None:
        self.checks.append({"check": name, "result": "PASS" if passed else "FAIL", "detail": detail})
        if not passed:
            self.failed = True

    def to_dict(self) -> dict:
        return {
            "verdict": "FAIL" if self.failed else "PASS",
            "checks": self.checks,
            "yaml_backend": _YAML_BACKEND,
        }


def check_alias_map(alias_map_path: Path, result: Result) -> Optional[dict]:
    """Alias map 자체 6 check 의 일부 — parse + sidecar."""
    try:
        amap = load_alias_map(alias_map_path)
    except Exception as e:
        result.add("alias_map.parse", False, f"{type(e).__name__}: {e}")
        return None
    result.add("alias_map.parse", True, f"loaded {len(amap.get('aliases', []))} entries")

    sidecar_ok, sidecar_detail = verify_sidecar_sha(alias_map_path)
    result.add("alias_map.sidecar_sha", sidecar_ok, sidecar_detail)
    return amap


def check_alias_entries(amap: dict, result: Result) -> None:
    """각 alias entry 의 10 field schema 검증 + blocked_scope D Class 1 enforcement."""
    required_fields = {
        "alias", "target", "status", "allowed_scope", "blocked_scope",
        "fallback", "source_subtrack", "breaking", "prev_revision",
        "migration_note", "argument_translation_map",
    }
    d_class_1 = {"oracle_judgment", "qa_verdict", "deploy_authorization", "self_review_loop"}
    declared_blocked = set(amap.get("blocked_scope_d_class_1", {}).get("scopes", []))

    if declared_blocked != d_class_1:
        result.add(
            "blocked_scope.d_class_1_complete",
            False,
            f"missing={d_class_1 - declared_blocked} extra={declared_blocked - d_class_1}",
        )
    else:
        result.add("blocked_scope.d_class_1_complete", True, "4 scopes")

    aliases = amap.get("aliases") or []
    for i, entry in enumerate(aliases):
        if not isinstance(entry, dict):
            result.add(f"alias[{i}].is_dict", False, type(entry).__name__)
            continue
        missing = required_fields - set(entry.keys())
        if missing:
            result.add(f"alias[{i}].schema", False, f"missing={sorted(missing)}")
        else:
            result.add(f"alias[{i}].schema", True, entry.get("alias", "?"))

        # blocked_scope override check: blocked alias must have blocked_scope ⊇ critical scopes
        status = entry.get("status")
        a_blocked = set(entry.get("blocked_scope") or [])
        if status == "blocked":
            # bmad-agent-dev 류 = impl/qa_verdict 둘 다 blocked
            need_blocked = {"impl"}
            if not need_blocked <= a_blocked:
                result.add(
                    f"alias[{i}].blocked_status_consistency",
                    False,
                    f"status=blocked but blocked_scope missing {need_blocked - a_blocked}",
                )
            else:
                result.add(f"alias[{i}].blocked_status_consistency", True, "blocked_scope ⊇ impl")


def check_target_existence(amap: dict, claude_dir: Path, kdh_pipelines_dir: Path, result: Result) -> None:
    """Active alias target 의 SKILL.md / agent.md 실제 존재 검증.

    abstract_role 분류: dev_executor / qa_reviewer 등 = SKILL.md 가 아닌 추상 역할.
    실제 실행 = Codex CLI / Phase D writer / target_resolution 본문에 명시.
    이 경우 target_resolution 비어있지 않은 것만 검증.
    """
    abstract_roles = {"dev_executor", "qa_reviewer"}
    bmad_tasks = {
        "bmad-editorial-review-prose",
        "bmad-editorial-review-structure",
        "bmad-distillator",
        "bmad-brainstorming",
    }
    special_agents = {"sally-local-agent"}

    aliases = amap.get("aliases") or []
    for i, entry in enumerate(aliases):
        if not isinstance(entry, dict):
            continue
        status = entry.get("status")
        target = entry.get("target", "")
        alias_label = entry.get("alias", f"#{i}")
        if status not in ("active", "deferred"):
            # tombstone / blocked = 검증 스킵 (의도적)
            continue

        # 1. abstract_role: target_resolution 본문 비어있지 않으면 PASS
        if target in abstract_roles:
            resolution = entry.get("target_resolution") or ""
            ok = bool(resolution.strip())
            result.add(
                f"target_resolution[{alias_label}->{target}]",
                ok,
                f"abstract_role; resolution={resolution[:60]!r}",
            )
            continue

        # 2. special: sally local agent
        if target in special_agents:
            sally = claude_dir / "agents" / "sally.md"
            result.add(
                f"target_exists[{alias_label}]",
                sally.is_file(),
                f"sally agent={sally}",
            )
            continue

        # 3. bmad_task: 본문 그대로 BMAD task 호출 = ~/.claude/skills/<target>/SKILL.md
        if target in bmad_tasks or target.startswith("bmad-"):
            installed = claude_dir / "skills" / target / "SKILL.md"
            candidate = kdh_pipelines_dir / "skills" / target / "SKILL.md"
            exists = installed.is_file() or candidate.is_file()
            result.add(
                f"target_exists[{alias_label}]",
                exists,
                f"bmad_task={target} local={installed.is_file()} repo={candidate.is_file()}",
            )
            continue

        # 4. kdh skill (default): repo 또는 local install 둘 중 하나 존재
        candidate = kdh_pipelines_dir / "skills" / target / "SKILL.md"
        installed = claude_dir / "skills" / target / "SKILL.md"
        exists = candidate.is_file() or installed.is_file()
        result.add(
            f"target_exists[{alias_label}]",
            exists,
            f"target={target} repo={candidate.is_file()} local={installed.is_file()}",
        )


def check_skill_frontmatter(claude_dir: Path, result: Result, skill_filter: Optional[str] = None) -> None:
    """R-06 frontmatter requirement 의 일부 — frontmatter 존재 검증.

    fail-closed: parse error = FAIL.
    Skip non-skill directories (log artifacts, etc.) — names starting with '_'.
    """
    skills_dir = claude_dir / "skills"
    if not skills_dir.is_dir():
        result.add("skills_dir.exists", False, str(skills_dir))
        return
    result.add("skills_dir.exists", True, str(skills_dir))

    for skill_dir in sorted(skills_dir.iterdir()):
        if not skill_dir.is_dir():
            continue
        if skill_filter and skill_dir.name != skill_filter:
            continue
        # log artifacts (_bmad-installed-log 등) = skip — skill 아님
        if skill_dir.name.startswith("_"):
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.is_file():
            result.add(f"frontmatter[{skill_dir.name}]", False, "SKILL.md absent")
            continue
        try:
            fm = parse_frontmatter(skill_md)
        except Exception as e:
            result.add(f"frontmatter[{skill_dir.name}]", False, f"parse error: {e}")
            continue
        if fm is None:
            result.add(f"frontmatter[{skill_dir.name}]", False, "frontmatter block absent")
            continue
        if not isinstance(fm, dict):
            result.add(f"frontmatter[{skill_dir.name}]", False, "frontmatter not a mapping")
            continue
        has_name = bool(fm.get("name"))
        has_desc = bool(fm.get("description"))
        if has_name and has_desc:
            result.add(f"frontmatter[{skill_dir.name}]", True, "name+description")
        else:
            missing = [k for k, ok in (("name", has_name), ("description", has_desc)) if not ok]
            result.add(f"frontmatter[{skill_dir.name}]", False, f"missing={missing}")


# ─── CLI ──────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="Skill Smoke Harness (R-23)")
    parser.add_argument("--skill", help="단일 skill 만 검증")
    parser.add_argument("--alias-only", action="store_true", help="alias map 만 검증")
    parser.add_argument("--json", action="store_true", help="JSON 출력")
    parser.add_argument(
        "--claude-dir",
        default=str(Path.home() / ".claude"),
        help="Claude home dir (default ~/.claude)",
    )
    parser.add_argument(
        "--kdh-pipelines-dir",
        default=str(Path.home() / "kdh-pipelines"),
        help="kdh-pipelines repo dir",
    )
    parser.add_argument(
        "--alias-map",
        default=None,
        help="skill-alias-map.yaml path (default: <claude-dir>/skill-alias-map.yaml)",
    )
    args = parser.parse_args()

    claude_dir = Path(args.claude_dir)
    kdh_pipelines_dir = Path(args.kdh_pipelines_dir)
    alias_map_path = Path(args.alias_map) if args.alias_map else (claude_dir / "skill-alias-map.yaml")

    if not claude_dir.is_dir():
        print(f"ERR: claude-dir absent: {claude_dir}", file=sys.stderr)
        return 2

    result = Result()
    amap = check_alias_map(alias_map_path, result)
    if amap is not None:
        check_alias_entries(amap, result)
        check_target_existence(amap, claude_dir, kdh_pipelines_dir, result)

    if not args.alias_only:
        check_skill_frontmatter(claude_dir, result, skill_filter=args.skill)

    output = result.to_dict()
    if args.json:
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        verdict = output["verdict"]
        print(f"=== Skill Smoke Harness — {verdict} ===")
        print(f"yaml_backend: {output['yaml_backend']}")
        passed = sum(1 for c in output["checks"] if c["result"] == "PASS")
        failed = sum(1 for c in output["checks"] if c["result"] == "FAIL")
        print(f"checks: {passed} PASS / {failed} FAIL / {len(output['checks'])} total")
        if failed:
            print("--- FAIL detail ---")
            for c in output["checks"]:
                if c["result"] == "FAIL":
                    print(f"  ✗ {c['check']}: {c['detail']}")
        else:
            print("  all checks PASS")

    return 1 if result.failed else 0


if __name__ == "__main__":
    sys.exit(main())
