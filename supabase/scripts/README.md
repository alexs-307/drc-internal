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
This key bypasses Row Level Security — keep it out of any file that touches the repo.

**Where the key lives:** `.env` at the repo root (`drc-internal/.env`) — gitignored.

File contents:

```bash
export SUPABASE_SECRET_KEY=sb_secret_xxxxxxxxxxxxxxxxxxxxxxxx
```

Set permissions to `600` so only your user can read it:

```bash
chmod 600 .env
```

**To load it into your shell (from the `drc-internal/` repo root):**

```bash
source .env
```

The DRC parent-project Claude skill (`drc-publish-session`) sources this file automatically
before invoking any script here. You only need to source it manually when running scripts
interactively.

**Never commit `.env` files.** The repo's `.gitignore` already excludes `.env`.

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
       Source .env (at the drc-internal/ repo root) before running this script.
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

## `add_members.sh`

Bulk-creates Supabase Auth users for club members via the **Admin API**
(`POST /auth/v1/admin/users`), silently — no invite email is sent. Each
created `auth.users` row fires the `on_auth_user_created` trigger
(see `supabase/migrations/0001_init.sql`), which auto-inserts the matching
`public.members` row from the metadata this script sends. The script never
writes to `public.members` directly — it can't: the table's INSERT policy
is `WITH CHECK (false)`, so only the `SECURITY DEFINER` trigger may insert
into it.

Unlike `insert_session.sh`, this script reads `SUPABASE_URL` from the
environment rather than hardcoding it, since the Admin API is a more
sensitive surface — keeping both required inputs (`SUPABASE_URL` and
`SUPABASE_SECRET_KEY`) in one sourced `.env` makes it easier to
double-check the target project before running.

### Usage

**Stdin form (preferred):**

```bash
source .env
printf '%s' "$JSON" | bash supabase/scripts/add_members.sh
```

**File-path form:** pass a path to a JSON file as the first argument
(unlike `insert_session.sh`'s argument form, this is a **file path**, not
inline JSON — bulk member lists are long enough that a file is more
practical than an inline argument).

```bash
source .env
bash supabase/scripts/add_members.sh path/to/members.json
```

### Input JSON shape

A JSON array of member objects. Each object:

| Field        | Type   | Notes                                          |
|--------------|--------|-------------------------------------------------|
| `first_name` | string | Required, non-empty                            |
| `last_name`  | string | Required, non-empty                            |
| `email`      | string | Required, must be a syntactically valid address |

### Validation: fail-fast on the whole batch

The entire input array is validated **before any user is created**. If any
record is malformed (empty name, invalid email), the script reports every
invalid record — by index and email where available — to stderr and exits
`2` **without creating any users**. This is deliberate: a member list is
usually pasted from one source (e.g. a spreadsheet export), so a typo a
few rows in more likely means "fix the input and re-run the whole batch"
than "create the good ones now, patch the bad one later."

Once validation passes, per-member failures during creation (e.g. a
transient API error) do **not** abort the rest of the batch — the script
continues to the next member and reports the failure in the summary.

### Idempotency

If a member's email is already registered, the Admin API returns an
already-registered error, which this script treats as **SKIPPED**, not a
failure. Re-running the script over the same input is therefore safe: a
second run reports every member as `SKIPPED (already exists)` and exits
`0`.

### Realistic example

```bash
source .env

JSON=$(cat <<'EOF'
[
  { "first_name": "Prénom", "last_name": "Nom", "email": "prenom@example.com" },
  { "first_name": "Autre",  "last_name": "Membre", "email": "autre@example.com" }
]
EOF
)

printf '%s' "$JSON" | bash supabase/scripts/add_members.sh
```

Expected output (stdout):

```
[1/2] prenom@example.com: CREATED (id=a1b2c3d4-e5f6-7890-abcd-ef1234567890)
[2/2] autre@example.com: CREATED (id=b2c3d4e5-f6a7-8901-bcde-f23456789012)

=== Summary ===
Created: 2
Skipped (already exists): 0
Failed:  0

  prenom@example.com -> CREATED (id=a1b2c3d4-e5f6-7890-abcd-ef1234567890)
  autre@example.com -> CREATED (id=b2c3d4e5-f6a7-8901-bcde-f23456789012)
```

Re-running the exact same input afterward:

```
=== Summary ===
Created: 0
Skipped (already exists): 2
Failed:  0
```

### Error examples

Missing env var:

```
error: SUPABASE_URL is not set.
       Source .env (at the drc-internal/ repo root) before running this script.
```

Invalid record (fail-fast, nothing created):

```
error: 1 invalid record(s) found — no users were created.
       - record #2 (email=pas-un-email): not a syntactically valid email address
```

Per-member API failure (batch continues; script exits 1 at the end):

```
[3/5] jean@example.com: FAILED (HTTP 500: internal error)
```

### Exit codes

| Code | Meaning                                                              |
|------|-----------------------------------------------------------------------|
| `0`  | Completed — zero FAILED members (created + skipped only)             |
| `1`  | Completed — at least one member FAILED                               |
| `2`  | Usage / validation / env error (nothing was created)                 |

### Stdout / stderr discipline

- **stdout** contains progress lines per member plus a final human-readable
  summary table. Unlike `insert_session.sh` (which feeds a skill's stdout
  capture), this script is run interactively by a human, so a readable
  summary is appropriate here.
- **stderr** contains validation and hard error diagnostics.
- The secret key is never printed, and the `Authorization` header is never
  echoed.

---

## What is not here yet

The following scripts may be added later as needed, following the same pattern as
`insert_session.sh`:

- `update_session.sh` — update an existing session row by UUID
- `delete_session.sh` — delete a session row by UUID
- `insert_race.sh` — insert a row into `public.races`

Don't pre-build. Add only when there is an active use case.
