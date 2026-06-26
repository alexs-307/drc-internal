# Audit — Intermediate splits on track sessions

> Architecture audit. Research and planning output, no code written.
> Produced by the EM orchestrator. See `CLAUDE.md` → *Infrastructure audit format*.
>
> Paired design brief: `.claude/design-briefs/track-session-splits.md` (visual treatment).
> This audit covers the data side only — where the venue → track-length map lives, and
> how passage times are computed and surfaced.

---

## v3 revision note (supersedes v2 where they conflict)

v2 shipped and was tested locally. Two visual problems came back:

1. **Toggle affordance** — the bare-text stopwatch + "Temps de passage" label looked decorative; users skipped over it without realising it was clickable.
2. **Vertical waste** — the per-landmark stacked rows (300m / 600m / 900m on three separate lines, both desktop table and mobile stack) consumed too much vertical space for what is essentially three short data points.

v3 (see design brief v3) keeps every data-shape decision below unchanged. The two display changes:

- The toggle becomes a **persistent low-profile bordered chip** (border in the existing border tone at rest, blue when the panel is open). Icon-blue-shift still happens too. No chevron, no fill change.
- The disclosed panel's landmark layout collapses to a **single inline horizontal row per rep group**, with a **centred dot (`·`) separator** between distance-time pairs. The rep-group label (`1000M À 90% VMA`) stays on its own line above the row. The desktop-table / mobile-stack split from v2 is **eliminated** — one layout serves all viewports, wrapping between pairs (never inside a pair) when the screen is narrow.

**Implementation deltas vs v2:**
- Restyle `.splits-toggle` from bare-text to bordered chip; add a `border-color` state on `.splits-toggle.active`.
- Replace the `<table class="splits-table">` + `.splits-table-mobile` stack with a single inline element per rep group (e.g. flexbox row with `flex-wrap: wrap`, each pair non-breaking, dot rendered as a separate inline element between pairs).
- Drop the `@media (max-width: 700px)` table/stacked-row split — the new layout is responsive on its own.
- All other v2 plumbing (`extractPassageData`, `toggleSplits`, `stopPropagation`, suppression rules, `(estimé)` tag, soft max-height unfurl) stays untouched.

---

## v2 revision note (supersedes the v1 inline model below where they conflict)

The v1 plan — inject split badges inline into the annotated session text via an extended
`annotateVMA` — shipped and was **rejected by the user**: always-on inline rows fragmented
the session description and hurt readability. v2 changes two things:

1. **Display model → on-demand per-card disclosure.** Passage times no longer live inline in
   the description. Each session card gets a single "Temps de passage" toggle that reveals a
   reference panel (see design brief v2). The description text reverts to exactly today's
   rendering. **Implication for the code:** `annotateVMA` reverts to its original
   two-pattern form (blue distance badge + amber timed badge, no splits). A *separate*
   pass computes passage data per session and the renderer builds the toggle + panel.
   The inline `.vma-splits` span and the splits branch inside `annotateVMA` are removed.

2. **Timed blocks are now in scope.** v1 excluded them. v2 includes them: for a timed effort
   (`<minutes>' à <pct>% VMA`), derive the distance covered at that pace
   (`distance = vma × pct/100 × minutes/60 × 1000` metres) and emit passage landmarks at each
   lap multiple up to that distance. These are pace-estimates, flagged "estimé" in the panel.

3. **All track venues, by lap length** (unchanged from the confirmed mapping below): 300m → 300/600/900…, 400m → 400/800/1200…, up to (not including) the rep total.

Sections 2–6 below are the original v1 record; read them through the lens of the three deltas above.

---

---

## 1. Current state

- **`public.sessions` schema** (`supabase/migrations/0001_init.sql:104`): `venue text NOT NULL`. Free-text string. No structured metadata, no track-length, no foreign key.
- **Venues currently referenced in the seeded sessions data** (`supabase/migrations/0002_seed_initial_data.sql`):
  - `Bertrand Dauvin` — track sessions
  - `Max Roussie` — track sessions
  - `Métro Château de Vincennes` — *off-track*; the two sessions at this venue (lines 133, 567) are outdoor "Hors les murs" pyramid and forest sessions, not track repeats. They have no lap structure.
- **VMA annotator** (`index.html:2746-2773`): signature `annotateVMA(text, vma)`. Two regex passes inject `<span class="vma-hint">` badges:
  - Distance reps (`<dist>m à <pct>% VMA`) → blue badge with the rep target time
  - Timed reps (`<minutes>' à <pct>% VMA`) → orange badge with estimated distance
- **Session rendering** (`index.html:2360-2410`): each session object `s` reaches the annotator with its full row in scope. `s.venue` is available — currently only used by `shortVenue()` for the header date-and-place line.
- **VMA storage**: `localStorage['drc_vma']`, restored on page load. Annotations re-render on VMA change and on search filter change.

## 2. Desired state

- For every distance-based rep where `rep_distance > track_length`, the card shows intermediate target times at each `track_length` landmark inside the rep — e.g. 1000m at 90% VMA on a 300m track renders split landmarks at 300m, 600m, 900m. The blue rep-total badge at 1000m remains in place.
- Track length is a **venue property**. Only track venues are mapped; off-track venues (Vincennes outdoor, future trail sessions) carry no entry, and the absence of an entry suppresses splits — which is the correct behavior for those sessions.
- Splits are derived from VMA + rep distance + track length at render time — **no per-session split data is stored** in Supabase.
- Visual treatment of the split row is governed by the paired design brief (bare muted-graphite text on a new indented line under the rep, no badge chip, always-on when VMA is set and the rep qualifies).

