# Structured session steps for Garmin workout export — design brief (spike v1)

> This is the design/planning output of the `feat/garmin-workout-export` spike. It proposes a
> structured-step data model that could sit alongside the existing free-text `g12`/`g3` session
> fields, and maps that model onto FIT `workout`/`workoutStep` messages. No schema change is
> made by this brief — it is a recommendation for the EM/backend agent to scope if the spike is
> approved to go further. The spike itself (`spike/generate.html`, `spike/fit-encoder.js`) hard-
> codes the structured model in JS for one real session rather than reading it from a DB column
> that doesn't exist yet.

## 1. Decomposition of the chosen session (`2026-05-05`, "Progressivité d'allure — Tempo → VMA")

Raw G1/G2 text (from `spike/session-sample.md`):

```
Chauffe : 20' EF · 15' gammes · 2 lignes droites

Bloc principal :
3 × (900m à 80% VMA / 600m à 90% VMA / 300m à 100% VMA)
r = 2' entre les courses · R = 3' entre les séries

Retour au calme : 5' jog léger
```

Logical parts:

| Part | Content | Notes |
|---|---|---|
| Warmup | 20' EF (easy running) | Fixed-time, no pace target — an easy effort by definition |
| Warmup | 15' gammes (running drills) | Fixed-time in the text, but not a running-pace effort — drills, not a "target" in the VMA sense |
| Warmup | 2 lignes droites (strides) | No duration given at all in the text — count-based, not time or distance-based |
| Repeat group, ×3 (G1/G2) / ×2 (G3) | 900m @ 80% VMA → r 2' → 600m @ 90% VMA → r 2' → 300m @ 100% VMA → R 3' | Three distinct work steps per repetition, each at a different %VMA; `r` (lowercase) separates the three runs within one repetition, `R` (uppercase) separates repetitions themselves |
| Cooldown | 5' easy jog | Fixed-time, no pace target |

G3 differs only in repeat count (2 vs 3) — everything else (warmup, per-rep structure, cooldown) is identical. This is exactly the kind of parametric difference (count only) the structured model should capture without duplicating the whole step list.

## 2. Proposed structured-step model

### Storage recommendation: JSONB columns, not a flat step table

Recommend two new **nullable** JSONB columns on the existing `public.sessions` table:
`structured_g12` and `structured_g3` (mirroring the existing `g12`/`g3` text columns). Rationale:

- **Nesting.** A repeat group is a tree, not a flat list — steps within a repeat, and a separate
  repeat-boundary marker, naturally nest one level. A flat relational step table would need a
  self-referencing `parent_step_id` / `sort_order` scheme to express this, adding join
  complexity for something that is always read as a single document (there is no query need to
  filter or aggregate across individual steps server-side — the whole structure is fetched once
  per session render, or once per FIT-export click).
- **Authoring cost for the `drc-publish-session` skill.** The skill already builds a JS/shell
  object today (`g12`, `g3`, `label`, `venue`, `date`, `suggestion`) and calls
  `insert_session.sh`. Adding two more optional JSON fields to that same object is a small
  , additive change. A flat step table would require the skill (or a follow-up migration
  script) to emit N inserts per session with correct ordering and repeat-boundary bookkeeping —
  meaningfully more surface for a skill that already has to parse free-form WhatsApp text.
- **Migration cost / backward compatibility.** Nullable JSONB columns are a pure addition —
  every existing row (36 historical sessions, and any new session the skill doesn't yet know
  how to structure) keeps rendering exactly as today from `g12`/`g3` text. A structured render
  path (accordion badges, VMA annotation, FIT export button) only activates when the JSONB
  column is non-null. A flat table would still need the same nullability story (an empty/no-rows
  case) but with more schema (a whole new table + FK) for the same non-null-else-fallback logic.
- **Postgres JSONB is a reasonable fit for a small, bounded document.** These are single-session
  workout structures — at most a few dozen steps — not a growing dataset that benefits from
  row-level indexing or partial queries. If a future need arises to query *across* sessions by
  structured content (e.g., "find all sessions with a 400m rep"), that would be the trigger to
  reconsider a normalized table; no such need exists today.

