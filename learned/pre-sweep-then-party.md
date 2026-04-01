# Pre-sweep + Party Mode Pattern

**Extracted:** 2026-03-22
**Context:** When reverifying documents that have known terminology/value issues across many sections

## Problem
Without pre-sweep, critics find the same terminology issue (e.g., "Gemini→Voyage AI", "4GB→2G") in every step. Each step's fixes don't propagate to the next step. Result: 50%+ of fixes are duplicates, wasting 2+ hours of party mode time.

## Solution
1. Before starting party mode, run grep to find all known stale terms
2. Do bulk replacement (Edit tool with replace_all or targeted edits)
3. Create a "confirmed decisions" reference file listing all settled values
4. Tell critics: "Pre-sweep done. Don't flag terminology. Focus on structure/logic/consistency."
5. Run party mode — critics now find real structural issues instead of term mismatches

## Example
```
Pre-sweep checklist:
- grep "Gemini" → replace with "Voyage AI" (except "Gemini banned" context)
- grep "vector(768)" → "vector(1024)"
- grep "4GB|4G.*RAM" → "2G"
- grep "6-layer" → "8-layer"
- grep "Subframe" → "Stitch 2" (except "deprecated" context)
```

## When to Use
Any reverify (Mode B) or fresh write (Mode A) where predecessor documents have been significantly modified. Especially when 5+ known value changes exist.
