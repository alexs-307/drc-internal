# Supabase Auth — magic-link sign-in/out + first-time signup capture — implementer brief

## EM resolutions (read first)

The designer's three open questions are resolved here so the implementer has no ambiguity:

1. **Placeholder sentinel.** `handle_new_user()` in `supabase/migrations/0001_init.sql` writes the literal string `'?'` for both `first_name` and `last_name` when `raw_user_meta_data` is absent or empty (`COALESCE(NULLIF(TRIM(...), ''), '?')`). `birth_date` is set to `NULL` when absent. The post-callback first-time-form detection rule is therefore: **show the first-time form when `members.first_name = '?'` OR `members.last_name = '?'`**. `birth_date IS NULL` is allowed for established members too (the column is nullable), so do not gate on it.
2. **Birthdate format.** The native `<input type="date">` returns a string in ISO `YYYY-MM-DD` format. Postgres `date` accepts that directly. The Supabase JS client serializes it as-is. **No client-side date transformation required.** When the field is empty, send `null` (not an empty string).
3. **Cross-device magic-link callback.** Accepted as-is for 45 members — keep Supabase's default OTP settings. **No code change.** If a member reports an issue we revisit the dashboard later.

**Display font correction.** The brief references "Space Grotesk" — that is not in use on the site. The actual V2 display stack is **Anton** (wordmark / display), **Bebas Neue** (sub-display / section titles), **JetBrains Mono** (mono / nav labels), and **Inter** (body). Map the brief's "Space Grotesk at section-title weight" → Bebas Neue, the established section-title font. The implementer should follow the existing patterns in `index.html` and not introduce a new font.

---

## Goal

Add member authentication to `index.html`: a magic-link email sign-in, a "check your inbox" waiting state, a first-time profile capture form (name + birthdate), and a signed-in state with a sign-out affordance. No passwords, no header greeting, no member-only content gating. The entry point must be discoverable without crowding the existing four-tab nav.

## Stack constraint

**No build pipeline, no bundler, no npm.** Vanilla JS, single `index.html`, inline styles. Supabase JS SDK already on the page via CDN ESM (PR 3). Auth calls use `supabase.auth.signInWithOtp()`, `supabase.auth.signOut()`, and `supabase.auth.onAuthStateChange()`. No new external dependencies.

**EM config step (not a code change):** The Supabase dashboard → Authentication → URL Configuration → Site URL must be set to the GitHub Pages root (`https://<username>.github.io/drc-internal/`) and that same URL must be added to the Redirect URLs allowlist. The implementer does not handle this — flag it in a code comment near the `signInWithOtp` call.

## Entry point decision: a fifth "Compte" tab

A fifth tab labelled **Compte** (placed last in the nav, after Ressources) is the chosen entry point. Rationale: the tab nav is already the site's top-level navigation idiom — adding auth as a peer tab is coherent, requires no new UI pattern, and leaves the header clean. A header button or footer link would be harder to discover on mobile. A dedicated panel inside an existing tab would feel buried. The Compte tab is lightly weighted at rest (same monospace uppercase label style as the others, no badge) and activates the sign-in form or the signed-in state depending on auth.

## First-time capture decision: AFTER the magic-link callback

Profile fields (first name, last name, birthdate) are collected after the user clicks the magic link and lands back on the site — not before sending the link. Rationale: asking three fields before even dispatching the email adds friction and may cause drop-off for a flow that 45 people use once. After the callback the user is already authenticated and committed; the one-time form feels like a natural "finish setting up your profile" moment rather than a gate. The `handle_new_user()` trigger populates `members` with placeholder values on first sign-in; the post-callback form detects those placeholders and replaces them via an `UPDATE` call.

## States

### 1 — Signed-out (Compte tab at rest)

A compact, vertically centred panel within the tab content area. Heading in the existing section-title font (Bebas Neue), same scale as other section titles. A short explanatory line in muted body text: _"Connecte-toi pour accéder à ton espace membre."_ Below it, the sign-in form (see State 2).

### 2 — Sign-in form

Single input for email address, full-width, matching the existing card border and border-radius. Label above in small monospace caps. Placeholder text: _"ton@email.fr"_. One primary button below: **"Recevoir le lien"** — filled with the primary blue, white label, matching the existing blue button treatment used elsewhere on the site. No other fields at this stage.

