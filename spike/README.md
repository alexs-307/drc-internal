# Spike — Garmin-compatible workout export (FIT)

Proves the path end-to-end for one real DRC track session: structured step
model → Garmin `.FIT` workout file → downloadable/testable locally. See
`.claude/design-briefs/session-structured-steps.md` for the full data-model
design; this folder is the runnable proof.

## Why FIT, not TCX

Modern Garmin Connect does not import TCX **workout** files (TCX activity
files still work for uploads of a completed run, but not for pushing a
structured workout *plan* to a watch). The wider ecosystem that does deliver
structured workouts to Garmin devices (intervals.icu, TrainingPeaks) does so
as FIT, and the file-based path onto a watch is a `.fit` file dropped into
`GARMIN/NewFiles` over USB. `spike/reference/simple_workout_1.tcx` and
`TrainingCenterDatabasev2.xsd` were still pulled and reviewed as reference —
the TCX step/duration/intensity model is structurally similar and useful for
sanity-checking the design — but the encoder in this spike targets FIT only.

## Files

- `spike/fit-encoder.js` — dependency-free FIT binary encoder (header, CRC-16,
  definition/data messages for `file_id`/`workout`/`workoutStep`). Runs
  unmodified in a browser or under Node.
- `spike/session-model.js` — the one real session (`2026-05-05`) hard-coded as
  the structured-step model, for both G1/G2 and G3.
- `spike/generate.html` — standalone page (opens via `file://`, no build step,
  no network calls). VMA input, group toggle, human-readable step/pace
  preview table, "Télécharger .FIT" button.
- `spike/generate-outputs.js` — Node runner that calls the same
  `fit-encoder.js` + `session-model.js` to (re)produce the committed output
  files, so they're reproducible without opening a browser.
- `spike/output/*.fit` — committed output, generated at **VMA = 16.0 km/h**
  (see below).
- `spike/verify_fit.py` — standalone python3 (stdlib only) FIT decoder/verifier.
- `spike/reference/` — FIT SDK profile excerpt + a real Garmin TCX workout,
  both with provenance headers.
- `spike/session-sample.md` — raw session JSON rows this spike is built from,
  with provenance (git history, pre-Supabase-cutover backup).

## How to test locally

1. **Open the page.** Open `spike/generate.html` directly in a browser (double-click
   the file, or `file:///…/spike/generate.html`). No server needed.
2. **Set VMA.** Defaults from `localStorage['drc_vma']` if you have it set from
   the main site (same key), otherwise defaults to 16.0 km/h. Editable in the
   page directly.
3. **Toggle group.** G1/G2 (3 series) vs G3 (2 series) — everything else
   (warmup, per-rep structure, cooldown) is identical between the two; only
   the repeat count changes.
4. **Read the preview table.** This is the human-readable proof of the
   DRC-text → structured-model → pace mapping described in the design brief.
   Compare it against the step table below (produced by `verify_fit.py`) —
   they should describe the same workout.
5. **Download.** Click "Télécharger .FIT" — encodes client-side (Blob +
   download), no network call.
6. **Verify the binary.** Run:
   ```
   python3 spike/verify_fit.py spike/output/progressivite-allure-2026-05-05-g12.fit
   python3 spike/verify_fit.py spike/output/progressivite-allure-2026-05-05-g3.fit
   ```
   Both commands print `RESULT: PASS` when header/CRC/message structure are
   all valid, followed by the decoded step list.

### `verify_fit.py` output (committed files, VMA = 16.0 km/h)

Per the design brief's warmup/recovery/cooldown convention revision (§2), the warmup is now a
single open (press-lap) step and both recovery granularities (`r`/`R`) are open (press-lap) steps
with the prescribed time kept in the step name — see `.claude/design-briefs/session-structured-steps.md`
§2/§3/§5 for the full rationale and the recomputed repeat jump-back `messageIndex`.

**G1/G2 (3 series):**

