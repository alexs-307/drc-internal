# Auth client cleanup — collapse to one canonical path — implementer brief

## EM resolutions (read first)

1. **Branch.** `fix/auth-cleanup`, branched from a freshly-pulled `main`. Per `feedback_branch_base_discipline`: run `git rev-parse --abbrev-ref HEAD` and `git log --oneline origin/main -5` before `git checkout -b` to confirm you're branching off the right base.
2. **Scope is `index.html` only.** No SQL, no migration, no Supabase dashboard change. The DB side (members table, RLS policies, on_auth_user_created trigger) is already correct and stays untouched.
3. **No new external dependencies.** Same supabase-js CDN import. Vanilla JS only.
4. **Pin the SDK minor.** Change the CDN import from `@supabase/supabase-js@2/+esm` to `@supabase/supabase-js@2.49/+esm` (the current latest minor of the v2 line as of the audit date). This prevents the SDK from shifting auth defaults under us mid-deploy — which is the exact failure mode documented in `feedback_supabase_flowtype` (defaults silently flipped to PKCE, broke magic links).

---

## Goal

Replace the current auth scaffolding in [index.html](../../index.html) with a single, canonical, supabase-js-v2 magic-link flow for a vanilla-JS client-only site. Fix two user-reported bugs in the process:

1. **Blank-page magic-link failure.** Clicking a magic link sometimes lands on a fully blank page with `#access_token=…` still in the URL.
2. **Auto sign-out on revisit.** Closing the tab and returning to the site logs the user out even though a valid session is in localStorage.

Both bugs trace to the same root cause: the page does **two** racing hash-consumption paths (SDK auto-detect + manual `setSession`), **two** separate `getSession()` calls, and a too-aggressive 3 s timeout that abandons normal token refresh. The cleanup collapses everything to one path and fixes the timeout.

## Background — why this brief exists

EM audit summary (full version is in chat history; reproduced briefly here):

