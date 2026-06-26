# Track session intermediate splits — design brief (v3)

> **Version history**
> v1 (always-on inline split rows) — rejected: fragmented the session description, hurt readability.
> v2 (toggle + stacked two-column table) — rejected: toggle read as decoration, not a control; vertical table wasted too much space for a simple list of three landmarks.
> v3 (this revision) — persistent chip affordance on the toggle; inline horizontal landmark row with centre-dot separator.

## Intent

Two targeted fixes to the v2 implementation. The toggle must register immediately as something you can click — it currently looks like a secondary label and users skip over it. The passage data panel itself must collapse each rep group's landmarks into a single compact horizontal line rather than one table row per landmark — on a 300m track a 1000m rep produces three checkpoints; showing them as three stacked rows is disproportionate to the information density.

## References

- **W3C ARIA Disclosure Pattern** — https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/ — borrow the principle that a disclosure trigger needs a persistent visual affordance (not just a hover state) so users can identify it as interactive before they move the cursor near it
- **Tracksmith Training Journal** — https://www.tracksmith.com/products/hare-ac-training-journal — borrow the coach-printout convention of tight, condensed reference data arranged horizontally on a single line, with small typographic glyphs separating entries — the reference material feels authored, not auto-generated
- **Headless UI Disclosure** — https://headlessui.com/react/disclosure — the single-button open/close mental model stays; what changes is the resting visual state of the button itself
- **Linear design system** — https://linear.app/now/how-we-redesigned-the-linear-ui — borrow the treatment of small secondary actions as quiet bordered chips rather than bare text; the border gives "I am a thing you can press" without heavy colour
- **NYRR Training Plans** — https://www.nyrr.org/train/runner-resources-hub/training-plans/training-plans — borrow the inline breadcrumb-style pace notation where checkpoints read left-to-right as a sequence, not a column

## Visual direction

**Color:** No new tokens. All changes use the existing palette — the existing border tone for the chip outline, the existing muted graphite for the label and landmark text, the existing blue surfacing only on the icon when the panel is open, the existing peach or blue-faint background for the chip's resting pill fill only if a light fill is needed (leave it at transparent first; add the faintest blue-faint wash only if the border alone is insufficient).

**Type:** The toggle label and landmark pairs both remain in the existing monospaced family at the existing smaller size from v2. The rep-group label (e.g. "1000M À 90% VMA") keeps its all-caps, slightly tracked treatment on its own line above the landmarks — do not fold it into the landmark row.

**Layout and spacing:** For the landmark row, each distance-time pair sits inline, reading left to right with a small centred dot — a middle dot, not a dash, not a bullet — as the separator between pairs. The dot sits at mid-height between baseline and cap-height, visually equidistant from the pair on each side. Within a pair the distance and time sit very close together with a hair of space, no separator — "300m 1'15"" reads as one unit. On screens too narrow to fit all pairs, the row wraps; when it wraps, each pair stays together on its line (the wrap happens between pairs at the dot, not inside a pair). The dot separator wraps with the following pair rather than orphaning at the end of a line.

**Toggle affordance:** Replace the current bare-text button with a persistent low-profile chip. The chip has a thin border in the existing border tone — the same hairline weight used elsewhere in the site for card outlines and dividers — and a very slight horizontal padding so the stopwatch glyph and label have breathing room inside the pill shape. The border is always visible at rest, not just on hover. In its resting state the chip uses the same muted graphite as today. On hover, the border shifts one step darker toward the primary text tone and the label sharpens slightly. When the panel is open, the stopwatch glyph turns blue (same as v2) and the chip border takes on the same blue, creating a paired open/closed signal: closed is a quiet grey chip, open is a blue-outlined chip with a blue icon. No fill change in either state — background stays transparent so the chip never feels like a heavy button. No chevron, no animated rotation — the chip border-color shift from grey to blue is the state indicator.

**Motion:** Unchanged from v2. The panel unfurls with a soft max-height transition, visually slower than the parent accordion's snap-open, closing the same way.

## Acceptance criteria

- [ ] The "Temps de passage" toggle has a visible border at rest — it reads as a pressable chip, not a text label
- [ ] The chip border shifts from the default border tone to the site's blue when the panel is open; the stopwatch icon also turns blue when open
- [ ] No downward chevron on the toggle in any state
- [ ] The toggle chip sits flush to the bottom-right of the session content block, after the last description line
- [ ] Each rep group's landmarks appear on a single horizontal row: pairs flow inline, separated by a centred dot, not stacked in a table
- [ ] Within each pair, distance and time stay tightly together with no separator between them
- [ ] The rep-group label (e.g. "1000M À 90% VMA") remains on its own line above the inline landmark row
- [ ] On narrow viewports the landmark row wraps between pairs; no pair is split across lines; the dot separator stays with the following pair
- [ ] Desktop table and mobile stacked-row structures from v2 are replaced by the single inline row on all viewport widths
- [ ] All v2 suppression rules remain: no toggle when VMA unset, off-track venue, or no qualifying rep
- [ ] Timed-block rep labels still carry the "(estimé)" parenthetical
- [ ] Panel unfurl motion remains a smooth max-height transition, distinct from the parent accordion's snap
