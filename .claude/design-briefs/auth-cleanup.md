# Auth client cleanup — collapse to one canonical path — implementer brief

## EM resolutions (read first)

1. **Branch.** `fix/auth-cleanup`. Already in flight — the implementer has one commit on it (`c89a681`). This amendment supersedes specific items in the original brief. Add a NEW commit on top of `c89a681`; do NOT amend or rebase.
2. **Scope is `index.html` only.** No SQL, no migration, no Supabase dashboard change.
3. **No new external dependencies.** Same supabase-js CDN import.
4. **Keep the SDK minor pinned** to `@supabase/supabase-js@2.49/+esm`.
5. **Why this amendment exists — read carefully.** The first iteration (`c89a681`) kept the `getSession()` call at startup with a 10 s timeout. Local browser testing exposed that this was the wrong fix. The actual SDK behaviour on session-restore-from-storage is:
   - The SDK fires `onAuthStateChange` SIGNED_IN at ~100 ms — that correctly rendered the signed-in UI (all 5 nav tabs visible).
   - But the SDK's internal init then hung validating the stored token against the server (known issue [supabase#35754](https://github.com/supabase/supabase/issues/35754)). All subsequent `supabase.from(...)` queries and the in-flight `getSession()` queued behind that stuck init — so the data fetchers ran but never returned, leaving the page signed-in with empty tabs.
   - At t=10 s, our `Promise.race` timeout fired, the `catch` branch called `setAuthUIState(false)`, and **our own code demoted the user from signed-in to anonymous.** The timeout actively caused the regression rather than masking it.

   The correct fix is to **stop calling `getSession()` at startup entirely**. Use `onAuthStateChange` (handling both `INITIAL_SESSION` and `SIGNED_IN`) as the single source of truth, with a 3 s safety-net timer that defaults to anonymous only if no event fires at all. This is the canonical pattern in current Supabase docs: the listener IS the source of truth; getSession at startup is redundant.

---

## Goal

Same as the original brief — fix the two user-reported bugs and collapse the auth client to one canonical path. The two bugs:

1. **Blank-page magic-link failure** (fixed in `c89a681` by removing the manual hash-parse race — verified passing in local testing).
2. **Auto sign-out on revisit** (NOT fixed by `c89a681` — the 10 s timeout was the wrong tool; this amendment removes `getSession()` at startup).

## Stack constraint

Vanilla JS, single `index.html`, inline styles. No build pipeline. Auth calls are `supabase.auth.signInWithOtp()`, `supabase.auth.signOut()`, `supabase.auth.onAuthStateChange()`. **`supabase.auth.getSession()` is removed entirely from this file by this amendment.**

## What to delete (amendment — IN ADDITION to deletions already in `c89a681`)