The two columns stay independent of `g12`/`g3` (which remain the source of truth for on-site
display and search) — the structured columns are additive, used only by the export path.

### JSON schema

```
StructuredSession := {
  "steps": [ Step, ... ]
}

Step := {
  "kind": "warmup" | "work" | "recovery" | "cooldown" | "repeat_group",
  "name": string,                    // short label, mirrors DRC text; becomes FIT wktStepName
                                      // (device-displayed length is limited — see §6 limitations)
  "duration": {
    "type": "time" | "distance" | "open",
    "value": number | null           // seconds if type=time, meters if type=distance,
                                      // null if type=open (no fixed end condition)
  },
  "target": null | {
    "type": "vma_pct",
    "pct": number,                   // single %VMA point, e.g. 90
    "pct_low": number | null,        // explicit range low, e.g. 100 (only when the DRC text
    "pct_high": number | null        // gives a range like "100-110% VMA"; null otherwise —
                                      // see §5 for how a single pct becomes a band)
  },
  // present only when kind === "repeat_group":
  "repeat": {
    "count": number,
    "steps": [ Step, ... ]           // body of the loop; MUST NOT itself contain a
                                      // kind === "repeat_group" step — see §6 nesting note
  }
}
```

Notes on the enums:
- `kind` intentionally mirrors FIT `intensity` closely (`warmup`, `cooldown`, `recovery` map
  1:1) but adds `work` (→ FIT `intensity = active`) and `repeat_group` (a model-only construct —
  it does not correspond to a single FIT message; it expands to a repeat-control `workoutStep`
  message placed after its body steps, see §4).
- A `recovery` step distinguishes `r` (between reps, short) from `R` (between blocks/series,
  longer) only through `name` and `duration.value` — both map to FIT `intensity`, but the brief
  recommends using `intensity: "rest"` for `r` and `intensity: "recovery"` for `R` (see §4) so a
  future on-site render (e.g. an accordion badge) can style them differently if desired.
