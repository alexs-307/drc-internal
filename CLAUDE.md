# CLAUDE.md — DRC Internal Website

> Context file for Claude Code. Read this before making any change to the site.

---

## Project overview

Static internal website for **Dérapage Running Club (DRC)**, a Paris-based FFA-affiliated running club (~45 members), founded June 2025. The site is for members only — not public-facing. It is deployed on GitHub Pages at `https://<username>.github.io/drc-internal/`.

**Owner / main contact:** Alexandre Saillard (sports director)
**Instagram:** [@derapagerunningclub](https://www.instagram.com/derapagerunningclub/)

---

## Tech stack & architecture

- **`index.html`** — all CSS, JS, and the base64-encoded logo are inline. No build step, no framework, no external dependencies except Google Fonts (Inter, CDN).
- **`sessions.json`** — session data for the Entrainement tab. Loaded via `fetch()` at runtime. Edit this file to add/update sessions without touching HTML.
- **Vanilla JS only** — no React, no Alpine, no jQuery.
- **No backend** — race data is hardcoded in a JS array inside `index.html`. Session data lives in `sessions.json`. `localStorage` is used for VMA persistence.
- **Password gate** — lightweight JS modal using SHA-256 (Web Crypto API) + `sessionStorage`. Password is never stored in plaintext.

Do not introduce a build system, a bundler, or a JS framework without explicit instruction.

---

## Design system

| Token | Value |
|---|---|
| Primary blue | `#001EFF` |
| Blue light | `#3348FF` |
| Blue faint | `#EEF0FF` |
| Peach accent | `#FFE1D2` |
| Background | `#F6F6F6` |
| White | `#FFFFFF` |
| Text | `#0D0D0D` |
| Text muted | `#5A5A5A` |
| Border | `#E2E2E2` |
| Border radius | `10px` (cards), `6px` (small) |
| Font | Inter (Google Fonts) |

The logo is embedded as a base64 PNG directly in the HTML. Do not replace it with an external path unless explicitly asked.

---

## Site structure — 3 tabs

### Tab 1 — Instagram
- Static card with handle, follower count, and a link to the Instagram profile.
- 6 placeholder slots for post images (manually updated).
- The follower count (`~450`) is hardcoded — update it manually when needed.

### Tab 2 — Calendrier Courses *(default tab on load)*
- Race list for season 2026-2027, rendered from the `races` JS array.
- Dynamic countdown banner to the next upcoming race (computed in JS from today's date).
- Three races are marked as **pillar** races (Semi Boulogne, Semi Paris, Marathon Paris) — displayed with a blue left border and "Pilier" badge.
- No inscription links — intentionally removed.

**To add or edit a race**, modify the `races` array. Each entry:
```js
{
  name: "Race name",
  dateStr: "YYYY-MM-DD",       // used for countdown + sort logic
  dateDisplay: "25",           // day number, or null if approx
  monthDisplay: "Oct",
  yearDisplay: "2026",
  approx: false,               // true = show approxText instead of dateDisplay
  approxText: "Mi-octobre",    // only used when approx: true
  format: "21.1km",
  note: "Optional note text",  // displayed as italic tag, omit if not needed
  pillar: false,               // true = blue left border + Pilier badge
  confirmed: true              // true = "Confirmée" badge, false = "À confirmer"
}
```

### Tab 3 — Entrainement
- Accordion list of track sessions since August 2025, most recent first.
- Search bar filters by any text across label, content, venue.
- **VMA calculator** at the top (see section below).

**To add a new session**, prepend an entry to `sessions.json` (most recent first):
```json
{
  "date": "YYYY-MM-DD",
  "label": "Short session title",
  "venue": "Bertrand Dauvin",
  "g12": "Content for Groupe 1 / Groupe 2\nUse \\n for line breaks.",
  "g3": "Content for Groupe 3, or null if same as G1/G2",
  "suggestion": "Weekly suggestion, or null"
}
```

Venue values in use: `"Bertrand Dauvin"`, `"Max Roussie"`, `"Métro Château de Vincennes"`.

Session content is plain text — no HTML. The VMA annotator parses it at render time and injects `<span>` badges inline. `sessions.json` is editable directly in the GitHub UI without cloning the repo.

---

## VMA Calculator

Located at the top of the Entrainement tab. Lets each member enter their own VMA (in km/h).

**Behaviour:**
- Input is saved to `localStorage` key `drc_vma` — persists across page reloads.
- 8 percentage chips display the corresponding pace: 70%, 75%, 80%, 85%, 90%, 100%, 105%, 110%.
- The `annotateVMA(text, vma)` function parses session content at render time and injects inline badges:
  - `400m à 100% VMA` → appends a **blue badge** with the target time (e.g. `1'34"`)
  - `3' à 90% VMA` → appends an **orange badge** with the estimated distance (e.g. `~702m`)
- Annotation is non-destructive: the raw session strings are never mutated.

**Regex patterns used:**
- Distance: `/(\d+)\s*m\s*à\s*(\d+)(?:\s*[-–]\s*(\d+))?\s*%\s*VMA/g`
- Timed block: `/(\d+)'\s*(?:à|allure)\s*(\d+)(?:\s*[-–]\s*(\d+))?\s*%\s*VMA/g`

If new session content uses a different phrasing for VMA percentages, extend these patterns.

---

## Password gate

- Implemented as a JS modal injected on page load.
- Uses `sessionStorage` key `drc_auth` — re-auth required when the tab is closed, not on refresh.
- Password validated via SHA-256 (Web Crypto API). Plaintext never stored or compared.
- The SHA-256 hash is hardcoded as a hex constant in the script. To change the password, compute a new hash and replace the constant.

To change the password:
```js
// In browser console or Node:
const hash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('newpassword'));
console.log([...new Uint8Array(hash)].map(b => b.toString(16).padStart(2,'0')).join(''));
```

---

## Deployment

- Hosted on GitHub Pages, `main` branch, root directory.
- `.nojekyll` file at root prevents Jekyll processing.
- `robots.txt` at root blocks all crawlers.

**To add a session (weekly update):**
```bash
# Edit sessions.json — prepend new entry at top of array — then:
git add sessions.json
git commit -m "séance du DD/MM/YYYY"
git push origin main
```

**To update the site layout or logic:**
```bash
git add index.html
git commit -m "describe your change"
git push origin main
```

GitHub Pages redeploys automatically in ~1 minute after each push.

---

## What NOT to do

- Do not add a backend, a database, or a server-side framework.
- Do not introduce npm / node_modules / a build pipeline.
- Do not remove the base64 logo or replace it with an external URL (site must work offline / file://).
- Do not modify the password gate to store plaintext.
- Do not add SEO meta tags or remove `<meta name="robots" content="noindex, nofollow">`.
- Do not change the default open tab (Calendrier Courses must open first).
- All member-facing text is in **French**. Do not translate it.

---

## Data sources (external, not in this repo)

The following live in a separate Claude Project (`DRC` workspace on Alexandre's Mac) and are manually synced into `index.html`:

| Data | Source |
|---|---|
| Weekly sessions | `DRC/sports/whatsapp_history.md` + Google Sheets `DRC PROG H2 2026` (ID: `1yenXpzfpSczJ8Hjw0dgsFMfUf0KWp9v3c5CCvDRT60Y`) → synced into `sessions.json` |
| Race calendar | `DRC/events/calendrier_courses_2026-2027.md` → hardcoded in `races[]` array in `index.html` |
| Weekend de Rentrée | `DRC/events/weekend_rentree_2026.md` |
| Logo | Google Drive — `06_Communication/Logos/Dérapage-logo-rond.png` (base64 in `index.html`) |

Future improvement: extract `races[]` into a `races.json` on the same pattern as `sessions.json`.
