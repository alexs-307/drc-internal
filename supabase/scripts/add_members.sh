#!/usr/bin/env bash
# add_members.sh — Bulk-create Supabase Auth users for club members via the
# Admin API. Each created auth.users row triggers public.handle_new_user()
# (see supabase/migrations/0001_init.sql), which auto-inserts the matching
# public.members row from user_metadata. This script never touches the
# members table directly — it can't: the members INSERT policy is
# WITH CHECK (false), so only the SECURITY DEFINER trigger may write it.
#
# No invite email is sent: users are created with email_confirm=true via the
# Admin API "create user" endpoint (NOT the invite endpoint), so this is a
# silent, backend-only provisioning step.
#
# Usage:
#   printf '%s' "$JSON" | bash supabase/scripts/add_members.sh   # stdin form (preferred)
#   bash supabase/scripts/add_members.sh path/to/members.json    # file-path form
#
# Input: a JSON array of objects, each shaped:
#   { "first_name": "...", "last_name": "...", "email": "..." }
#
# Validation strategy — FAIL FAST: the entire input array is validated
# up front (non-empty first_name/last_name, syntactically valid email).
# If ANY record is malformed, the script reports every invalid record
# (by index and, where available, email) to stderr and exits 2 WITHOUT
# creating any users. This was chosen over partial processing because a
# batch of new members is usually pasted from a single source (e.g. a
# spreadsheet export); a typo three rows in more likely means "fix the
# input and re-run the whole batch" than "create the 12 good ones now
# and patch the 1 bad one later." Once validation passes, per-member API
# failures during creation DO NOT abort the batch (see below).
#
# Idempotency: if a member's email is already registered, the Admin API
# returns an error (already-registered) which this script treats as
# SKIPPED, not FAILED. Re-running this script over the same input is
# therefore safe — a second run reports everyone as SKIPPED and exits 0.
#
# Required env vars:
#   SUPABASE_URL          — project URL, e.g. https://xxxx.supabase.co
#                            (lives in .env at the drc-internal/ repo root)
#   SUPABASE_SECRET_KEY   — service-role key; lives in the same .env (mode 600)
#
# Note on SUPABASE_URL: unlike insert_session.sh (which hardcodes the
# project URL as a script constant), this script reads it from the
# environment, matching the SUPABASE_URL variable already documented in
# .env.example and CLAUDE.md. The Admin API is a more sensitive surface
# than PostgREST, so keeping the URL alongside the secret key in one
# sourced .env (rather than baked into the script) keeps both required
# inputs in a single place to double-check before running.
#
# Dependencies: curl (ships with macOS), jq (brew install jq)
#
# Output:
#   stdout — human-readable progress + a final summary table (this script
#            is run interactively by a human, unlike insert_session.sh
#            which feeds a skill's stdout capture).
#   stderr — all diagnostic and error messages.
#
# Exit codes:
#   0 — completed, zero FAILED members (created + skipped only)
#   1 — completed, at least one member FAILED
#   2 — usage / validation / env error (nothing was created)

set -euo pipefail

# ---------------------------------------------------------------------------
# 1. Check required env vars
# ---------------------------------------------------------------------------
if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "error: SUPABASE_URL is not set." >&2
  echo "       Source .env (at the drc-internal/ repo root) before running this script." >&2
  exit 2
fi

if [[ -z "${SUPABASE_SECRET_KEY:-}" ]]; then
  echo "error: SUPABASE_SECRET_KEY is not set." >&2
  echo "       Source .env (at the drc-internal/ repo root) before running this script." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# 2. Read input — stdin preferred; fallback to a file path as $1
# ---------------------------------------------------------------------------
BODY=""

if [[ ! -t 0 ]]; then
  # stdin is not a terminal: data is being piped, redirected, or sent via heredoc.
  BODY=$(cat)
fi