- For a **vanilla-JS, static, client-only** site, the canonical supabase-js v2 magic-link setup is: `createClient(URL, KEY, { auth: { flowType: 'implicit', detectSessionInUrl: true } })` → SDK auto-consumes the `#access_token` hash on load → one `getSession()` call at startup + `onAuthStateChange` listener for everything after. That is the entire pattern, per the official [Implicit flow](https://supabase.com/docs/guides/auth/sessions/implicit-flow) and [Passwordless email logins](https://supabase.com/docs/guides/auth/auth-email-passwordless) docs.
- DRC's current code adds: a redundant manual `URLSearchParams` + `setSession` hash parser, a second `getSession()` inside `initAuth()`, two separate ready-events plus a debounce boolean, a 3 s hard timeout on `getSession`, and a 400 ms defensive timer on `signOut`. All of this exists because the original author hit one or more SDK quirks and bolted on workarounds. The workarounds now race with each other.
- The `getSession()` hang is a real, currently-open supabase-js bug ([supabase#35754](https://github.com/supabase/supabase/issues/35754)). The community workaround is a `Promise.race` with a **10 s** timeout, not 3 s. 3 s is short enough to trip on a normal refresh-token round-trip over a slow mobile connection — which is exactly the auto-sign-out symptom.

## Stack constraint

Vanilla JS, single `index.html`, inline styles. No build pipeline, no bundler, no npm. Supabase JS SDK already on the page via CDN ESM. Auth calls remain `supabase.auth.signInWithOtp()`, `supabase.auth.signOut()`, `supabase.auth.onAuthStateChange()`, `supabase.auth.getSession()`. No new external dependencies.

## What to delete

Be precise about line ranges — these are the only blocks affected. Existing line numbers refer to `main` at the time this brief was written.

1. **Manual hash parser** ([index.html:1882-1912](../../index.html#L1882-L1912)) — the `if (window.location.hash && window.location.hash.includes('access_token=')) { … setSession(…) … }` block. SDK's `detectSessionInUrl: true` already does this; the manual path races with it and has no timeout, which is the root cause of the blank-page bug.
2. **Second `getSession()` call** ([index.html:2534-2538](../../index.html#L2534-L2538)) inside `initAuth()`. The module script's `getSession()` at line 1929 already covers initial session detection; `onAuthStateChange`'s SIGNED_IN event (which fires for the initial session restore too) handles the UI transition into the signed-in state.
3. **`supabase-client-ready` event + `_dataFetchersTriggered` debounce flag** ([index.html:1917](../../index.html#L1917), [1944](../../index.html#L1944), [1949](../../index.html#L1949), [2499-2502](../../index.html#L2499-L2502)). Collapse to a single `supabase-ready` event dispatched exactly once.
4. **`signOut` 400 ms fallback timer** ([index.html:2470-2480](../../index.html#L2470-L2480)). The SDK fires `SIGNED_OUT` on `onAuthStateChange` reliably after `signOut()` resolves; the defensive timer just papered over a transient symptom that, if it ever recurred, deserves a console error rather than silent UI correction.

## What to add / change

5. **Bump the `getSession()` timeout from 3 s → 10 s** in the module script ([index.html:1929-1932](../../index.html#L1929-L1932)). Keep the `Promise.race` pattern — the [supabase#35754](https://github.com/supabase/supabase/issues/35754) hang is real and unresolved. 10 s is the community-validated workaround value: long enough to absorb a slow refresh-token round-trip on a flaky mobile connection, short enough that a genuinely-broken SDK doesn't strand the page forever.
6. **Add a one-line regression canary** after the 1 s mark on initial load: if `window.location.hash.includes('access_token=')` is still true 1 second after the module script begins, `console.warn('[DRC] auth: SDK did not consume #access_token hash within 1s — possible SDK regression')`. We deleted the manual fallback in step 1; this canary is how we'd notice if the SDK ever regresses and we need to put a fallback back. Pure observability — no UI change.
7. **Centralise body-class state transitions** into a single function `setAuthUIState(authenticated)` defined once. Replace every direct `document.body.classList.add/remove('is-authenticated' | 'is-anonymous' | 'is-loading')` call ([index.html:1939-1941](../../index.html#L1939-L1941), [1947-1948](../../index.html#L1947-L1948), [2475-2477](../../index.html#L2475-L2477), [2493-2494](../../index.html#L2493-L2494), [2506-2507](../../index.html#L2506-L2507)) with a call to `setAuthUIState(true)` or `setAuthUIState(false)`. The function also handles the anonymous-mode default-tab switch (currently inline at [index.html:1956-1963](../../index.html#L1956-L1963)) so all UI consequences of an auth state change live in one place.
8. **Pin SDK minor.** Change [index.html:1864](../../index.html#L1864) from `@supabase/supabase-js@2/+esm` to `@supabase/supabase-js@2.49/+esm`. Same SDK semantics today, immune to surprise default flips tomorrow.

## Target shape — the canonical flow

The module script at the bottom of `index.html` should look approximately like this (illustrative — not a literal find-and-replace; the implementer adapts to existing style):

```js
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49/+esm';

const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    flowType: 'implicit',          // correct for vanilla-JS static SPA (no SSR)
    detectSessionInUrl: true,      // SDK auto-consumes #access_token=... from magic links
    // persistSession + autoRefreshToken default to true; do not override
  },
});
window.supabase = supabase;

// Centralised UI state transition. Called from initial-session resolver and onAuthStateChange.
function setAuthUIState(authenticated) {
  document.body.classList.remove('is-loading', 'is-authenticated', 'is-anonymous');
  document.body.classList.add(authenticated ? 'is-authenticated' : 'is-anonymous');
  if (!authenticated) {
    // Anonymous default tab: Saison 01, not Calendrier
    document.querySelector('.tab-btn[data-tab="calendar"]')?.classList.remove('active');
    document.querySelector('.tab-btn[data-tab="saison"]')?.classList.add('active');
    document.getElementById('tab-calendar')?.classList.remove('active');
    document.getElementById('tab-saison')?.classList.add('active');
  }
}

// Single dispatch latch for the data-fetcher event (renderRaces / loadSessions / loadResources).
let _readyDispatched = false;
function dispatchSupabaseReady() {
  if (_readyDispatched) return;
  _readyDispatched = true;
  document.dispatchEvent(new CustomEvent('supabase-ready'));
}

// onAuthStateChange handles every transition: initial restore, magic-link callback, sign-out,
// silent token refresh. Wired BEFORE getSession() so the initial SIGNED_IN event is not missed.
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_IN' && session) {
    setAuthUIState(true);
    dispatchSupabaseReady();
    handleSignedIn(session.user);  // existing function — first_name fetch + signed-in card
  } else if (event === 'SIGNED_OUT') {
    setAuthUIState(false);
    if (typeof activateTab === 'function') activateTab('saison');
    if (typeof showAuthState === 'function') showAuthState('auth-state-signout', 'Déconnecté.');
  }
  // TOKEN_REFRESHED, INITIAL_SESSION: no UI change needed.
});

// One getSession at startup, raced against a 10s timeout to defend against the
// known supabase-js hang (github.com/supabase/supabase/issues/35754).
// If we time out, we render anonymous; onAuthStateChange will still upgrade us
// to authenticated if the SDK eventually catches up.
try {
  const { data: { session } } = await Promise.race([
    supabase.auth.getSession(),
    new Promise((_, r) => setTimeout(() => r(new Error('getSession timeout (10s)')), 10000)),
  ]);
  if (session) {
    setAuthUIState(true);
    dispatchSupabaseReady();
    // Do NOT call handleSignedIn here — onAuthStateChange fires INITIAL_SESSION/SIGNED_IN
    // immediately after getSession resolves, and that handler calls handleSignedIn.
  } else {
    setAuthUIState(false);
  }
} catch (e) {
  console.error('[DRC] getSession timed out; defaulting to anonymous view.', e);
  setAuthUIState(false);
}

// Regression canary — if SDK ever fails to consume the hash, we hear about it in console
// before users start reporting blank pages.
setTimeout(() => {
  if (window.location.hash && window.location.hash.includes('access_token=')) {
    console.warn('[DRC] auth: SDK did not consume #access_token hash within 1s — possible SDK regression');
  }
}, 1000);

// initAuth() is still called to wire the sign-in form / resend / change-email / signout buttons.
// It MUST NOT call getSession() itself anymore — the module script above is the single source of truth.
initAuth();
```

The exact wiring may differ — the implementer should respect existing function shapes (`handleSignedIn`, `initAuth`, `showAuthState`, `activateTab`, etc.) and not rename or relocate them. The skeleton above is the **flow**, not the literal text to paste.

## Things that stay untouched

- `handleSignedIn()` ([index.html:2541-2554](../../index.html#L2541-L2554)) — first_name fetch + signed-in card.
- `sendMagicLink()` / `signInWithOtp` form-submit logic ([index.html:2363-2417](../../index.html#L2363-L2417)) — the sign-in UI, resend lockdown, error mapping.
- Magic-link error parser ([index.html:2515-2532](../../index.html#L2515-L2532)) — `#error=…&error_description=…` handling. Implicit-flow errors arrive in the hash; this code is correct.
- `is-loading` CSS rule ([index.html:1539-1542](../../index.html#L1539-L1542)) — the initial loading mask stays; `setAuthUIState` removes it on the first state transition.
- Compte tab UI, sign-in / resend / sign-out form copy, all French strings.
- All RLS policies, migrations, `members` table, `on_auth_user_created` trigger.

## Acceptance criteria

Functional (must pass):
- [ ] Cold-load magic-link click → page renders signed-in within ~2 s, `#access_token=…` is stripped from the URL, no console errors.
- [ ] Already-signed-in revisit (close tab → reopen) → page renders signed-in directly, no flash of anonymous, no spurious sign-in card.
- [ ] Already-signed-in revisit after >1 h (access token expired, refresh token valid) → SDK refreshes the access token transparently; page lands signed-in without prompting for a new magic link. The 10 s timeout must not trip under normal network conditions.
- [ ] Anonymous visitor → Compte tab on Saison 01 by default, sign-in form visible and functional.
- [ ] Sign-in → confirmation panel transition, magic link arrives, click → signed-in. No blank page.
- [ ] Sign-out → returns to anonymous view immediately (no 400 ms wait, no fallback warning in console).
- [ ] Expired or already-used magic link → French error message shown inline, hash cleared.
- [ ] Network flakiness during initial load (devtools "Slow 3G" simulation) → either signed-in within 10 s, or anonymous view with no broken state and the sign-in form ready. No blank page.

Code (must pass):
- [ ] Only one `getSession()` call exists in the entire file (`grep 'getSession()' index.html | wc -l` → 1).
- [ ] Only one `supabase-ready` dispatch site exists (`grep "dispatchEvent.*supabase-ready" index.html | wc -l` → 1). `supabase-client-ready` is removed entirely.
- [ ] No call to `supabase.auth.setSession(` remains in the file.
- [ ] No `_dataFetchersTriggered` references remain.
- [ ] Body-class mutations for `is-authenticated` / `is-anonymous` / `is-loading` happen only inside `setAuthUIState`. (Search the file for `classList.*is-authenticated` / `is-anonymous` / `is-loading` — every match should be inside `setAuthUIState` or the initial HTML `<body class="is-loading">`.)
- [ ] SDK import URL is pinned to `@supabase/supabase-js@2.49/+esm`.
- [ ] The 1-second hash-leftover canary is present and uses `console.warn`.

Out of scope:
- New visual changes (this is a behavioural cleanup; the UI must look identical at every state).
- Migrating to PKCE flow (a separate decision; would require email-template changes and a `verifyOtp({ token_hash })` callback handler — not needed for a client-only static site).
- Changing the Compte tab UX, copy, or layout.
- SMTP / dashboard config changes.
- Touching any migration, RLS policy, or backend script.

## Testing notes for the reviewer

The two user-reported bugs are the regression-test cases:

1. **Blank-page magic-link.** Hard to reproduce on demand because it requires the SDK auto-detect + manual `setSession` to race in a particular order. To validate the fix: request a magic link in an incognito window, click it from email, confirm the page renders signed-in within 2 s and the hash is gone. Repeat 5 times to catch any residual race.

2. **Auto sign-out on revisit.** To validate: sign in, close the tab, wait ≥1 hour (so the access token expires), reopen `derapage.xyz`. Expected: signed-in state restored within ~2 s with no sign-in card flash. If the 10 s timeout trips on a healthy network, that's a regression — bump it or report the SDK timing back to the EM.

DevTools verification:
- Network tab: confirm exactly one `/auth/v1/token?grant_type=refresh_token` call on revisit-after-1h (no manual extra round-trips).
- Console: clean except for the one-time `[DRC] auth: SDK did not consume…` warning IF (and only if) the SDK regresses — should be silent in the happy path.
- Application → Local Storage: the `sb-<project-ref>-auth-token` key persists across tab close.

## References

- [Supabase: Passwordless email logins](https://supabase.com/docs/guides/auth/auth-email-passwordless) — canonical client-only magic-link skeleton
- [Supabase: Implicit flow](https://supabase.com/docs/guides/auth/sessions/implicit-flow) — why implicit is correct for client-only and what `detectSessionInUrl` does
- [Supabase: User sessions](https://supabase.com/docs/guides/auth/sessions) — `getSession` + `onAuthStateChange` best practice (one of each, not many)
- [supabase#35754](https://github.com/supabase/supabase/issues/35754) — open bug confirming `getSession()` / `getUser()` can hang; 10 s `Promise.race` is the community workaround
- Internal memory `feedback_supabase_flowtype.md` — context on why `flowType: 'implicit'` stays explicit (defaults flipped to PKCE in a past SDK minor and silently broke us)
- Internal memory `feedback_branch_base_discipline.md` — verify HEAD before branching
