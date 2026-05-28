# DRC Internal

Internal website for **Dérapage Running Club (DRC)** — a Paris-based FFA-affiliated running club (~45 members), founded June 2025. Members-only, not public-facing.

- **Owner:** Alexandre Saillard (sports director)
- **Instagram:** [@derapagerunningclub](https://www.instagram.com/derapagerunningclub/)
- **Hosting:** GitHub Pages, `main` branch, root directory

## Tech stack

- `index.html` — all CSS, JS, and the base64-encoded logo are inline. No build step, no framework.
- **Supabase backend** — `sessions`, `races` and `resources` are fetched from Supabase Postgres tables at runtime via the Supabase JS SDK; member sign-in uses Supabase Auth (magic link). Schema + migrations under `supabase/`.
- Vanilla JS only. `localStorage` is used for VMA persistence (intentionally not in the DB).
- External dependencies: Google Fonts (Inter) and the Supabase JS SDK (CDN ESM import).

No build system, bundler, or JS framework. Do not introduce one without explicit instruction.

## Site structure

Four tabs (order: **Instagram · Calendrier Courses · Entrainement · Ressources**; default = Calendrier Courses):

1. **Instagram** — static card with handle, follower count, and link. Follower count (`~450`) is hardcoded.
2. **Calendrier Courses** *(default tab)* — race list for season 2026-2027, fetched from the Supabase `races` table. Dynamic countdown banner to the next race. Three pillar races (Semi Boulogne, Semi Paris, Marathon Paris) get a blue left border + "Pilier" badge.
3. **Entrainement** — accordion list of track sessions since August 2025 (most recent first), search bar, and VMA calculator at the top. Sessions are fetched from the Supabase `sessions` table.
4. **Ressources** — club PDF documents, fetched from the Supabase `resources` table; the PDF files themselves live in `ressources/`.

## VMA calculator

Each member enters their VMA (km/h). The value persists in `localStorage` under `drc_vma`. Eight percentage chips display the corresponding pace at 70 / 75 / 80 / 85 / 90 / 100 / 105 / 110 % VMA. The `annotateVMA(text, vma)` function parses session content at render time and injects inline badges:

- `400m à 100% VMA` → blue badge with the target time
- `3' à 90% VMA` → orange badge with the estimated distance

Regex patterns:

- Distance: `/(\d+)\s*m\s*à\s*(\d+)(?:\s*[-–]\s*(\d+))?\s*%\s*VMA/g`
- Timed block: `/(\d+)'\s*(?:à|allure)\s*(\d+)(?:\s*[-–]\s*(\d+))?\s*%\s*VMA/g`

Annotation is non-destructive — the raw session strings from the DB are never mutated.

## Adding a session

Sessions live in the Supabase `public.sessions` table. The normal path is the **`drc-publish-session` skill** in the parent DRC project, which runs after the Monday WhatsApp message is sent: it inserts the row via `supabase/scripts/insert_session.sh` and keeps a local `DRC/sessions.json` backup in sync. Row shape:

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

Session content is plain text — no HTML. For a one-off manual insert, run `supabase/scripts/insert_session.sh` (see its README) or edit the `sessions` table in Supabase Studio.

## Adding a race

Races live in the Supabase `public.races` table — edit it in Supabase Studio. Columns: `name`, `type`, `date` (NULL if approximate), `date_label` (shown when `date` is NULL), `url`, `pillar`, `confirmed`, `note`. Schema: `supabase/migrations/0001_init.sql`.

## Deployment

GitHub Pages redeploys automatically ~1 minute after each push to `main`. All code changes go through a feature branch + PR — never commit directly to `main` (see `CLAUDE.md`).

- **Weekly session updates** do *not* touch this repo or trigger a deploy: the `drc-publish-session` skill inserts the row into Supabase, and the live site picks it up on the next page load.
- **Layout / logic changes** go through the `implementer` subagent on a feature branch, then a PR.

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

- No custom server or self-hosted backend — Supabase (Postgres + Auth + Storage) is the only sanctioned backend layer.
- No npm / `node_modules` / build pipeline for the frontend.
- Keep the base64 logo inline (do not replace it with an external URL).
- Do not add SEO meta tags or remove `<meta name="robots" content="noindex, nofollow">`.
- Calendrier Courses must remain the default open tab.
- All member-facing text is in **French**.
- Never put the Supabase **secret** key in the repo or browser — only the publishable key is client-side.

## Data sources

External sources live in a separate Claude project (`DRC` workspace) and feed the site's content (now stored in Supabase):

| Data | Source → destination |
|---|---|
| Weekly sessions | `DRC/sports/whatsapp_history.md` + Google Sheets `DRC PROG H2 2026` → Supabase `public.sessions` via the `drc-publish-session` skill (local `DRC/sessions.json` kept as backup) |
| Race calendar | `DRC/events/calendrier_courses_2026-2027.md` → Supabase `public.races` (via Supabase Studio) |
| Weekend de Rentrée | `DRC/events/weekend_rentree_2026.md` |
| Logo | Google Drive — `06_Communication/Logos/Dérapage-logo-rond.png` (base64 in `index.html`) |
