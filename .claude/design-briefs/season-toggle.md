# Season selector — design brief

## Intent

The journal has outgrown a single scroll: it now spans multiple seasons and will keep accruing one every year. We're adding a way to view one season at a time, defaulting to the newest. The selector must read as a natural extension of the page's own navigation logic — the site already uses an understated underline-tab idiom for its top-level sections — rather than introducing a second competing pill-row right under the VMA chips. It should feel like scoping a lens, not filling out a form.

## References

- **Apple HIG — Segmented Controls** — developer.apple.com — a segmented control should hold a small number of closely related, mutually exclusive views; borrow the single-visible-active-state discipline, not the iOS chrome
- **Mobbin — Segmented Control glossary** — mobbin.com/glossary/segmented-control — confirms the "avoid this pattern once the option count grows past a handful; switch to a dropdown" guidance, directly relevant to the N-seasons question
- **Linear — Cycles** — linear.app/docs/use-cycles — borrow the "current cycle is the default view, older ones are one click away" mental model, not the visual chrome
- **Tracksmith — Journal** — tracksmith.com/journal — borrow the restrained, text-first editorial navigation tone: entries are found by scanning quiet labels, not by hunting through decoration

## Visual direction

**Control form and placement.** A small row of underline tabs, sitting directly beneath the page description and above the VMA bar. It borrows the same idiom as the top nav — quiet label, coloured underline on the active one, no fill, no border box — but at a visibly smaller scale and without icons, so it reads as a subordinate, second-tier control rather than a rival to the main nav or to the VMA percentage chips. Because the VMA chips are filled bordered pills and this new row is flat text with an underline, the two rows sit comfortably stacked without echoing each other.

**Active vs inactive state.** The active season takes the site's blue for its label and underline, exactly as the active main-nav tab does. Inactive seasons sit in the same muted graphite used for resting nav labels and page captions, underline absent, brightening slightly on hover. No new colour, no fill change — selection is carried entirely by colour and the underline, consistent with how the top nav already signals "you are here."

**Labelling.** Use the year-range form — "2025-2026", "2026-2027" — not "Saison 1 / Saison 2". The year range is self-explanatory even to a member skimming for the first time, avoids the club having to keep "Saison N" numbering straight as years accrue, and matches phrasing already used elsewhere on the site (the resource placeholder card already reads "saison 2025-2026").

**Growth to N seasons.** Up to four or five seasons, the tab row stays exactly this — the main nav itself carries four items comfortably at this scale. Beyond that, collapse into a compact dropdown-style control carrying the same quiet mono label and blue accent for the selected value, so the row never wraps to a second line under the page title.

**Description line.** Replace with: *"Historique des séances, une saison à la fois · La plus récente en premier."* Same length, same register, now names the season-scoped model.

**Empty and edge states.** Two distinct messages, same quiet centred-text treatment as today's single message — differentiated by copy only, not by new iconography: search-no-match reads *"Aucune séance ne correspond à votre recherche pour la saison [année]."*; season-has-no-sessions reads *"Aucune séance enregistrée pour cette saison."*

**Count line.** Stays terse — "12 séances" — no season name appended; the active tab directly above already carries that context, and restating it would turn a label into a sentence.

**Mobile.** The season row follows the exact same convention already used for the main nav at narrow widths: single row, horizontal scroll, no visible scrollbar, no wrap — the same gesture a member already uses to reach the fourth nav tab.

## Acceptance criteria

- [ ] The season selector sits between the page description and the VMA bar, not inside or below the search bar
- [ ] It is visually distinct from the VMA percentage chip row — flat underline tabs, not filled bordered pills
- [ ] It is visually smaller/quieter than the main top nav — same idiom, one step down in scale, no icons
- [ ] The active season is shown in the site's blue with a blue underline; inactive seasons are muted graphite with no underline
- [ ] Season labels read as year ranges ("2025-2026"), not "Saison 1/2"
- [ ] The newest season is selected by default on load
- [ ] The search box filters only within the active season
- [ ] At small option counts the row does not wrap to a second line; a defined threshold (around four to five seasons) triggers a dropdown-style fallback instead of horizontal wrapping
- [ ] The page description reads "Historique des séances, une saison à la fois · La plus récente en premier."
- [ ] Search-no-match and season-has-no-sessions render two distinct copy strings, sharing the same quiet visual treatment as the current no-results block
- [ ] The sessions count line remains a short count only, with no season name appended
- [ ] On narrow viewports the season row scrolls horizontally without a visible scrollbar, matching the main nav's mobile behaviour
