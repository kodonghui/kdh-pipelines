---
name: kdh-research
description: "Deep Research v2 — 7-angle query decomposition, 2-round search, cross-verification, learning-based synthesis"
---

# /kdh-research — Deep Research Command v2

When the user invokes `/kdh-research [topic]`, execute a comprehensive, multi-source deep research operation using the 6-step methodology below.

## Core Directive

Research the given topic with these mandatory qualities:
- **Latest**: Only use current, up-to-date information. Verify publication dates. Reject sources older than 12 months for fast-moving topics (AI, frameworks).
- **Accurate**: Cross-reference across 3+ sources before stating a claim as fact. Flag single-source claims.
- **Popular/Trending**: Prioritize widely-adopted, battle-tested approaches. Include GitHub stars, npm downloads, citation counts.
- **Comprehensive**: Cover the topic from 7 different angles (see Step 1).
- **Detailed**: Include specific numbers, code examples, architecture patterns, comparison tables.
- **Verified**: Every claim in the report must have a source. No source = don't include it.

## Execution Steps

### Step 1: Query Decomposition (쿼리 분해)

Before searching, decompose the topic into **7 sub-queries** covering different angles.
Take 30 seconds to think: "What are the different facets of this topic?"

| # | Angle | Query Pattern | Purpose |
|---|-------|--------------|---------|
| 1 | Problem | "{topic} problem challenge bottleneck" | Why is this hard? |
| 2 | Solutions | "{topic} solution pattern best practice 2026" | How do people solve it? |
| 3 | Our Stack | "{our_tools} {topic} how to" | How does it apply to us? |
| 4 | Implementations | "github {topic} implementation stars:>500" | Real code examples |
| 5 | Research | "arxiv {topic} survey paper 2025 2026" | Academic grounding |
| 6 | Official | "{vendor} official {topic} documentation guide" | Vendor/framework docs |
| 7 | Production | "{topic} production experience lessons learned enterprise" | Real-world experience |

★ Execute ALL 7 WebSearch queries in parallel (single message, multiple tool calls).
★ If the topic is very specific, adapt angle names but KEEP 7 angles.
★ Include year "2025 2026" in at least 3 queries to get fresh results.

### Step 2: Round 1 — Breadth (발견)

From 7 WebSearch results:
1. **Select top 5~8 URLs** — judge by title + snippet relevance
2. **WebFetch each** with focused prompt:
   > "Extract: (1) specific findings with numbers/evidence, (2) what this source uniquely contributes that others might not, (3) any claims made without evidence. Be concrete — no vague summaries."
3. **Extract learning** from each source:

```
Source: [Title](URL) | Date: YYYY-MM | Type: blog/paper/docs/repo
Finding: {core discovery in 1-2 sentences}
Evidence: {specific numbers, code, quotes that support the finding}
Gap: {what this source alone can't answer}
Confidence: high/medium/low (based on evidence quality)
```

★ WebFetch prompts MUST ask for specific evidence, not summaries.
★ Note TYPE of each source (blog vs paper vs official docs vs repo).
★ If a source has no concrete evidence, mark Confidence: low.

### Step 3: Specialized Search (특화 검색)

Run in parallel with Step 2 where possible:

**GitHub (implementations):**
```bash
gh search repos "{topic}" --stars=">500" --sort=stars --limit=5
gh search repos "{topic}" --sort=updated --limit=5
```
For each relevant repo: note stars, last push date, README summary, key pattern used.
Quality threshold: stars > 500 = validated, 100-500 = promising, < 100 = reference only.

**Academic (if topic warrants):**
```
WebSearch: "site:arxiv.org {topic} survey 2025 2026"
WebSearch: "site:semanticscholar.org {topic}"
```
For papers: extract abstract + key findings + citation count.
Quality threshold: citations > 10 = trusted, 5-10 = recent and OK, < 5 = only if very recent.

**Package registries (if applicable):**
```
WebSearch: "npmjs.com {package}" OR "pypi.org {package}"
```
Note: weekly downloads, last publish date, GitHub stars link.

