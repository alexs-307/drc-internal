-- =============================================================================
-- 0006_add_season_column_to_sessions.sql
-- DRC Internal — generated `season` column on public.sessions
--
-- Context / reasoning:
--   The Entrainement tab is moving to a per-season view. Every session row
--   needs a `season` value — for the ~100 existing rows and, critically, for
--   every row inserted from now on — WITHOUT changing the insert path.
--
--   The insert path (supabase/scripts/insert_session.sh, driven by the
--   drc-publish-session skill) lives in a *different* repository (the parent
--   DRC project). A plain `season text` column would require a coordinated
--   cross-repo change to that script, and any row inserted without it would
--   silently get NULL and vanish from a season-filtered UI — a footgun we
--   want to make structurally impossible.
--
--   Solution: a `GENERATED ALWAYS ... STORED` column computed from `date`.
--   Postgres derives it on every INSERT and UPDATE automatically, server-side.
--   The insert path needs zero changes — it already sends `date`.
--
-- The season rule — boundary is 1 August, not 1 September:
--   A season runs 1 August → 31 July, labelled 'YYYY-YYYY':
--     - month >= 8 (Aug–Dec)  → season = '<year>-<year+1>'
--     - month <= 7 (Jan–Jul)  → season = '<year-1>-<year>'
--
--   Why August and not September: the earliest session in the DB is
--   2025-08-26 (the reprise). A hypothetical September boundary would use
--   month >= 9 as its cutoff — under that rule, month 8 fails the check and
--   falls to the else branch, producing '<year-1>-<year>' = a phantom
--   '2024-2025' season containing exactly that single row, with no other
--   session anywhere near it. The shipped rule here uses month >= 8, which
--   correctly buckets the reprise into '2025-2026' together with the rest
--   of that season.
--
--   Verified against real data:
--     2025-08-26 (earliest session)              → '2025-2026'
--     Sept 2025 .. July 2026 (incl. real sessions
--       in June and July 2026)                   → '2025-2026'
--     (no sessions exist in August 2026)
--     Sept 2026 onward                           → '2026-2027'
--
--   Reference table (verified by hand, see self-check below):
--     2025-08-26 -> '2025-2026'
--     2025-12-09 -> '2025-2026'
--     2026-01-13 -> '2025-2026'
--     2026-07-14 -> '2025-2026'
--     2026-09-08 -> '2026-2027'
--     2026-12-01 -> '2026-2027'
--
-- Immutability (required for a generated column expression):
--   EXTRACT(... FROM <date>) is IMMUTABLE when the source is a plain `date`
--   (it is only STABLE for `timestamptz`, because that depends on the
--   session's time zone setting). `sessions.date` is a plain `date` column,
--   so EXTRACT is safe here.
--   `to_char()` is deliberately NOT used — it depends on the `lc_time`
--   locale setting and is not IMMUTABLE, so Postgres would reject it in a
--   generated column expression.
--   EXTRACT returns `numeric` on modern Postgres. The expression casts
--   through `::int` before `::text` on every extracted value — not because
--   a numeric-to-text cast here would otherwise produce a trailing decimal
--   point (EXTRACT of YEAR/MONTH from a `date` is scale-0 numeric, so it
--   would not), but because the `::int` cast makes the label's type
--   explicit and self-documenting, and keeps the `+ 1` as integer
--   arithmetic rather than numeric arithmetic.
--
-- Nullability: `season` has no explicit NOT NULL constraint, but it is
-- implicitly always populated — `sessions.date` is itself NOT NULL (see
-- 0001_init.sql), so the generated expression always has an input and never
-- produces NULL.
--
-- RLS: no policy change needed or included here. A new column inherits the
-- table's existing RLS policies verbatim (RLS is enforced per-row, not
-- per-column) — the sessions_select_public / insert_admin_only /
-- update_admin_only / delete_admin_only policies from 0001_init.sql already
-- cover this column with no further action.
--
-- Indexing: deliberately NOT added. public.sessions holds roughly a hundred
-- rows today and the frontend fetches the full table and filters/groups by
-- season client-side — a sequential scan is effectively free at this size.
-- Revisit (e.g. `CREATE INDEX ON public.sessions (season);`) if the table
-- grows into the thousands of rows or a query starts filtering server-side
-- by season instead of fetching everything.
--
-- Performance note: adding a STORED generated column rewrites the entire
-- table (Postgres must compute and store the value for every existing row).
-- At ~100 rows this is instant; not a concern at this scale.
-- =============================================================================

ALTER TABLE public.sessions
  ADD COLUMN season text GENERATED ALWAYS AS (
    CASE
      WHEN EXTRACT(MONTH FROM date)::int >= 8
        THEN EXTRACT(YEAR FROM date)::int::text
             || '-'
             || (EXTRACT(YEAR FROM date)::int + 1)::text
      ELSE (EXTRACT(YEAR FROM date)::int - 1)::text
             || '-'
             || EXTRACT(YEAR FROM date)::int::text
    END
  ) STORED;


-- =============================================================================
-- SANITY CHECK (paste into Supabase SQL editor after running the migration)
--
-- 1. Season distribution — expected: two groups, '2025-2026' spanning
--    2025-08-26 through some date in July 2026, and '2026-2027' starting in
--    September 2026 (no August 2026 sessions exist).
--
-- SELECT season, COUNT(*) AS row_count, MIN(date) AS earliest, MAX(date) AS latest
-- FROM   public.sessions
-- GROUP BY season
-- ORDER BY season;
--
-- 2. Spot-check the earliest row — expected: date = 2025-08-26, season = '2025-2026'.
--
-- SELECT date, season
-- FROM   public.sessions
-- ORDER BY date ASC
-- LIMIT  1;
--
-- 3. Reference cases (verified by hand against the expression above):
--    2025-08-26 -> '2025-2026'
--    2025-12-09 -> '2025-2026'
--    2026-01-13 -> '2025-2026'
--    2026-07-14 -> '2025-2026'
--    2026-09-08 -> '2026-2027'
--    2026-12-01 -> '2026-2027'
-- =============================================================================


-- =============================================================================
-- ROLLBACK INSTRUCTIONS (comment only — do not execute unless intentional)
--
--   ALTER TABLE public.sessions DROP COLUMN season;
--
-- On PostgreSQL 16 and earlier, a GENERATED ALWAYS expression cannot be
-- altered in place (confirmed: this errors on 16.13). PostgreSQL 17 adds
-- `ALTER TABLE ... ALTER COLUMN ... SET EXPRESSION AS (...)`, which can
-- change the expression without a drop/re-add — this repo does not pin a
-- Postgres version, so a new-enough Supabase project could support it.
-- Regardless of which is available, the supported path for this project is
-- DROP COLUMN and re-ADD via a new forward migration (e.g.
-- 0007_change_season_boundary.sql), not an in-place ALTER, so the rule's
-- full history stays legible as separate files in supabase/migrations/.
-- This is the accepted trade-off for keeping the external insert-path
-- repository untouched: the rule lives entirely in this repo's schema, and
-- any future change to it is a single forward-only migration here, not a
-- cross-repo coordination.
-- =============================================================================
