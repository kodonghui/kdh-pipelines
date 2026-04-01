# Background Agent for Stitch MCP Batch Generation

**Extracted:** 2026-03-23
**Context:** Phase 6 Stitch 2 MCP screen generation — 23 web pages

## Problem
Generating 20+ screens via Stitch MCP takes ~2-3 minutes per screen. Sequential generation in the main thread blocks all other work for 40+ minutes.

## Solution
Use a single background Agent (not TeamCreate) for batch Stitch MCP generation:
1. Generate the first 2-5 critical screens in the main thread (for immediate quality validation)
2. Launch a background agent with `run_in_background: true` for the remaining screens
3. Include the full design system prefix in every prompt (Stitch creates a new design system per call)
4. Generate 2 screens at a time in parallel within the background agent
5. Download HTML via `curl` (not WebFetch — WebFetch returns AI summaries, not raw HTML)

## Key Details
- Stitch `generate_screen_from_text` accepts one prompt per call
- Each call takes ~2-3 minutes
- Background agent can call 2 in parallel → ~4 pages per 5 minutes
- 18 pages completed in ~47 minutes
- Save HTML to `phase-6-generated/web/{page-name}.html`

## When to Use
Any time you need to generate 10+ screens via Stitch MCP. Main thread handles first batch + commits, background handles the rest.