if [[ -z "$BODY" && $# -ge 1 ]]; then
  if [[ ! -f "$1" ]]; then
    echo "error: file not found: $1" >&2
    exit 2
  fi
  BODY=$(cat "$1")
fi

if [[ -z "$BODY" ]]; then
  echo "error: no member JSON provided." >&2
  echo "       Usage: printf '%s' \"\$JSON\" | bash supabase/scripts/add_members.sh" >&2
  echo "          or: bash supabase/scripts/add_members.sh path/to/members.json" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# 3. Validate: well-formed JSON array
# ---------------------------------------------------------------------------
if ! echo "$BODY" | jq -e . > /dev/null 2>&1; then
  echo "error: input is not valid JSON." >&2
  exit 2
fi

if ! echo "$BODY" | jq -e 'type == "array"' > /dev/null 2>&1; then
  echo "error: input must be a JSON array of member objects." >&2
  exit 2
fi

MEMBER_COUNT=$(echo "$BODY" | jq 'length')

if [[ "$MEMBER_COUNT" -eq 0 ]]; then
  echo "error: input array is empty — nothing to do." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# 4. Validate: every record has non-empty first_name, last_name, and a
#    syntactically valid email. Whole-batch validation — fail fast, create
#    nothing if any record is malformed (see header comment).
# ---------------------------------------------------------------------------
EMAIL_REGEX='^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'

VALIDATION_ERRORS=()
INDEX=0

while IFS= read -r record; do
  INDEX=$((INDEX + 1))

  if ! echo "$record" | jq -e 'type == "object"' > /dev/null 2>&1; then
    VALIDATION_ERRORS+=("record #${INDEX}: not a JSON object")
    continue
  fi

  first_name=$(echo "$record" | jq -r '.first_name // empty')
  last_name=$(echo "$record" | jq -r '.last_name // empty')
  email=$(echo "$record" | jq -r '.email // empty')

  if [[ -z "$first_name" ]]; then
    VALIDATION_ERRORS+=("record #${INDEX} (email=${email:-unknown}): missing or empty \"first_name\"")
  fi
  if [[ -z "$last_name" ]]; then
    VALIDATION_ERRORS+=("record #${INDEX} (email=${email:-unknown}): missing or empty \"last_name\"")
  fi
  if [[ -z "$email" ]]; then
    VALIDATION_ERRORS+=("record #${INDEX}: missing or empty \"email\"")
  elif ! [[ "$email" =~ $EMAIL_REGEX ]]; then
    VALIDATION_ERRORS+=("record #${INDEX} (email=${email}): not a syntactically valid email address")
  fi
done < <(echo "$BODY" | jq -c '.[]')

if [[ "${#VALIDATION_ERRORS[@]}" -gt 0 ]]; then
  echo "error: ${#VALIDATION_ERRORS[@]} invalid record(s) found — no users were created." >&2
  for err in "${VALIDATION_ERRORS[@]}"; do
    echo "       - ${err}" >&2
  done
  exit 2
fi

# ---------------------------------------------------------------------------
# 5. Create each member via the Admin API
# ---------------------------------------------------------------------------
ENDPOINT="${SUPABASE_URL%/}/auth/v1/admin/users"
TMPFILE=$(mktemp /tmp/add_members_resp.XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

CREATED=()
SKIPPED=()
FAILED=()
RESULT_LINES=()

INDEX=0
while IFS= read -r record; do
  INDEX=$((INDEX + 1))

  first_name=$(echo "$record" | jq -r '.first_name')
  last_name=$(echo "$record" | jq -r '.last_name')
  email=$(echo "$record" | jq -r '.email')

  REQUEST_BODY=$(jq -n \
    --arg email "$email" \
    --arg first_name "$first_name" \
    --arg last_name "$last_name" \
    '{
      email: $email,
      email_confirm: true,
      user_metadata: { first_name: $first_name, last_name: $last_name }
    }')

  # Do not let a curl-level failure (network error, etc.) abort the whole
  # batch under `set -e` — capture its exit code and treat it as a
  # per-member failure instead.
  set +e
  HTTP_STATUS=$(curl -sS \
    -o "$TMPFILE" \
    -w "%{http_code}" \
    -X POST "$ENDPOINT" \
    -H "apikey: ${SUPABASE_SECRET_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SECRET_KEY}" \
    -H "Content-Type: application/json" \
    --data-binary "$REQUEST_BODY")
  CURL_EXIT=$?
  set -e

  if [[ $CURL_EXIT -ne 0 ]]; then
    FAILED+=("$email")
    RESULT_LINES+=("  ${email} -> FAILED (curl error, exit code ${CURL_EXIT})")
    echo "[${INDEX}/${MEMBER_COUNT}] ${email}: FAILED (curl error, exit code ${CURL_EXIT})"
    continue
  fi

  RESPONSE=$(cat "$TMPFILE")

  if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "201" ]]; then
    USER_ID=$(echo "$RESPONSE" | jq -r '.id // empty' 2>/dev/null || true)
    if [[ -n "$USER_ID" ]]; then
      CREATED+=("$email")
      RESULT_LINES+=("  ${email} -> CREATED (id=${USER_ID})")
      echo "[${INDEX}/${MEMBER_COUNT}] ${email}: CREATED (id=${USER_ID})"
    else
      FAILED+=("$email")
      RESULT_LINES+=("  ${email} -> FAILED (HTTP ${HTTP_STATUS} but no user id in response)")
      echo "[${INDEX}/${MEMBER_COUNT}] ${email}: FAILED (unexpected success response shape)"
    fi
  else
    ERROR_CODE=$(echo "$RESPONSE" | jq -r '(.error_code // .code // "unknown")' 2>/dev/null || echo "unknown")
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '(.msg // .message // .error_description // .error // "no message")' 2>/dev/null || echo "no message")
    LOWER_MSG=$(echo "$ERROR_MSG" | tr '[:upper:]' '[:lower:]')
    LOWER_CODE=$(echo "$ERROR_CODE" | tr '[:upper:]' '[:lower:]')

    if [[ ( "$HTTP_STATUS" == "422" || "$HTTP_STATUS" == "400" ) \
          && ( "$LOWER_MSG" == *"already been registered"* \
            || "$LOWER_MSG" == *"already registered"* \
            || "$LOWER_MSG" == *"already exists"* \
            || "$LOWER_CODE" == *"email_exists"* \
            || "$LOWER_CODE" == *"user_already_exists"* ) ]]; then
      SKIPPED+=("$email")
      RESULT_LINES+=("  ${email} -> SKIPPED (already exists)")
      echo "[${INDEX}/${MEMBER_COUNT}] ${email}: SKIPPED (already exists)"
    else
      FAILED+=("$email")
      RESULT_LINES+=("  ${email} -> FAILED (HTTP ${HTTP_STATUS}: ${ERROR_MSG})")
      echo "[${INDEX}/${MEMBER_COUNT}] ${email}: FAILED (HTTP ${HTTP_STATUS}: ${ERROR_MSG})"
    fi
  fi
done < <(echo "$BODY" | jq -c '.[]')

# ---------------------------------------------------------------------------
# 6. Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "Created: ${#CREATED[@]}"
echo "Skipped (already exists): ${#SKIPPED[@]}"
echo "Failed:  ${#FAILED[@]}"
echo ""
for line in "${RESULT_LINES[@]}"; do
  echo "$line"
done

if [[ "${#FAILED[@]}" -gt 0 ]]; then
  exit 1
fi

exit 0
