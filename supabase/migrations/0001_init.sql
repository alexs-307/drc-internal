-- =============================================================================
-- 0001_init.sql
-- DRC Internal — initial schema bootstrap
-- Tables: members, sessions, races, resources
-- Includes: is_admin() helper, handle_new_user() trigger, RLS policies
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Helper: is_admin(uid)
-- SECURITY DEFINER so it runs as the function owner (bypasses RLS), which
-- prevents infinite recursion when the members policies call it.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin(uid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.members
    WHERE id = uid
      AND role = 'admin'
  );
$$;


-- ---------------------------------------------------------------------------
-- Table: members
-- 1:1 with auth.users via shared PK. Club-specific profile fields only.
-- VMA is intentionally NOT stored here — it stays in browser localStorage.
-- ---------------------------------------------------------------------------
CREATE TABLE public.members (
  id          uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name  text        NOT NULL,
  last_name   text        NOT NULL,
  email       text        NOT NULL,
  birth_date  date,
  role        text        NOT NULL DEFAULT 'member'
                          CHECK (role IN ('member', 'admin')),
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;

-- SELECT: own row, or admin sees all rows
CREATE POLICY "members_select_own_or_admin"
  ON public.members
  FOR SELECT
  USING (
    auth.uid() = id
    OR public.is_admin(auth.uid())
  );

-- INSERT: blocked at the policy layer.
-- The handle_new_user() trigger (SECURITY DEFINER) is the only writer.
-- We create an explicit restrictive policy so the intent is documented.
CREATE POLICY "members_insert_blocked"
  ON public.members
  FOR INSERT
  WITH CHECK (false);

-- UPDATE: own row, but cannot escalate role; admins can update any row.
CREATE POLICY "members_update_own_no_role_change"
  ON public.members
  FOR UPDATE
  USING (
    auth.uid() = id
    OR public.is_admin(auth.uid())
  )
  WITH CHECK (
    -- Non-admins may not change their own role
    CASE
      WHEN public.is_admin(auth.uid()) THEN true
      ELSE role = (SELECT m.role FROM public.members m WHERE m.id = auth.uid())
    END
  );

-- DELETE: admins only
CREATE POLICY "members_delete_admin_only"
  ON public.members
  FOR DELETE
  USING (public.is_admin(auth.uid()));


-- ---------------------------------------------------------------------------
-- Table: sessions
-- Mirrors sessions.json 1:1. One row per training session.
-- ---------------------------------------------------------------------------
CREATE TABLE public.sessions (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  date        date        NOT NULL,
  label       text        NOT NULL,
  venue       text        NOT NULL,
  g12         text        NOT NULL,
  g3          text,
  suggestion  text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

-- SELECT: public read — session content is not sensitive; any site visitor
-- (logged in or not) should be able to view the training schedule.
CREATE POLICY "sessions_select_public"
  ON public.sessions
  FOR SELECT
  USING (true); -- public read for site visitors; member-only data lives in `members` only

-- INSERT: admins only
CREATE POLICY "sessions_insert_admin_only"
  ON public.sessions
  FOR INSERT
  WITH CHECK (public.is_admin(auth.uid()));

-- UPDATE: admins only
CREATE POLICY "sessions_update_admin_only"
  ON public.sessions
  FOR UPDATE
  USING (public.is_admin(auth.uid()));

-- DELETE: admins only
CREATE POLICY "sessions_delete_admin_only"
  ON public.sessions
  FOR DELETE
  USING (public.is_admin(auth.uid()));


-- ---------------------------------------------------------------------------
-- Table: races
-- Replaces the races[] JS array literal in index.html.
-- `date` is NULL for approximate dates; `date_label` holds the display string.
-- ---------------------------------------------------------------------------
CREATE TABLE public.races (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text        NOT NULL,
  type        text        NOT NULL,   -- e.g. "21.1km", "42.2km", "Trail 25km"
  date        date,                   -- NULL when date is approximate
  date_label  text,                   -- e.g. "Mi-octobre" — shown when date IS NULL
  url         text,
  pillar      boolean     NOT NULL DEFAULT false,
  confirmed   boolean     NOT NULL DEFAULT true,
  note        text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.races ENABLE ROW LEVEL SECURITY;

-- SELECT: public read — the race calendar is public-facing content.
CREATE POLICY "races_select_public"
  ON public.races
  FOR SELECT
  USING (true); -- public read for site visitors; member-only data lives in `members` only

-- INSERT: admins only
CREATE POLICY "races_insert_admin_only"
  ON public.races
  FOR INSERT
  WITH CHECK (public.is_admin(auth.uid()));

-- UPDATE: admins only
CREATE POLICY "races_update_admin_only"
  ON public.races
  FOR UPDATE
  USING (public.is_admin(auth.uid()));

-- DELETE: admins only
CREATE POLICY "races_delete_admin_only"
  ON public.races
  FOR DELETE
  USING (public.is_admin(auth.uid()));


-- ---------------------------------------------------------------------------
-- Table: resources
-- Metadata for club PDF documents. PDF files stay in the GitHub repo at
-- ressources/*.pdf — only the relative path is stored here.
-- ---------------------------------------------------------------------------
CREATE TABLE public.resources (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  title         text        NOT NULL,
  description   text        NOT NULL,
  pdf_path      text        NOT NULL,   -- e.g. "ressources/vma_seuil.pdf"
  preview_path  text,                   -- e.g. "ressources/vma_seuil_preview.png"
  display_order int         NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;

-- SELECT: public read — resource metadata (PDF titles, descriptions) is
-- not sensitive; any site visitor should be able to list available documents.
CREATE POLICY "resources_select_public"
  ON public.resources
  FOR SELECT
  USING (true); -- public read for site visitors; member-only data lives in `members` only

-- INSERT: admins only
CREATE POLICY "resources_insert_admin_only"
  ON public.resources
  FOR INSERT
  WITH CHECK (public.is_admin(auth.uid()));

-- UPDATE: admins only
CREATE POLICY "resources_update_admin_only"
  ON public.resources
  FOR UPDATE
  USING (public.is_admin(auth.uid()));

-- DELETE: admins only
CREATE POLICY "resources_delete_admin_only"
  ON public.resources
  FOR DELETE
  USING (public.is_admin(auth.uid()));


-- ---------------------------------------------------------------------------
-- Auth trigger: handle_new_user()
-- Fires AFTER INSERT on auth.users. Creates the matching members row.
-- SECURITY DEFINER so it can insert past the members INSERT policy (which
-- is set to WITH CHECK (false) to block direct client inserts).
-- Falls back to '?' placeholder if first_name / last_name are absent from
-- raw_user_meta_data so the trigger never hard-fails a signup.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.members (id, first_name, last_name, email, birth_date, role)
  VALUES (
    NEW.id,
    COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'first_name'), ''), '?'),
    COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'last_name'),  ''), '?'),
    NEW.email,
    CASE
      WHEN NEW.raw_user_meta_data->>'birth_date' IS NOT NULL
       AND NEW.raw_user_meta_data->>'birth_date' <> ''
      THEN (NEW.raw_user_meta_data->>'birth_date')::date
      ELSE NULL
    END,
    'member'
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();


-- =============================================================================
-- ROLLBACK INSTRUCTIONS (comment only — do not execute unless intentional)
--
-- To tear down this migration, run in this exact order (reverse FK dependency):
--
--   DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
--   DROP FUNCTION IF EXISTS public.handle_new_user();
--   DROP FUNCTION IF EXISTS public.is_admin(uuid);
--   DROP TABLE IF EXISTS public.resources;
--   DROP TABLE IF EXISTS public.races;
--   DROP TABLE IF EXISTS public.sessions;
--   DROP TABLE IF EXISTS public.members;
--
-- Note: `members` must be dropped last because it is the only table with a
-- FK dependency (on auth.users). The other three tables have no FK references
-- to each other, so their drop order is arbitrary within the first three drops.
--
-- Policies are automatically dropped when their table is dropped.
-- =============================================================================
