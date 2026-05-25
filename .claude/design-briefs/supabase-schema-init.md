# Supabase schema init (0001_init.sql) — backend brief

## Goal

Bootstrap the Supabase Postgres database for drc-internal with four tables, RLS policies, an auth trigger, and the supporting `.env` template. This is PR 1 of the migration described in `website_audit/audit_dynamic_website_migration.md` — Option C path.

No frontend changes in this PR. No data migration in this PR. Just schema + policies + the env template.

## Tables

### `members`
Mirrors Supabase `auth.users` 1:1 via shared `id`. Holds the club-specific profile fields. VMA is intentionally NOT stored here — it stays in browser `localStorage`.

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, FK to `auth.users(id)` ON DELETE CASCADE |
| `first_name` | `text` | NOT NULL |
| `last_name` | `text` | NOT NULL |
| `email` | `text` | NOT NULL |
| `birth_date` | `date` | NULL allowed |
| `role` | `text` | NOT NULL, DEFAULT `'member'`, CHECK `role IN ('member', 'admin')` |
| `created_at` | `timestamptz` | NOT NULL, DEFAULT `now()` |

### `sessions`
Mirrors today's `sessions.json` 1:1.

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` |
| `date` | `date` | NOT NULL |
| `label` | `text` | NOT NULL |
| `venue` | `text` | NOT NULL |
| `g12` | `text` | NOT NULL |
| `g3` | `text` | NULL allowed |
| `suggestion` | `text` | NULL allowed |
| `created_at` | `timestamptz` | NOT NULL, DEFAULT `now()` |

### `races`
Replaces the `races[]` JS array literal in `index.html`. Keeps the three visible-on-calendar fields the user confirmed (`pillar`, `confirmed`, `note`). `type` is the format/distance string (free text), matching today's `format` field.

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` |
| `name` | `text` | NOT NULL |
| `type` | `text` | NOT NULL (e.g. `"21.1km"`, `"42.2km"`, `"Trail 25km"`) |
| `date` | `date` | NULL allowed (for approximate dates) |
| `date_label` | `text` | NULL allowed (e.g. `"Mi-octobre"` — shown when `date` is NULL) |
| `url` | `text` | NULL allowed |
| `pillar` | `boolean` | NOT NULL, DEFAULT `false` |
| `confirmed` | `boolean` | NOT NULL, DEFAULT `true` |
| `note` | `text` | NULL allowed |
| `created_at` | `timestamptz` | NOT NULL, DEFAULT `now()` |

### `resources`
Metadata about PDFs. The PDF files themselves stay in the GitHub repo at `ressources/*.pdf` — only paths are stored here.

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, DEFAULT `gen_random_uuid()` |
| `title` | `text` | NOT NULL |
| `description` | `text` | NOT NULL |
| `pdf_path` | `text` | NOT NULL (e.g. `"ressources/vma_seuil.pdf"`) |
| `preview_path` | `text` | NULL allowed (e.g. `"ressources/vma_seuil_preview.png"`) |
| `display_order` | `int` | NOT NULL, DEFAULT `0` |
| `created_at` | `timestamptz` | NOT NULL, DEFAULT `now()` |

## RLS policies

Every table has `ENABLE ROW LEVEL SECURITY`. Every table has explicit policies.

### `members`
- **SELECT**: a user can read their own row; admins can read all rows
- **INSERT**: blocked at the policy layer — only the auth trigger inserts (SECURITY DEFINER bypasses RLS)
- **UPDATE**: a user can update their own row but NOT change their `role` (use a `WITH CHECK` clause to prevent role escalation); admins can update any row
- **DELETE**: admins only

**Implementation note**: checking `role = 'admin'` from inside a policy on the `members` table itself would recurse. Solve via a `SECURITY DEFINER` function `is_admin(uid uuid) RETURNS boolean` that does a direct read (bypassing RLS) and is called from the policies. Backend agent picks the exact pattern.

### `sessions`, `races`, `resources`
- **SELECT**: public — `USING (true)` with an inline comment explaining "public read for site visitors, member-only content is in `members` only"
- **INSERT / UPDATE / DELETE**: admins only

## Auth trigger

Create a Postgres trigger on `auth.users` insert that automatically creates a corresponding `members` row.

- Inputs (from the signup metadata `raw_user_meta_data`): `first_name`, `last_name`, `birth_date`
- If `first_name` or `last_name` are missing from signup metadata, the trigger should still succeed and fall back to placeholder values (`'?'` or similar) — the admin can fix later. Birthday is genuinely optional.
- Default `role = 'member'`.
- The trigger function is `SECURITY DEFINER` so it can insert past RLS.

## Other files

- **`.env.example`** at repo root with two placeholder lines:
  ```
  SUPABASE_URL=https://your-project-ref.supabase.co
  SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxxxxxxxxxxxxxxxxxxxxx
  ```
  Do NOT include a secret key placeholder. The secret key (formerly known as the service role key — `sb_secret_...` format) is referenced only in script comments where applicable, never in `.env.example`.

- **`.gitignore`** must include `.env` (add if not present).

- **`supabase/migrations/README.md`** (short) explaining: how to apply migrations (paste into Supabase SQL editor, or use `supabase db push` if the CLI is set up later), naming convention (`NNNN_slug.sql`), append-only rule.

## Acceptance criteria

- [ ] `supabase/migrations/0001_init.sql` exists and contains all four `CREATE TABLE` statements with the columns, types, and constraints above
- [ ] Every table has `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`
- [ ] Every table has at least one `CREATE POLICY` for SELECT, INSERT, UPDATE, DELETE — no operation is left implicitly denied without an explicit policy unless that's the intent
- [ ] `is_admin()` (or equivalent) function exists and is used by member policies to avoid RLS recursion
- [ ] `handle_new_user()` trigger function exists and is wired to `auth.users` AFTER INSERT
- [ ] No service role key, JWT, password, or other secret appears in any committed file (grep the diff)
- [ ] `.env.example` exists with placeholders only
- [ ] `.gitignore` excludes `.env`
- [ ] `supabase/migrations/README.md` exists with apply instructions
- [ ] The migration file ends with a comment block describing how to roll it back (drop tables in reverse FK order)

## Out of scope (later PRs)

- Data migration script (loading `sessions.json` + `races[]` into the tables)
- Frontend changes to `index.html` / `admin.html`
- Auth provider configuration in the Supabase dashboard (manual task — invite-only mode, redirect URLs, email templates)
- Inviting the 45 members
- Admin UI

## Branch

The EM will name the branch at invocation time (not hardcoded here — the previous branch `feat/supabase-schema-init` was used only for the brief itself, which has now landed on `main`).
