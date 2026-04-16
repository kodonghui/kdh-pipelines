"""
kdh-claude-browser-use — Claude 네이티브 브라우저 러너.

Claude CLI + Playwright MCP로 브라우저를 직접 제어.
Python SDK가 아닌 CLI subprocess 사용 (OAuth 인증 호환).

Usage:
  python3.11 _browser-use-test/kdh_claude_browser_use.py --url http://localhost:5173/admin
"""
import argparse
import asyncio
import json
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path

# from dotenv import load_dotenv  # project-specific

sys.path.insert(0, os.path.dirname(__file__))
from contracts import SweepBug, SweepFeatureRequest, SweepResult


SWEEP_TASK = """
You are a thorough QA tester. You have Playwright browser tools via MCP.
Test EVERY feature on this web application systematically.

## Target: {base_url}

### Phase A: Authentication
1. Navigate to {base_url}/login
2. Describe the login page layout
3. Log in with: email={sweep_email}, password={sweep_password}
4. If login fails, try signing up first

### Phase B: Visit ALL Sidebar Pages
After login, click EVERY link in the sidebar. You MUST visit ALL of these:
- 대시보드 (Dashboard)
- 본부 / 팀 (Divisions / Teams)
- 에이전트 (Agents)
- 직원 (Members)
- 대화 로그 (Conversation Logs)
- 시스템 설정 (System Settings)
- 감사 로그 (Audit Log)

On EACH page: describe layout, click buttons, open dropdowns, note errors/blank content.

### Phase C: Theme Verification
Switch to each theme (Brand, Green, Toss Dark, Toss Light, Cherry Blossom).
Check: text readable? Elements visible? Buttons have borders?

### Phase D: Error Detection
Check console errors, 500 API calls, missing resources.

### CRITICAL: Final Report
When DONE, output EXACTLY this format:

SWEEP_REPORT_START
{{
  "sweep_complete": true,
  "pages_tested": ["/admin/login", "/admin/dashboard", ...],
  "bugs": [
    {{
      "page": "/path",
      "bug_type": "ui|routing|schema|env|logic",
      "severity": "critical|major|minor",
      "description": "description",
      "theme": "theme or null",
      "steps_to_reproduce": ["step 1"],
      "console_errors": []
    }}
  ],
  "feature_requests": [],
  "working_correctly": ["features that work"]
}}
SWEEP_REPORT_END
"""


def _parse_sweep_report(text: str) -> dict | None:
    """Extract JSON report from Claude result text."""
    # Strategy 1: SWEEP_REPORT markers
    match = re.search(
        r"SWEEP_REPORT_START\s*(\{.*?\})\s*SWEEP_REPORT_END",
        text, re.DOTALL,
    )
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass

    # Strategy 2: JSON with sweep_complete
    for m in re.finditer(r'\{[^{}]*"sweep_complete"[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', text, re.DOTALL):
        try:
            return json.loads(m.group())
        except json.JSONDecodeError:
            continue

    # Strategy 3: Any large JSON
    depth = 0
    start = -1
    for i, ch in enumerate(text):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start >= 0:
                candidate = text[start:i + 1]
                if len(candidate) > 50:
                    try:
                        data = json.loads(candidate)
                        if "bugs" in data or "pages_tested" in data:
                            return data
                    except json.JSONDecodeError:
                        pass
                start = -1
    return None


