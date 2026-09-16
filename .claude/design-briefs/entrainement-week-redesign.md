# Entraînement week redesign — design brief (options)

## Intent

The Entraînement tab currently reads as a list of Tuesday track sessions with an occasional footnote. Structurally the club runs a two-session week — a coached, fixed-day track session and a flexible, self-directed threshold session — but the card header only ever names Tuesday, so the second session is invisible until a member happens to open the accordion. The fix must make "this week has (up to) two sessions" legible at the header level, without inflating a normal one-session week into something that looks broken or incomplete, and without making the flexible session read as optional homework rather than a real, expected part of training.

## References

- **TrainingPeaks Workout Card** — help.trainingpeaks.com/hc/en-us/articles/204861204 — a coded label/color carries the distinction between workout types; card size and position stay equal so neither workout reads as lesser
- **Editorial "lead + secondary rail" pattern** (general magazine front-page convention) — one anchor item is established first, a second item sits alongside with its own heading rather than being shrunk into a footnote of the first
- **Linear — Cycles** — linear.app/docs/use-cycles — the time-boxed cycle, not the first issue inside it, is the addressable, nameable unit; useful model for naming a card by its week rather than by Tuesday's date
- **Tracksmith Journal** — tracksmith.com/journal — dates and labels are treated as quiet captions, not headlines; supports a "Semaine du…" framing that stays understated rather than shouty
- **Google Calendar multi-day/no-fixed-day events** — flexible-window items render as a soft date range rather than being forced into one day cell; the reference for how to visually say "any day in this window" without inventing a fake date

## Option A — Week-headed card (recommended)

1. **Header:** replaces the Tuesday date with the week itself — "Semaine du 15 septembre" — plus the chevron. The header never claims a count, so it works identically whether the week holds one session or two.
2. **Differentiation:** the Tuesday date and venue move into the body, as a small caption above the core block ("Mardi 16 sept · Bertrand Dauvin") tagged "Coaché". The suggestion block keeps its own caption in place of a date — a soft window ("Jeu, ven ou week-end") tagged "En autonomie". Same type size and weight for both captions; only the tag and its accent color differ.
3. **No-suggestion weeks:** render exactly as they do today, one block, no second column, no placeholder. Because the header no longer promises two sessions, one session never reads as a gap.
4. **Flexible day:** communicated as the caption text itself ("Jeu, ven ou week-end") — no icon needed. The existing eligibility warning stays, now sitting directly under the suggestion's caption as a quiet second line, scoped clearly to that block.
5. **Schema:** none required. The week label is computed from the existing Tuesday date; the suggestion stays a column on the same row.
6. **Mobile:** this is the one option that actively relieves the known header-overflow defect — the header row sheds the specific date, venue and label crowding, leaving just the week phrase and chevron. The next-session pin badge continues to sit on the header; when the week's Tuesday is still upcoming the whole card pins, and once Tuesday has passed but a suggestion remains for that week, the pin's emphasis can shift to the suggestion caption inside the (already-open-by-default logic) body — see open question below.

## Option B — Two distinct cards, visually bound as a pair

1. **Header:** the track session keeps today's header verbatim (date, venue, label). A second card follows immediately after with no gap between them and a shared enclosing border, so the pair reads as one seam split in two rather than two unrelated list items.
2. **Differentiation:** the second card's header swaps the date pill for a text window ("Jeu, ven ou week-end") in the same pill shape, tagged "En autonomie" in the existing suggestion accent color. Same card padding, type weight, and size as the track card — equal footing, different tag only.
3. **No-suggestion weeks:** the second card simply doesn't render; the track card sits alone exactly as it does today, with no adjacent gap or bracket, so nothing looks removed.
4. **Flexible day:** the text-window pill described above; the eligibility warning moves to sit right under this card's own header, now scoped to a whole card rather than a column.
5. **Schema:** works without migration if the suggestion stays a column rendered as a second card, inheriting Tuesday's date for sort order only. A schema change (a `kind` field distinguishing track/suggestion rows sharing a week identifier, with the suggestion allowed its own real date) would be a natural next step if a firm day is ever assigned after the fact — flag as future, not required now.
6. **Mobile:** raises list density (two cards per week rather than one), which cuts against an already busy tab; each individual header is simpler than Option A's combined one, but the accordion list grows longer to scroll and scan.

## Option C — One card, header gains a second chip

1. **Header:** unchanged shape — Tuesday date, "Prochaine" badge, label, venue, chevron — with one addition: a small appended chip reading "+ Séance libre" when a suggestion exists.
2. **Differentiation:** the chip uses the existing suggestion accent color, distinct from the blue "Prochaine" badge, so it reads as a different kind of marker, not a second badge of the same kind.
3. **No-suggestion weeks:** chip simply absent — closest of the three to today's shape.
4. **Flexible day:** the chip only signals presence; the window/eligibility copy stays exactly where it lives today, inside the body.
5. **Schema:** none — a presentational addition driven by existing truthiness of the suggestion field.
6. **Mobile:** highest risk. The header already overflows before this change; adding a chip without also trimming something (e.g. moving venue to its own line under the title on narrow widths) would compound a known defect rather than fix it.

## Recommendation

**Option A.** It is the only option that fixes the actual complaint — the header currently centers the whole week on Tuesday — rather than patching around it, and it is the only option that measurably relieves the existing mobile overflow instead of risking or ignoring it. It also ships with no schema change. Option C is cheapest but treats the symptom, not the cause, and adds to a header that's already tight. Option B gives the strongest "there are two" signal at a glance but at a real cost to list density and to next-session-pin clarity; keep it as the fallback if user testing shows Option A's single-card body still under-signals the second session.

## Open questions

- Once Tuesday has passed but the week's suggestion is still open (no fixed date to compare against), should the "Prochaine" pin shift emphasis to the suggestion, stay on the whole card, or disappear until next Tuesday? This affects all three options and is the one decision that most changes implementation shape.
- Is "Semaine du [Tuesday's date]" acceptable, or should the week label anchor to the preceding Monday?

## Acceptance criteria (for whichever option is chosen)

- [ ] The card header no longer implies a single Tuesday-only session when a suggestion exists
- [ ] A week with no suggestion renders with no visible gap, placeholder, or "missing" cue
- [ ] The track session and the suggestion are visually differentiated by a coded tag/color, not by size or prominence
- [ ] The flexible-day window is communicated without inventing a fake date
- [ ] The eligibility warning line survives, clearly scoped to the suggestion only
- [ ] The next-session pin behavior is resolved per the open question above and documented
- [ ] Mobile header does not regress the known overflow defect; ideally it improves
