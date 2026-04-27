---
name: 'kdh-wiki-build'
description: "OWK wiki rebuild: lock, provenance, monotonic log."
---

# kdh-wiki-build

**Purpose**: Single-writer, atomic rebuild of the 4 seed files in `_bmad-output/wiki/` with complete OWK-011 event trace.

Uses `flock` (OWK-018) to serialize concurrent writers. Every invocation emits ≥3 events to `log.md`: `LOCK acquire`, `BUILD`, `LOCK release`. Optional `INGEST`/`CONSOLIDATE`/`ARCHIVE` events when corresponding work happens.

---

## Invocation

```bash
# Default: rebuild from canonical sources
/kdh-wiki-build

# Dry run (no writes, preview diff)
/kdh-wiki-build --dry-run

# Rebuild but skip consolidation pass
/kdh-wiki-build --no-consolidate

# Force rebuild even if source hashes unchanged (useful after schema bump)
/kdh-wiki-build --force
```

Exit codes:
- `0` — build succeeded, lock released, events logged
- `1` — lock acquisition timed out (another writer busy >30s)
- `2` — source validation failure (kdh-wiki-scan FAIL)
- `3` — build logic error (caught exception, lock released, events logged)
- `4` — monotonicity violation attempted (wiki_size or entry_count would regress without CONSOLIDATE/ARCHIVE event)

---

## Design

### Lock protocol (OWK-018)

```bash
LOCK_FILE=_bmad-output/wiki/.writer.lock

exec 9>"$LOCK_FILE"
if ! flock -n -x 9; then
  # Stale lock check (>10 min)
  if [ "$(find "$LOCK_FILE" -mmin +10 | wc -l)" -gt 0 ]; then
    echo "stale lock detected (>10min), removing and retrying"
    rm -f "$LOCK_FILE"
    exec 9>"$LOCK_FILE"
    flock -n -x 9 || exit 1
  else
    exit 1
  fi
fi

trap 'rc=$?; flock -u 9; log_event LOCK release; exit $rc' EXIT
```

Writers hold the lock for the entire build. Readers do NOT need the lock (they tolerate minor inconsistency across files).

### Build phases

1. **VALIDATE** — `kdh-wiki-scan` must PASS. Else exit 2.
2. **LOCK acquire** — flock with 30s timeout. Log event.
3. **SOURCE HASH** — compute SHA256 of each source: `STATUS.md`, `DECISIONS.md`, `MASTER-ROADMAP.md`, `_bmad-output/kdh-plans/_index.yaml`, active board R5-FINAL files. Compare to previous build SHA (stored in `.writer.lock.meta`). Skip if unchanged unless `--force`.
4. **BUILD** — regenerate:
   - `home.md` — refresh "Current Operational Snapshot" table links; preserve user-edited text blocks by comment markers (`<!-- preserve-start -->`).
   - `glossary.md` — merge in new actor/term entries extracted from sources (dedupe).
   - `decision-index.md` — add new DECISIONS.md pointer entries (by timestamp) + new board R5-FINAL entries.
   - `log.md` — append-only. Build emits 1 BUILD event with source SHA.
5. **MONOTONICITY CHECK** — new `wiki_size_bytes` + `wiki_entry_count` must be ≥ previous (unless CONSOLIDATE/ARCHIVE ran). Else exit 4.
6. **COMMIT** — optional `git add -A _bmad-output/wiki/ && git commit -m "wiki-build: {sha}"` if running inside a repo.
7. **LOCK release** — via trap, logs LOCK release event.

### Provenance

Every BUILD event carries:
- `sha` — short git hash of source tree at build time
- `page_size_bytes` — total size of the 4 seed files combined
- `wiki_size_bytes` — alias of page_size_bytes for home/glossary/decision-index + log size
- `wiki_entry_count` — count of log.md event lines at time of build
- (optional) `consolidated_merged`, `consolidated_dropped`, `archived_target` if those phases ran

### OWK-011 schema emitted

Per build (minimum):
```
{ts} event=LOCK        action=acquire  duration_ms=23
{ts} event=BUILD       sha=abc1234  page_size_bytes=8210  wiki_size_bytes=8210  wiki_entry_count=12
{ts} event=LOCK        action=release  duration_ms=145
```

Per optional phase (when triggered):
```
{ts} event=INGEST      source=DECISIONS.md  entry_count_delta=2  wiki_size_bytes=8410  wiki_entry_count=14
{ts} event=CONSOLIDATE merged=3  dropped=1  wiki_size_bytes=8280  wiki_entry_count=12
{ts} event=ARCHIVE     target=_bmad-output/wiki/archive/20260420.md  wiki_size_bytes=4100  wiki_entry_count=4
```

---

## Anti-patterns (DO NOT)

- DO NOT write to any file in `_bmad-output/wiki/` without holding the lock.
- DO NOT skip `kdh-wiki-scan` VALIDATE phase — it catches OWK-011 drift early.
- DO NOT emit BUILD events that decrease `wiki_size_bytes` without a preceding CONSOLIDATE / ARCHIVE event.
- DO NOT use this skill to create new wiki files beyond the 4 seed files (OWK-015 violation).
- DO NOT run Graphify build from within this skill — Graphify stays in `/tmp/graphify-sandbox/` (OWK-019 gate 1).

## Integration

- Invoke after `save-session-conductor` or `save-session` to refresh wiki pointers.
- Invoke after Board R5-FINAL write to index new decisions.
- Invoke from `kdh-ecc-12h` learn+evolve cycle (periodic rebuild).
- Do NOT invoke from inside `kdh-bug-fix-pipeline` or `kdh-dev-pipeline` — wiki state is metadata, not on the hot path.

## Helper script

See `./build.sh` in this skill directory — reference bash implementation of the phases above. Consumers can reuse or replace.