Error display: below the button, a single line in muted text (same quiet treatment as `.data-error` from PR 3 — no red, no icon). Messages:
- Invalid or empty email: _"Adresse e-mail invalide."_
- Rate limit: _"Trop de tentatives. Réessaie dans quelques minutes."_
- Network failure: _"Connexion impossible. Vérifie ta connexion et réessaie."_

### 3 — Awaiting email (confirmation state)

The form is replaced — not pushed down, replaced — by a confirmation panel. A small envelope icon (inline SVG, one color: the primary blue) sits above the text. Heading: **"Vérifie ta boîte mail"** in the section-title font (Bebas Neue). Body: _"Un lien de connexion vient d'être envoyé à [email]. Clique dessus pour te connecter — il est valable 10 minutes."_

Below the body, two small secondary affordances in muted monospace: a **"Renvoyer le lien"** text-link (triggers a second `signInWithOtp` call; disabled and greyed for 30 seconds after first send to prevent spam), and a **"Utiliser une autre adresse"** link that returns to the sign-in form.

No spinner. No timer countdown. The wait is calm, not urgent.

### 4 — Magic-link callback handling

When the user returns to the site from the magic-link URL, Supabase's `onAuthStateChange` fires with a `SIGNED_IN` event. The page does not reload. The Compte tab transitions silently: if the user is already on the Compte tab they see the transition directly; if they are on another tab the Compte tab updates in the background (no forced navigation). No toast, no banner — the signed-in state (State 5 or 6) simply appears in the Compte tab. The transition is a quick fade rather than a hard swap.

### 5 — First-time profile form (new members only)

Triggered when `onAuthStateChange` fires and the `members` row has placeholder values (`first_name = '?'` or `last_name = '?'` — see EM resolution 1). This check is a single Supabase select on the `members` table filtered by the current user's ID.

The form presents three fields stacked vertically within the Compte tab content area, styled like the sign-in form:
- **Prénom** (text input)
- **Nom** (text input)
- **Date de naissance** (date input — native browser date picker, no custom calendar widget)

Heading: **"Bienvenue chez DRC — complète ton profil"** in the section-title font. Brief line below: _"Ces informations sont réservées aux membres du club."_ in muted body text.

One primary blue button: **"Enregistrer"**. On success, transition to the signed-in state (State 6). On error, a muted inline error below the button: _"Impossible d'enregistrer. Réessaie."_

No skip affordance — the form is a one-time requirement and short enough not to warrant it.

### 6 — Signed-in state

The Compte tab shows a minimal summary panel. First line: the member's first name in the section-title font, slightly larger than body text, not display-sized. Second line in muted body text: _"Connecté en tant que [email]"_. Below, a single secondary-style button: **"Se déconnecter"** — outlined, not filled, matching the secondary button treatment. On click: `signOut()`, silent, then transition back to State 1.

No avatar, no stats, no member details panel at this stage.

### 7 — Error states (general)

All errors appear inline, below their triggering action. No modal. No toast. Muted grey text, body size, no icon. Consistent with the `.data-error` pattern from PR 3.

Specific messages (French):
- Expired magic link: _"Ce lien a expiré. Demande un nouveau lien."_
- Already used link: _"Ce lien a déjà été utilisé. Demande un nouveau lien."_

## Copy table (French strings, member-facing)

| Context | String |
|---|---|
| Compte tab label | Compte |
| Signed-out description | Connecte-toi pour accéder à ton espace membre. |
| Email label | Adresse e-mail |
| Email placeholder | ton@email.fr |
| Submit button | Recevoir le lien |
| Confirmation heading | Vérifie ta boîte mail |
| Confirmation body | Un lien de connexion vient d'être envoyé à [email]. Clique dessus pour te connecter — il est valable 10 minutes. |
| Resend link | Renvoyer le lien |
| Change email link | Utiliser une autre adresse |
| Profile form heading | Bienvenue chez DRC — complète ton profil |
| Profile form subtext | Ces informations sont réservées aux membres du club. |
| Save button | Enregistrer |
| Sign-out button | Se déconnecter |
| Signed-in email line | Connecté en tant que [email] |
| Error — invalid email | Adresse e-mail invalide. |
| Error — rate limit | Trop de tentatives. Réessaie dans quelques minutes. |
| Error — network | Connexion impossible. Vérifie ta connexion et réessaie. |
| Error — link expired | Ce lien a expiré. Demande un nouveau lien. |
| Error — link used | Ce lien a déjà été utilisé. Demande un nouveau lien. |
| Error — profile save | Impossible d'enregistrer. Réessaie. |

