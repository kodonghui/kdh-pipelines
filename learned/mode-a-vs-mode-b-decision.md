# Mode A (Fresh Write) vs Mode B (Reverify) Decision

**Extracted:** 2026-03-22
**Context:** When deciding how to handle a completed stage whose predecessor was heavily modified

## Problem
Reverifying (Mode B) a document whose input was heavily modified leads to "patching an outdated answer." Critics find issues that are artifacts of the old input, not real problems. Time wasted on false positives.

## Solution
Decision framework:
- **Mode B (Reverify)** when: predecessor had < 20% changes, document structure is sound, issues are mostly values/terms
- **Mode A (Fresh Write)** when: predecessor had > 20% changes (especially structural), document references outdated data throughout, reverify v-05 scored < 6.0 (indicates fundamental mismatch)

Evidence from this session:
- Stage 1 Tech Research: Mode B worked (predecessor = Brief, only term changes needed)
- Stage 2 PRD: Mode B worked (pre-sweep handled terms, structure was sound)
- Stage 3 PRD Validate: Mode B FAILED (v-05 scored 5.83, validation report referenced old PRD numbers). Mode A fresh write scored 8.73.

## When to Use
At the start of any reverify. If the first 2-3 steps consistently score < 6.5, switch to Mode A immediately. Don't wait for all steps to fail.
