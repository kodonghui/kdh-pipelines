# Corthex Design System

**Operator's Atelier** — quiet confidence + editorial typographic pride + instrument heft.

This is the design system for **corthex**, a multi-agent orchestration console for Korean small- and medium-sized enterprises (SMEs). It is an operator's daily driver — a precision instrument the professional chose deliberately. Not a marketing surface. Not a consumer product.

Canonical source of truth: [`DESIGN.md`](https://github.com/kodonghui/corthex-v3/blob/main/DESIGN.md) in `kodonghui/corthex-v3`. Everything here derives from it. If this file and DESIGN.md conflict, DESIGN.md wins.

---

## Who uses corthex

| Role | Session pattern | Daily hours |
|------|-----------------|-------------|
| **Primary — Korean SME CEO** | Natural-language delegation, approval, oversight | **6–10 h** |
| **Employees (2–15 per company)** | Purpose-driven bursts | 15 min – 2 h |

Mental model: **Bloomberg Terminal** for a trader · **Linear** for a staff engineer · **Figma** for a designer. A tool the operator already chose. The design must honor that commitment by being worth their long-session attention.

---

## What corthex does

The CEO types a request in Korean ("이번 주 매출 분석해줘"). A **Chief-of-Staff agent (비서)** classifies intent, decomposes the work into parallel sub-tasks, dispatches each to the right specialist (legal / analysis / ops / marketing / engineering / admin), aggregates output against a 5-criteria QA checklist (accuracy · completeness · clarity · feasibility · format), and returns one synthesized report.

Every agent has a visible personality, a growing memory, and an observable execution state (thinking / tool-call / streaming / complete).

---

## Sources

- **Repo (single source of truth):** `kodonghui/corthex-v3` → `DESIGN.md`, `README.md`, `ROADMAP.md`, `CLAUDE.md`
- **App package:** `packages/app/src/` (React 18 + Vite + shadcn/ui + Tailwind)
- **Admin package:** `packages/admin/src/`
- **Index CSS (live tokens):** `packages/app/src/index.css`
- **Reference Phase-3 session (archived):** `api.anthropic.com/v1/design/h/wR5N2EKIacgeE0tiiPX1TA`

Treat this design system as read-only mirroring of the above — do not invent new direction here.

---

## Index

| File | What's inside |
|------|---------------|
| `README.md` | This file — context, CONTENT FUNDAMENTALS, VISUAL FOUNDATIONS, ICONOGRAPHY |
| `colors_and_type.css` | CSS custom properties for Paper / Carbon / Signal + full type scale + spacing + shadows |
| `SKILL.md` | Agent-skill entry point — read this to start a design with the corthex brand |
| `preview/` | Design-system cards (Type, Colors, Spacing, Components, Brand) |
| `ui_kits/console/` | Corthex Console recreation — sidebar, hub chat, routing panel, profile, activity log |
| `assets/` | Logos and brand marks |
| `fonts/` | Font license / source notes (Pretendard + JetBrains Mono load via CDN) |

---

## CONTENT FUNDAMENTALS

### Language + voice

- **Korean first, English ready.** The interface is Korean by default. English is reserved for code, commit messages, technical docs, and internal identifiers.
- **Tone:** 존댓말 (polite formal). Calm, direct, operator-to-operator. No exclamation marks. No cheerleading. No "🎉 awesome!" copy.
- **Second person:** Korean uses the implied subject — rarely "당신". Prefer action-first sentences: "저장했어요" not "저는 저장했어요".
- **First person:** The product does not refer to itself as "we" or "corthex". Agents speak in their own voice through their role prompt; chrome UI speaks in the passive of events: "저장됐어요" / "연결이 끊겼어요".
- **Sentence endings:** "-어요 / -아요" is the default register. "-습니다 / -십니다" only in legal/terms copy. Never "-다" (too blunt for 6–10 hours of continuous use).

### Casing + punctuation

- **Brand name:** `corthex` — lowercase, always. Never `Corthex`, never `CORTHEX` in product chrome (the repo uses uppercase; product UI does not).
- **Em dash:** `—` (U+2014) with **no surrounding space** → `에이전트—직원` · `Paper—default light`.
- **Ellipsis:** `…` (single U+2026 character). Never three dots `...`.
- **Quotation marks:** `"` `"` for both Korean and Latin body. Single `'` `'` for nested quotes.
- **Numbers:** Always tabular (`font-variant-numeric: tabular-nums`) so columns align at six-hour gaze. Korean counter words: `3개`, `5명`, `10개 화면`.

### Casing in Latin identifiers

- File names: `kebab-case.tsx`
- React components: `PascalCase`
- CSS tokens: `--kebab-case-in-hsl`
- API payloads: `snake_case` on the wire, `camelCase` in JS

### Examples — correct vs wrong

| ✅ Correct | 🚫 Wrong | Why |
|-----------|---------|-----|
| `세션이 만료됐어요` | `세션이 만료되었습니다!` | 존댓말 -어요 over -습니다; no exclamation |
| `다시 로그인해주세요. 5초 후 자동으로 이동합니다.` | `로그인 세션이 종료되었습니다. 🔒 지금 다시 로그인하세요!` | no emoji, no alarm tone |
| `이 에이전트와 대화를 시작하세요` | `🚀 AI 에이전트와 대화 시작!` | instrument voice, not marketing |
| `요청이 많아요. 12초 후 다시 시도해주세요.` | `Too many requests - please try again` | Korean first; concrete number |
| `corthex` | `Corthex` · `CORTHEX` | lowercase brand in UI |

### Emoji policy

**Not used.** Status is shown through typographic labels and small colored dots (`.dot-status`, see `colors_and_type.css`). Emoji status indicators are forbidden (`DESIGN.md §7.1 — NEVER list item 6`).

### Writing checklist before shipping any copy

1. Is it 존댓말 and ending in `-어요/-아요`?
2. Any exclamation marks? → remove.
3. Any emoji? → remove.
4. Any "we" / "our" / "당신"? → rewrite impersonally.
5. Brand spelled `corthex` lowercase?
6. Em-dashes with no space · ellipsis `…` not `...`?
7. Numbers tabular and concrete (not "잠시 후" — state the seconds)?

---

## VISUAL FOUNDATIONS

### Color system

- **Near-monochrome backgrounds** in every theme. Color is a **signal**, never a wash. No brand-washed cards. No gradient surfaces in work areas.
- **One primary** (action-inducing only): Paper = deep ink blue `#1B2A4A` · Carbon = luminous ice blue `#5FA8F7` · Signal = burnt sienna `#C23E15`.
- **One destructive** (`#B32534` dim red — not alarm) · **one success** (`#257A51` forest green — not neon) · **one warning** (amber) · **one info** (slate blue).
- **Contrast:** every foreground/background pair verified WCAG AA (≥ 4.5:1). Paper body = 14.2:1. Carbon body = 13.1:1. Signal primary on primary-foreground = 5.3:1.
- **Gradients + noise:** allowed **only** on login / onboarding shell. Forbidden on Card, Button, Dialog, Sidebar — those stay flat.
- **Never:** purple gradient on white (Anthropic AI-slop #2), brand color on large surfaces (hero backgrounds, sidebar backgrounds), any hex/rgb hardcoded in components — use `hsl(var(--…))` only.

### Typography

- **Pretendard Variable** for all UI text (Korean + Latin + numerals). Loaded via jsDelivr dynamic-subset (Korean 완성형 only → 1/4 the byte weight).
- **JetBrains Mono** for numbers, code, model IDs, stream output, token counts. Google Fonts CDN, weights 400/500/600.
- **Four distinct voices:** display / heading / body / monospace. Information stratifies by **type weight**, not by color.
- **Scale (px / line-height / tracking / weight):** see `colors_and_type.css`. Base body is 15px (Korean hinting optimum — Pretendard 15 ≈ Latin 16 optically).
- **Prohibited faces:** Inter, Roboto, Arial, Helvetica, Space Grotesk, Noto Sans, Spoqa Han Sans, Open Sans, system fonts. Violating this is treated as AI-slop surrender.
- **Numerals:** `font-variant-numeric: tabular-nums` for every stat, count, timestamp, token figure.
- **Dashes + ellipsis:** `—` no-space, `…` single glyph.
- **Korean font features:** `"ss01" 1, "ss02" 1, "rlig" 1, "calt" 1, "tnum" 1` on `<body>`. Non-negotiable.

### Spacing + layout

- **8-pixel rhythm, 4-pixel sub-atomic.** Allowed values: 4, 8, 12 (list gap only), 16, 24, 32, 40, 48, 56, 64.
- **Component-height exceptions:** buttons/inputs at 32 / 36 / 44 (WCAG touch-target + optical balance).
- **Sidebar:** 256 px fixed (32 × 8 — perfect 8-multiple).
- **Page padding:** 32 desktop / 16 mobile. **Card padding:** 24 desktop / 16 mobile.
- **Breakpoints:** `mobile 0 / tablet 768 / desktop 1024 / wide 1440`. Tailwind custom `wide:` prefix — we do **not** override Tailwind's `2xl` (1536).
- **Layout rule:** left-align long-form body. Center only display text. Asymmetric column widths allowed (narrow sidebar, wide main) — forced center-align is banned.

### Backgrounds

- **No background images** in work areas. No dot-matrix, no mesh, no animated gradient, no glassmorphism blur as default chrome.
- **Warm paper** (`#FAF9F6`) for Paper / Signal. **Deep graphite** (`#15171B` — never pure `#000`) for Carbon.
- Login / onboarding shell **may** use a single subtle noise or a very low-contrast gradient — only those two screens, and only then.

### Animation + motion

- **Punctuation, not performance.** Transitions ≤ 150 ms, `ease-out` or `cubic-bezier(0.16, 1, 0.3, 1)`.
- **Forbidden:** parallax, scroll-jacking, bounce, elastic easing, decorative loops, hover-lift on cards, wiggle on idle, pulse on hero, scanning effects.
- **Allowed motion:** fade (opacity only), 1–2 px translate on press, accordion height, skeleton pulse at 500 ms, streaming cursor `▌` at 500 ms blink.

### Hover + press + focus states

- **Hover (buttons):** `opacity: 0.9` on primary · `bg-accent` swap on ghost · `bg-muted` on outline.
- **Hover (nav item):** `bg-sidebar-accent` swap. Never lift with shadow.
- **Active/press:** `translate-y: 1px` for solid buttons; opacity 0.85. No shrink/scale.
- **Focus-visible:** `outline: 2px solid hsl(var(--ring)); outline-offset: 1–2px;`. Never `:focus` alone (mouse users would see rings).
- **Disabled:** `opacity: 0.5; cursor: not-allowed`. Color stays; don't also mute.

### Borders

- **1 px solid** `hsl(var(--border))` everywhere. No 2 px or 3 px strokes.
- Input borders match card borders — same `--border` token; `--input` is reserved for future divergence.
- **Alerts** use a 4 px left accent bar in the semantic color (`border-l-4 border-l-warning`) with a 5 % tinted fill (`bg-warning/5`). This is the only "accent border" pattern used.

### Shadows

- **Elevation only.** Never used as decoration.
- Scale: `none / sm / md / lg / xl / inner`. Carbon uses blacker shadows since the background is already dark.
- **Z-layers:** Card resting `sm` · Card hover `md` · Popover/Tooltip `md` (z 50/60) · Dialog/Sheet `xl` (z 70) · Toast `lg` (z 90).
- **Forbidden:** `shadow-2xl`, colored glows (blue/purple), neumorphism, multi-layer decorative shadows.

### Corner radii

- Base `--radius: 8px` (0.5 rem). 12 px retired 2026-04-18 — "too soft for instrument feel."
- Tokens: `none 0 / sm 4 / md 6 / base 8 / lg 12 (special feature cards only) / full 9999 (avatar, pill)`.
- **Buttons, cards, inputs, dialogs all use 8 px.** Consistency is the point.

### Transparency + blur

- **Sparingly.** Dialog overlay: `bg-background/80 backdrop-blur-[2px]`. That's the only default-chrome place blur appears.
- Semantic tints for alerts: `bg-{variant}/5` or `/10`. Never `/50` — we never stack UI on top of UI.
- No frosted-glass sidebar. No translucent headers.

### Imagery

- The product ships **very little imagery**. Avatar fallbacks are single-letter monograms (`h4 font-semibold`) on `bg-muted`. No stock photos.
- If a marketing screen ever needs imagery: warm, matte, understated. No cool-blue tech stock. No hand-drawn illustration.

### Fixed UI elements

- Sidebar (desktop): fixed 256 px, full height, `bg-sidebar-background`. Collapses to a `Sheet` drawer below 768 px with a top-left hamburger trigger (44 × 44 px).
- Mobile header: 56 px tall, one-row.
- Toasts (Sonner): top-right, stacked, auto-dismiss 4 s.
- Session-expired Dialog: centered, `max-w-sm`, backdrop-blur 2 px — cannot be closed by backdrop click.

### Density

**Medium-high.** Linear > Notion > Toss. Whitespace must earn its place — the operator is here 6–10 h/day. Dense but never cramped; hierarchy spaces groups at 24 px, sections at 48 px, items within a group at 8 px.

---

## ICONOGRAPHY

- **Library:** **Lucide React** (`lucide-react` — the same set the repo uses). Line-style, 1.5 px stroke default, rounded line-caps.
- **Size scale:** `12 / 14 / 16 / 20 / 24 / 28 / 40 / 48 px`. Inline-with-body-text is 16 px. In 9 px-high buttons, icon is 16 px. Section-empty-state icon is 48 px `stroke-[1.25]` (thinner, decorative-weight).
- **Color:** icons inherit `currentColor` and thus the text color around them. Never tint icons with a hue other than the parent text token.
- **Stroke:** default `stroke-width: 1.5`. Thin-decorative (empty-state, large hero icons) `1.25`. Do not use `stroke-2` — too chunky for the Atelier feel.
- **Accessibility:** every icon-only button carries an `aria-label`. Tooltips (400 ms delay, desktop only) give a visible hint on hover.
- **Emoji:** never used as icon. Unicode symbols used **only** for typographic purposes: `▌` (streaming cursor), `—` (em dash), `…` (ellipsis), `·` (middle-dot separator).
- **Delivery:** corthex imports lucide-react tree-shaken from npm. In this design system, we link from the CDN (`https://cdn.jsdelivr.net/npm/lucide@latest/dist/umd/lucide.js`) so previews work offline of the corthex monorepo. Substitution noted: **none** — Lucide is the source the product uses.
- **Custom marks / logos:** see `assets/corthex-wordmark.svg`. The wordmark is **always lowercase `corthex`**, Pretendard 700, letter-spacing -0.02 em, no glyph/icon accompaniment. There is no standalone symbol mark — the wordmark is the logo.

### When to use an icon vs a word

| Situation | Choice |
|-----------|--------|
| Single action in a toolbar row | **Icon + tooltip** (aria-label mandatory) |
| Navigation item in sidebar | **Icon 16 px + label**, gap 8 px |
| Empty state | **Icon 48 px stroke-[1.25]** + title + description + CTA |
| Status (agent running, idle, error) | **Colored `.dot-status` + text label** — never icon alone |
| Form field | **Label only.** Icon inside input only for semantic affordance (search = Search icon) |

---

## Caveats + things flagged

- **No custom logotype SVG existed in the repo** — I generated a simple wordmark (`assets/corthex-wordmark.svg`) that follows the rule "lowercase Pretendard 700, tracking −0.02 em, no symbol." If there is a canonical one, please drop it in `assets/` and I'll swap.
- **JetBrains Mono** is loaded from Google Fonts (not jsDelivr) for preview reliability. In production, the repo uses `jetbrains-mono.css` via jsDelivr — functionally equivalent.
- **Pretendard Variable** is linked from CDN. No local `.woff2` in `fonts/` — the repo's canonical practice is the CDN import. `fonts/` contains only a NOTES.md pointing to the source.
- **Lucide icons** not copied as SVG files — they're consumed at runtime in the UI kit from the CDN. This matches how the product consumes them (tree-shaken from `lucide-react`).
- **UI kit is a cosmetic recreation**, not the production codebase. Components are modular JSX but do not implement real SSE / API flows — they fake the data shape visible to the operator.
