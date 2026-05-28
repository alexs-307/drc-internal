# Session-write helper script — backend brief

## Goal

Add a small shell helper that inserts a single row into `public.sessions` via the Supabase PostgREST API, plus brief documentation. This is the durable, version-controlled half of the new weekly-session workflow.

**The other half** (the `session-write` skill in the DRC parent project + the update to the Monday-message skill) lives outside this repo and will be scoped separately. Both pieces are needed for the workflow, but only the helper belongs in `drc-internal` because it's tied to the schema/data here.

## Why this exists (context)

Until PR 3, the weekly workflow was: Alexandre drafts the Monday WhatsApp message via a skill in the DRC parent project, validates it, then a code PR adds the new entry to `sessions.json`. PR 3 deleted `sessions.json` and cut the frontend over to Supabase, breaking the weekly workflow. The replacement is a Claude Code skill in the DRC parent project that, after WhatsApp validation, invokes this helper to write the row.

Alexandre will drive this from his phone via Remote Control — the skill runs on his Mac (which holds the secret key in a local `.env`) while the conversation happens on the phone. No cloud-container port, no admin UI.

## What to write

### `supabase/scripts/insert_session.sh`

A POSIX-friendly bash script (`#!/usr/bin/env bash`, `set -euo pipefail`) that:

1. **Reads `SUPABASE_SECRET_KEY` from environment.** Exits with code 2 + a message on stderr (NOT containing the key itself) if missing.
2. **Reads the session JSON body** from stdin OR the first positional argument. Stdin is preferred for safety (the JSON contains French text with apostrophes/newlines and shouldn't be passed on the command line where it would show up in process listings). Exits with code 2 if neither source provides input.
3. **Validates the input** is well-formed JSON via `jq -e .` and contains the four required non-empty string fields: `date`, `label`, `venue`, `g12`. The optional fields are `g3` and `suggestion` (either may be `null` or absent). Exits with code 2 + a precise error on stderr if validation fails.
4. **POSTs to `https://zglyzryhckxbwsivlotu.supabase.co/rest/v1/sessions`** with these headers:
   - `apikey: ${SUPABASE_SECRET_KEY}`
   - `Authorization: Bearer ${SUPABASE_SECRET_KEY}`
   - `Content-Type: application/json`
   - `Prefer: return=representation` (returns the inserted row including the generated UUID + created_at)
5. **Inspects the response.** If the response is a JSON object with a `code` field (PostgREST error shape), prints the error to stderr (with the row's `date` value for context, but NOT the secret key) and exits with code 1. If the response is a JSON array of one row with a UUID, prints the UUID to stdout (single line, no trailing whitespace) and exits with code 0.
6. **Never logs the secret key.** Not in error messages, not in verbose mode, not anywhere. Use `set +x` if you ever turn on tracing for debugging.

### `supabase/scripts/README.md`

Brief documentation (about 40-60 lines) covering:

- **Purpose** of the `supabase/scripts/` folder: local helpers for one-shot ops against the Supabase database. Not part of the deployed site.
- **Prerequisites:**
  - `curl` (ships with macOS)
  - `jq` — `brew install jq` if not already present
- **The `SUPABASE_SECRET_KEY` env var:**
  - Lives in `.env` at the `drc-internal/` repo root, permissions `600`
  - File format: `export SUPABASE_SECRET_KEY=sb_secret_...`
  - The skill (`drc-publish-session`, in the DRC parent project) sources this file before invoking the helper. The user can also `source .env` (from the `drc-internal/` repo root) interactively to call the helper from the shell.
  - **NEVER commit `.env` files anywhere.** The repo's `.gitignore` already excludes `.env`.
- **`insert_session.sh` usage:**
  - Stdin form (preferred): `printf '%s' "$JSON" | bash supabase/scripts/insert_session.sh`
  - Argument form: `bash supabase/scripts/insert_session.sh "$JSON"`
  - Show one realistic example with a multi-line `g12` (so the apostrophe/newline handling is illustrated)
  - Show the expected success output (a UUID on stdout) and a sample error response
- **What's NOT in this folder yet:**
  - `update_session.sh`, `delete_session.sh`, `insert_race.sh`, etc. — add as needed; same pattern as `insert_session.sh`. Don't pre-build.

## Hard rules

- Do NOT include the secret key in any file. The `.env` file is created out-of-band by Alexandre after the PR merges.
- Do NOT touch `index.html`, `sessions.json` (which doesn't exist anyway), or any migration file.
- Do NOT introduce new external dependencies beyond `curl` and `jq`. No node_modules, no Python packages, no extra binaries.
- Do NOT add executable bit logic — `bash supabase/scripts/insert_session.sh` is the documented invocation. (You can mark the file executable with `chmod +x` and the script can also be run directly, but document the `bash <path>` form for portability.)

## Acceptance criteria

- [ ] `supabase/scripts/insert_session.sh` exists, starts with `#!/usr/bin/env bash` and `set -euo pipefail`
- [ ] Script exits non-zero with a clear stderr message when `SUPABASE_SECRET_KEY` is unset
- [ ] Script exits non-zero with a clear stderr message when input JSON is missing, malformed, or missing any of `date`/`label`/`venue`/`g12`
- [ ] On success, script prints exactly the inserted row's UUID to stdout (no other text on stdout)
- [ ] Script never echoes or logs `SUPABASE_SECRET_KEY` — grep the script for any pattern that could leak it (echo, printf, set -x without restore, etc.)
- [ ] `supabase/scripts/README.md` exists with all sections listed above
- [ ] No secrets in either file (placeholder examples use `sb_secret_xxxxxxxx` style)
- [ ] File mode on `insert_session.sh` is either `0644` (sourced/invoked via `bash`) or `0755` (also directly executable) — either is fine, just be consistent and document it

## Test before committing

The script can't be fully tested against the live database without the real secret key (which the backend agent shouldn't see). Smoke test what you can:

- Run with no env var: should fail with the right message
- Run with the env var set to a dummy value + no JSON input: should fail with the input-missing message
- Run with the env var set + a malformed JSON arg: should fail JSON-validation
- Run with the env var set + valid-shape JSON but a fake URL: optional; mainly tests that the script reaches the curl invocation. (The agent CAN set `SUPABASE_URL` via a temporary env override if it wants to point at httpbin or similar for a smoke test, but the URL in the committed script is the real Supabase URL.)

## Commit

Commit message: `backend: helper for inserting a session row (supabase/scripts/insert_session.sh)`. Do NOT push — EM pushes after reviewer signs off.

## Report back

- Branch + commit SHA
- Files touched (should be just two new files)
- Confirmation you grep'd the diff for secrets and for any pattern that could leak `SUPABASE_SECRET_KEY` in error paths
- Sample of the script's output for at least two error cases (missing env var, missing input)

## Branch

The EM will name the branch at invocation time.
