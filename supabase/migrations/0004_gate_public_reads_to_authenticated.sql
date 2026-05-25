-- =============================================================================
-- 0004_gate_public_reads_to_authenticated.sql
-- DRC Internal — tighten SELECT policies on sessions, races, resources
--
-- Policy shift: public read → authenticated read only
-- -------------------------------------------------------
-- PR 1 (0001_init.sql) deliberately set SELECT policies on sessions, races,
-- and resources to USING (true), allowing any anonymous request to read these
-- tables. At the time, the site was "publicly readable but unlisted" — content
-- was non-sensitive and protected only by obscurity (robots.txt + no links).
--
-- This migration (PR 5) pivots to a members-only posture. The site UI is
-- simultaneously gated behind a Supabase auth check (implementer's half of
-- this PR). This migration makes the API layer consistent with that gate:
-- anonymous requests with only the publishable anon key can no longer read
-- sessions, races, or resources. Only authenticated users can.
--
-- The guard used is `auth.uid() IS NOT NULL`. auth.uid() is a Supabase-provided
-- function that returns the UUID of the currently authenticated user, or NULL
-- for anonymous (unauthenticated) requests. A non-NULL uid proves a valid
-- session token was sent.
--
-- Brief reference: .claude/design-briefs/members-only-gate.md
-- Original public-read brief: .claude/design-briefs/supabase-schema-init.md
--
-- Scope of this migration:
--   CHANGED:  sessions SELECT · races SELECT · resources SELECT
--   UNCHANGED: all INSERT/UPDATE/DELETE policies on all four tables
--   UNCHANGED: all members table policies (were never public)
-- =============================================================================


-- ---------------------------------------------------------------------------
-- sessions: replace public SELECT with authenticated-only SELECT
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "sessions_select_public" ON public.sessions;

-- authenticated read only — was public before PR 5; see brief
CREATE POLICY "sessions_select_authenticated"
  ON public.sessions
  FOR SELECT
  USING (auth.uid() IS NOT NULL);


-- ---------------------------------------------------------------------------
-- races: replace public SELECT with authenticated-only SELECT
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "races_select_public" ON public.races;

-- authenticated read only — was public before PR 5; see brief
CREATE POLICY "races_select_authenticated"
  ON public.races
  FOR SELECT
  USING (auth.uid() IS NOT NULL);


-- ---------------------------------------------------------------------------
-- resources: replace public SELECT with authenticated-only SELECT
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "resources_select_public" ON public.resources;

-- authenticated read only — was public before PR 5; see brief
CREATE POLICY "resources_select_authenticated"
  ON public.resources
  FOR SELECT
  USING (auth.uid() IS NOT NULL);


-- =============================================================================
-- VERIFICATION (paste into Supabase SQL editor after applying this migration)
--
-- After applying, verify policies are in place:
-- SELECT schemaname, tablename, policyname, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public' AND tablename IN ('sessions','races','resources') AND cmd = 'SELECT';
--
-- Expected: 3 rows (one per table), each with `qual` = `(auth.uid() IS NOT NULL)`.
-- =============================================================================


-- =============================================================================
-- ROLLBACK INSTRUCTIONS (comment only — do not execute unless intentional)
--
-- To revert this migration and restore the original public-read posture from
-- 0001_init.sql, run the following DROP+CREATE pairs in any order:
--
--   DROP POLICY IF EXISTS "sessions_select_authenticated" ON public.sessions;
--   CREATE POLICY "sessions_select_public"
--     ON public.sessions
--     FOR SELECT
--     USING (true); -- public read for site visitors; member-only data lives in `members` only
--
--   DROP POLICY IF EXISTS "races_select_authenticated" ON public.races;
--   CREATE POLICY "races_select_public"
--     ON public.races
--     FOR SELECT
--     USING (true); -- public read for site visitors; member-only data lives in `members` only
--
--   DROP POLICY IF EXISTS "resources_select_authenticated" ON public.resources;
--   CREATE POLICY "resources_select_public"
--     ON public.resources
--     FOR SELECT
--     USING (true); -- public read for site visitors; member-only data lives in `members` only
--
-- After rollback: anonymous API requests can again read all three tables.
-- Note: if the frontend gate (PR 5 implementer half) is still in place,
-- anonymous visitors still see only the sign-in card in the UI — but the
-- API layer will no longer enforce auth, which restores the pre-PR5 posture.
-- =============================================================================
