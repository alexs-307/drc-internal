# DRC Internal

Internal website for **Dérapage Running Club (DRC)** — a Paris-based FFA-affiliated running club (~45 members), founded June 2025. Members-only, not public-facing.

- **Owner:** Alexandre Saillard (sports director)
- **Instagram:** [@derapagerunningclub](https://www.instagram.com/derapagerunningclub/)
- **Hosting:** GitHub Pages, `main` branch, root directory

## Tech stack

- `index.html` — all CSS, JS, and the base64-encoded logo are inline. No build step, no framework.
- `sessions.json` — session data for the Entrainement tab, loaded via `fetch()` at runtime.
- Vanilla JS only. No backend. `localStorage` is used for VMA persistence.
- Only external dependency: Google Fonts (Inter).

No build system, bundler, or JS framework. Do not introduce one without explicit instruction.

## Site structure

Three tabs:

1. **Instagram** — static card with handle, follower count, and link. Follower count (`~450`) is hardcoded.
2. **Calendrier Courses** *(default tab)* — race list for season 2026-2027, rendered from the `races` JS array in `index.html`. Dynamic countdown banner to the next race. Three pillar races (Semi Boulogne, Semi Paris, Marathon Paris) get a blue left border + "Pilier" badge.
3. **Entrainement** — accordion list of track sessions since August 2025 (most recent first), search bar, and VMA calculator at the top.

## VMA calculator

Each member enters their VMA (km/h). The value persists in `localStorage` under `drc_vma`. Eight percentage chips display the corresponding pace at 70 / 75 / 80 / 85 / 90 / 100 / 105 / 110 % VMA. The `annotateVMA(text, vma)` function parses session content at render time and injects inline badges:

- `400m à 100% VMA` → blue badge with the target time
- `3' à 90% VMA` → orange badge with the estimated distance

Regex patterns:

- Distance: `/(\d+)\s*m\s*à\s*(\d+)(?:\s*[-–]\s*(\d+))?\s*%\s*VMA/g`
- Timed block: `/(\d+)'\s*(?:à|allure)\s*(\d+)(?:\s*[-–]\s*(\d+))?\s*%\s*VMA/g`

Annotation is non-destructive — the raw strings in `sessions.json` are never mutated.

## Adding a session

Prepend a new entry to the top of `sessions.json`:

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

Venues in use: `"Bertrand Dauvin"`, `"Max Roussie"`, `"Métro Château de Vincennes"`.

Session content is plain text — no HTML. `sessions.json` is editable directly in the GitHub UI without cloning the repo.

## Adding a race

Edit the `races` array in `index.html`:

```js
{
  name: "Race name",
  dateStr: "YYYY-MM-DD",
  dateDisplay: "25",
  monthDisplay: "Oct",
  yearDisplay: "2026",
  approx: false,
  approxText: "Mi-octobre",
  format: "21.1km",
  note: "Optional note text",
  pillar: false,
  confirmed: true
}
```

## Deployment

GitHub Pages redeploys automatically ~1 minute after each push to `main`.

```bash
# Weekly session update
git add sessions.json
git commit -m "séance du DD/MM/YYYY"
git push origin main

# Layout or logic change
git add index.html
git commit -m "describe your change"
git push origin main
```

`.nojekyll` prevents Jekyll processing. `robots.txt` blocks all crawlers.

## Design tokens

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
| Border radius | `10px` cards, `6px` small |
| Font | Inter (Google Fonts) |

## Constraints

- No backend, database, or server-side framework.
- No npm / `node_modules` / build pipeline.
- Keep the base64 logo inline (site must work from `file://`).
- Do not add SEO meta tags or remove `<meta name="robots" content="noindex, nofollow">`.
- Calendrier Courses must remain the default open tab.
- All member-facing text is in **French**.

## Data sources

External sources live in a separate Claude project (`DRC` workspace) and are manually synced into the repo:

| Data | Source |
|---|---|
| Weekly sessions | `DRC/sports/whatsapp_history.md` + Google Sheets `DRC PROG H2 2026` → `sessions.json` |
| Race calendar | `DRC/events/calendrier_courses_2026-2027.md` → `races[]` in `index.html` |
| Weekend de Rentrée | `DRC/events/weekend_rentree_2026.md` |
| Logo | Google Drive — `06_Communication/Logos/Dérapage-logo-rond.png` (base64 in `index.html`) |
