# Suggestion de la semaine — two-column card layout — design brief

## Intent

On weeks where a "Suggestion de la semaine" exists, the Tuesday session card should communicate two parallel, distinct paths without implying hierarchy between the suggestion and the core programme. Today the suggestion sits underneath G1/G2 and G3 as a stacked block, which reads like an afterthought — a footnote to the real session. The redesign proposes a side-by-side layout on wide screens so both paths sit at equal eye-level inside the same card envelope. The left column carries the authoritative track programme; the right column carries the suggestion as a session block that is visually identical in structure to the blocks on the left — same shape, same padding, same white background, differentiated only by its amber left-border accent. The separation should feel like an editorial split — the same DNA as a double-spread magazine article — not like a dashboard widget dropped alongside. On narrow screens the columns collapse to stacked, suggestion below core, exactly as today. On the roughly half of 2026 weeks that have no suggestion, nothing changes: the card remains single-column and no empty gutter appears.

## References

- **Paris Running Club / TheRunDrop** — https://therundrop.com/clubs/paris-running-club-52730564 — borrow the idea of pace-group differentiation within a single event card; visual language that separates "Cool / Mid / Hard" tracks without one looking subordinate to the others
- **Tracksmith Training Journal** — https://www.tracksmith.com/products/hare-ac-training-journal — borrow the ruled-column structure of a physical training log: two columns on the same page-spread, clean vertical divider, mono typeface for data fields, whitespace as the primary visual tool
- **WHOOP Weekly Plan design breakdown** — https://www.925studios.co/blog/whoop-design-breakdown — borrow the progressive-disclosure approach to optional content: the secondary track is presented with equal typographic weight but the same background surface as the primary track, making "optional" legible through the block label alone
- **Circle Sportswear Run Club** — https://circlesportswear.com/en/pages/circle-run-club — borrow the crew-culture tone of clearly labelled session types within a compact card; each programme has its own named section but shares a single card shell
- **Marais Running Club / On Running editorial** — https://www.on.com/en-fr/stories/who-are-the-marais-running-club-movement-mrc-paris-france — borrow the editorial restraint: no heavy borders, no coloured backgrounds fighting each other; quiet dividers let the content breathe

## Visual direction (prose, no code)

**Color:** Neither column carries a tinted background. Both the left and right columns share the same plain white or off-white card surface — the existing card body background. No warm cream wash, no amber fill on the right column wrapper. The suggestion block within the right column uses the same amber left-border accent it already carries, which is sufficient to signal its distinct character. The vertical divider between the columns is a single hairline in the existing bone tone; without a background contrast to do visual work, this hairline becomes the primary separator between the two columns, so it may be rendered marginally more visible than its previous iteration — just enough to read clearly as a column boundary without becoming a hard wall.

**Type:** The suggestion block header ("Suggestion de la semaine") sits at the same visual weight as the G1/G2 and G3 labels — same scale, same uppercase mono treatment — but in the amber tone it already carries. The disclaimer line ("Uniquement pour ceux qui font déjà au moins 3 séances/semaine") lives inside the suggestion block, between the block header and the session content. It steps back one size, rendered in the graphite secondary text colour, set in regular body type rather than the mono accent. It reads as a quiet aside — present and legible, but not demanding to be read first.

**Layout and spacing:** On desktop the card body splits into two columns with a roughly sixty-forty proportion: the left column, holding two distinct session blocks, takes the larger share; the right column, holding the suggestion block, takes the smaller. The first block in the right column starts at the same vertical position as the first block in the left column — top-aligned, no offset. The suggestion block fills its column naturally from the top without being padded to match the height of the taller left column — the asymmetry is honest and fine. The vertical divider runs the full height of the expanded card body. Internal padding inside each column matches the existing block padding used elsewhere in the card, so nothing feels tighter or looser than the current single-column treatment.

**Motion:** No new animation introduced. The card opens and closes with the same accordion behaviour it has today. The two-column layout is visible once the card is open; there is no reveal animation for the columns themselves.

## Copy / labelling

The left-column session blocks use the following titles, applied consistently regardless of whether a suggestion is present that week:

- When there is no group distinction — that is, when no third-group session data exists — the single block is titled **"Séance coeur"**.
- When a group distinction exists — that is, when third-group session data is present — the two blocks are titled **"Séance coeur G1/G2"** and **"Séance coeur G3"** respectively.

The current labels "Groupe 1 / Groupe 2" and "Groupe 3" are replaced by these in every context.

## Acceptance criteria

- [ ] When a session with a suggestion is expanded on a viewport wider than roughly tablet landscape, the card body presents two columns side by side — core session blocks on the left, suggestion block on the right
- [ ] When the same session is expanded on a narrow (phone-width) viewport, the card body stacks vertically: core session blocks first, suggestion below — matching today's mobile behaviour exactly
- [ ] When a session has no suggestion, the card body is visually indistinguishable from its current single-column treatment — no gap, no empty right column, no structural change
- [ ] The right column wrapper has no background fill — the column surface matches the card body background
- [ ] The suggestion block in the right column is visually identical in structure to the G1/G2 and G3 blocks — same white background, same padding, same shape; differentiated only by its amber left-border accent
- [ ] A single hairline vertical divider separates the two columns; it does not appear when the card is in single-column mode
- [ ] The suggestion block header sits at the same typographic scale as the session block labels in the left column
- [ ] The disclaimer ("Uniquement pour ceux…") lives inside the suggestion block, between the block header and the session content — smaller in scale, graphite in tone, no background or border treatment
- [ ] The first block in the right column is top-aligned with the first block in the left column — no vertical offset between them
- [ ] The card header row (date badge, session label, venue, chevron) spans the full width regardless of whether the body is one- or two-column
- [ ] When no group distinction exists, the single session block is labelled "Séance coeur"
- [ ] When a group distinction exists, the two session blocks are labelled "Séance coeur G1/G2" and "Séance coeur G3"
