---
name: 'kdh-wiki-query'
description: 'Read-only query skill for _bmad-output/wiki/ (Topic 6 OWK Readable Wiki layer). Grep-based search + link traversal + provenance lookup. No writes, no lock acquire. Per OWK-014 search-before-create rule.'
---

# kdh-wiki-query

**Purpose**: Read-only access to `_bmad-output/wiki/` for agents (before build/create) and for CEO (via Obsidian or CLI). No writes. No lock acquire.

Reference: `_bmad-output/kdh-plans/0417-board-v2-discussions/topic-6-rounds/R4/A.md` OWK-014 (search-before-create), OWK-012 (provenance lookup).

---

## Invocation

```bash
# Search free-text across all wiki pages
/kdh-wiki-query "Topic 6"
/kdh-wiki-query --term="OWK-020"

# Provenance lookup (OWK-012 4-field match)
/kdh-wiki-query --provenance kind=decision path=conductorA/DECISIONS.md id="[22:10]" version=22:10

# Link traversal from a starting page
/kdh-wiki-query --link-graph home.md --depth=2

# List all pages (sanity check vs OWK-015 4-file invariant)
/kdh-wiki-query --list

# Find all events of a given type in log.md (OWK-011)
/kdh-wiki-query --events BUILD
/kdh-wiki-query --events SANDBOX_POC
```

Exit codes:
- `0` — query completed, results printed to stdout
- `1` — wiki dir missing or malformed
- `2` — query syntax error
- `3` — OWK-015 violation detected (unexpected files)

---

## Checks

### Free-text search

grep -rni through home.md / glossary.md / decision-index.md / log.md only (NOT sub-dirs like `.obsidian/`).

```bash
grep -rniE "$TERM" _bmad-output/wiki/{home,glossary,decision-index,log}.md
```

Output format:
```
home.md:42:relevant line
glossary.md:18:relevant line
```

### Provenance lookup (OWK-012)

Match on all 4 fields `source_kind + source_path + source_id + source_version`. If all 4 match exactly → return page. If partial match → return candidates. If none → exit 1 with message "no provenance match — safe to create new page".

Per OWK-014 fail-closed: multiple matches → error (do not pick arbitrary).

### Link graph (traversal)

Parse `[[wikilink]]` and markdown `[text](file.md)` from source page. Recursively follow up to `--depth` (default 2). Output adjacency list:

```
home.md:
  → glossary.md
  → decision-index.md
  → log.md (backlink only)
glossary.md:
  → home.md
  (no outgoing to log or decision-index)
```

### Event lookup (OWK-011)

Parse `log.md` event stream. Filter by event type. Output timestamp + full event line.

```
2026-04-20T14:27:31Z event=BUILD sha=99da319 page_size_bytes=8584 wiki_size_bytes=9839 wiki_entry_count=7
```

### List check (OWK-015)

`ls _bmad-output/wiki/*.md` → must show exactly 4 files. Any more/less → FAIL with list of violations. Hidden dotfiles (like `.obsidian/`) excluded from check.

---

## Integration with other skills

- **Before `kdh-wiki-build` writes**: query for existing provenance match (OWK-014) → if match, in-place update; if none, safe to create.
- **Before `kdh-wiki-consolidate` merges**: query for duplicate entries across pages by provenance.
- **Before `kdh-board-meeting` R0 research**: query for prior board records on same topic by term search.

---

## Anti-patterns (DO NOT)

- DO NOT acquire `.writer.lock` — query is read-only by OWK contract.
- DO NOT walk into `.obsidian/` subdirectory (Obsidian metadata, not wiki content).
- DO NOT write results to wiki — output to stdout or `/tmp/wiki-query-{ts}.md` only.
- DO NOT query line numbers or Obsidian block refs for cross-layer identity (OWK-013 prohibited).

---

## Reference implementation

See `./query.sh` — minimal bash reference. Consumers may replace with faster impls (ripgrep, indexed search) as needed — all must satisfy the 5 checks above.