## 3. Gap analysis — where does the venue → track-length map live?

Considered options:

| Option | Storage | Adding a venue | Frontend lift |
|---|---|---|---|
| **A — Frontend constant** in `index.html` next to `annotateVMA`, mapping each track-venue string to its lap length in meters | None | One-line frontend PR | Small — pass `trackLengthM` into `annotateVMA`, extend the distance regex |
| **B — `public.venues` table** with `name PK, track_length_m INT`; frontend fetches alongside sessions and builds the map | New table + RLS read policy mirroring sessions/races | SQL insert in Supabase Studio | Same as A + the fetch wiring |
| **C — `sessions.track_length_m` column** with backfill migration; per-session value | Schema change + per-row data | Filled per-insert by the `drc-publish-session` skill | Same as A, plus a small skill change |
| **D — Per-rep explicit markers in session text** (e.g. `1000m à 90% VMA (splits @300, 600, 900)`) | None | N/A | Annotator parses two formats; conflicts with the "by stadium" intent the user expressed |

**Decision: Option A.** Three to four track venues today, changes rarely, zero schema lift, fastest path. Upgrade to Option B later if venues proliferate or non-devs need to edit the map in Studio without a frontend PR.

### Venue → track-length map (per user-confirmed input)

The frontend constant should seed with the following entries (described in prose for the audit; the implementer encodes them as JS):

| Venue (matches `s.venue` exactly) | Lap length (m) | Source of truth |
|---|---|---|
| `Bertrand Dauvin` | 300 | User-confirmed |
| `Max Roussie` | 400 | User-confirmed (corrects an earlier guess of 300m in the prior audit pass) |
| `Stade des Poissonniers` | 400 | User-confirmed (new venue, not yet present in the seeded sessions data — included now so the first session at Poissonniers renders splits correctly without a frontend change) |

Venues not in this map (e.g. `Métro Château de Vincennes`, future trail venues) → no splits rendered. This is the correct behavior: off-track sessions have no lap structure.

### Other plumbing common to whichever option

- `annotateVMA(text, vma)` → `annotateVMA(text, vma, trackLengthM)` — backwards-compatible: when `trackLengthM` is `null` or `undefined`, the splits branch is skipped and the function behaves exactly as today.
- Distance regex extends to emit additional split annotations per landmark inside the rep, when `dist > trackLengthM`.
- Splits stop at the last full lap landmark strictly less than the rep total (e.g. 1000m on a 300m track → 300, 600, 900; not 1000, since the blue rep-total badge already covers the rep finish).
- Timed-rep regex stays as-is — no splits for timed blocks per the design brief.
- VMA-unset: splits are suppressed (same as the existing blue/orange badges).

## 4. Risk and complexity

- **Low risk overall.** Additive feature, pure render-time derivation. Reversible by removing the annotator extension and the constant. No data migration.
- **Renderer math** is mechanical: for a rep of `dist` meters at `pct` % VMA on a `len`-meter track, the i-th landmark is `i × len` meters and its target time is `(i × len) / (vma × pct / 100 / 3.6)` seconds, for `i = 1` to `floor((dist - 1) / len)`. No corner-case fiddling beyond integer division.
- **Stale CLAUDE.md venue list** — the *Site structure → Tab 3 — Entrainement* section currently lists `"Bertrand Dauvin"`, `"Max Roussie"`, `"Métro Château de Vincennes"` as the active venue values. The implementer (or a separate housekeeping PR) should refresh this to add `Stade des Poissonniers` and to flag Vincennes as off-track. Not blocking implementation — just keeps the docs honest.
- **First session at Stade des Poissonniers** will land without a corresponding seed row anywhere; the frontend constant is the only place that needs to know about it ahead of time.

## 5. Recommended sequence

Single implementation PR — no backend work.

1. **PR 1 — implementer** on a feature branch (`feat/track-session-splits` or similar): add the `VENUE_TRACK_LENGTHS` constant in `index.html` next to the existing VMA helpers; extend `annotateVMA` signature to accept `trackLengthM`; render the split row per the design brief at `.claude/design-briefs/track-session-splits.md`; refresh the CLAUDE.md venue list as part of the same diff or as a paired chore commit. Reviewer LGTM, EM pushes, user reviews and merges.

That is the entire scope. No backend agent, no migration, no schema change.

## 6. Out of scope

- Per-rep manual override of split landmarks (e.g. `splits @250/500/750`) — uncommon, can be added later via a second regex pass if a coach ever needs it
- Splits for timed blocks (`3' à 90% VMA`) — explicitly suppressed by the design brief; revisit only if member feedback requests it
- Pace per km / per 400m alongside split times (different feature, separate brief)
- Stopwatch / interval-timer UI on the session card (different feature, larger scope)
- Backfilling historical sessions with the new feature (none of the data is destructive — older sessions just render the same way they do today, with splits appearing automatically once the constant is in place)
- Migrating `sessions.venue` to a foreign key against a new `venues` table (deferred until venue count grows past ~5 or non-dev management is needed)
- Distribution of the `Métro Château de Vincennes` outdoor sessions — already correctly handled by the "venue absent from map → no splits" rule; no extra logic required
