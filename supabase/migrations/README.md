# Supabase migrations

## How to apply a migration

### Option 1 — Supabase SQL editor (no CLI required)

1. Open the Supabase dashboard for the project.
2. Go to **SQL Editor**.
3. Paste the contents of the migration file (e.g. `0001_init.sql`) and click **Run**.

### Option 2 — Supabase CLI (once wired up)

```bash
supabase db push
```

Requires `supabase` CLI installed and `supabase/config.toml` initialised (`supabase init`). See [Supabase CLI docs](https://supabase.com/docs/guides/cli).

## Naming convention

Migration files follow the pattern:

```
NNNN_slug.sql
```

Where `NNNN` is a zero-padded sequential integer starting at `0001`, and `slug` is a short kebab-case description of the change (e.g. `0001_init`, `0002_add_attendance`).

## Append-only rule

**Never edit a committed migration file.** Migrations are append-only.

If a committed migration contains an error or needs to be changed, write a new migration file with the next sequential prefix that applies the corrective change. This keeps the migration history auditable and safe to replay from scratch.
