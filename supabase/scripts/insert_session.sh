#!/usr/bin/env bash
# insert_session.sh — Insert a single row into public.sessions via PostgREST.
#
# Usage:
#   printf '%s' "$JSON" | bash supabase/scripts/insert_session.sh   # stdin form (preferred)
#   bash supabase/scripts/insert_session.sh "$JSON"                 # argument form
#
# On success: prints the inserted row's UUID to stdout (single line), exits 0.
# On failure: prints a diagnostic message to stderr, exits 1 (API error)
#             or 2 (usage / validation error).
#
# Required env var:
#   SUPABASE_SECRET_KEY   — service-role key; lives in .env at the drc-internal repo root (mode 600)
#
# Dependencies: curl (ships with macOS), jq (brew install jq)

set -euo pipefail

# ---------------------------------------------------------------------------
# 1. Check required env var
# ---------------------------------------------------------------------------
if [[ -z "${SUPABASE_SECRET_KEY:-}" ]]; then
  echo "error: SUPABASE_SECRET_KEY is not set." >&2
  echo "       Source .env (at the drc-internal repo root) before running this script." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# 2. Read input — stdin preferred; fallback to first positional argument
# ---------------------------------------------------------------------------
BODY=""

if [[ ! -t 0 ]]; then
  # stdin is not a terminal: data is being piped, redirected, or sent via heredoc.
  # Read it, but if it yields nothing and an argument was supplied, use the argument.
  BODY=$(cat)
fi

if [[ -z "$BODY" && $# -ge 1 ]]; then
  BODY="$1"
fi

if [[ -z "$BODY" ]]; then
  echo "error: no session JSON provided." >&2
  echo "       Usage: printf '%s' \"\$JSON\" | bash supabase/scripts/insert_session.sh" >&2
  echo "          or: bash supabase/scripts/insert_session.sh \"\$JSON\"" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# 3. Validate: well-formed JSON
# ---------------------------------------------------------------------------
if ! echo "$BODY" | jq -e . > /dev/null 2>&1; then
  echo "error: input is not valid JSON." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# 4. Validate: required non-empty string fields
# ---------------------------------------------------------------------------
REQUIRED_FIELDS=("date" "label" "venue" "g12")

for field in "${REQUIRED_FIELDS[@]}"; do
  # jq -e exits nonzero if the result is null or false.
  # We check that the field exists AND is a non-empty string.
  if ! echo "$BODY" | jq -e --arg f "$field" \
      'has($f) and (.[$f] | type == "string") and (.[$f] | length > 0)' \
      > /dev/null 2>&1; then
    echo "error: required field \"${field}\" is missing, null, or empty." >&2
    exit 2
  fi
done

# ---------------------------------------------------------------------------
# 5. POST to PostgREST
# ---------------------------------------------------------------------------
SUPABASE_URL="https://zglyzryhckxbwsivlotu.supabase.co"
ENDPOINT="${SUPABASE_URL}/rest/v1/sessions"
TMPFILE=$(mktemp /tmp/insert_session_resp.XXXXXX)

# Always remove the temp file on exit (normal or error).
trap 'rm -f "$TMPFILE"' EXIT

HTTP_STATUS=$(curl -sS \
  -o "$TMPFILE" \
  -w "%{http_code}" \
  -X POST "$ENDPOINT" \
  -H "apikey: ${SUPABASE_SECRET_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SECRET_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  --data-binary "$BODY")

RESPONSE=$(cat "$TMPFILE")

# ---------------------------------------------------------------------------
# 6. Inspect response
# ---------------------------------------------------------------------------
# Extract the date from the input for error context (never log the key).
INPUT_DATE=$(echo "$BODY" | jq -r '.date // "unknown"')

# Non-2xx HTTP status → hard failure
if [[ "$HTTP_STATUS" -lt 200 || "$HTTP_STATUS" -ge 300 ]]; then
  echo "error: PostgREST returned HTTP ${HTTP_STATUS} for session date=${INPUT_DATE}." >&2
  # Surface any error detail from the response body if it looks like JSON.
  if echo "$RESPONSE" | jq -e . > /dev/null 2>&1; then
    echo "       Response: $(echo "$RESPONSE" | jq -c .)" >&2
  else
    echo "       Response: ${RESPONSE}" >&2
  fi
  exit 1
fi

# 2xx but PostgREST error object (some errors come back as 200 with a code field)
if echo "$RESPONSE" | jq -e 'type == "object" and has("code")' > /dev/null 2>&1; then
  ERROR_CODE=$(echo "$RESPONSE" | jq -r '.code // "unknown"')
  ERROR_MSG=$(echo "$RESPONSE"  | jq -r '.message // "no message"')
  echo "error: database error for session date=${INPUT_DATE} (code=${ERROR_CODE}): ${ERROR_MSG}" >&2
  exit 1
fi

# Expect a JSON array with at least one row containing an id (UUID).
if ! echo "$RESPONSE" | jq -e 'type == "array" and length > 0 and (.[0] | has("id"))' > /dev/null 2>&1; then
  echo "error: unexpected response shape for session date=${INPUT_DATE}." >&2
  echo "       Response: $(echo "$RESPONSE" | jq -c . 2>/dev/null || echo "$RESPONSE")" >&2
  exit 1
fi

# Success — print the UUID to stdout only.
echo "$RESPONSE" | jq -r '.[0].id'