- `duration.type: "open"` covers both "no fixed duration given in the text" (e.g. "2 lignes
  droites") and genuinely free-running segments — see §6 for what's lost either way.

## 3. The chosen session (`2026-05-05`), fully expressed — G1/G2

```json
{
  "steps": [
    { "kind": "warmup", "name": "Échauffement EF",
      "duration": { "type": "time", "value": 1200 }, "target": null },
    { "kind": "warmup", "name": "Gammes",
      "duration": { "type": "time", "value": 900 }, "target": null },
    { "kind": "warmup", "name": "2 lignes droites",
      "duration": { "type": "open", "value": null }, "target": null },
    { "kind": "repeat_group", "name": "Série 900/600/300",
      "duration": null, "target": null,
      "repeat": {
        "count": 3,
        "steps": [
          { "kind": "work", "name": "900m à 80% VMA",
            "duration": { "type": "distance", "value": 900 },
            "target": { "type": "vma_pct", "pct": 80, "pct_low": null, "pct_high": null } },
          { "kind": "recovery", "name": "Récup r",
            "duration": { "type": "time", "value": 120 }, "target": null },
          { "kind": "work", "name": "600m à 90% VMA",
            "duration": { "type": "distance", "value": 600 },
            "target": { "type": "vma_pct", "pct": 90, "pct_low": null, "pct_high": null } },
          { "kind": "recovery", "name": "Récup r",
            "duration": { "type": "time", "value": 120 }, "target": null },
          { "kind": "work", "name": "300m à 100% VMA",
            "duration": { "type": "distance", "value": 300 },
            "target": { "type": "vma_pct", "pct": 100, "pct_low": null, "pct_high": null } },
          { "kind": "recovery", "name": "Récup R (série)",
            "duration": { "type": "time", "value": 180 }, "target": null }
        ]
      }
    },
    { "kind": "cooldown", "name": "Retour au calme",
      "duration": { "type": "time", "value": 300 }, "target": null }
  ]
}
```

G3 is byte-identical except `"count": 3` → `"count": 2`. This is exactly the parametric-only
difference described in §1 — the model expresses it as a one-field diff, not a duplicated tree.

**Nothing is lost** encoding this specific session: every phase (warmup components, the 3-part
repeated block with two recovery granularities, cooldown) maps cleanly. The only soft loss is
that "gammes" and "lignes droites" become generic `open`/`time` steps with a name — the *content*
of a "gamme" (a technical drill: skipping, heel flicks, etc.) has no structural representation;
see §6.

## 4. Mapping (a): DRC text → structured model

| DRC phrase | Structured `Step` |
|---|---|
| `20' EF` | `{ kind: "warmup", duration: {type:"time", value:1200}, target:null }` |
| `15' gammes` | `{ kind: "warmup", duration: {type:"time", value:900}, target:null }` |
| `2 lignes droites` (no duration given) | `{ kind: "warmup", duration: {type:"open", value:null}, target:null }` |
| `900m à 80% VMA` | `{ kind: "work", duration:{type:"distance", value:900}, target:{type:"vma_pct", pct:80} }` |
| `r = 2' entre les courses` | `{ kind: "recovery", duration:{type:"time", value:120}, target:null }` (× between each work step) |
| `R = 3' entre les séries` | `{ kind: "recovery", duration:{type:"time", value:180}, target:null }` as the **last** step inside the `repeat_group` body (see §6 trailing-recovery caveat) |
| `3 × (...)` | `repeat.count = 3` on the enclosing `repeat_group` |
| `100m en trottinant` (distance-based recovery, seen in the 2026-05-19 stress test) | `{ kind: "recovery", duration:{type:"distance", value:100}, target:null }` — recoveries are not always time-based |
| `5' jog léger` | `{ kind: "cooldown", duration:{type:"time", value:300}, target:null }` |
| `100-110% VMA` (explicit range, seen elsewhere in the corpus, e.g. `2026-01-27`) | `target: {type:"vma_pct", pct: null, pct_low:100, pct_high:110}` |

## 5. Mapping (b): structured model → FIT `workoutStep` messages, with VMA math

Field/enum values below are taken verbatim from `spike/reference/fit-profile-excerpt.md`.

| Model field | FIT field (num) | Encoding |
|---|---|---|
| `Step.name` | `wktStepName` (0) | UTF-8 string, as-is (device may truncate on display) |
| `duration.type = "time"` | `durationType` (1) = `time` (0) | `durationValue` (2) = seconds × 1000 (ms) |
| `duration.type = "distance"` | `durationType` (1) = `distance` (1) | `durationValue` (2) = meters × 100 (cm) |
| `duration.type = "open"` | `durationType` (1) = `open` (5) | `durationValue` (2) = 0 (unused) |
| `target = null` | `targetType` (3) = `open` (2) | `targetValue`/`customTargetValueLow/High` = 0 (unused) |
| `target.type = "vma_pct"` | `targetType` (3) = `speed` (0) | `customTargetValueLow`/`High` (5/6) = m/s × 1000 (see band formula below); `targetValue` (4) = 0 (custom, not a zone) |
| `Step.kind = "warmup"` | `intensity` (7) = `warmup` (2) | |
| `Step.kind = "work"` | `intensity` (7) = `active` (0) | |
| `Step.kind = "recovery"`, short (`r`) | `intensity` (7) = `rest` (1) | |
| `Step.kind = "recovery"`, long (`R`) | `intensity` (7) = `recovery` (4) | |
| `Step.kind = "cooldown"` | `intensity` (7) = `cooldown` (3) | |
| `repeat_group` (the group itself) | one extra `workoutStep` message, placed immediately after the body's last step | `durationType` (1) = `repeatUntilStepsCmplt` (6); `durationValue` (2) = `messageIndex` of the **first** body step; `targetType` (3) = `open` (2); `targetValue` (4) = `repeat.count` |

### VMA → speed → FIT speed band

```
target_speed_ms   = VMA_kmh × (pct / 100) / 3.6
band_low_ms       = target_speed_ms × (1 − 0.03)     // when pct is a single point
band_high_ms      = target_speed_ms × (1 + 0.03)
```

When the DRC text already gives an explicit range (`pct_low`/`pct_high`, e.g. "100-110% VMA"),
the low/high FIT speeds are computed directly from those two percentages instead of synthesizing
a band — the text's own range is already wider than any padding we'd add, and re-widening it
would blur two distinct hill-sprint intensities together.

**Why ±3% for a single-point target:** a zero-width target would make the watch beep
continuously (GPS-derived instantaneous pace never exactly matches a fixed target, and consumer
GPS pace accuracy itself has on the order of a 2-3% real-world jitter even at a truly constant
effort). A ±3% relative band is wide enough to stop constant nagging while still meaningfully
distinguishing 80% / 90% / 100% VMA targets from each other (adjacent targets 10 percentage
points apart stay well outside each other's ±3% bands). This is a spike default, not a tuned
value — flagged as an open decision in §8.

**Worked example at VMA = 16.0 km/h (the reference value used for `spike/output/*.fit`):**

| %VMA | Target speed | Pace (display) | Band low speed / pace | Band high speed / pace |
|---|---|---|---|---|
| 80% | 12.80 km/h (3.556 m/s) | 4'41"/km | 12.416 km/h → 4'50"/km | 13.184 km/h → 4'33"/km |
| 90% | 14.40 km/h (4.000 m/s) | 4'10"/km | 13.968 km/h → 4'17"/km | 14.832 km/h → 4'02"/km |
| 100% | 16.00 km/h (4.444 m/s) | 3'45"/km | 15.520 km/h → 3'52"/km | 16.480 km/h → 3'38"/km |

Pace display formula: `pace_sec_per_km = 3600 / speed_kmh`, formatted `m'ss"`. Note the
low-**speed** bound is the **slower** (higher-number) pace, and the high-**speed** bound is the
**faster** (lower-number) pace — this inversion is easy to get backwards and is called out
explicitly in `spike/generate.html`'s preview table column headers.

## 6. Known limitations

- **FIT repeat steps cannot nest.** A `workoutStep` with `durationType = repeatUntilStepsCmplt`
  jumps back to a single `messageIndex`; it cannot itself contain another repeat-control step in
  its loop body without ambiguity about which loop a "jump back" belongs to. The model's rule —
  a `repeat_group.repeat.steps` array **must not** contain a nested `kind: "repeat_group"` — pushes
  this flattening requirement to authoring time, not encoding time.
  - **`2026-05-05` (the chosen/encoded session):** single-level already — `3 × (900/600/300)` is
    one repeat group with a 6-step body (3 work + 3 recovery). Supported natively, no flattening
    needed.
  - **`2026-05-19` (the stress test, modeled here but not encoded):** on inspection, this session
    also turns out to need only a **single level** of repeat, not a true repeat-inside-a-repeat.
    The "2 blocs de [100/200/300/200/100 pyramid, with 100m-trot recoveries between each distance
    and a 4' recovery between blocks]" is one `repeat_group` (`count: 2`) whose body is a flat,
    heterogeneous 10-step sequence (5 distinct work distances + 5 distinct recoveries) — FIT
    permits arbitrary step content inside a repeat body, it does not require the repeated unit to
    be a simple work/recovery pair. See the full JSON below — it is flattened by construction
    (no nested `repeat_group` appears), which is the general strategy this brief recommends for
    the case where a session genuinely does describe a repeat-of-a-repeat (e.g. a hypothetical
    "3 sets of (2 × (400m/200m))"): unroll the inner repeat N times into a flat step list at
    authoring time, and let only the outer loop remain a real `repeat_group`.
  - The "Retour au métro" tail (`3 × 3' à 90% VMA / Récup 1'30`) is a **second, independent**
    `repeat_group` at the top level of `steps[]` — not nested inside the pyramid group.

  Full structured JSON for `2026-05-19`, G1/G2 (flattened, no nested `repeat_group`):

  ```json
  {
    "steps": [
      { "kind": "warmup", "name": "Footing vers la zone",
        "duration": { "type": "time", "value": 1200 }, "target": null },
      { "kind": "warmup", "name": "Gammes en côtes",
        "duration": { "type": "time", "value": 900 }, "target": null },
      { "kind": "repeat_group", "name": "Pyramide 100/200/300/200/100",
        "duration": null, "target": null,
        "repeat": {
          "count": 2,
          "steps": [
            { "kind": "work", "name": "100m à 110% VMA",
              "duration": { "type": "distance", "value": 100 },
              "target": { "type": "vma_pct", "pct": 110, "pct_low": null, "pct_high": null } },
            { "kind": "recovery", "name": "Récup trot 100m",
              "duration": { "type": "distance", "value": 100 }, "target": null },
            { "kind": "work", "name": "200m à 100% VMA",
              "duration": { "type": "distance", "value": 200 },
              "target": { "type": "vma_pct", "pct": 100, "pct_low": null, "pct_high": null } },
            { "kind": "recovery", "name": "Récup trot 100m",
              "duration": { "type": "distance", "value": 100 }, "target": null },
            { "kind": "work", "name": "300m à 100% VMA",
              "duration": { "type": "distance", "value": 300 },
              "target": { "type": "vma_pct", "pct": 100, "pct_low": null, "pct_high": null } },
            { "kind": "recovery", "name": "Récup trot 100m",
              "duration": { "type": "distance", "value": 100 }, "target": null },
            { "kind": "work", "name": "200m à 100% VMA",
              "duration": { "type": "distance", "value": 200 },
              "target": { "type": "vma_pct", "pct": 100, "pct_low": null, "pct_high": null } },
            { "kind": "recovery", "name": "Récup trot 100m",
              "duration": { "type": "distance", "value": 100 }, "target": null },
            { "kind": "work", "name": "100m à 110% VMA",
              "duration": { "type": "distance", "value": 100 },
              "target": { "type": "vma_pct", "pct": 110, "pct_low": null, "pct_high": null } },
            { "kind": "recovery", "name": "Récup bloc",
              "duration": { "type": "time", "value": 240 }, "target": null }
          ]
        }
      },
      { "kind": "repeat_group", "name": "Retour au métro",
        "duration": null, "target": null,
        "repeat": {
          "count": 3,
          "steps": [
            { "kind": "work", "name": "3' allure 90% VMA",
              "duration": { "type": "time", "value": 180 },
              "target": { "type": "vma_pct", "pct": 90, "pct_low": null, "pct_high": null } },
            { "kind": "recovery", "name": "Récup 1'30",
              "duration": { "type": "time", "value": 90 }, "target": null }
          ]
        }
      }
    ]
  }
  ```

  What's lost/flagged for `2026-05-19`:
  - **"en côtes" / hill context** — the model has no grade/incline field. FIT does support a
    `grade` target type (`wktStepTarget` value 5, seen in the profile excerpt) but wiring hill
    grade targets is out of scope for this spike; the hill context survives only in the step
    `name` string, not as an enforceable target.
  - **"en trottinant" (jogging recovery, as opposed to walking or standing)** — the model
    captures the recovery as a plain distance-based `recovery` step; the *manner* of the recovery
    (jog vs walk vs stand) has no field. Same treatment as "gammes"/"lignes droites" below.
  - **Trailing recovery after the last repetition** — both `2026-05-05`'s `R = 3' entre les
    séries` and `2026-05-19`'s `Récup bloc : 4'` are encoded as the last step of their repeat
    body, per the FIT convention (§ mapping table (b)). This means FIT will play that recovery
    **after every iteration, including the final one** — e.g. `2026-05-05` G1/G2 will show a 3'
    recovery after the 3rd (final) series even though the DRC text implies R only separates
    series from each other (so 2 occurrences, not 3). This is a structural FIT limitation (a
    repeat body has no "except on the last iteration" step) shared with how most FIT-authoring
    tools (TrainingPeaks, intervals.icu) handle it — the accepted convention is that the runner
    simply stops/skips the trailing recovery once the workout is otherwise complete. Documented
    here so it's not mistaken for an encoder bug when reviewing `verify_fit.py` output.

- **"Gammes" and "lignes droites" (drills/strides) have no duration in the source text and no
  structural content.** They become `kind: "warmup"`, `duration: {type: "open"}` (no fixed end —
  device waits for a manual lap-button press to advance) with only a descriptive `name`. The
  actual content of a "gamme" (skipping drills, heel flicks, high knees, etc.) is not
  representable and is not attempted — an "open" step with a label is the ceiling of fidelity
  here without inventing new step kinds. Flagged as an open decision in §8.

## 7. Reference: pattern-variation session (`2026-04-07`, glanced at, not fully modeled)

`Cycle VMA — Variations 300/200` repeats a "300/200/300/200" block four times, but with an
*alternating starting order* on later blocks (`300/200/300/200` then three times
`200/300/200/300`) — see `spike/session-sample.md` for the full text. This is **not** the same
irregularity as the `2026-05-19` pyramid (which is symmetric, not alternating) — it's included
here only to note that "N reps of what looks like the same block" in DRC text is not always a
clean, literal repeat at the FIT level: a mechanical translation would need per-repetition
step lists (4 distinct sequences) rather than one `repeat_group`, i.e. **not** every
`N × (...)`-shaped phrase in the corpus maps to a single native FIT repeat step — some need to be
authored as N consecutive `repeat_group`s of count 1 (equivalently, N flat step sequences) if the
per-repetition order genuinely varies. No JSON is produced for this session in this brief; it is
noted as a corpus-level caveat for whoever authors structured data for the remaining ~34
historical sessions.

## 8. Open decisions for the EM

1. **VMA source at generation time.** This spike reads `localStorage['drc_vma']` (matching the
   existing site's VMA calculator) with a manual override input. A member-profile VMA stored in
   Supabase (tied to their authenticated account) would let the export always use the *current*
   member's VMA without them re-typing it, and would open the door to a "download my workout"
   button embedded directly in the Entrainement tab per-session accordion. **Recommendation:**
   keep `localStorage` for now (matches the existing site's own precedent of *not* storing VMA in
   the DB, per `CLAUDE.md` — "VMA stays in `localStorage` (intentionally not in the DB)") — revisit
   only if per-member FIT export becomes a real feature, not just a spike.
2. **Backfill ~36 historical sessions vs. structuring new sessions only.** Backfilling every past
   session into the structured model is a meaningful one-time authoring cost (likely
   semi-automated parsing of the free text, given the corpus caveat in §7) for something with
   diminishing value once a session is in the past. **Recommendation:** structure new sessions
   only, going forward, authored by the `drc-publish-session` skill at insert time; do not
   backfill history unless a specific need for historical exports emerges.
3. **Authoring safety — how does the skill avoid shipping a wrong workout?** Two options: (a) a
   preview-only path (structured JSON is generated but a human reviews the rendered step table —
   the exact table this spike's `generate.html` produces — before the FIT file is offered for
   download) vs (b) automated validation (e.g., total structured duration/distance should
   roughly match the sum implied by the free-text `g12`, sanity bounds on %VMA values, etc.).
   **Recommendation:** (a) first — the human-readable preview table already doubles as manual QA,
   is cheap, and matches how the skill's author currently reviews the WhatsApp text before
   publishing; add (b) only if preview-based review proves insufficient in practice.
4. **Free-run/approximate segments ("gammes", "lignes droites", "footing libre").** Per §6, the
   spike's model represents these as `duration: {type: "open"}` warmup steps rather than omitting
   them. **Recommendation:** keep them as open steps (so the watch still shows *something* named
   during warmup, rather than silently jumping from file-start straight to the first timed
   step) — omitting them entirely would make the FIT file's step count silently diverge from the
   DRC text's described structure, which seems like the worse failure mode for a training tool.
5. **Band width for single-point %VMA targets.** ±3% is this spike's default (§5) — worth
   validating against Alexandre's actual on-watch experience (does it beep too often / too
   rarely?) before treating it as a real setting rather than a spike placeholder.