## Visual direction

- **Color:** Primary blue for the submit button fill and the confirmation icon. Secondary affordances (resend, change email, sign-out) use the outlined/text style — blue text, no fill. Error messages in the existing muted grey. The panel background inherits the off-white page background — no card lift or shadow for the auth panel itself; it should feel like a content area, not a widget.
- **Type:** Section heading in the existing section-title font (Bebas Neue, per the V2 stack), matching every other tab's section title. Form labels in small monospace uppercase (JetBrains Mono), matching the nav tab label style. Error messages in regular Inter body, one step smaller than body size, muted.
- **Layout and spacing:** The sign-in panel is horizontally centred within the tab content area and narrower than the full content column — roughly two-thirds the width — so it reads as a focused form rather than a stretched page section. Vertical spacing between elements follows the existing card internal rhythm. The confirmation panel replaces the form in-place, same bounding box, so there is no layout shift.
- **Motion:** A soft opacity fade (quick, under 200ms) when transitioning between states — signed-out to confirmation, confirmation to signed-in, signed-in to signed-out. The fade mirrors the existing tab-switch behaviour and keeps the page feeling calm.

## Accessibility

- Every input has an associated label (not placeholder-as-label).
- The sign-out button is keyboard-focusable and activatable.
- State transitions are announced via an `aria-live` region (polite) so screen-reader users hear the confirmation message without a page reload.
- Focus moves to the confirmation heading after submit, and to the first input after "Utiliser une autre adresse" is clicked.

## Acceptance criteria

- [ ] A fifth "Compte" tab appears last in the nav, styled identically to the existing four tabs
- [ ] Unsigned-in state shows the email input and "Recevoir le lien" button
- [ ] Submitting a valid email calls `signInWithOtp` and replaces the form with the confirmation panel
- [ ] The confirmation panel shows the submitted email address and a "Renvoyer le lien" link disabled for 30 seconds
- [ ] The "Renvoyer le lien" link re-enables after 30 seconds
- [ ] "Utiliser une autre adresse" returns to the sign-in form
- [ ] `onAuthStateChange` SIGNED_IN event transitions the Compte tab to signed-in state (or first-time form) without a page reload
- [ ] First-time form appears when `members.first_name = '?'` or `members.last_name = '?'`; skipped otherwise
- [ ] First-time form saves via Supabase update (`birth_date` empty → `null`, not empty string) and transitions to signed-in state on success
- [ ] Signed-in state shows the member's first name and email
- [ ] "Se déconnecter" calls `signOut()` and returns to the sign-out state
- [ ] All French error messages appear inline, muted, no red, no icon
- [ ] Expired / already-used magic-link errors display the appropriate French message
- [ ] Invalid email shows an error without calling `signInWithOtp`
- [ ] All inputs have associated labels; sign-out button is keyboard-operable
- [ ] An `aria-live` region announces state transitions
- [ ] A code comment near `signInWithOtp` flags the Supabase dashboard redirect-URL config step for the EM
- [ ] No new external dependencies beyond the Supabase CDN already added in PR 3

## Out of scope

Email/password login, OAuth providers, "remember me" toggle, profile edit after first capture, header greeting, member-only content gating (all content remains readable without sign-in), admin UI, password reset, avatars, VMA migration to user record.

## References

- [Authentication with a magic link — Projects by IF](https://catalogue.projectsbyif.com/patterns/authentication-with-a-magic-link/) — established pattern catalogue entry covering the confirmation-state UX
- [Magic links UX and security — Baytech Consulting 2025](https://www.baytechconsulting.com/blog/magic-links-ux-security-and-growth-impacts-for-saas-platforms-2025) — covers expiry UX, resend affordances, and error state guidance
- [Best Sign Up Flows 2026 — Eleken](https://www.eleken.co/blog-posts/sign-up-flow) — defer-profile-fields-until-after-auth precedent (ClickUp, Stripe examples)
- [OTP vs Magic Links — Scalekit](https://www.scalekit.com/blog/otp-vs-magic-links-passwordless-authentication) — cross-device considerations and expiry tradeoffs
- [Passwordless login with magic links — AppMaster checklist](https://appmaster.io/blog/passwordless-magic-links-ux-security-checklist) — UX and accessibility checklist for magic-link flows
