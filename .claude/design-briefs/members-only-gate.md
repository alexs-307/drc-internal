# Members-only gate (PR 5) — backend + implementer brief

## Goal

Lock the site behind authentication. After this PR:
- Anonymous visitors at https://derapage.xyz/ see ONLY a centered sign-in card with a "Pas encore membre?" note. No tabs, no nav, no content.
- Signed-in members see the full site as today (all 5 tabs).
- Direct API calls with the publishable key against `sessions`/`races`/`resources` fail when the request is anonymous — RLS now requires authentication for reads.

This pivots the site from "publicly readable but unlisted" to "actually invite-only." PR 1 (schema) deliberately allowed public reads because content was non-sensitive. The new posture: only invited members see anything. RLS becomes the actual security boundary, not just robots.txt + obscurity.

## Tab inventory (the source of truth)

The current site has 5 tabs (in `<nav>` between lines ~1540 and ~1590 of `index.html`):

| `data-tab` | Panel id | Label | Owner |
|---|---|---|---|
| `saison` | `#tab-saison` | Saison 01 | Content tab — replaces the old Instagram tab |
| `calendar` | `#tab-calendar` | Calendrier (default active) | Content tab — race list |
| `sessions` | `#tab-sessions` | Entraînement | Content tab — weekly session list |
| `resources` | `#tab-resources` | Ressources | Content tab — PDF list |
| `compte` | `#tab-compte` | Compte | Auth UI from PR #18 |

After this PR:
- **Anonymous:** only `#tab-compte` content visible (as a centered standalone card). `<nav>` and all four content panels hidden.
- **Signed-in:** all 5 tabs visible and behave exactly as today.

## Two-part PR (one branch, two agents)

### Part 1 — Backend: `supabase/migrations/0004_gate_public_reads_to_authenticated.sql`

Tighten the SELECT policies on the three public-content tables:

- `sessions` SELECT: replace `USING (true)` with `USING (auth.uid() IS NOT NULL)`
- `races` SELECT: same
- `resources` SELECT: same

Members SELECT policy is UNCHANGED (already gated to own row OR admin via `is_admin()`).

INSERT/UPDATE/DELETE policies on all four tables are UNCHANGED (still admin-only via `is_admin()`).

Use `DROP POLICY IF EXISTS … ON …` followed by `CREATE POLICY … USING (auth.uid() IS NOT NULL)` for each. Don't use `ALTER POLICY` (handling varies across Postgres versions); drop-then-create is the portable idiom.

Header comment block: explain the policy shift (was public, now authenticated-only) + reference this brief + reference PR 1's original brief at `.claude/design-briefs/supabase-schema-init.md` which set the original public-read posture.

Rollback comment block at the bottom: show the DROP+CREATE pairs that restore `USING (true)`.

### Part 2 — Frontend: `index.html` changes

The implementer's job: gate the entire site on auth state, repurpose `#tab-compte` as the gated landing for anonymous users.

#### Auth state machine — uses PR #18's existing API surface

PR #18 already wired:
- `window.supabase.auth.onAuthStateChange(async (event, session) => { … })` (around line 2380)
- `window.supabase.auth.getSession()` (around line 2410)
- DOM divs for the four auth states (`#auth-state-signout`, `#auth-state-pending`, `#auth-state-profile`, `#auth-state-signedin`) inside `#tab-compte`

This PR adds a layer ABOVE that: a body-level class that controls whether the page is in "anonymous" mode (show only the centered auth card) or "authenticated" mode (show the full site).

#### Recommended approach

1. **Body class.** Add a class to `<body>` that defaults to `is-loading` until the auth check completes. Inside the existing `onAuthStateChange` handler AND the initial `getSession()` resolution path:
   - If session exists: switch body to `is-authenticated`
   - If no session: switch body to `is-anonymous`

2. **CSS rules** (add near the bottom of the existing inline `<style>` block):

   ```css
   /* Loading state — page is fully blank while we check auth */
   body.is-loading > header,
   body.is-loading > nav,
   body.is-loading > main { visibility: hidden; }

   /* Anonymous state — hide nav and all content tabs except #tab-compte */
   body.is-anonymous > nav { display: none; }
   body.is-anonymous .tab-panel { display: none !important; }
   body.is-anonymous #tab-compte {
     display: block !important;
     max-width: 420px;
     margin: 48px auto 0;
     padding: 0 16px;
   }
   body.is-anonymous footer { display: none; }

   /* Authenticated state — explicit no-op; default styles apply */
   /* (nav visible, .tab-panel.active visible, etc.) */
   ```

   The `!important` flags override the default `.tab-panel` display logic (where only `.active` is shown).

   Footer: implementer's call to hide or show. Recommend hidden in anonymous view since there's no context for the visitor.

3. **`<body class="is-loading">`** at page load. CSS hides header/nav/main while loading so there's no flash of either the gated card or the full site before we know which one to show.

