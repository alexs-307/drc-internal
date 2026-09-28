#!/usr/bin/env bash
# site_usage.sh — read-only usage analytics for the drc-internal website,
# API-only (no direct DB connection; everything goes through Supabase APIs).
#
# Part 1 (works with just the secret key): Auth Admin API
#   GET $SUPABASE_URL/auth/v1/admin/users → who has an account, who ever
#   signed in, and a "last seen" snapshot (max of last_sign_in_at and
#   updated_at — updated_at moves with session activity; see caveats below).
#   Never-signed-in accounts are excluded from the snapshot because
#   updated_at is set at account creation.
#
# Part 2 (needs a Personal Access Token, skipped gracefully if absent):
#   Management API — POST https://api.supabase.com/v1/projects/{ref}/database/query
#   → SQL over auth.refresh_tokens / auth.sessions / auth.audit_log_entries,
#   which is the only place a per-visit history exists (the auth schema is
#   not exposed through PostgREST, so the service-role key alone cannot
#   read it). Create a token at supabase.com/dashboard/account/tokens,
#   scoped to this project with the narrowest read-only DB query permission
#   available and a short expiry, and add it to drc-internal/.env as:
#     export SUPABASE_ACCESS_TOKEN=sbp_...
#
# Caveats (findings from running this against production):
#   - auth.audit_log_entries is empty for this project (DB audit logging
#     is off), so history comes from auth.refresh_tokens instead, whose
#     revoked rows are retained back to launch (May 2026).
#   - A refresh token is minted roughly once per page open after the ~1h
#     access token expires, so one refresh token ≈ one visit (sub-hour
#     repeat visits collapse into a single event).
#
# Usage:
#   bash supabase/scripts/site_usage.sh [YYYY-MM-DD]   # default since 2026-09-01
#
# Required env vars (sourced from drc-internal/.env, resolved relative to
# this script's own location):
#   SUPABASE_URL          — project URL, e.g. https://xxxx.supabase.co
#   SUPABASE_SECRET_KEY   — service-role key (bypasses RLS; Admin API needs it)
#
# Optional env vars (also in .env):
#   SUPABASE_ACCESS_TOKEN — Supabase Personal Access Token; enables Part 2.
#                            Part 2 is skipped (not an error) when absent.
#   DRC_EXCLUDE_EMAIL      — an account email to exclude from all counts
#                            (e.g. the admin's own test account). When unset,
#                            nobody is excluded and the output header says so.
#
# Output: everything goes to stdout, one labelled section per query. This
# script is read-only — it never writes to the database. The output
# contains member names and per-member activity: do not paste it into
# shared places (Slack, tickets, etc.) — see supabase/scripts/README.md.
#
# Exit codes:
#   0  Success (Part 2 sections included or skipped, both are success)
#   1  An API call failed (network error or non-2xx HTTP response)
#   2  Usage / environment error (missing .env, missing required var,
#      invalid SINCE argument, or invalid DRC_EXCLUDE_EMAIL)
#
# Dependencies: curl (ships with macOS), jq (brew install jq)

set -euo pipefail

SINCE="${1:-2026-09-01}"

