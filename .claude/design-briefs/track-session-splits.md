# Track session intermediate splits — design brief

## Intent

When a rep spans more than one lap of the track, runners need intermediate checkpoint times to pace themselves through each lap landmark. These splits are a third kind of derived datum — below the existing blue rep-total badge and the amber timed-block distance badge in the typographic hierarchy — and their role is purely navigational: a quiet reference the eye can glance at while still reading the session line first. The design must add this information without disrupting the calm mono rhythm of the session content block, which already carries two badge types. The key constraint is repetition: a session with five 1000m reps on a 300m track produces fifteen split values, and if each one carries visual weight comparable to the existing badges the card becomes illegible. The solution is to keep the split row subordinate in every dimension — size, weight, color saturation, and placement — so the rep line and its existing badge remain the primary read.

## References

- **Tracksmith Big Workouts — 1K Repeats** — https://big-workouts-1k.tracksmith.com/ — borrow the principle of presenting a rep-total prominently, then letting landmark times sit beneath it in a quieter register; the editorial restraint comes from the size and weight differential between the headline number and the sub-data
- **Strava Running Workout Analysis** — https://support.strava.com/hc/en-us/articles/115001136770-Mobile-Workout-Analysis — borrow the "bar graph + numerical breakdown below" structure: the primary metric is always more prominent, the lap breakdown is available but visually secondary; note especially how laps are separated by a light rule rather than heavy borders
- **TrainingPeaks Structured Workout Builder** — https://help.trainingpeaks.com/hc/en-us/articles/235164967-Structured-Workout-Builder — borrow the stepped indentation model where warm-up, interval, and cooldown live at different levels of visual depth; the secondary information sits in from the margin, signalling "this belongs to the item above"
- **NAZ Elite Intermediate Marathon Plan (HOKA)** — https://blog.hoka.com/wordpress/wp-content/uploads/2024/01/HOKANAZEliteIntermediateMarathon.pdf — borrow the coach-printout convention of listing lap checkpoints in a compact row after the rep description, prefixed by a subdued landmark label; the split times are never larger than the rep target itself
- **Renato Canova 2 Key Marathon Sessions — SweatElite** — https://www.sweatelite.co/renato-canova-2-key-marathon-training-sessions/ — borrow the convention where intermediate distance markers are treated as secondary footnotes to the overall rep: the total is always the anchor, the splits are the supporting data underneath it, indented or separated by a thin rule in printed materials

## Visual direction (prose, no code)

**Placement — stacked below, not inline.** Split times appear on a new line directly beneath the rep line that triggered them, indented slightly from the left edge of the session content block. They do not crowd onto the same line as the rep text. This preserves the natural line rhythm of the mono content block — each rep still reads as one line — and keeps the splits visually dependent on their parent rep without requiring a toggle.

**When to show them.** Splits appear automatically whenever a VMA is set and the rep distance is strictly greater than the track's lap length for that session venue. No tap or toggle required — the extra line is always present if relevant. For reps equal to or shorter than one lap, no split row appears. This avoids the need to explain the feature; it is simply there when it applies.

**Visual differentiation — same family, lower rank.** The existing blue badge is solid, filled, and high contrast — it reads from across the card. The split row must read clearly but never compete. Treat it as a sequence of small monospaced landmark labels paired with their times, rendered in the same existing muted graphite tone used for secondary text throughout the site. The landmark distance (e.g., "300m") acts as the label; the time follows it directly. Each landmark pair is separated by a quiet space, not a bullet or divider. No pill shape, no fill, no border — the split row is bare type only. If the implementer judges that some minimal visual grouping aids legibility on a narrow viewport, a very faint inline separator between landmark pairs is acceptable, but the default is spaced text, not badged chips.

**Clutter risk — kept calm by restraint.** Because splits are bare type rather than filled badges, fifteen split values across five reps add visual mass proportional to text, not to pill-shaped objects. The uniform indentation means the eye reads each rep line first, then drops to the splits if needed; the pattern becomes expected after the first rep and stops registering as clutter. No animation, no hover state on the split row itself.

**Mobile rhythm.** The split row wraps naturally as a single line of text. On narrow viewports where the session content block is already full-width and the line length is tight, the landmark pairs may wrap to a second line within the split row — this is fine and expected. The indentation holds even on wrap, so the split row never visually merges with the following rep line above it.

**Timed-block case.** For timed reps ("3' à 90% VMA"), no split row is shown. A timed effort has no fixed distance landmarks; computing hypothetical checkpoints at arbitrary time intervals would produce numbers that mean nothing to a runner without a GPS watch. The amber badge (estimated distance) remains the only annotation. Suppress splits entirely for timed blocks.

## Acceptance criteria

- [ ] For a distance rep whose distance exceeds the session venue's lap length, a split row appears on a new line directly beneath the rep line — one landmark-time pair per lap landmark up to (but not including) the total rep distance
- [ ] The split row is indented relative to the left edge of the session content block, clearly subordinate in reading order to the rep line above it
- [ ] Split times are rendered in the existing muted secondary-text color — not blue, not amber, not black; noticeably quieter than the existing blue and amber badges
- [ ] Split values are plain monospaced text — no pill shape, no filled background, no border
- [ ] For a rep equal to or shorter than one lap length, no split row appears
- [ ] For a timed-block rep ("3' à 90% VMA"), no split row appears; the amber estimated-distance badge remains the only annotation
- [ ] When VMA is unset, no split row appears (same behavior as existing badges)
- [ ] A session with five 1000m reps on a 300m track renders cleanly on both desktop and a narrow mobile viewport — the overall card reads as calmer than a comparable card with fifteen filled badge chips would
- [ ] The existing blue rep-total badge remains visually dominant on each rep line — the split row never competes with it in weight or saturation
- [ ] The split row text wraps gracefully on narrow viewports without merging visually with an adjacent rep line