1. **The entire `Promise.race` block** at [index.html:1941-1956](../../index.html#L1941-L1956) — `try { const { data: { session } } = await Promise.race([supabase.auth.getSession(), …timeout…]); if (session) {…} else {…} } catch (e) { …setAuthUIState(false) }`. This is the block that demoted signed-in users to anonymous on the 10 s timeout. Replace it with the new pattern below.

(All other deletions from `c89a681` stay deleted.)

## What to add / change (amendment — replaces items 5 and 6 of the original brief)

1. **No `getSession()` call.** The module script must not call `supabase.auth.getSession()` anywhere. Verified by `grep -c 'getSession()' index.html` returning `0`.

2. **Handle `INITIAL_SESSION` in `onAuthStateChange`.** In supabase-js v2.49, the SDK fires `INITIAL_SESSION` shortly after `createClient` with the storage-restored session (or `null` if none). This is the primary signal for "what's the user's session at startup".

3. **Defensive — accept first-firing `SIGNED_IN` as initial auth too.** Older v2 minors and the magic-link callback flow may fire `SIGNED_IN` as the first session-bearing event. The new pattern uses "first session-bearing event wins" semantics: whichever of `INITIAL_SESSION (with session)` or `SIGNED_IN (with session)` fires first sets the initial UI state. A single boolean latch `_initialAuthHandled` prevents the initial path from running twice.

4. **3-second safety-net timer.** If neither `INITIAL_SESSION` nor `SIGNED_IN` has fired within 3 s of page load, default to anonymous. Normal SDK behaviour fires `INITIAL_SESSION` within ~100 ms; the 3 s fallback only trips on a genuinely broken SDK state. Log a `console.warn` when it trips. Crucially, **the fallback only fires if `_initialAuthHandled === false`**, so it cannot demote a session the listener already established.

5. **Module script is no longer top-level-`await`.** With the `getSession()` await gone, the script runs synchronously top to bottom. Confirm this.

6. **Keep the regression canary** (the 1-second `console.warn` if `#access_token=` is still in the URL after page load — already present in `c89a681`). Unchanged.

## Target shape — the canonical flow (replaces the previous target shape)

The module script's auth section should look approximately like this. Style and formatting follow the existing file; this is the **flow**, not the literal text to paste.

```js
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.49/+esm';

const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    flowType: 'implicit',
    detectSessionInUrl: true,
    // persistSession + autoRefreshToken default to true; do not override.
  },
});
window.supabase = supabase;

// setAuthUIState(authenticated) — unchanged from c89a681.
// dispatchSupabaseReady() + _readyDispatched latch — unchanged from c89a681.

// Initial-auth latch: flips true on the first session-bearing event
// (INITIAL_SESSION or SIGNED_IN), OR on the 3s safety-net fallback.
// Guards the initial path from running twice, and — critically — prevents
// the safety-net fallback from demoting an already-restored session.
let _initialAuthHandled = false;

function handleInitialAuth(session) {
  if (_initialAuthHandled) return;
  _initialAuthHandled = true;
  if (session) {
    setAuthUIState(true);
    dispatchSupabaseReady();
    handleSignedIn(session.user);
  } else {
    setAuthUIState(false);
  }
}

supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'INITIAL_SESSION') {
    // Fires once shortly after createClient with the storage-restored session
    // (or null). In supabase-js v2.49 this is the primary signal for restoring
    // a session from localStorage. Handle it as the initial-auth gate.
    handleInitialAuth(session);
  } else if (event === 'SIGNED_IN' && session) {
    if (!_initialAuthHandled) {
      // SDK fired SIGNED_IN as the first session-bearing event (older v2
      // behaviour, or a SDK version that skips INITIAL_SESSION). Treat it
      // as the initial-auth signal.
      handleInitialAuth(session);
    } else {
      // Post-initial sign-in: page already rendered anonymous after an
      // INITIAL_SESSION(null), then the SDK consumed the magic-link hash and
      // fires SIGNED_IN with the new session. Transition forward; do not
      // re-run the initial gate.
      setAuthUIState(true);
      dispatchSupabaseReady();
      handleSignedIn(session.user);
    }
  } else if (event === 'SIGNED_OUT') {
    setAuthUIState(false);
    if (typeof activateTab === 'function') activateTab('saison');
    if (typeof showAuthState === 'function') showAuthState('auth-state-signout', 'Déconnecté.');
  }
  // TOKEN_REFRESHED, USER_UPDATED, PASSWORD_RECOVERY: no UI change required.
});

// Safety-net: INITIAL_SESSION normally fires within ~100ms. If 3s elapses
// without any session-bearing event, default to anonymous. The latch check
// inside handleInitialAuth means this can never downgrade a session the
// listener already restored — it only catches the "SDK never fired anything"
// failure mode.
setTimeout(() => {
  if (!_initialAuthHandled) {
    console.warn('[DRC] no initial auth event within 3s — defaulting to anonymous');
    handleInitialAuth(null);
  }
}, 3000);

// Regression canary — unchanged from c89a681.
setTimeout(() => {
  if (window.location.hash && window.location.hash.includes('access_token=')) {
    console.warn('[DRC] auth: SDK did not consume #access_token hash within 1s — possible SDK regression');
  }
}, 1000);

initAuth();
```

## Things that stay untouched

Unchanged from `c89a681`:
- `setAuthUIState`, `dispatchSupabaseReady`, `_readyDispatched` latch.
- `handleSignedIn()`.
- The trimmed `initAuth()` body (no inline `getSession()`, no `onAuthStateChange` block, no signOut fallback timer).
- The `#error=...` magic-link error parser inside `initAuth`.
- `sendMagicLink()` / `signInWithOtp` form-submit logic.
- The SDK `@2.49` pin.
- The 1-second hash-leftover regression canary.
- All RLS policies, migrations, `members` table, `on_auth_user_created` trigger.
- All Compte tab UI, copy, and French strings.

## Acceptance criteria

**Code (greppable invariants — updated for the amendment):**

- [ ] `grep -c 'getSession()' index.html` outputs `0` (was `1` in `c89a681`; this amendment removes it entirely).
- [ ] `grep -c "Promise.race" index.html` outputs `0`.
- [ ] `grep -c 'INITIAL_SESSION' index.html` outputs at least `1` (the new event is handled by name).
- [ ] `grep -c "dispatchEvent.*supabase-ready" index.html` outputs `1` (unchanged).
- [ ] `grep -c 'supabase.auth.setSession(' index.html` outputs `0` (unchanged).
- [ ] `grep -c '_dataFetchersTriggered' index.html` outputs `0` (unchanged).
- [ ] `grep -c 'supabase-client-ready' index.html` outputs `0` (unchanged).
- [ ] `grep -c '@supabase/supabase-js@2.49/+esm' index.html` outputs `1` (unchanged).
- [ ] `handleSignedIn` is invoked from exactly the call sites in the target shape — `handleInitialAuth` once per page load, plus the post-initial SIGNED_IN branch. No double-fires for the same session.
- [ ] The 3 s fallback's call to `handleInitialAuth(null)` runs through the `_initialAuthHandled` early-return guard — confirmed by reading the code, not just by grep.
- [ ] The module script no longer uses top-level `await` (no `await` keyword outside a function declaration in the module script).

**Functional (must pass — verified by the EM in a real browser before any push):**

- [ ] **Bug 2 regression test, the one that failed in round 1.** In a **regular** (non-incognito) browser window: sign in via magic link, confirm `sb-zglyzryhckxbwsivlotu-auth-token` is in `localStorage`, close the tab, reopen `http://localhost:8000/`. The page must (a) land signed-in with all 5 nav tabs visible, (b) **the data tabs populated** (races, sessions, resources all loaded — not empty), (c) no `[DRC] getSession timed out` message in the console (because there's no getSession to time out), (d) no `[DRC] no initial auth event within 3s` warning either.
- [ ] **Bug 1 regression** (already passing in `c89a681`, must remain passing): cold-load magic-link click → signed-in within ~2 s, `#access_token=…` stripped, console silent.
- [ ] Sign-out → returns to anonymous view immediately, no 400 ms delay, no fallback warning.
- [ ] Expired or already-used magic link → French inline error (unchanged path).
- [ ] Anonymous visitor → lands on Saison 01 by default, sign-in form functional.
- [ ] Network flakiness (DevTools "Slow 3G") → either signed-in within ~3 s, or anonymous with the sign-in form ready. No blank page, no demoted-from-signed-in regression.

**Out of scope:**

Same as original brief — no UI changes, no PKCE migration, no dashboard changes. The Compte tab UX is untouched.

## Testing notes for the reviewer (round 2)

Reviewer round 1 was static-only and correctly reported `LGTM` against the brief as written. The brief itself was wrong — the runtime regression was only caught when the EM ran the local browser test. The reviewer for round 2 should:

1. Re-run all greppable invariants above.
2. Trace the latch logic: confirm the 3 s fallback's call to `handleInitialAuth(null)` cannot downgrade a session restored by the listener, by reading `handleInitialAuth`'s early-return guard.
3. Confirm `handleSignedIn` cannot be called twice for the same session, even across the INITIAL_SESSION → SIGNED_IN ordering.
4. Confirm `dispatchSupabaseReady` still has once-only semantics.
5. Verify no top-level `await` remains in the module script.
6. Confirm the diff vs `c89a681` is purely additive/replacement of the Promise.race block — no other file regions touched.

The reviewer's verdict gates the next round of EM-driven local browser testing, which is the actual ship gate.

## References

- [supabase#35754](https://github.com/supabase/supabase/issues/35754) — open SDK init hang. The amendment side-steps it by removing the `getSession` await; even if the SDK's internal init still hangs on token validation, the UI is already correctly set by `onAuthStateChange INITIAL_SESSION` / `SIGNED_IN` and stays signed-in.
- [Supabase: User sessions](https://supabase.com/docs/guides/auth/sessions) — `onAuthStateChange` as the source of truth, getSession is for one-off reads not startup gates.
- [Supabase: Implicit flow](https://supabase.com/docs/guides/auth/sessions/implicit-flow) — flow choice justification (unchanged).
- Internal memory `feedback_supabase_flowtype.md` — keep `flowType: 'implicit'` explicit.
- Internal memory `feedback_branch_base_discipline.md` — verify HEAD before branching (still on `fix/auth-cleanup`, do not start a new branch).
