#!/usr/bin/env python3
"""
kdh-dev-pipeline Modular Split Regression — board 0425 R-10

Purpose: Wave 3 modular split 후 golden path 검증. 4 명령 (slash + NL + help-router
         + alias) 모두 wrapper 가 받고, sub-skill 등록 + frontmatter 일관 + alias
         conflict 없음 확인. fail-closed.

Checks:
  1. wrapper SKILL.md 존재 + frontmatter
  2. 4 sub-skill 디렉토리 + SKILL.md 존재
  3. 각 sub-skill frontmatter 의 wrapper 필드 = "kdh-dev-pipeline"
  4. 각 sub-skill frontmatter 의 phase 필드 valid (A | B | D | codex_review)
  5. wrapper 본문에 sub-skill registry 섹션 존재
  6. wrapper 본문에 4 sub-skill 모두 reference 박힘
  7. alias map 에 wrapper / sub-skill 명칭 conflict 없음
  8. wrapper invocation surface 보존 표지 ("Phase Sub-skills" + "Invocation Surface")
  9. rollback target 명시 (R-11)
  10. R-32 atomic-write 본문 reference 존재

Exit codes:
  0 = PASS
  1 = FAIL (1+ check 실패)
  2 = ENV ERROR
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

try:
    import yaml  # type: ignore
except ImportError:
    yaml = None


VALID_PHASES = {"A", "B", "D", "codex_review"}
WRAPPER_NAME = "kdh-dev-pipeline"
SUB_SKILLS = [
    "kdh-dev-pipeline-phase-a",
    "kdh-dev-pipeline-phase-b",
    "kdh-dev-pipeline-phase-d",
    "kdh-dev-pipeline-codex",
]


def _parse_frontmatter(text: str):
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
    if not m:
        return None
    if yaml is None:
        # minimal parse
        result = {}
        for line in m.group(1).splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if ":" not in line:
                continue
            k, _, v = line.partition(":")
            result[k.strip()] = v.strip().strip('"').strip("'")
        return result
    try:
        return yaml.safe_load(m.group(1))
    except Exception:
        return None


class Result:
    def __init__(self):
        self.checks: list[dict] = []
        self.failed = False

    def add(self, name: str, passed: bool, detail: str = ""):
        self.checks.append({"check": name, "result": "PASS" if passed else "FAIL", "detail": detail})
        if not passed:
            self.failed = True

    def to_dict(self):
        return {
            "verdict": "FAIL" if self.failed else "PASS",
            "checks": self.checks,
        }


def main() -> int:
    parser = argparse.ArgumentParser(description="kdh-dev-pipeline modular split regression (R-10)")
    parser.add_argument(
        "--repo-root",
        default=str(Path.home() / "kdh-pipelines"),
        help="kdh-pipelines repo root",
    )
    parser.add_argument(
        "--alias-map",
        default=str(Path.home() / ".claude" / "skill-alias-map.yaml"),
        help="alias map path",
    )
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    repo_root = Path(args.repo_root)
    skills_dir = repo_root / "skills"
    if not skills_dir.is_dir():
        print(f"ERR: skills dir absent: {skills_dir}", file=sys.stderr)
        return 2

    result = Result()

    # 1. wrapper SKILL.md 존재 + frontmatter
    wrapper_path = skills_dir / WRAPPER_NAME / "SKILL.md"
    wrapper_text = ""
    wrapper_fm = None
    if wrapper_path.is_file():
        wrapper_text = wrapper_path.read_text(encoding="utf-8")
        wrapper_fm = _parse_frontmatter(wrapper_text)
        result.add("1.wrapper.exists", True, str(wrapper_path))
        result.add("1.wrapper.frontmatter", wrapper_fm is not None,
                   f"name={wrapper_fm.get('name') if wrapper_fm else None}")
    else:
        result.add("1.wrapper.exists", False, str(wrapper_path))

    # 2-4. 4 sub-skill 검증
    for sub in SUB_SKILLS:
        sub_path = skills_dir / sub / "SKILL.md"
        if not sub_path.is_file():
            result.add(f"2.sub.{sub}.exists", False, str(sub_path))
            continue
        result.add(f"2.sub.{sub}.exists", True, str(sub_path))
        sub_text = sub_path.read_text(encoding="utf-8")
        sub_fm = _parse_frontmatter(sub_text)
        if sub_fm is None:
            result.add(f"3.sub.{sub}.frontmatter", False, "parse failed")
            continue
        # name = sub-skill name
        name_ok = sub_fm.get("name") == sub
        result.add(f"3.sub.{sub}.frontmatter.name", name_ok,
                   f"got {sub_fm.get('name')!r}")
        # wrapper 필드 = kdh-dev-pipeline
        wrapper_ok = sub_fm.get("wrapper") == WRAPPER_NAME
        result.add(f"3.sub.{sub}.frontmatter.wrapper", wrapper_ok,
                   f"got {sub_fm.get('wrapper')!r}")
        # phase 필드 valid
        phase_ok = sub_fm.get("phase") in VALID_PHASES
        result.add(f"4.sub.{sub}.frontmatter.phase", phase_ok,
                   f"got {sub_fm.get('phase')!r}, valid={sorted(VALID_PHASES)}")

    # 5-6. wrapper 본문 sub-skill registry + 4 sub-skill reference
    if wrapper_text:
        has_registry = "Phase Sub-skills" in wrapper_text or "Sub-skill Registry" in wrapper_text
        result.add("5.wrapper.registry_section", has_registry,
                   "expects 'Phase Sub-skills' or 'Sub-skill Registry' header")
        for sub in SUB_SKILLS:
            ref_ok = sub in wrapper_text
            result.add(f"6.wrapper.references.{sub}", ref_ok,
                       f"wrapper body must mention {sub}")

    # 7. alias map conflict 검증
    alias_map_path = Path(args.alias_map)
    if alias_map_path.is_file():
        amap_text = alias_map_path.read_text(encoding="utf-8")
        # wrapper 와 sub-skill 명칭이 alias map 의 alias 컬럼에 있으면 conflict
        # (alias 가 본 skill 이름을 가리키는 경우만 OK = target)
        for skill in [WRAPPER_NAME] + SUB_SKILLS:
            # alias: "<skill>" 패턴 검색 (여기서 alias 가 skill 자체면 self-loop)
            pattern = re.compile(rf"^\s*-\s*alias:\s*[\"']?{re.escape(skill)}[\"']?\s*$", re.MULTILINE)
            self_loop = pattern.search(amap_text) is not None
            result.add(f"7.alias_map.no_self_alias.{skill}", not self_loop,
                       "wrapper/sub-skill 자체가 alias 의 source 가 되면 self-loop")
    else:
        result.add("7.alias_map.exists", False, str(alias_map_path))

    # 8. wrapper invocation surface 보존 표지
    if wrapper_text:
        has_surface = "Invocation Surface" in wrapper_text or "invocation surface" in wrapper_text.lower()
        result.add("8.wrapper.invocation_surface_marker", has_surface,
                   "expects 'Invocation Surface' marker (R-08)")

    # 9. rollback target (R-11)
    if wrapper_text:
        has_rollback = "rollback" in wrapper_text.lower() and "monolith" in wrapper_text.lower()
        result.add("9.wrapper.rollback_target", has_rollback,
                   "expects rollback + monolith mention (R-11)")

    # 10. R-32 atomic-write reference
    refs_atomic = "atomic-write" in wrapper_text.lower() or "R-32" in wrapper_text
    result.add("10.wrapper.atomic_write_reference", refs_atomic,
               "expects R-32 / atomic-write reference")

    output = result.to_dict()
    if args.json:
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        passed = sum(1 for c in output["checks"] if c["result"] == "PASS")
        failed = sum(1 for c in output["checks"] if c["result"] == "FAIL")
        print(f"=== R-10 Regression — {output['verdict']} ===")
        print(f"checks: {passed} PASS / {failed} FAIL / {len(output['checks'])} total")
        if failed:
            print("--- FAIL detail ---")
            for c in output["checks"]:
                if c["result"] == "FAIL":
                    print(f"  ✗ {c['check']}: {c['detail']}")

    return 1 if result.failed else 0


if __name__ == "__main__":
    sys.exit(main())