```
=== spike/output/progressivite-allure-2026-05-05-g12.fit (628 bytes) ===
Header: size=14 protocol=0x10 profile_version=2132 data_size=612
Header CRC: OK
File CRC: OK
file_id: type=workout manufacturer=255 timeCreated=2026-07-06T12:00:00+00:00
file_id.type == workout: OK
workout: sport=running numValidSteps=9 wktName='Progressivité d'allure — Tem'
workout.numValidSteps matches actual workout_step count: OK

Decoded 9 workout_step message(s):

idx  name                     durationType             duration                     targetType target                   intensity
---------------------------------------------------------------------------------------------------------------------------------
  0  Échauffement — 20' EF + gamm open                     open                         open       open/none                warmup
  1  900m à 80% VMA           distance                 900m                         speed      speed 12.42-13.18 km/h   active
  2  Récup 2' (ou lap)        open                     open                         open       open/none                rest
  3  600m à 90% VMA           distance                 600m                         speed      speed 13.97-14.83 km/h   active
  4  Récup 2' (ou lap)        open                     open                         open       open/none                rest
  5  300m à 100% VMA          distance                 300m                         speed      speed 15.52-16.48 km/h   active
  6  Récup série 3' (ou lap)  open                     open                         open       open/none                recovery
  7                           repeatUntilStepsCmplt    jump back to messageIndex 1  open       repeat count = 3         n/a
  8  Retour au calme — 5' jog lég time                     300s                         open       open/none                cooldown

RESULT: PASS — header valid, CRC valid, file_id/workout/workout_step present and consistent
```

**G3 (2 series)** — identical except step 7 shows `repeat count = 2` (see
`spike/output/progressivite-allure-2026-05-05-g3.fit`, same command). Confirmed byte-identical to
the G1/G2 file except for the repeat-count field and the trailing whole-file CRC (3 differing
bytes total across the 628-byte files).

The workout pace bands above match the design brief's worked example (§5,
VMA = 16.0 km/h): 80% → 12.42–13.18 km/h, 90% → 13.97–14.83 km/h, 100% →
15.52–16.48 km/h. `wktStepName` values that exceed the 32-byte fixed field (e.g. the warmup step's
full name, `"Échauffement — 20' EF + gammes + lignes droites"`) are truncated on decode — expected,
see *Known limitations* below.

## On-watch test (not run by this spike — Alexandre's test)

1. Connect the watch via USB.
2. Copy `spike/output/progressivite-allure-2026-05-05-g12.fit` (or the `-g3`
   variant) into the watch's `GARMIN/NewFiles` folder.
3. Disconnect; the watch should import it into its workout list within a few
   seconds (device-dependent).
4. Alternatively, some Garmin Connect mobile app versions support importing a
   `.fit` workout file directly — try this first if USB access isn't
   convenient.
5. Open the imported workout on the watch and check: 9 steps, correct
   warmup/work/recovery/cooldown order, correct repeat count (3 for G1/G2, 2
   for G3), pace targets that roughly match the table above for the VMA used,
   and that the warmup step and both recovery steps show as press-lap
   (open-duration, no countdown) rather than a running timer.

## What "passed" means

- **"Local test passed"** = `verify_fit.py`'s output (above) matches the
  session structure table in `.claude/design-briefs/session-structured-steps.md`
  §3 — i.e. the encoder faithfully turned the structured model into valid FIT
  bytes. This has been confirmed for both committed files.
- **"Spike validated"** = the workout actually appears and runs correctly on
  a real Garmin watch, with the right steps and pace alerts — this requires
  Alexandre's hardware and has **not** been performed as part of this spike.

## Known limitations (see the design brief for the full list)

- **`wktStepName` / `wktName` truncation.** Both are fixed-size 32-byte
  (null-terminated) string fields in this encoder. Accented characters are
  UTF-8 multi-byte, so `wktName` for this session truncates to `'Progressivité
  d'allure — Tem'` in the decoded output above — cosmetic only (does not
  affect duration/target/intensity data), but worth knowing before assuming
  the full session name will show on-device. The same truncation now also
  shows up on the (longer) combined warmup step name and the cooldown step
  name, both visible truncated in the decoded output above.
- **Trailing recovery after the final repetition** (`R = 3'` after the 3rd/2nd
  series, `Récup bloc` after the 2nd pyramid block in the stress-test
  session) — a structural FIT limitation, not an encoder bug. Since this
  revision, the trailing recovery is open-duration rather than a forced timer
  (design brief §2), so in practice it costs a single lap-press to skip past
  rather than a full forced wait — but the extra step still fires; FIT has no
  "except on the last iteration" step type. See design brief §6.
- Everything else (nested-repeat flattening, "gammes"/"lignes droites"
  fidelity, band-width choice, hill-grade context) is discussed in the design
  brief, not repeated here.