**Official documentation (if applicable):**
Use Context7 MCP or WebFetch vendor docs for authoritative reference.

### Step 4: Round 2 — Depth (깊이)

After Round 1 + Specialized Search, review ALL learnings:

1. **List gaps**: What's still unknown? (from each learning's "Gap" field)
2. **List conflicts**: Where do sources disagree?
3. **Generate 3~5 targeted queries** based on gaps and conflicts
4. **Execute targeted WebSearch + WebFetch**
5. **Extract additional learnings**

★ Round 2 queries are NARROW — "해결법 X의 단점은?" not "해결법 전반"
★ If two sources conflict, search specifically for a third opinion
★ Round 2 should NOT repeat Round 1 queries

### Step 5: Cross-Verification (교차 검증)

Before writing the report, verify key claims:

For each major claim that will appear in the report:
- Count how many independent sources support it
- Assign confidence level:

| Confidence | Criteria | Report Format |
|-----------|---------|---------------|
| ✅ HIGH | 3+ independent sources agree | State as fact: "X is Y" |
| ⚠️ MEDIUM | 2 sources agree | State with qualifier: "X appears to be Y" |
| 🔴 LOW | 1 source only | State with attribution: "According to [source], X is Y" |
| ❌ CONFLICTED | Sources disagree | Present both sides: "Source A says X, Source B says Y" |

★ Never state a LOW confidence claim as fact.
★ CONFLICTED claims are valuable — include both sides with your analysis of which is more likely correct and why.

### Step 6: Report Synthesis (보고서 합성)

Synthesize ALL learnings into a structured report. Do NOT copy-paste source content — all text must be your synthesis.

```markdown
# Research Report: [Topic]
> Researched: [date] | Sources: [count] | Rounds: [N] | Queries: [N]
> Cross-verified claims: [N verified / N total] | Overall confidence: [HIGH/MEDIUM/LOW]

## TL;DR
[3~5 bullet points — each with confidence indicator]

## Current State (as of [date])
[Cross-verified facts only. Date + source count per claim.]

## Detailed Analysis
[Subsections by theme. Each claim marked with confidence level.]
[Include specific numbers, code examples, architecture patterns.]
[CONFLICTED claims: present both sides with analysis.]

## Comparison Table
[If comparing options — include quantitative metrics where available]

## Recommendations
[Ranked recommendations. Each with: confidence level, supporting evidence count, trade-offs.]

## Gaps & Limitations
[What this research could NOT answer. Where more investigation is needed.]
[Single-source claims that need additional verification.]

## Sources
| # | Source | Date | Type | Cited in | Confidence |
|---|--------|------|------|----------|-----------|
| 1 | [Title](URL) | YYYY-MM | blog/paper/docs/repo | §1,§3 | HIGH |
| 2 | [Title](URL) | YYYY-MM | paper | §2 | HIGH |
```

★ Save report to `_research/[topic-slug]-[date].md` or `_bmad-output/pipeline-audit/` as appropriate.
★ ALL claims must have [source] reference.
★ No "~인 것 같다" or "아마도" — use confidence levels instead.

## Rules
- Never rely on training data alone — always verify with live search
- If a topic has changed rapidly, explicitly note what changed and when
- If the user's topic is vague, ask ONE clarifying question before researching
- Write the report in the same language the user used for the topic
- Minimum: 7 WebSearch + 5 WebFetch + 1 GitHub search per research
- Round 2 is MANDATORY — never skip even if Round 1 seems sufficient
- Cross-verification is MANDATORY — never skip even if sources seem reliable
- Report MUST include Gaps & Limitations section — intellectual honesty

## Quality Self-Check (보고서 작성 후)

Before presenting the report, verify:
- [ ] Every claim has at least 1 source reference
- [ ] Confidence levels assigned to all major claims
- [ ] At least 1 CONFLICTED or LOW claim exists (if everything is HIGH, you're not looking hard enough)
- [ ] Gaps section is non-empty
- [ ] Comparison table includes quantitative data (not just qualitative)
- [ ] Sources table is complete with dates and types
- [ ] No copy-paste from sources — all text is synthesized
