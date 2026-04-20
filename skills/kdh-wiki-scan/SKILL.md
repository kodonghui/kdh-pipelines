---
name: 'kdh-wiki-scan'
description: 'OWK compliance scanner for _bmad-output/wiki/ (Topic 6). Checks 4-seed-file invariant, OWK-011 7-event log schema, .writer.lock hygiene, wiki_size_bytes/wiki_entry_count monotonicity. Output report to /tmp/ (not inside wiki per §12 Fix 4).'
---

# kdh-wiki-scan

**Purpose**: Read-only audit of `_bmad-output/wiki/` against OWK rules. Surface violations before they propagate.

**Reference**: `_bmad-output/kdh-plans/0420-topic6-graphify-integration.md` §12 patch-v2. Board ratification in `_bmad-output/kdh-plans/0417-board-v2-discussions/topic-6-rounds/`.

---

## Invocation

```bash
# Default: scan repo-local wiki, write report to /tmp/
/kdh-wiki-scan

# Custom target wiki + output
/kdh-wiki-scan --wiki-dir=_bmad-output/wiki --report=/tmp/wiki-scan-$(date -u +%Y%m%dT%H%M%SZ).md
```

Exit codes:
- `0` — all checks PASS
- `1` — OWK-015 violation (file count or unexpected files)
- `2` — OWK-011 violation (log schema)
- `3` — OWK-018 violation (lock missing or stale)
- `4` — monotonicity violation (wiki_size or entry_count regressed across events)

---

## Checks

### Check 1 — OWK-015 file count (PASS = 4 files)

Target wiki must contain exactly: `home.md`, `glossary.md`, `decision-index.md`, `log.md`. No `concepts/`, no sub-dirs, no extra `.md` at the top level (hidden dotfiles excluded).

```bash
ls -1 "$WIKI_DIR"/*.md | wc -l  # must be 4
```

FAIL if count ≠ 4 or if any filename outside the allowed set.

### Check 2 — OWK-011 log.md schema (PASS = all events one of 7 types, required fields)

Every non-blank line in `log.md` (excluding front-matter `>`-quoted and `---` separators) must match:

```
YYYY-MM-DDTHH:MM:SSZ event=<TYPE> <key=value>...
```

Where `<TYPE>` ∈ `{INGEST, QUERY, BUILD, CONSOLIDATE, ARCHIVE, LOCK, SANDBOX_POC}`.

Required per-event fields:
- `INGEST`: `source` + `entry_count_delta` + `wiki_size_bytes` + `wiki_entry_count`
- `QUERY`: `query` + `hits` + `latency_ms`
- `BUILD`: `sha` + `page_size_bytes` + `wiki_size_bytes` + `wiki_entry_count`
- `CONSOLIDATE`: `merged` + `dropped` + `wiki_size_bytes` + `wiki_entry_count`
- `ARCHIVE`: `target` + `wiki_size_bytes` + `wiki_entry_count`
- `LOCK`: `action` (acquire|release) + `duration_ms` (release only — acquire may omit)
- `SANDBOX_POC`: `sandbox_sha` + `smoke_result` (PASS|FAIL)

FAIL per missing required field.

### Check 3 — OWK-018 lock hygiene

Check `_bmad-output/wiki/.writer.lock`:
- If present: must be < 10 min old (stale lock → FAIL)
- If absent: OK
- Any other lock path inside wiki (e.g., `*.lock` files) → FAIL

### Check 4 — Monotonicity (wiki_size + entry_count)

Across the log.md event stream, these fields must be monotonically non-decreasing within a single build generation:

- `wiki_size_bytes` — may drop only at CONSOLIDATE or ARCHIVE events
- `wiki_entry_count` — may drop only at CONSOLIDATE (merged > 0) or ARCHIVE

Regressions outside these allowed events → FAIL.

### Check 5 — SKILL sync (advisory)

Warn if runtime mirror `~/.claude/skills/kdh-wiki-scan/` differs from source `~/kdh-pipelines/skills/kdh-wiki-scan/`. Related to §12 Fix v2-2 (installer reality). Not a blocker.

---

## Output report format

Report written to `/tmp/wiki-scan-{ts}.md` (not inside the wiki — §12 Fix 4 explicit):

```markdown
# Wiki Scan Report — {ts}

**Target**: {wiki_dir}
**Overall**: {PASS|FAIL}

## Check 1: OWK-015 file count
- Status: {PASS|FAIL}
- Expected: 4 files (home, glossary, decision-index, log)
- Actual: {n} files
- Extras / missing: {list}

## Check 2: OWK-011 log schema
- Status: {PASS|FAIL}
- Events parsed: {n}
- Errors: {list with line numbers}

## Check 3: OWK-018 lock hygiene
- Status: {PASS|FAIL}
- Notes: {e.g., lock absent | lock 2min old | stale lock at X}

## Check 4: Monotonicity
- Status: {PASS|FAIL}
- Regressions: {list}

## Check 5: Skill sync (advisory)
- Status: {OK|DRIFT}
- Source: ~/kdh-pipelines/skills/kdh-wiki-scan/
- Runtime: ~/.claude/skills/kdh-wiki-scan/
- Diff: {inline diff or "none"}
```

---

## Integration

- Run manually before any `kdh-wiki-build` or `kdh-wiki-consolidate`.
- Add to Sprint Close pre-gate (Phase 4.6 kickoff): wiki-scan PASS required before sprint-gate invocation if wiki was modified in Sprint.
- CI hook (future, Phase 4.6 Day 3+): run on PRs touching `_bmad-output/wiki/`.

---

## Anti-patterns (DO NOT)

- DO NOT write report inside `_bmad-output/wiki/` — violates §12 Fix 4 (scan self-contradiction).
- DO NOT create additional wiki files when scan reveals missing ones — fixing is a separate action (kdh-wiki-build or manual).
- DO NOT bypass OWK-015 by moving content to hidden files or subdirs.
