---
name: kdh-corthex-design
description: "Corthex 디자인 토큰, 테마, 타이포, UI kit 조회."
user-invocable: true
---

# corthex design skill

> **Scope:** This skill READS the Claude Design handoff bundle (mYPQJITG pages + NDPK design system).
> It does NOT generate new designs — new designs come from Claude Design (claude.ai/design) + handoff bundles.
> Use this skill to answer "what are the brand tokens / themes / components / motion rules?" during dev work.

Read `README.md` first — it covers product context, content fundamentals, visual foundations, and iconography. Then explore:

- `colors_and_type.css` — all CSS custom properties in HSL (three themes — Paper default, Carbon dark, Signal accent). Import this from any HTML artifact.
- `assets/` — wordmarks (SVG). Icons use Lucide via CDN at stroke-width 1.5px.
- `preview/` — small reference cards for tokens, scales, and components.
- `ui_kits/console/` — React components for the hub chat, sidebar, profile, and activity log. Read `index.html` to see composition.

## Non-negotiables
- Never revive the retired themes (brand / toss-light / toss-dark / green / cherry-blossom). Never ship purple-on-white gradients or Toss-style pastel rounded-fintech palettes.
- Primary font stack is Pretendard Variable for UI + JetBrains Mono for numbers/code. Do NOT use Inter, Roboto, Arial, Open Sans, or system fonts as primary face — Korean hinting is lost.
- Color is a signal, never a wash. Monochrome backgrounds; identity ink blue primary; destructive dim red; success forest green. No gradient surfaces in work areas.
- Everything snaps to the 8px grid (8 / 16 / 24 / 32 / 40 / 48 / 56 / 64). Buttons 32 / 36 / 44. Radius 8 default, 4 tight, 9999 pill.
- Motion is punctuation: transitions ≤ 150ms ease-out. No bounce, no hover-lift, no parallax, no decorative loops.
- Density is medium-high. Linear > Notion > Toss. Whitespace earns its place.

## If the user invokes this skill without guidance
Ask what they want to build (slide, mock, full prototype, or production code guidance). Ask which theme (Paper / Carbon / Signal). Ask language (Korean default; English available). Then act as an expert corthex designer.

When producing HTML artifacts, copy `colors_and_type.css` and relevant `ui_kits/console/*.jsx` files into the artifact's folder and reference them directly. When producing production guidance, cite the CSS variables and tokens rather than inlining hex values.
