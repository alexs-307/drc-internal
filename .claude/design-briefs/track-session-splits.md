# Track session intermediate splits — design brief (v2)

> v1 (always-on inline split rows) was rejected: the permanently visible split data
> fragmented the description and made sessions harder to read. v2 adopts on-demand
> disclosure. The inline `.vma-splits` treatment is abandoned entirely.

## Intent

Each session card gains a single, unobtrusive toggle that reveals a "Temps de passage"
panel on demand. By default the session description reads exactly as it does today —
clean mono text with the existing blue and amber badges. A member who wants lap checkpoints
taps the toggle; everyone else never sees the data. The panel is a reference table, not
a badge swarm — it should feel like flipping to the back of a training booklet.

## References

- **Strava Workout Analysis (lap breakdown)** — https://communityhub.strava.com/insider-journal-9/running-workout-analysis-guide-1491 — borrow the two-column pattern of landmark label and time side-by-side in a muted secondary register, subordinate to the main activity headline
- **Tracksmith brand typography** — https://fontsinuse.com/uses/43122/tracksmith — borrow the discipline of keeping secondary reference data in a smaller, quieter weight so the headline effort reads first; size and weight differential carries hierarchy without additional color
- **Bootstrap Icons: Stopwatch** — https://icons.getbootstrap.com/icons/stopwatch/ — the stopwatch glyph; compact, universally legible, zero cultural noise for a French running club
- **Headless UI Disclosure pattern** — https://headlessui.com/react/disclosure — borrow the single-button open/close mental model: one control, one panel, no ambiguity about what expands
- **NYRR Training Plans** — https://www.nyrr.org/train/runner-resources-hub/training-plans/training-plans — borrow the coach-printout convention of tight two-column pace reference tables that sit outside the workout narrative proper

## Visual direction

**The toggle control.** Three candidates:

1. A stopwatch/chronometer glyph (Unicode or inline SVG) paired with the label "Temps de passage". Communicates "timing data lives here" without any explanation. Fits the club's restrained tone because it is a tool glyph, not a decorative icon.
2. A flag or lap-marker glyph alongside "Temps de passage". Communicates "checkpoint" well for track runners, though it skews slightly more playful than the site's current register.
3. A bare downward chevron with the label "Temps de passage". Maximally minimal but risks looking identical to the parent accordion's own chevron, which would confuse the two levels.

**Recommend the stopwatch glyph (candidate 1)** paired with the short French label "Temps de passage". The glyph earns the label; the label earns the glyph. Together they leave no ambiguity about the data type. Place the control flush to the bottom-right of the session content block — after the last line of the description, right-aligned — so it never interrupts reading. In its resting state the control uses the existing muted secondary text tone: present but quiet. When the panel is open, the stopwatch glyph picks up the site's blue — the same blue used for the rep-total badges — signalling "this is active." The label text does not change; only the icon color shifts. No chevron rotation on this control; it would mimic the parent accordion too closely.

**The disclosed panel.** The panel sits directly below the session content block, separated from it by a thin hairline in the existing border tone — the same quiet rule used elsewhere to divide sections. Inside the panel, reps are grouped individually: each qualifying rep gets a small, all-caps label in the muted graphite tone (e.g. "1000M À 90% VMA") followed immediately by its passage row. The passage row is a compact two-column table: the left column holds the landmark distance (e.g. "300m", "600m", "900m") and the right column holds the target time. Both columns use the monospaced family already used for session content, at a size one step smaller than the main session text. The landmark distances are right-aligned within their column; the times are left-aligned in theirs — this mirrors the "label : value" cadence familiar from a splits sheet. Multiple reps stack vertically with a modest gap between them, enough to tell them apart without heavy dividers.

Timed blocks (e.g. "3' à 90% VMA") are treated identically in structure but their rep label should carry a brief parenthetical clarifier — something like "estimé" — to signal these are pace-derived estimates, not fixed checkpoints. No extra color or badge; the word alone is enough. Both columns keep the same layout.

**Color and type.** The panel background uses the existing off-white site background rather than white, so it reads as a slightly recessed reference layer beneath the white card surface. The landmark labels and time values inherit the existing graphite secondary tone — quieter than the blue and amber badges but not invisible. Nothing in the panel introduces a new color. The existing blue surfaces only on the active toggle icon.

**Motion.** The parent card accordion expands with no animation (display:none toggled to display:block). The passage-time panel should use a soft max-height transition — a gentle vertical unfurl, slightly slower than an instant snap but not theatrical. This keeps the two levels distinct: the parent card snaps open (fast, decisive), the inner panel eases open (measured, referential). Closing mirrors opening.

**Empty and no-VMA states.** When a session has no rep longer than one lap — e.g. only 200m reps at Bertrand Dauvin — the toggle does not appear at all. A hidden toggle for empty data adds visual noise without purpose; suppression is cleaner. Off-track venues (Vincennes) follow the same rule: no track length, no toggle. When VMA is unset, the toggle also does not appear — its existence implies actionable data, and without a VMA there is none.

**Mobile.** At narrow viewport widths the two-column table collapses: landmark distance and target time stack on a single row separated by an em-dash rather than column spacing. Each rep group occupies its own block. The panel itself scrolls within the card if it grows tall — it does not force the card to grow without bound.

## Acceptance criteria

- [ ] The session description text is visually identical to today — no split annotations inline, no new rows between rep lines
- [ ] A "Temps de passage" stopwatch-labeled toggle appears bottom-right of the content block only when: VMA is set, the session venue has a known track length, and at least one rep in the session is longer than one lap
- [ ] Tapping the toggle reveals the passage-time panel; tapping again collapses it; the toggle icon turns blue when the panel is open
- [ ] The panel groups passage times by rep, with a small muted all-caps label per rep before its rows
- [ ] Passage rows use a two-column layout: landmark distance (right-aligned) and target time (left-aligned), in monospaced type one step smaller than the main session text
- [ ] Timed-block reps show passage rows with an "estimé" parenthetical on their label
- [ ] The panel opening motion is a smooth vertical unfurl visually distinct from the parent card's snap-open behavior
- [ ] At narrow viewport widths the two-column layout collapses gracefully to stacked landmark–dash–time rows
- [ ] Sessions at off-track venues (Vincennes) show no toggle
- [ ] Sessions where no rep exceeds one lap show no toggle
- [ ] When VMA is unset, no toggle appears anywhere
