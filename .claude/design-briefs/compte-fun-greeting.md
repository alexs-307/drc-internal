# Compte — signed-in welcome state — design brief

## Goal

The signed-in state is the moment a member arrives after clicking their magic link: they are in, they belong here. Right now the panel is three lines of flat text — it reads like a receipt. The redesign should make this moment feel like the club greeting you at the door: warm, a little sharp, unmistakably DRC. The "Paré à drifter ?" tagline is the wink that earns this view its personality — it should feel like an aside from a friend, not a marketing line. Everything else stays deliberately compact; this is a single-tab moment, not a homepage hero.

## References

- **Satisfy Running — satisfyrunning.com** — Parisian running brand using bold display type paired with restrained body copy; the tonal contrast between a large statement word and quiet supporting text is the pattern to borrow here.
- **Saison 01 tab — existing site** — the hero figure caption uses Bebas Neue at section-title scale over the cream background. That pairing of all-caps sub-display type above muted body text is already proven on this site; extend it into the Compte signed-in state.
- **Sézane brand voice (via design analysis at salabyscharf.substack.com)** — center-aligned, mixed-size typography that creates warmth and a sense of editorial intimacy. The feeling of someone speaking directly to you, not at you.
- **DRC race-card pillar treatment — existing site** — the blue left-border accent on pillar races is the most expressive decorative gesture the site currently uses. A similarly purposeful one-line color accent (not a border, but a background wash) can do the same tonal work in the Compte panel.
- **Dribbble / welcome-card tag (dribbble.com/tags/welcome-card)** — small-scale member cards that use a soft background color block behind greeting text to signal "you are somewhere special" without a full modal or hero layout.

## Visual direction

**Color:** The greeting card sits on a peach wash — the existing peach accent color, applied as a full-bleed background fill within the signed-in panel container, not the whole tab. It is subtle, the lightest reading of the peach, as if the panel has been printed on warm paper. Against this: the primary blue for the member's name display and for the "Paré à drifter ?" fragment; near-black body text for the email confirmation line; and the standard outlined secondary button for sign-out, which inherits its usual blue-on-white look and sits below the warm zone on a white or cream surface — visually stepping outside the greeting card feel to signal "this is a function, not a welcome."

**Type:** Three tiers. First tier: the member's first name rendered in Bebas Neue at the section-title scale (the same weight as "Saison 01" or "Calendrier"), uppercase, in the primary blue. It should feel like a section opener — assertive but not shouting. Second tier: the tagline fragment "Paré à drifter ?" on its own line, immediately below the name, in Inter italic at a comfortable reading size — one step smaller than the name, graphite-colored. It is phrased as a question, so it should feel like it trails off slightly; the italic carries that quality. Third tier: the email confirmation line in JetBrains Mono at the small mono scale, muted graphite, flush-left — this is metadata, not copy, and the mono treatment signals that clearly. The "Connecté avec ton email" prefix stays quiet; the email address itself can be slightly heavier weight within the mono to give it legibility.

**Layout and spacing:** The panel is a single rounded card — matching the existing card radius — centered within the Compte tab content column and noticeably narrower than the full column width, the same narrowing proportion the sign-in form already uses. Inside: generous top padding so the name has room to breathe at the top of the peach zone; the tagline follows immediately with a small gap, then the email line with a slightly larger gap to create a visual pause between "greeting" and "metadata." The sign-out button lives outside the peach card, below it, with a clear vertical gap — it should feel detached from the welcome moment, like a door latch that is always there but not part of the greeting itself. On mobile at 375px width, the card fills the full content column minus standard horizontal padding; nothing changes structurally, just proportionally wider.

**Motion:** When the signed-in state becomes visible (the existing fade-in transition fires), the name line and tagline animate in from a small upward offset — roughly the height of one line — with opacity going from zero to full, over about 350 milliseconds, with an ease-out curve. The email line and button follow a beat later, perhaps 80 milliseconds delayed, with a simpler opacity-only fade. This is a pure CSS keyframe sequence, no JS. The total animation is under half a second. The peach background does not animate — it is present immediately, acting as the stage.

## Wireframe

```
┌─────────────────────────────────────┐
│                                     │  ← peach wash card
│   ALEXANDRE                         │  ← Bebas Neue, blue, section-title scale
│   Paré à drifter ?                  │  ← Inter italic, graphite, one step smaller
│                                     │
│   alexsaillard307@gmail.com         │  ← JetBrains Mono, small, muted
│                                     │
└─────────────────────────────────────┘

  [ Se déconnecter ]                     ← secondary outlined button, below card
                                          on white/cream, standard style unchanged
```

## Specific recommendations

**Name line (`auth-member-name`)**
- Font: Bebas Neue, section-title scale (matching `.page-title .line-1` in other tabs)
- Color: primary blue
- Weight: Bebas Neue has a single weight; no change needed
- Spacing: comfortable top margin inside the peach card; zero margin below (tagline follows directly)
- Motion: slides up from a small offset while fading in, starts immediately on state reveal

**Tagline line (new element wrapping "Paré à drifter ?")**
- This is the second line of the greeting text; the JS that populates the email line currently includes "Paré à drifter ?" at the end of `auth-member-email`. The implementer should split it: move "Paré à drifter ?" into a dedicated element between the name and the email line.
- Font: Inter italic, comfortable reading size (body-level, not small)
- Color: graphite — it is a wink, not a headline
- Spacing: small gap below the name line
- Motion: same slide-up as the name, same timing

**Email line (`auth-member-email`)**
- Font: JetBrains Mono, small scale (matching the existing `.mono-s` scale)
- Color: muted graphite
- The email address itself: slightly heavier mono weight for legibility within the muted line
- Spacing: larger gap above (separation from greeting content), flush with left edge of card
- Motion: opacity-only fade, 80ms delay after the name line starts

**Sign-out button (`auth-btn-secondary`)**
- No change to the button's visual style — keep the existing outlined secondary treatment exactly
- Layout change only: move it outside/below the peach card container, not inside the warm zone
- Add a clear vertical gap between the bottom of the card and the button so it reads as distinct from the greeting

**Peach card container (new wrapper)**
- Background: the existing peach accent color, full fill
- Border radius: existing card radius
- Padding: generous on all sides, matching internal card rhythm from other components
- No border, no shadow — the color itself provides the boundary

## Acceptance criteria

- [ ] The signed-in state shows a peach-background card containing the name, tagline, and email line
- [ ] The member's first name renders in Bebas Neue at section-title scale in primary blue
- [ ] "Paré à drifter ?" appears as its own line in Inter italic, in graphite, between the name and email
- [ ] The email line renders in JetBrains Mono at small scale, muted
- [ ] The sign-out button sits visually outside/below the peach card with a clear gap
- [ ] The name and tagline animate in with a combined slide-up-and-fade on state reveal; email fades in with a short delay
- [ ] Animation is pure CSS (keyframes + transform/opacity only); no JS animation library
- [ ] At 375px width, the card fills the content column with standard horizontal padding; no horizontal scroll
- [ ] The existing fade-in transition for state switching still works; the new animation layers on top of it
- [ ] "Se déconnecter" button remains keyboard-operable and retains its current secondary outlined style

## Out of scope

Everything except the `auth-state-signedin` div and its immediate contents. Do not change the sign-out state, the pending/confirmation state, the first-time profile form, the surrounding Compte tab layout, the tab navigation, or any other tab. The auth logic (JS) is untouched except for potentially splitting the email/tagline text into two separate DOM elements — that is the only JS change permitted.
