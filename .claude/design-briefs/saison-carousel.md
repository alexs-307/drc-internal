# Saison 01 carousel — design brief

## Intent
We are adding a single horizontally-scrolling row of ten photo slots as the closing act of the Saison 01 album, placed between the mosaic section and the Instagram footer. The row should feel like a contact sheet being pulled from the archive — unhurried, slightly cinematic, a natural exhale after the denser mosaic above. Because the photos are not yet loaded, every slot must render as a visible, numbered placeholder that communicates "image incoming" rather than "something broke". The row earns its place by extending the editorial narrative without competing with the mosaic; it is deliberately lighter and more spacious in feel.

## References
- Ciele Athletics — https://cieleathletics.com/pages/ciele-athletics-pictures — tonal restraint in sports photo presentation; letting images carry the weight without decorative framing
- Dribbble horizontal scrolling carousel — https://dribbble.com/search/horizontal-scrolling-carousel — card-peek convention showing roughly one quarter of the next card to signal scrollability
- Format.com editorial horizontal scroll — https://www.format.com/magazine/resources/photography/horizontal-scrolling-templates — film-strip rhythm: equal-width cards, consistent gap, no variation in card height within a row
- Justinmind carousel UI best practices — https://www.justinmind.com/ui-design/carousel — accessibility labelling patterns for scroll regions; using the container label as the primary orientation cue rather than visible controls
- Lovable scrolling design patterns — https://lovable.dev/guides/scrolling-designs-patterns-when-to-use — affirms that a scroll-snap strip without arrows works when the partial-card peek is generous enough to be unmistakable

## Visual direction

**Placeholder tile aesthetic.** Each empty slot should feel like unexposed film: a quiet, warm-toned tile using the existing off-white bone colour as the base, overlaid with a very subtle diagonal texture that echoes the grid motif already present in the site's wider identity. At the centre of the tile, the slot number is printed in the monospaced display family — zero-padded, two digits, all caps — in the muted graphite tone, large enough to be legible at a glance but not so large it becomes decorative. Below the number, a single line of faint uppercase mono text reads "PHOTO À VENIR" in the same graphite, at the smallest size the mono font supports while remaining readable. When a real image is later assigned to a slot, it covers the tile entirely via the same object-cover treatment used on all mosaic photos; the placeholder disappears without any structural change.

**Carousel proportions and rhythm.** Cards should be portrait-leaning — roughly the same aspect ratio as the hero photo, narrower than they are tall — so the strip has a film-contact-sheet quality. On a wide desktop viewport, approximately three and a half cards should be visible at once, meaning a clean slice of the fourth card peeks into view at the right edge to signal the row continues. The gap between cards should be tight but breathing — the same gap used between mosaic cells, not wider. The overall height of the row should sit noticeably shorter than the mosaic section above: the mosaic is the dense, editorial centrepiece; the carousel is the lighter coda. Visually the row should feel one step quieter and airier.

**Section header.** The row should have its own section heading in the same style as "La course mais pas que" — uppercase, subdued, display-sub family at the same scale. Recommended heading: **"Et tout le reste"** — it positions this strip as the informal overflow of the season's archive, which is exactly right for a placeholder-heavy row that will fill in over time.

**Caption treatment.** Reuse the mosaic's dark-gradient overlay caption exactly: a bottom-anchored gradient from transparent to a semi-opaque black, with the caption title in the uppercase sub family at the smaller of the two caption sizes used in the mosaic. Because cards are narrower than mosaic cells, captions should be kept to one short line; a title that wraps looks cramped at this card width.

**Mobile behaviour.** At the medium breakpoint, each card should occupy roughly three-quarters of the viewport width, leaving a clear quarter-card peek at the right edge. At the smallest breakpoint, cards can grow to about eighty percent of viewport width — enough that the image reads as a genuine photo, not a thumbnail — with the same quarter-peek. The row should never be wider than the page container; no overflow bleed beyond the content margins.

**Accessibility.** The scrollable region should carry an accessible label in French identifying it as the photo strip — something like "Galerie — moments de la saison". The container should declare a carousel role description so assistive technology announces it correctly rather than as a generic list. Each figure carries its alt text or slot-number as a text alternative when the image is absent.

## Acceptance criteria
- [ ] Ten numbered tiles render visibly without any images present; each shows its two-digit slot number and a "PHOTO À VENIR" label
- [ ] The row appears after the mosaic section and before the Instagram footer, with consistent vertical spacing matching the gap above the mosaic
- [ ] A section heading "Et tout le reste" appears above the row in the same typographic style as "La course mais pas que"
- [ ] On desktop, at least three full cards and a partial fourth are visible simultaneously without scrolling
- [ ] Swiping or scrolling within the row moves through cards with snap-to-card behaviour; there are no arrow buttons or dot indicators
- [ ] Placeholder tiles use the bone background tone with a graphite slot number — no harsh contrast, no white or blue fill
- [ ] Caption overlay on a populated card matches the dark-gradient bottom-anchor treatment of the mosaic above
- [ ] On a viewport below the medium breakpoint, each card occupies roughly three-quarters of viewport width with a clear peek of the next card
- [ ] No horizontal scrollbar appears at the page level; only the carousel strip scrolls horizontally
