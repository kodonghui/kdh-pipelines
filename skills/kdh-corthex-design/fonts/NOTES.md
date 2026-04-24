# Fonts

corthex uses two typefaces. Both load via CDN in production; no local `.woff2` files are checked in.

## Pretendard Variable

- **Use:** all UI text (Korean + Latin + numerals).
- **CDN (canonical):** `https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css`
- **License:** Open Font License 1.1 — https://github.com/orioncactus/pretendard
- **Why dynamic-subset:** Korean 완성형 only, roughly one-quarter the weight of the full subset. Latin and numerals come through the Variable file.
- **Required font-feature-settings on `<body>`:** `"ss01" 1, "ss02" 1, "rlig" 1, "calt" 1, "tnum" 1` — proper Korean hinting + tabular numerals.

## JetBrains Mono

- **Use:** numbers, code blocks, model IDs, stream output, token counts.
- **CDN (canonical):** `https://cdn.jsdelivr.net/gh/JetBrains/JetBrainsMono/web/css/jetbrains-mono.css`
- **CDN (design-system previews):** `https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap`
- **License:** Open Font License 1.1 — https://github.com/JetBrains/JetBrainsMono
- **Weights used:** 400 (code blocks), 450 (inline code — Variable interpolation), 500, 600.

## Prohibited primary faces

Inter · Roboto · Arial · Helvetica · Space Grotesk · Noto Sans · Spoqa Han Sans · Open Sans · system-ui.

They strip Korean hinting and read as generic AI output (`DESIGN.md §3` · `§7.1 🚫 Typography`). Do not substitute.
