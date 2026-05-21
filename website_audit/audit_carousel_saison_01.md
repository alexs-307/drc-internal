# Audit — Two-row carousel on the Saison 01 tab

> Architecture audit. Research output, no code written.
> Produced by the EM orchestrator. See `CLAUDE.md` → *Infrastructure audit format*.

---

## 1. Current state

The Saison 01 tab (`index.html:1413-1483`) is an editorial photo layout, not a feed. It uses three composed sections:

- **Hero block** — one large photo (`01-hero.jpg`) + an aside that contains two small photos (grid 2×1) and one wide photo
- **Mosaic** — a 4-column CSS grid (`grid-template-columns: 1.4fr 1fr 1.1fr 1fr`) of 4 photos, each ~240px tall, with a gradient-darkened caption overlay
- **Footer** — text + Instagram link

Photos live in `photos_saison_01/` (8 files, kebab-case names: `01-hero.jpg` through `08-cloture-cycle.jpg`). Each `<img>` carries `loading="lazy"` + `onerror="this.style.display='none'"` (graceful failure if a file is missing). No JS touches this tab — it's pure static markup. Visual language is governed by `.album-*` CSS classes (lines 1052-1262), tied to design tokens `--bone`, `--blue`, `--graphite` and three font families (`--font-display`, `--font-sub`, `--font-mono`).

## 2. Desired state

Two horizontally-scrolling rows added to the Saison 01 tab — one tagged "sports" (training, races, on-track), one tagged "drift" (lifestyle, hangouts, off-track culture). Each row scrolls independently via touch-swipe on mobile and scroll/arrows on desktop. Captions reuse the existing dark-gradient overlay treatment. The carousels live alongside or beneath the existing hero/mosaic — they extend the album, they don't replace it.

## 3. Gap analysis

| Area | Change |
|---|---|
| **Photo sourcing** | Currently 8 photos; carousels need ~10-20 per row to feel populated. New photos go into `photos_saison_01/` (or a sibling folder). Curation/cropping work is out of `implementer` scope — content task. |
| **Tagging** | Need a way to declare which photos belong in which row. Two options: (a) **filename prefix convention** (`sport-*.jpg`, `drift-*.jpg`) — zero JSON, no JS, just a glob-style hardcoded list in HTML; (b) **small manifest** at `photos_saison_01/manifest.json` with `[{file, row, caption}]` — adds one fetch but scales cleanly when content grows. Recommendation: manifest. Mirrors the `sessions.json` pattern that already works well. |
| **Markup** | Two new `<section>` blocks, each containing a `.carousel-row` with N `<figure>` children. Reuse `<figcaption>` + `.title` styling already in use. |
| **CSS** | New rules: `.carousel-row { display: flex; overflow-x: auto; scroll-snap-type: x mandatory; gap: 10px; scrollbar-width: none; }` and `.carousel-row figure { flex: 0 0 auto; scroll-snap-align: start; width: clamp(220px, 35vw, 320px); height: 240px; }`. ~25 lines total, fits the existing `.album-*` family. |
| **JS** | Optional. CSS scroll-snap delivers a usable carousel on its own (touch-swipe on mobile, scroll/drag on desktop). Arrow buttons would need ~40 lines of vanilla JS (`scrollBy()` on click, hide arrows at edges). |
| **Render path** | If using the manifest, fetch it on tab show (or eagerly on page load like `sessions.json`) and inject figures. Mirrors the existing `fetch('sessions.json') → renderSessions()` pattern. |
| **Mobile breakpoint** | The `@media (max-width: 700px)` block at line 1260+ already handles album layout. Carousel widths can shrink there too (e.g. `width: 75vw` so cards take most of the viewport with a peek of the next one). |
| **Accessibility** | `aria-label="Carrousel — moments sport"` on the section, `aria-roledescription="carousel"` on the row container, keyboard arrow-key support if JS arrows are added. Lazy-loading already in use. |

## 4. Risk and complexity

- **Low risk overall.** Additive change, no existing flows broken, no shared CSS modified.
- **Image-weight risk.** Each new photo is ~200-400KB. 30+ photos on one tab = 6-12MB first load. `loading="lazy"` mitigates: only the first row's leftmost few load eagerly. Worth running through an image-optimization pass before adding (WebP, 1200px max width).
- **Scroll-snap UX gotcha.** On Safari, `scroll-snap-align: start` combined with `gap` can leave the last card slightly off-edge. Easy fix with `scroll-padding-inline-end` on the container — implementer will catch in QA.
- **Reversibility.** Fully reversible. Carousels can be removed in one commit.

## 5. Recommended sequence

1. **(content task, Alexandre)** Curate ~15 sport photos + ~15 drift photos. Resize to 1200px wide, WebP if convenient. Drop into `photos_saison_01/`.
2. **PR 1 — manifest + CSS-only carousel.** Implementer adds `photos_saison_01/manifest.json`, the two `.carousel-row` sections in `#tab-saison`, the CSS, and a small JS function that reads the manifest and renders figures. Scroll-snap handles all interaction. ~80 lines diff.
3. **PR 2 (optional) — arrow buttons + edge fade.** Vanilla JS prev/next, hides at scroll endpoints. ~50 lines. Skip if mobile-first is fine and desktop users are comfortable with trackpad scroll.

## 6. Out of scope

- Lightbox / fullscreen zoom on click
- Photo upload UI for members
- Auto-advance / autoplay (rarely well-received, drains battery)
- EXIF parsing for dates/captions
- Per-photo Instagram deep-links

**Effort estimate**: PR 1 ≈ 2-3 hours implementer time once photos are ready. PR 2 ≈ 1-2 hours.