4. **Resolve auth state on load.** Inside the existing `getSession()` handler (or right after `supabase` is exposed to `window`), call:
   ```js
   const { data: { session } } = await window.supabase.auth.getSession();
   document.body.classList.remove('is-loading');
   document.body.classList.add(session ? 'is-authenticated' : 'is-anonymous');
   ```

5. **React to auth state changes.** Inside the existing `onAuthStateChange` handler at line ~2380, after PR #18's logic runs:
   ```js
   if (event === 'SIGNED_IN') {
     document.body.classList.remove('is-anonymous', 'is-loading');
     document.body.classList.add('is-authenticated');
   } else if (event === 'SIGNED_OUT') {
     document.body.classList.remove('is-authenticated', 'is-loading');
     document.body.classList.add('is-anonymous');
   }
   ```

6. **The "Pas encore membre?" note.** Add a `<p class="auth-help">` BELOW the submit button inside `#auth-state-signout`. French copy:
   > Pas encore membre ? Contacte Alexandre (sports director) pour rejoindre le club.

   Style as muted text (`color: var(--text-muted)`, `font-size: 0.9rem`, `margin-top: 16px`, `text-align: center`). Centered or left-aligned with the form — implementer's call.

   The note lives inside `#auth-state-signout` so it auto-disappears once the user submits and moves to the pending/profile/signedin state.

7. **No layout regression for signed-in users.** The full 5-tab site must look IDENTICAL to today for anyone with a valid session.

## Hard rules

- **No new external dependencies.** Vanilla JS only.
- **Do NOT modify the publishable key handling** — it stays in `index.html` and stays public. The security delta is the RLS change, not key secrecy.
- **The Saison 01 tab is locked behind auth too.** ALL 4 content tabs are gated.
- **First-time profile capture (PR #18)** continues to work — invited members who haven't filled their profile yet get the profile form between sign-in and seeing the full site. That flow is untouched.

## Order of operations on apply (CRITICAL)

To avoid a broken interim state on production:

1. **Merge the PR first.** Frontend gate ships via GitHub Pages (~60s).
2. **Then apply `0004` migration** in the SQL editor.

Between (1) and (2):
- Anonymous visitors see only the sign-in card (frontend gate is live)
- Signed-in users see the full site (RLS hasn't tightened yet, reads still work)
- Both states are correct — safe interim

The OPPOSITE order (migration first, merge second) would leave anonymous visitors with "Calendrier indisponible" errors on three tabs for ~60s while Pages redeploys. Avoid.

Reviewer must flag this ordering in the verdict so the EM remembers post-LGTM.

## Acceptance criteria

### Backend (0004)
- [ ] `supabase/migrations/0004_gate_public_reads_to_authenticated.sql` exists
- [ ] Three `DROP POLICY IF EXISTS … ON …; CREATE POLICY … USING (auth.uid() IS NOT NULL)` pairs (one each for `sessions`, `races`, `resources`)
- [ ] INSERT/UPDATE/DELETE policies on those tables NOT touched
- [ ] Members table policies NOT touched
- [ ] Header comment block explains the policy shift
- [ ] Rollback comment block at the bottom (restoring `USING (true)`)
- [ ] No secrets in the file

### Frontend
- [ ] Anonymous visitor sees ONLY the centered sign-in card + "Pas encore membre?" line. Header visible (logo). No nav, no content tabs (Saison 01, Calendrier, Entraînement, Ressources all hidden).
- [ ] Signed-in visitor sees the full 5-tab site as today (no regression)
- [ ] Sign-in transition (anonymous → authenticated) updates the UI smoothly without page reload
- [ ] Sign-out transition (authenticated → anonymous) updates the UI smoothly without page reload
- [ ] Initial-load `is-loading` state prevents flashing the wrong UI before `getSession()` resolves
- [ ] Mobile width (375px): card fits, no overflow, no horizontal scroll
- [ ] No console errors in either state
- [ ] No new external dependencies

## Out of scope

- Inviting the 44 other members (manual dashboard work, no PR needed)
- Public landing page with "About the club" content (the user picked the minimal sign-in-card-only option)
- Email customization for the magic-link template (Supabase dashboard, separate manual task)
- Per-member content gating (e.g., admin-only race calendar) — everyone authenticated sees the same content
- Removing the publishable key from `index.html` (it's public by design — only the RLS change matters for security)
- Restyling the Compte tab when signed in (keeps its current PR #18 styling)
- **Locking static assets** — `photos_saison_01/*.jpg` and `ressources/*.pdf` are served by GitHub Pages directly and remain reachable via direct URL even after this PR. Anonymous visitors see no UI pointing to them, but anyone who knows or guesses the filenames can still fetch them. Acknowledged limitation; the user accepted this gap. To genuinely lock these, a future PR would move them to Supabase Storage with bucket-level RLS (introduces Storage as a new runtime dependency; signed URLs etc.) or switch the host to one with auth-gated routes (Vercel, Cloudflare Access). Out of scope here.

## Branch

The EM will name the branch at invocation time.
