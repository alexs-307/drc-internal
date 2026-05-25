# supabase/scripts/

Local helper scripts for one-shot operations against the Supabase database.
These scripts are **not** part of the deployed site — they run on Alexandre's Mac
and communicate directly with Supabase via the PostgREST API.

This folder lives under `supabase/` (next to `migrations/`) because every script
here is coupled to the Supabase schema and credentials. For generic project
tooling not coupled to the DB (deploy, content conversion, etc.), use a
root-level `scripts/` folder if one is ever introduced.

---

## Prerequisites

- **curl** — ships with macOS. No installation needed.
- **jq** — JSON processor. Install via Homebrew if not already present:
  ```bash
  brew install jq
  ```

---

## Secret key setup

The scripts require `SUPABASE_SECRET_KEY` (the Supabase service-role key).
This key bypasses Row Level Security — keep it out of any committed file.

**Where the key lives:**

```
drc-internal/.env   (at the repo root)
```

File contents (one line):

```bash
export SUPABASE_SECRET_KEY=sb_secret_xxxxxxxxxxxxxxxxxxxxxxxx
```

The `.gitignore` already excludes `.env`, so this file cannot be accidentally
committed. Still, lock permissions for defense in depth:

```bash
chmod 600 .env
```

**To load it into your shell** (run from the repo root):

```bash
source .env
```

The DRC parent-project Claude skill sources this file automatically before
invoking any script here, using the absolute path
`/Users/alexsaillard/Claude/DRC/drc-internal/.env`. You only need to source it
manually when running scripts interactively from the repo root.

---

## `insert_session.sh`

Inserts one row into `public.sessions` and prints the generated UUID on success.

### Usage

**Stdin form (preferred):** JSON is passed on stdin. Safer for text containing
apostrophes or newlines, and does not expose the payload in the process listing.

```bash
source .env
printf '%s' "$JSON" | bash supabase/scripts/insert_session.sh
```

Note: we use `printf '%s'` instead of `echo` because zsh's built-in `echo` interprets `\n` escape sequences and would corrupt JSON containing them.

**Argument form:** JSON is passed as the first positional argument.

```bash
source .env
bash supabase/scripts/insert_session.sh "$JSON"
```

### Required JSON fields

| Field       | Type   | Notes                                      |
|-------------|--------|--------------------------------------------|
| `date`      | string | ISO 8601 date, e.g. `"2026-05-20"`        |
| `label`     | string | Short session title                        |
| `venue`     | string | Track name, e.g. `"Bertrand Dauvin"`       |
| `g12`       | string | Content for Groupe 1 / Groupe 2            |
| `g3`        | string | Content for Groupe 3 — `null` if same as G1/G2 |
| `suggestion`| string | Weekly suggestion — `null` if none         |

`g3` and `suggestion` are optional (may be `null` or absent from the JSON object).

### Realistic example

```bash
source .env

JSON=$(cat <<'EOF'
{
  "date": "2026-05-20",
  "label": "Séance seuil 3×2000m",
  "venue": "Bertrand Dauvin",
  "g12": "Echauffement 15'\n3×2000m à 85% VMA (récup 2')\nRetour au calme 10'",
  "g3": "Echauffement 15'\n3×1500m à 80% VMA (récup 2'30\")\nRetour au calme 10'",
  "suggestion": "Pensez à vous hydrater avant la séance !"
}
EOF
)

printf '%s' "$JSON" | bash supabase/scripts/insert_session.sh
```

Expected output on success (stdout only):

```
a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

### Error examples

Missing env var:

```
error: SUPABASE_SECRET_KEY is not set.
       Source .env (at the drc-internal repo root) before running this script.
```

Missing required field:

```
error: required field "venue" is missing, null, or empty.
```

API error (e.g. RLS denial):

```
error: database error for session date=2026-05-20 (code=42501): new row violates row-level security policy for table "sessions"
```

### Exit codes

| Code | Meaning                                                    |
|------|------------------------------------------------------------|
| `0`  | Success — UUID printed to stdout                           |
| `1`  | API / database error (curl reached Supabase but it rejected the request) |
| `2`  | Usage or validation error (wrong invocation, bad JSON, missing field) |

### Stdout / stderr discipline

- **stdout** contains exactly one line: the UUID of the inserted row. Nothing else.
- **stderr** contains all diagnostic and error messages.
- The calling skill captures stdout to extract the UUID.

---

## What is not here yet

The following scripts may be added later as needed, following the same pattern as
`insert_session.sh`:

- `update_session.sh` — update an existing session row by UUID
- `delete_session.sh` — delete a session row by UUID
- `insert_race.sh` — insert a row into `public.races`

Don't pre-build. Add only when there is an active use case.