async def run_claude_sweep(
    base_url: str,
    output_dir: str,
    timestamp: str,
) -> SweepResult:
    """Run Claude native browser sweep via CLI + Playwright MCP."""
    sweep_email = os.environ.get("SWEEP_EMAIL", f"sweep-{timestamp}@test.com")
    sweep_password = os.environ.get("SWEEP_PASSWORD", "SweepTest123!")

    task = SWEEP_TASK.format(
        base_url=base_url,
        timestamp=timestamp,
        sweep_email=sweep_email,
        sweep_password=sweep_password,
    )

    # MCP config for Playwright
    mcp_config = json.dumps({
        "mcpServers": {
            "playwright": {
                "command": "npx",
                "args": ["@playwright/mcp@latest", "--headless"],
            }
        }
    })

    # Build CLI command
    env = os.environ.copy()
    # Remove ALL Anthropic tokens — force CLI to use its own OAuth login state
    env.pop("ANTHROPIC_API_KEY", None)
    env.pop("CLAUDE_CODE_OAUTH_TOKEN", None)
    env.pop("ANTHROPIC_AUTH_TOKEN", None)

    start = time.monotonic()
    print(f"  [claude-native] Starting sweep (CLI + Playwright MCP)...")

    try:
        proc = await asyncio.create_subprocess_exec(
            "/usr/bin/claude", "-p", task,
            "--mcp-config", mcp_config,
            "--allowedTools", "mcp__playwright__*",
            "--output-format", "json",
            "--max-turns", "100",
            "--permission-mode", "acceptEdits",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env,
        )

        stdout, stderr = await proc.communicate()
        duration = time.monotonic() - start

        output = stdout.decode().strip()
        if not output:
            err = stderr.decode().strip()[:500]
            print(f"  [claude-native] FAILED — empty output, stderr: {err} ({duration:.0f}s)")
            return SweepResult(
                provider="claude", model="claude-sonnet-4-6",
                error=f"Empty output: {err}", duration_seconds=duration,
            )

        # Parse CLI JSON envelope
        try:
            envelope = json.loads(output)
        except json.JSONDecodeError:
            # Raw text output
            envelope = {"result": output}

        result_text = envelope.get("result", "")
        num_turns = envelope.get("num_turns", 0)
        cost = envelope.get("total_cost_usd", 0)
        is_error = envelope.get("is_error", False)

        # Save raw
        raw_path = os.path.join(output_dir, "bug-fix", f"sweep-{timestamp}-claude-native-raw.txt")
        os.makedirs(os.path.dirname(raw_path), exist_ok=True)
        with open(raw_path, "w") as f:
            f.write(result_text)

        # Parse report
        bugs: list[SweepBug] = []
        feature_requests: list[SweepFeatureRequest] = []
        pages_tested: list[str] = []
        working: list[str] = []

        report = _parse_sweep_report(result_text)
        if report:
            pages_tested = report.get("pages_tested", [])
            working = report.get("working_correctly", [])
            for b in report.get("bugs", []):
                bugs.append(SweepBug(
                    page=b.get("page", "unknown"),
                    bug_type=b.get("type", b.get("bug_type", "ui")),
                    severity=b.get("severity", "minor"),
                    description=b.get("description", ""),
                    theme=b.get("theme"),
                    steps_to_reproduce=b.get("steps_to_reproduce", []),
                    console_errors=b.get("console_errors", []),
                ))
            for fr in report.get("feature_requests", []):
                feature_requests.append(SweepFeatureRequest(description=fr.get("description", "")))
            print(f"  [claude-native] COMPLETE — {len(bugs)} bugs, {len(pages_tested)} pages, {num_turns} turns, ${cost:.2f} ({duration:.0f}s)")
        else:
            print(f"  [claude-native] COMPLETE — JSON parse failed, {num_turns} turns, ${cost:.2f} ({duration:.0f}s)")
            if result_text:
                print(f"  [claude-native] Result preview: {result_text[:200]}")

        return SweepResult(
            provider="claude", model="claude-sonnet-4-6",
            sweep_complete=not is_error,
            pages_tested=pages_tested, bugs=bugs,
            feature_requests=feature_requests, working_correctly=working,
            duration_seconds=duration,
        )

    except Exception as e:
        duration = time.monotonic() - start
        print(f"  [claude-native] FAILED — {e} ({duration:.0f}s)")
        return SweepResult(
            provider="claude", model="claude-sonnet-4-6",
            error=str(e)[:500], duration_seconds=duration,
        )


async def main_async() -> None:
    parser = argparse.ArgumentParser(description="Claude native browser sweep")
    parser.add_argument("--url", default="http://localhost:5173/admin", help="Base URL")
    parser.add_argument("--output", default=str(Path(__file__).resolve().parent.parent / "_bmad-output"))
    args = parser.parse_args()

    
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    result = await run_claude_sweep(args.url, args.output, timestamp)

    print(f"\nProvider: {result.provider}")
    print(f"Pages: {len(result.pages_tested)}")
    print(f"Bugs: {len(result.bugs)}")
    print(f"Duration: {result.duration_seconds:.0f}s")
    if result.error:
        print(f"Error: {result.error}")
    for bug in result.bugs:
        print(f"  [{bug.severity}] {bug.page} — {bug.description[:80]}")


if __name__ == "__main__":
    asyncio.run(main_async())
