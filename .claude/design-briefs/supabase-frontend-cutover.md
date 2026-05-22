# Supabase frontend cutover (PR 3) — implementer brief

## Goal

Replace the three static data sources in `index.html` with Supabase reads. After this PR, the site behaves visually identical to today but reads its data from Postgres instead of `sessions.json`, the inline `races[]` array, and the hardcoded resource cards.

**Out of scope:** auth (sign-in / sign-out / signed-in state — deferred to PR 4). RLS public-read policies on `sessions`, `races`, `resources` let anonymous visitors read everything, so the site needs zero auth to render.

This is PR 3 of the Supabase migration (Option C path, `website_audit/audit_dynamic_website_migration.md`). PR 1 shipped the schema; PR 2 seeded the data; this PR is the frontend cutover.

## Stack constraint

**No build pipeline, no bundler, no npm.** Per `CLAUDE.md`: vanilla JS, single `index.html`, deployed on GitHub Pages. Add Supabase via CDN ESM import — same pattern as Google Fonts is loaded today.

Recommended import (in a `<script type="module">` block):

```html
<script type="module">
  import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

  const SUPABASE_URL = 'https://zglyzryhckxbwsivlotu.supabase.co';
  const SUPABASE_PUBLISHABLE_KEY = '<<EM_WILL_INJECT_PUBLISHABLE_KEY_HERE>>';

  const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
  window.supabase = supabase;  // expose for the existing non-module code blocks
</script>
```

Leave the placeholder `<<EM_WILL_INJECT_PUBLISHABLE_KEY_HERE>>` in the committed file — the EM will replace it with the real key in a follow-up commit on the same branch before pushing.

## Files to modify

### `index.html`

1. **Add the Supabase client init `<script type="module">`** in the `<head>` (or right before the existing inline `<script>` block). Export the client to `window.supabase` so the existing non-module IIFE-style code below can call it.

2. **Delete the `races[]` JS array literal** (around line 1650, ~100 lines).

3. **Delete the `cleanName()` function** (lines 1751–1753). Data is already clean in the DB — emojis stripped at seed time.

