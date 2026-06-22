-- =============================================================================
-- 0005_race_updates_chablis_boulogne.sql
-- DRC Internal — data correction: Chablis replaces rentrée slot, Boulogne confirmed
--
-- Context / reasoning:
--   Two races in public.races required updating as of 2026-06-22 (today):
--
--   1. "Weekend de Rentrée DRC" was a placeholder row seeded in 0002 while the
--      club voted on which race to target for the October 2026 rentrée weekend.
--      The vote has now closed: the chosen race is "Trail/Semi-marathon de Chablis"
--      on 2026-10-24 (date unchanged). The deadline-for-candidatures note is no
--      longer relevant (deadline was 15 juin 2026 — now past). confirmed is flipped
--      to true: the race is decided.
--
--   2. "Semi-marathon de Boulogne" was seeded in 0002 as approximate (date_label =
--      'Mi-novembre 2026', date = NULL), then given a best-guess date of 2026-11-15
--      by migration 0003 — but date_label was left in place, keeping the row in
--      "approximate" display mode. The race date is now confirmed as 2026-11-15.
--      Per the convention established in 0003: clearing date_label to NULL is the
--      only step needed to flip the row from approximate to concrete. confirmed is
--      also set to true.
-- =============================================================================


-- Update 1: Replace "Weekend de Rentrée DRC" with "Trail/Semi-marathon de Chablis"
-- The AG vote closed; Trail/Semi-marathon de Chablis (2026-10-24) was chosen.
-- Drop the candidature-deadline note (past) and mark the race as confirmed.
UPDATE public.races
SET    name      = 'Trail/Semi-marathon de Chablis',
       type      = 'Trail',
       confirmed = true,
       note      = NULL
WHERE  name = 'Weekend de Rentrée DRC';

-- Update 2: Flip "Semi-marathon de Boulogne" from approximate to confirmed concrete date
-- 0003 set date = 2026-11-15 but left date_label = 'Mi-novembre 2026', keeping the
-- row in approximate-display mode. Date is now confirmed — clear date_label and
-- set confirmed = true. date = 2026-11-15 is left unchanged.
UPDATE public.races
SET    date_label = NULL,
       confirmed  = true
WHERE  name       = 'Semi-marathon de Boulogne'
  AND  date_label = 'Mi-novembre 2026';


-- =============================================================================
-- SANITY CHECK (paste into Supabase SQL editor after running the migration)
--
-- Expected result: 2 rows.
--   Row 1 — name='Trail/Semi-marathon de Chablis', type='Trail', date='2026-10-24',
--            date_label=NULL, confirmed=true, note=NULL
--   Row 2 — name='Semi-marathon de Boulogne', type='21.1km', date='2026-11-15',
--            date_label=NULL, confirmed=true, note=NULL
--
-- SELECT name, type, date, date_label, confirmed, note
-- FROM   public.races
-- WHERE  name IN ('Trail/Semi-marathon de Chablis', 'Semi-marathon de Boulogne')
-- ORDER BY date ASC;
-- =============================================================================


-- =============================================================================
-- ROLLBACK INSTRUCTIONS (comment only — do not execute unless intentional)
--
-- To revert Update 1 (restore the original rentrée placeholder row from 0002):
--
--   UPDATE public.races
--   SET    name      = 'Weekend de Rentrée DRC',
--          type      = 'Weekend long · vote en cours',
--          confirmed = false,
--          note      = 'Deadline candidatures : 15 juin 2026'
--   WHERE  name = 'Trail/Semi-marathon de Chablis';
--
-- To revert Update 2 (restore the approximate state from 0003):
--
--   UPDATE public.races
--   SET    date_label = 'Mi-novembre 2026',
--          confirmed  = false
--   WHERE  name = 'Semi-marathon de Boulogne';
--
-- =============================================================================