# SINCE is interpolated directly into SQL literals sent to a privileged
# endpoint (Management API) below — validate its shape before it touches
# any query string.
if [[ ! "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "error: date argument must be YYYY-MM-DD (got: $SINCE)" >&2
  exit 2
fi

PROJECT_REF="zglyzryhckxbwsivlotu"   # matches the project referenced by SUPABASE_URL

# Project-specific cutoff: accounts created on/after this date are treated as
# the admin-provisioned member cohort (batches created Jun 22, Aug 31, Sep 1,
# 2026). Adjust here if a new bulk-invite batch changes what "invited" means.
INVITED_SINCE="2026-06-01"

# ---------------------------------------------------------------------------
# 0. Locate and source .env (relative to this script's own location, not CWD)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$(cd "$SCRIPT_DIR/../.." && pwd)/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: .env not found at $ENV_FILE" >&2
  echo "       Expected drc-internal/.env (mode 600, gitignored)." >&2
  exit 2
fi

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "error: SUPABASE_URL is not set in $ENV_FILE" >&2
  exit 2
fi
if [[ -z "${SUPABASE_SECRET_KEY:-}" ]]; then
  echo "error: SUPABASE_SECRET_KEY is not set in $ENV_FILE" >&2
  exit 2
fi

EXCLUDE_EMAIL="${DRC_EXCLUDE_EMAIL:-}"

# EXCLUDE_EMAIL is also interpolated into a SQL literal below — reject
# anything that could break out of the quoted string before it gets there.
if [[ -n "$EXCLUDE_EMAIL" && "$EXCLUDE_EMAIL" =~ [\'\\[:space:]] ]]; then
  echo "error: DRC_EXCLUDE_EMAIL must not contain quotes, backslashes, or whitespace" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# HTTP helper: surfaces curl/HTTP failures instead of letting `set -e` exit
# silently on a `curl -sf` failure. Never echoes tokens or keys.
# ---------------------------------------------------------------------------
http_call() {
  # $1 = human-readable description (for error messages), remaining args = curl args
  local desc="$1"; shift
  local response http_code body
  if ! response="$(curl -sS -w '\n%{http_code}' "$@")"; then
    echo "error: $desc — curl request failed (network error)" >&2
    exit 1
  fi
  http_code="${response##*$'\n'}"
  body="${response%$'\n'*}"
  if [[ "$http_code" -lt 200 || "$http_code" -ge 300 ]]; then
    echo "error: $desc — HTTP $http_code" >&2
    exit 1
  fi
  printf '%s' "$body"
}

# ---------------------------------------------------------------------------
# Part 1 — Auth Admin API
# ---------------------------------------------------------------------------
users_json="$(http_call "Auth Admin API (list users)" \
  "$SUPABASE_URL/auth/v1/admin/users?per_page=1000" \
  -H "apikey: $SUPABASE_SECRET_KEY" -H "Authorization: Bearer $SUPABASE_SECRET_KEY")"

if [[ -n "$EXCLUDE_EMAIL" ]]; then
  echo "== Accounts (Auth Admin API) — excluding $EXCLUDE_EMAIL"
else
  echo "== Accounts (Auth Admin API) — excluding nobody (DRC_EXCLUDE_EMAIL not set)"
fi
jq -r --arg me "$EXCLUDE_EMAIL" --arg since "$SINCE" --arg invited_since "$INVITED_SINCE" '
  [.users[] | select($me == "" or .email != $me)
   | { invited: (.created_at >= $invited_since),
       signed_in: (.last_sign_in_at != null),
       seen: (if .last_sign_in_at == null then "" else ([.last_sign_in_at, .updated_at] | max) end) }] as $u
  | ($u | map(select(.invited))) as $inv
  | "accounts:                   \($u|length)",
    "invited (admin-created):    \($inv|length)",
    "invited, signed in >= once: \($inv|map(select(.signed_in))|length) (\(if ($inv|length)==0 then 0 else (($inv|map(select(.signed_in))|length) * 100 / ($inv|length) | floor) end)%)",
    "all, signed in >= once:     \($u|map(select(.signed_in))|length) (\(if ($u|length)==0 then 0 else (($u|map(select(.signed_in))|length) * 100 / ($u|length) | floor) end)%)",
    "last seen >= \($since):     \($u|map(select(.seen != "" and .seen >= $since))|length)  (floor — snapshot, not history)"
' <<<"$users_json"

# ---------------------------------------------------------------------------
# Part 2 — Management API (SQL). Skipped gracefully without a PAT.
# ---------------------------------------------------------------------------
if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo
  echo "== Weekly history: SKIPPED — set SUPABASE_ACCESS_TOKEN in drc-internal/.env (see header)."
  exit 0
fi

run_sql() {
  local desc="$1" query="$2"
  jq -n --arg q "$query" '{query: $q}' \
  | http_call "$desc" -X POST "https://api.supabase.com/v1/projects/$PROJECT_REF/database/query" \
      -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" -H "Content-Type: application/json" -d @-
}

echo
# As of 2026-09-28 auth.audit_log_entries is empty (DB audit logging is off
# for this project); history comes from auth.refresh_tokens, whose revoked
# rows are retained back to launch (May 2026).
echo "== History coverage (source | rows | first | last)"
run_sql "Management API (history coverage)" "
select 'audit_log_entries' as src, count(*) as n, min(created_at)::date as first, max(created_at)::date as last from auth.audit_log_entries
union all
select 'refresh_tokens', count(*), min(created_at)::date, max(created_at)::date from auth.refresh_tokens;" | jq -r '.[] | [.src, .n, .first, .last] | @tsv'

# Activity events: a magic-link login, a token refresh (supabase-js refreshes
# the ~1h access token on page load / while the tab is visible), or a new
# session. One event ≈ "opened the site"; we count distinct users per week.
# The `me` CTE is guarded so an empty DRC_EXCLUDE_EMAIL excludes nobody
# (email = '' matches no auth.users row, so `not in (select id from me)`
# is true for everyone).
EVENTS_CTE="
with me as (select id from auth.users where email = '$EXCLUDE_EMAIL'),
ev as (
  select (payload->>'actor_id')::uuid as user_id, created_at
  from auth.audit_log_entries
  where payload->>'action' in ('login', 'token_refreshed') and created_at >= ('$SINCE'::timestamp at time zone 'Europe/Paris')
  union all
  select user_id, created_at from auth.sessions where created_at >= ('$SINCE'::timestamp at time zone 'Europe/Paris')
  union all
  select user_id::uuid, created_at from auth.refresh_tokens where created_at >= ('$SINCE'::timestamp at time zone 'Europe/Paris')
),
ev2 as (
  select user_id, (created_at at time zone 'Europe/Paris') as ts
  from ev where user_id not in (select id from me)
)"

echo
echo "== Weekly active users since $SINCE (weeks start Monday, Paris time)"
run_sql "Management API (weekly active users)" "$EVENTS_CTE
select date_trunc('week', ts)::date as week_start,
       count(distinct user_id) as active_users,
       count(distinct user_id::text || ts::date::text) as user_days
from ev2 group by 1 order by 1;" | jq -r '(["week_start","active_users","user_days"] | @tsv), (.[] | [.week_start, .active_users, .user_days] | @tsv)'

echo
echo "== Season summary since $SINCE"
run_sql "Management API (season summary)" "$EVENTS_CTE,
weekly as (
  select date_trunc('week', ts)::date as wk, count(distinct user_id) as wau
  from ev2
  where ts < date_trunc('week', now() at time zone 'Europe/Paris')  -- full weeks only: drop the current, still-open week
    and ts >= date_trunc('week', '$SINCE'::date + 6)                -- ...and drop a partial first week if SINCE isn't a Monday
  group by 1)
select (select count(distinct user_id) from ev2) as distinct_users_since,
       (select round(avg(wau), 1) from weekly) as avg_weekly_active_users,
       (select count(*) from weekly) as full_weeks_counted;" | jq -r '.[0] | to_entries[] | "\(.key): \(.value)"'

echo
echo "== Per-user active days since $SINCE"
run_sql "Management API (per-user active days)" "$EVENTS_CTE
select coalesce(nullif(m.first_name, '?') || ' ' || m.last_name, u.email) as member,
       count(distinct ev2.ts::date) as active_days, max(ev2.ts)::date as last_seen
from ev2 join auth.users u on u.id = ev2.user_id left join public.members m on m.id = u.id
group by 1 order by 2 desc;" | jq -r '.[] | [.member, .active_days, .last_seen] | @tsv'
