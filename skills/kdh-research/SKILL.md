---
name: kdh-research
description: "/kdh-research — Deep Research Command"
---

# /kdh-research — Deep Research Command

When the user invokes `/kdh-research [topic]`, execute a comprehensive, multi-source deep research operation.

## Core Directive

Research the given topic with these mandatory qualities:
- **Latest**: Only use current, up-to-date information. Verify publication dates. Reject outdated sources.
- **Accurate**: Cross-reference across multiple sources. Flag conflicting claims. Cite sources.
- **Popular/Trending**: Prioritize widely-adopted, battle-tested, community-validated approaches. Include GitHub stars, npm downloads, adoption metrics where relevant.
- **Comprehensive**: Cover the topic from multiple angles — not surface-level summaries.
- **Detailed**: Include specific numbers, code examples, architecture diagrams, comparison tables.

## Execution Steps

1. **Web Search** — Use WebSearch for broad discovery (3-5 queries with different angles)
2. **Deep Dive** — Use WebFetch to read the most relevant 5-10 sources in full
3. **GitHub Search** — Use `gh search repos` and `gh search code` for real implementations and adoption metrics
4. **Package Registry Check** — Search npm/PyPI/crates.io for relevant libraries, check download counts
5. **Documentation Lookup** — Use Context7 MCP (`/docs`) for official framework/library docs if applicable
6. **Synthesis** — Combine all findings into a structured analysis report

## Output Format

```markdown
# Research Report: [Topic]
> Researched: [date] | Sources: [count] | Confidence: [high/medium/low]

## TL;DR
[3-5 bullet points — the key findings]

## Current State (as of [date])
[What exists today, adoption numbers, key players]

## Detailed Analysis
[Deep breakdown with subsections as needed]

## Comparison Table
[If comparing options/tools/approaches — structured table]

## Recommendations
[Ranked options with pros/cons and clear winner]

## Sources
[Numbered list of all sources with URLs and access dates]
```

## Rules
- Never rely on training data alone — always verify with live search
- If a topic has changed rapidly (AI, frameworks, etc.), explicitly note what changed and when
- Include real GitHub repos, real npm packages, real adoption numbers
- If the user's topic is vague, ask ONE clarifying question before researching
- Write the report in the same language the user used for the topic
- Save the report to `_research/[topic-slug]-[date].md` if in a project directory
