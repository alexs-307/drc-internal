# Suggestion de la semaine — two-column card layout — design brief

## Intent

On weeks where a "Suggestion de la semaine" exists, the Tuesday session card should communicate two parallel, distinct paths without implying hierarchy between the suggestion and the core programme. Today the suggestion sits underneath G1/G2 and G3 as a stacked block, which reads like an afterthought — a footnote to the real session. The redesign proposes a side-by-side layout on wide screens so both paths sit at equal eye-level inside the same card envelope. The left column carries the authoritative track programme (G1/G2 and G3); the right column carries the suggestion, visually cordoned off as an optional, solo-friendly alternative. The separation should feel like an editorial split — the same DNA as a double-spread magazine article — not like a dashboard widget dropped alongside. On narrow screens the columns collapse to stacked, suggestion below core, exactly as today. On the roughly half of 2026 weeks that have no suggestion, nothing changes: the card remains single-column and no empty gutter appears.

## References

- **Paris Running Club / TheRunDrop** — https://therundrop.com/clubs/paris-running-club-52730564 — borrow the idea of pace-group differentiation within a single event card; visual language that separates "Cool / Mid / Hard" tracks without one looking subordinate to the others
- **Tracksmith Training Journal** — https://www.tracksmith.com/products/hare-ac-training-journal — borrow the ruled-column structure of a physical training log: two columns on the same page-spread, clean vertical divider, mono typeface for data fields, whitespace as the primary visual tool
- **WHOOP Weekly Plan design breakdown** — https://www.925studios.co/blog/whoop-design-breakdown — borrow the progressive-disclosure approach to optional content: the secondary track is presented with equal typographic weight but a softer background surface, making "optional" legible without using the word
- **Circle Sportswear Run Club** — https://circlesportswear.com/en/pages/circle-run-club — borrow the crew-culture tone of clearly labelled session types within a compact card; each programme has its own named section but shares a single card shell
- **Marais Running Club / On Running editorial** — https://www.on.com/en-fr/stories/who-are-the-marais-running-club-movement-mrc-paris-france — borrow the editorial restraint: no heavy borders, no coloured backgrounds fighting each other; quiet dividers let the content breathe

## Visual direction (prose, no code)

**Color:** The left column needs no new surface treatment — it inherits the existing card background and the already-established blue and purple left-border accents on the G1/G2 and G3 blocks. The right column should sit on the warm, slightly tinted surface that the suggestion block already uses today — a faint cream-amber wash, noticeably lighter than the amber accent on the block title but clearly distinct from the plain white of the left column. This creates a soft thermal contrast: cool-white on the left, warm-cream on the right. The vertical divider between the columns should be a single hairline in the existing bone colour — barely-there, enough to articulate the split without looking like a hard wall.

**Type:** The suggestion column header ("Suggestion de la semaine") should sit at the same visual weight as the G1/G2 and G3 labels — same scale, same uppercase mono treatment — but in the amber tone it already carries. The disclaimer line ("Uniquement pour ceux qui font déjà au moins 3 séances/semaine") should step back one size, rendered in the graphite secondary text colour, set in regular body type rather than the mono accent. It reads as a quiet aside, not a headline.

**Layout and spacing:** On desktop the card body splits into two columns with a roughly sixty-forty proportion: the left column, holding two distinct session blocks, takes the larger share; the right column, holding one suggestion block, takes the smaller. The columns share top-alignment. The suggestion block in the right column fills its column naturally from the top, without being padded to match the height of the taller left column — the asymmetry is fine and honest. The vertical divider runs the full height of the expanded card body. Internal padding inside each column matches the existing block padding used elsewhere in the card, so nothing feels tighter or looser than the current single-column treatment.

**Motion:** No new animation introduced. The card opens and closes with the same accordion behaviour it has today. The two-column layout is visible once the card is open; there is no reveal animation for the columns themselves.

## Week indicator

The indicator is in. The chosen format is a short date range: "5–11 mai" (day numbers flanking an en-dash, month in lowercase). This reads immediately in French without any mental translation — unlike an ISO week number like "S20", which is compact but opaque for non-technical club members who have no reason to think in ISO weeks.

**Placement:** The indicator lives inside the card body, flush to the top-left, above the G1/G2 block and above any column structure. It occupies its own quiet line before the session content begins — a preamble, not a header element. The header row (date badge, session label, venue chip, chevron) is left entirely untouched.

**Visual weight:** The indicator should be noticeably smaller than the existing date badge in the header — roughly the size of the disclaimer text or the venue chip label. It is rendered in the same muted graphite tone used for secondary text and inactive labels throughout the site, not in the amber accent or the deep blue. No background chip, no border, no pill shape. The lettering follows the same spaced uppercase mono style used elsewhere for quiet metadata in the card, but at a reduced size so it sits clearly below the visual hierarchy of the session labels. It should feel like a marginal note in a printed race programme — present and useful, but not asking to be read first.

**Scope:** Every Entrainement tab session card gets the indicator, regardless of whether a suggestion exists that week. It is a consistent navigation anchor for the full list, not a feature of the two-column layout.

## Acceptance criteria

- [ ] When a session with a suggestion is expanded on a viewport wider than roughly tablet landscape, the card body presents two columns side by side — core session blocks on the left, suggestion block on the right
- [ ] When the same session is expanded on a narrow (phone-width) viewport, the card body stacks vertically: core session blocks first, suggestion below — matching today's mobile behaviour exactly
- [ ] When a session has no suggestion, the card body is visually indistinguishable from its current single-column treatment — no gap, no empty right column, no structural change
- [ ] The right column has a visibly warmer background surface than the left column, but neither reads as a strong accent colour — the difference is subtle, a tint not a fill
- [ ] A single hairline vertical divider separates the two columns; it does not appear when the card is in single-column mode
- [ ] The suggestion column header sits at the same typographic scale as the G1/G2 and G3 labels in the left column
- [ ] The disclaimer ("Uniquement pour ceux…") is visually subordinate to the suggestion content — smaller, quieter, in secondary text colour
- [ ] The card header row (date badge, session label, venue, chevron) spans the full width regardless of whether the body is one- or two-column
- [ ] Every session card in the Entrainement tab shows a week date range indicator (e.g. "5–11 mai") in the card body, above the session content
- [ ] The week indicator reads as clearly subordinate to both the date badge and the session labels — smaller in scale, graphite in tone, no background or border treatment
