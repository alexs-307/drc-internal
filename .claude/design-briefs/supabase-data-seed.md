# Supabase data seed (0002_seed_initial_data.sql) — backend brief

## Goal

Seed the three public-content tables (`sessions`, `races`, `resources`) with the data that today lives in `sessions.json` and inline in `index.html`. This is PR 2 of the Supabase migration (Option C path described in `website_audit/audit_dynamic_website_migration.md`). PR 1 (schema init) is already on `main` and applied to the live database.

No schema changes. No frontend changes. No `members` rows (members come from invite + trigger). Just `INSERT` statements.

## Approach

Single migration file: `supabase/migrations/0002_seed_initial_data.sql`. Inline `INSERT` statements grouped by table. No new tooling, no `scripts/` folder yet — the file is pasted into the Supabase SQL editor by the EM after the reviewer signs off, same flow as PR 1.

Idempotency: this is a fresh-schema seed. Re-running it would create duplicate rows. We accept that — the file lives in version control and is meant to be applied exactly once. The reviewer should flag this in the verdict so the EM remembers not to re-paste.

## Sources

### `sessions` — from `sessions.json`

36 entries (as of 2026-05-23). Direct column-for-column mapping:

| JSON key      | Postgres column |
|---------------|-----------------|
| `date`        | `date`          |
| `label`       | `label`         |
| `venue`       | `venue`         |
| `g12`         | `g12`           |
| `g3`          | `g3` (NULL when JSON is `null`) |
| `suggestion`  | `suggestion` (NULL when JSON is `null`) |

`id` and `created_at` use the column defaults (`gen_random_uuid()`, `now()`).

The `g12` / `g3` / `suggestion` strings contain literal `\n` newline characters and apostrophes (e.g. `Pyramide en côtes`, `jusqu'à`). The SQL must use dollar-quoted strings (`$txt$ ... $txt$`) to avoid manual escaping. Don't lose any newline.

### `races` — from the `races[]` JS array literal at `index.html:1650`

8 entries (as of 2026-05-23). Mapping:

| JS key        | Postgres column      | Notes |
|---------------|----------------------|-------|
| `name`        | `name`               |       |
| `format`      | `type`               |       |
| `dateStr`     | `date`               | **Only when `approx: false`**. When `approx: true`, set `date = NULL`. |
| `approxText`  | `date_label`         | **Only when `approx: true`**. When `approx: false`, set `date_label = NULL`. |
| `pillar`      | `pillar`             |       |
| `confirmed`   | `confirmed`          |       |
| `note`        | `note`               | NULL when JS key is absent. |
| (no JS source)| `url`                | Always NULL — no race links today. |

Dropped fields (derived or unused): `dateDisplay`, `monthDisplay`, `yearDisplay`, `approx` (encoded by date NULL/NOT NULL), `tbdType`, `link`.

`id` and `created_at` use defaults.

### `resources` — from the resource cards in `index.html` + files in `ressources/`

Two seed rows. Placeholder card in the markup is NOT seeded — only real PDFs.

| Row | `title` | `description` | `pdf_path` | `preview_path` | `display_order` |
|-----|---------|---------------|------------|----------------|-----------------|
| 1   | (read from `index.html` `.resource-body` block around line 1559–1561 for vma_seuil) | (read from same block) | `ressources/vma_seuil.pdf` | `ressources/vma_seuil_preview.png` | `10` |
| 2   | (read from `.resource-body` block around line 1571–1573 for renfo_du_coureur) | (same) | `ressources/renfo_du_coureur.pdf` | `ressources/renfo_du_coureur_preview.png` | `20` |

`display_order` is set with gaps (10, 20) so admins can insert between later without re-numbering everything.

The agent should `Read` `index.html` around the cited line range to copy the exact French title + description text — don't paraphrase.

## File structure (recommended)

```sql
-- =============================================================================
-- 0002_seed_initial_data.sql
-- DRC Internal — seed initial public-content data
-- Tables seeded: sessions (36 rows), races (8 rows), resources (2 rows)
-- One-shot seed — do not re-run.
-- =============================================================================

-- ----------------------------------------------------------------------------
-- Resources (2 rows)
-- ----------------------------------------------------------------------------
INSERT INTO public.resources (title, description, pdf_path, preview_path, display_order) VALUES
  (...),
  (...);

-- ----------------------------------------------------------------------------
-- Races (8 rows)
-- ----------------------------------------------------------------------------
INSERT INTO public.races (name, type, date, date_label, pillar, confirmed, note) VALUES
  (...),
  (...),
  ...;

-- ----------------------------------------------------------------------------
-- Sessions (36 rows, most recent first to match sessions.json order)
-- ----------------------------------------------------------------------------
INSERT INTO public.sessions (date, label, venue, g12, g3, suggestion) VALUES
  (...),
  ...;

-- =============================================================================
-- ROLLBACK INSTRUCTIONS (comment only)
--
-- To wipe the seeded data (e.g. before re-running):
--   DELETE FROM public.sessions;
--   DELETE FROM public.races;
--   DELETE FROM public.resources;
--
-- DO NOT use TRUNCATE — would also reset sequences if any are added later.
-- =============================================================================
```

Ordering note: insert `resources` and `races` first, `sessions` last, so a partial failure (network drop on a big INSERT) leaves the smaller tables fully seeded.

## Acceptance criteria

- [ ] `supabase/migrations/0002_seed_initial_data.sql` exists and contains exactly: 2 resources, 8 races, 36 sessions
- [ ] Every approximate race (`approx: true` in the JS source) has `date IS NULL` and a non-null `date_label`
- [ ] Every concrete race (`approx: false`) has `date IS NOT NULL` and `date_label IS NULL`
- [ ] No secrets in the file (the seed contains no API keys or tokens — but grep anyway)
- [ ] Session content is byte-identical to `sessions.json` (apostrophes preserved, newlines preserved, no double-escaping)
- [ ] Resource titles and descriptions are copied verbatim from `index.html` (not paraphrased)
- [ ] Rollback `DELETE` block as a comment at the bottom
- [ ] File ends with a newline

## Out of scope (later PRs)

- Removing `sessions.json` and the `races[]` literal from `index.html` (frontend cutover happens in PR 3)
- Wiring the Supabase JS SDK into `index.html` (PR 3)
- Auth-gated session attendance, RSVPs, or any new feature (later PRs)
- Resource preview generation or migration to Supabase Storage (out of scope)

## Branch

The EM will name the branch at invocation time.