4. **Rewrite `renderRaces()`** (around line 1755) to be `async` and fetch from Supabase:
   ```js
   async function renderRaces() {
     const { data: races, error } = await supabase
       .from('races')
       .select('*')
       .order('date', { ascending: true, nullsFirst: false });
     if (error) {
       /* show error in the race list container, see Error handling below */
       return;
     }
     // ... existing render logic, adapted for the new column names
   }
   ```

   Schema mapping (today's JS object → DB row):
   - `r.dateStr` → `r.date` (now a `string` like `'2026-12-06'` or `null` for approximate races)
   - `r.format` → `r.type`
   - `r.approxText` → `r.date_label` (only set when `r.date` is `null`)
   - `r.approx` → derive: `const isApprox = r.date === null;`
   - `r.dateDisplay` / `r.monthDisplay` / `r.yearDisplay` → derive on the fly from `r.date` (use `new Date(r.date)` and format in JS — `dateDisplay = String(d.getUTCDate()).padStart(2, '0')`, `monthDisplay = ['Jan','Fév','Mars','Avr','Mai','Juin','Juil','Août','Sep','Oct','Nov','Déc'][d.getUTCMonth()]`, `yearDisplay = d.getUTCFullYear()`)
   - `r.name` → `r.name` (no `cleanName()` call needed)
   - `r.note` / `r.pillar` / `r.confirmed` → unchanged

5. **Adapt the countdown logic.** Today the `nextRace` calculation uses `new Date(r.dateStr)` and assumes every race has a date. With the new schema, **approximate races (date IS NULL) must be skipped from the countdown** — they appear in the list but can't be the "next race". Filter them out before scanning:
   ```js
   const concreteRaces = races.filter(r => r.date !== null);
   for (const r of concreteRaces) { ... }
   ```

6. **Rewrite the `sessions.json` fetch** (around line 1828–1843) to read from Supabase:
   ```js
   async function loadSessions() {
     const { data: sessions, error } = await supabase
       .from('sessions')
       .select('*')
       .order('date', { ascending: false });
     if (error) { /* error state */ return; }
     const saved = localStorage.getItem('drc_vma');
     // ... rest of the existing flow (set VMA input, call renderSessions)
   }
   loadSessions();
   ```

7. **Convert resource cards to JS-rendered** (lines 1555–1593 in the `#tab-resources` section). The container `<div class="resource-list">` (line 1555) already exists. Replace the two real `<div class="resource-card">` blocks (lines 1557 and 1569) with a JS render loop that pulls from `supabase.from('resources').select('*').order('display_order')`. **Keep the placeholder `is-placeholder` card (line 1581) hardcoded** — it's a UI hint, not data, and the user explicitly chose to keep it visible. The hardcoded placeholder stays after the JS-rendered cards (i.e. the container ends with: dynamic cards + the static placeholder).

8. **Delete `sessions.json`** at the repo root. The DB is now the source of truth.

### `sessions.json`

Delete the file. (`git rm sessions.json`)

## Render logic — race date display

Today's race card shows day + month + year as three separate visual elements (`dateDisplay`, `monthDisplay`, `yearDisplay`). For concrete races (`date !== null`), derive these from `r.date`. For approximate races (`date === null`), show `r.date_label` as a single-line label in place of the day+month+year stack — preserve the existing visual distinction.

The pillar styling (`r.pillar === true`) and confirmation styling (`r.confirmed === false`) already work off the column values; no change needed.

## Error handling

If a Supabase call returns an error (network failure, RLS denial, etc.), show a discreet inline message in French in the affected tab's container:

- Race list: `<p class="data-error">Calendrier indisponible. Réessayez dans un instant.</p>`
- Sessions list: `<p class="data-error">Séances indisponibles. Réessayez dans un instant.</p>`
- Resources list: `<p class="data-error">Ressources indisponibles. Réessayez dans un instant.</p>`

Add a single CSS rule for `.data-error` near the bottom of the existing `<style>` block (subtle, not alarming — muted grey text on the existing card background, no red, no icons; this is a 45-member club site, not a production dashboard). The brand has no precedent for error states yet, so the implementer picks a sensible muted styling and the reviewer flags if it clashes.

## Loading state

Don't add spinners or skeletons. The DB calls return in <200ms over a normal connection. The tab containers can briefly show empty, then populate when the data arrives. If a loading indicator is genuinely useful (e.g. the user opens the Calendrier tab before the network call returns), use a simple `<p class="data-loading">Chargement…</p>` placeholder that gets replaced when data arrives. Same muted styling as `.data-error`.

## VMA — unchanged

VMA stays in `localStorage` under key `drc_vma`. PR 1 schema deliberately omitted it from `members` for exactly this reason — VMA is per-browser, per-device. No change to this code.

## Acceptance criteria

- [ ] `<script type="module">` block imports Supabase JS SDK from the jsdelivr CDN ESM bundle and exports the client to `window.supabase`
- [ ] `sessions.json` is deleted
- [ ] `races[]` JS array literal is deleted
- [ ] `cleanName()` function is deleted
- [ ] Hardcoded resource cards for the two real PDFs (lines 1557, 1569) are deleted
- [ ] Placeholder `is-placeholder` resource card (line 1581) is KEPT as hardcoded HTML
- [ ] `renderRaces()` is async and reads from `supabase.from('races')`
- [ ] `renderSessions()` is unchanged in shape; its caller now reads from `supabase.from('sessions')`
- [ ] Resources are JS-rendered from `supabase.from('resources').select('*').order('display_order')`
- [ ] Approximate races (`date IS NULL`) are excluded from countdown but included in the race list
- [ ] Error states are rendered as muted inline messages in French
- [ ] The publishable key in the source is the literal placeholder `<<EM_WILL_INJECT_PUBLISHABLE_KEY_HERE>>` (the EM will substitute the real value before pushing)
- [ ] No new external dependencies beyond the CDN import (no npm, no node_modules)
- [ ] No regression in any existing functionality: VMA chip rendering, the annotation badges on session content, the search bar filter, tab switching, the countdown banner format

## Out of scope (later PRs)

- Magic-link sign-in UI / sign-out / signed-in state (PR 4)
- Admin UI for editing sessions/races (PR 5+)
- Real-time subscriptions (`supabase.channel(...)`) — defer until there's a use case
- Migrating VMA to the user record (deliberately out of scope per PR 1 schema brief)
- Removing the placeholder resource card

## Branch

The EM will name the branch at invocation time.
