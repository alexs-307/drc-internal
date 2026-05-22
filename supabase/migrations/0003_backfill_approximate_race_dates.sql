-- =============================================================================
-- 0003_backfill_approximate_race_dates.sql
-- DRC Internal — one-time data correction for approximate race dates
--
-- Context / reasoning (referenced in PR 3 — feat/supabase-frontend-cutover):
--   In 0002_seed_initial_data.sql, the 6 approximate races were seeded with
--   `date = NULL` per the original schema brief (NULL = approximate).
--   This caused a UX bug: ORDER BY date ASC NULLS LAST pushed all 6 rows to the
--   bottom of the race list in seed-insertion order, breaking chronological sort
--   (e.g. Semi-marathon de Boulogne, Nov 2026, appeared below Marathon de Paris,
--   Apr 2027).
--
--   Decision: store a best-guess date in `date` for every row (sortable), and
--   rely solely on `date_label IS NOT NULL` as the "approximate" flag. The
--   display string (e.g. "Mi-novembre 2026") is preserved in `date_label`.
--   After this migration, `date IS NULL` is no longer semantically meaningful
--   for the races table — `date_label IS NOT NULL` is the only flag needed.
--
--   Best-guess dates are taken verbatim from the original JS `dateStr` values
--   in the races[] array in index.html before that data was migrated to Postgres.
--   These are not guesses — they are the original source-of-truth values.
-- =============================================================================


-- Semi-marathon de Boulogne — best-guess mid-November 2026
UPDATE public.races
SET    date = '2026-11-15'
WHERE  name = 'Semi-marathon de Boulogne'
  AND  date IS NULL;

-- 10K de Montmartre — best-guess mid-January 2027
UPDATE public.races
SET    date = '2027-01-15'
WHERE  name = '10K de Montmartre'
  AND  date IS NULL;

-- Course folklore (Trail) — best-guess mid-February 2027
UPDATE public.races
SET    date = '2027-02-15'
WHERE  name = 'Course folklore (Trail)'
  AND  date IS NULL;

-- Semi-marathon de Paris — best-guess early-March 2027
UPDATE public.races
SET    date = '2027-03-07'
WHERE  name = 'Semi-marathon de Paris'
  AND  date IS NULL;

-- Marathon de Paris — best-guess mid-April 2027
UPDATE public.races
SET    date = '2027-04-13'
WHERE  name = 'Marathon de Paris'
  AND  date IS NULL;

-- Course de clôture de saison — best-guess mid-May 2027
UPDATE public.races
SET    date = '2027-05-15'
WHERE  name = 'Course de clôture de saison'
  AND  date IS NULL;


-- =============================================================================
-- SANITY CHECK (paste into Supabase SQL editor after running the migration)
--
-- Expected result: 8 rows, all with date IS NOT NULL.
-- The 6 backfilled rows also have date_label IS NOT NULL (approximate flag).
-- Concrete-date races (date_label IS NULL) sort first, then approximates by date.
--
-- SELECT name, date, date_label FROM public.races ORDER BY (date_label IS NOT NULL) ASC, date ASC;
-- =============================================================================


-- =============================================================================
-- ROLLBACK INSTRUCTIONS (comment only — do not execute unless intentional)
--
-- To revert this data correction (restores the original NULL state from 0002):
--
--   UPDATE public.races SET date = NULL WHERE name = 'Semi-marathon de Boulogne';
--   UPDATE public.races SET date = NULL WHERE name = '10K de Montmartre';
--   UPDATE public.races SET date = NULL WHERE name = 'Course folklore (Trail)';
--   UPDATE public.races SET date = NULL WHERE name = 'Semi-marathon de Paris';
--   UPDATE public.races SET date = NULL WHERE name = 'Marathon de Paris';
--   UPDATE public.races SET date = NULL WHERE name = 'Course de clôture de saison';
--
-- Note: after rollback the UX sort bug described above re-appears.
-- =============================================================================
