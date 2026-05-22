# CLAUDE.md — DRC Internal Website

> Context file for Claude Code. Read this before making any change to the site.

---

## Project overview

Static website for **Dérapage Running Club (DRC)**, a Paris-based FFA-affiliated running club (~45 members), founded June 2025. It is intended primarily for club members (training sessions, race calendar, internal resources), but it is technically publicly reachable — it is deployed on GitHub Pages at `https://<username>.github.io/drc-internal/` with no access control. Content is non-sensitive; the site is unlisted (`robots.txt` blocks crawlers, `<meta name="robots" content="noindex, nofollow">`) but not private.

**Owner / main contact:** Alexandre Saillard (sports director)
**Instagram:** [@derapagerunningclub](https://www.instagram.com/derapagerunningclub/)

---

## EM Orchestrator — how Claude operates in this repo

Every Claude Code session in this repo runs as an **Engineering Manager (EM)**. The EM scopes work, coordinates subagents, audits infrastructure, and decides when to push or open a PR. The EM **never writes production code directly** — not even a one-line fix.

### Hard rules

- **Never edit `index.html` or `admin.html` directly.** All layout, CSS, and browser-side JS changes go through the `implementer` subagent.
- **Never write CSS, JS, or HTML — not in chat, not in a file.** Describe the problem; the implementer translates it into code.
- **Never write SQL, RLS policies, or migration scripts directly.** Those go through the `backend` subagent.
- **Never commit or push code changes yourself.** The worker (implementer or backend) commits; the EM reviews the diff, then pushes.
- **Never open a PR without the reviewer's `LGTM`** (or an explicit user override).
- **`sessions.json` is the only data file the EM may edit directly** — weekly session data entries are mechanical and contain no logic. Any structural change to the schema goes through the implementer (for the JSON) or the backend agent (for Supabase tables).

### What the EM owns

- Reading and auditing `CLAUDE.md`, `.claude/agents/*.md`, `.claude/design-briefs/*.md`
- Editing infrastructure files: `CLAUDE.md`, agent definitions, design briefs
- Creating feature branches and naming them per convention (`feat/<slug>`, `fix/<slug>`, `chore/<slug>`)
- Scoping tasks and writing prompts for subagents — including the brief path and the branch name
- Reviewing subagent handoffs: reading diffs, checking acceptance criteria, routing punch lists
- Pushing approved branches and opening PRs (with user confirmation)
- Mechanical `sessions.json` updates (weekly session data, no schema changes)
- **Infrastructure audits and migration scoping** — when a large architectural change is being considered (e.g. moving from a static single-file site to a dynamic stack, extracting `races[]` into `races.json`, introducing a build pipeline), the EM reads the current codebase in full, maps every dependency and coupling that would be affected, estimates the work surface, identifies risks, and produces a structured gap analysis: current state → desired state → what changes, in what order, at what cost. This is a research and planning output delivered in chat — no code is written during an audit. The EM presents the findings to the user before any implementation is agreed.

### Infrastructure audit format

When asked to scope a large change, produce a report with these sections:
1. **Current state** — what exists today and how it is structured (data sources, render path, deploy model, dependencies)
2. **Desired state** — what the target architecture looks like
3. **Gap analysis** — a table or list of everything that would need to change: files, patterns, external services, workflow
4. **Risk and complexity** — what is hardest, what is most likely to break, what can't be easily reversed
5. **Recommended sequence** — an ordered list of steps, each scoped small enough to be a single PR
6. **Out of scope** — what the audit explicitly does not cover

### Agent roster

| Agent | Invoke when |
|---|---|
| `designer` | Visual direction is unclear or needs external research before the implementer can act. Covers both public site and admin UI (utilitarian where the public site is editorial). Skip for mechanical or obviously-scoped changes. |
| `implementer` | Any change to `index.html`, `sessions.json`, or any browser-side JS (including Supabase JS SDK calls). Also `admin.html` if/when that file is ever built — none today. Always supply the branch name and brief path. |
| `backend` | Any change under `supabase/migrations/`, `scripts/`, or anything related to Postgres schema, RLS policies, or server-side data plumbing. Always supply the branch name and the relevant audit/brief. |
| `reviewer` | After every implementer or backend commit, before pushing. Returns `LGTM` or a numbered punch list. Max 3 worker–reviewer rounds before escalating to the user. |

### Orchestration loop

1. **Scope** — define the task. Frontend, backend, or both? Is a design brief needed?
2. **Design** (if needed) → invoke `designer` → read and sanity-check the brief before proceeding.
3. **Backend first** (if a schema change is needed) → invoke `backend` with branch name + audit/brief path → read the resulting SQL diff.
4. **Implement** → invoke `implementer` with branch name + brief path → read the resulting diff.
5. **Review** → invoke `reviewer` → if `Needs changes`, re-invoke the responsible worker with the punch list.
6. **Ship** → push the branch, open PR with user confirmation.

---

## Tech stack & architecture

- **`index.html`** — all CSS, JS, and the base64-encoded logo are inline. No build step, no framework, no external dependencies except Google Fonts (Inter, CDN).
- **`sessions.json`** — session data for the Entrainement tab. Loaded via `fetch()` at runtime. Edit this file to add/update sessions without touching HTML.
- **Vanilla JS only** — no React, no Alpine, no jQuery.
- **Backend** — Supabase (Postgres + Auth + Storage) is being introduced in stages. As of today the live production site is still fully static: race data hardcoded in `races[]` inside `index.html`, session data in `sessions.json`, VMA in `localStorage`. The schema for Supabase lives at `supabase/migrations/0001_init.sql`; the frontend has not yet been wired to it. See *Secrets & Supabase keys* below for how keys are handled.
- **No access control on the static site** — the public site is open on GitHub Pages. A client-side password gate used to exist but was removed: on a static site any JS-based gate is trivially bypassable (view-source, disable JS, fetch the JSON directly), so it gave a false sense of privacy. Real access control comes from Supabase Auth + RLS at the data layer once member features are wired — not from JS in this repo.

Do not introduce a build system, a bundler, or a JS framework without explicit instruction.

---

## Secrets & Supabase keys

Supabase issues two long-lived API keys per project. They are handled very differently.

| Key | New name (format) | Old name | Where it lives | Bypasses RLS? |
|---|---|---|---|---|
| Publishable | `sb_publishable_...` | `anon` | Local `.env`; safe to inline in client HTML once the frontend is wired | No — RLS fully enforced |
| Secret | `sb_secret_...` | `service_role` | Local `.env` only — never repo, never browser, never CI logs | **Yes — full admin** |

**Publishable key.** A public token that tells Supabase the request is coming from a browser. All authorization happens via RLS policies on the database. Safe to commit into client HTML — the security model assumes any attacker has it. Without an authenticated user session, it can only do what `USING (true)` policies allow.

**Secret key.** Equivalent to a Postgres superuser. Holding it = full read/write/delete on every table, RLS ignored. Required only by server-side scripts (e.g. a one-off bulk-load script under `scripts/`). Never goes in browser code. Never gets committed. Scripts read it via `process.env.SUPABASE_SECRET_KEY` (or equivalent) at runtime, pulled from a local `.env` or password manager.

**`.env.example`** lists `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` only. The secret key is deliberately omitted from `.env.example` to avoid the "fill in real value → forget → commit" failure mode. When a script under `scripts/` first needs it, that script's README explains how to set it locally.

**`.env`** is gitignored. Always.

**If a key ever leaks** (screenshot, public repo, CI log): rotate it immediately in the Supabase dashboard. This invalidates every place it was used, so check `scripts/` and `index.html` for hardcoded references afterward.

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

## Site structure — 4 tabs

Tab order in the nav: **Instagram · Calendrier Courses · Entrainement · Ressources**. Default tab on load is **Calendrier Courses**.

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

### Tab 4 — Ressources
- List of internal PDF documents the club shares with members (e.g. *VMA & Seuil*, *Renfo du coureur & mobilité*).
- Each resource is rendered as a card with: title, short description, an **Ouvrir** icon button (opens the PDF in a new tab) and a **Télécharger** icon button (downloads it). The PDF itself is embedded inline via an `<iframe>` below the header.
- Resource cards are hardcoded in `index.html` inside `#tab-resources` — there is no JSON data file for resources (yet).
- PDF files live in the `ressources/` folder at the repo root (e.g. `ressources/vma_seuil.pdf`).

**To add a new resource:** drop the PDF into `ressources/`, then duplicate an existing `<div class="resource-card">` block in `#tab-resources` and update the title, description, and the two `href` attributes (open + download) plus the `<iframe src>`.

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

## Git workflow — feature branches only

**Never commit directly to `main`.** Every change — even a one-line tweak or a weekly session update — goes through a feature branch and a pull request.

Why: `main` is what GitHub Pages deploys. Working on a branch keeps the live site stable, gives a chance to preview the diff before it ships, and leaves a clean history of every change as a PR.

Workflow:
```bash
# Start from an up-to-date main
git checkout main
git pull origin main

# Create a feature branch — name it after the change
git checkout -b session-2026-05-18         # weekly session update
git checkout -b fix-vma-regex              # bugfix
git checkout -b add-race-marathon-nantes   # content change

# Commit and push the branch
git add <files>
git commit -m "describe the change"
git push -u origin <branch-name>

# Open a PR on GitHub, review the diff, then merge into main
gh pr create --fill
```

Only after the PR is merged does the change reach the live site.

**PRs must be reviewed by a human (Alexandre) before merging.** Never self-merge a PR, even for trivial changes. Open the PR, leave it for review, and wait for explicit approval before running `gh pr merge`.

**All commit messages, PR titles, PR descriptions, code identifiers, and code comments must be written in English.** Member-facing UI text in `index.html` remains in French (that rule is unchanged) — this English-only rule applies to everything else: branch names, commit subjects/bodies, PR content, variable/function names, and inline code comments.

---

## Deployment

- Hosted on GitHub Pages, `main` branch, root directory.
- `.nojekyll` file at root prevents Jekyll processing.
- `robots.txt` at root blocks all crawlers.

All changes go through a feature branch + PR (see *Git workflow* above). Once the PR is merged into `main`, GitHub Pages redeploys automatically in ~1 minute.

**Trigger for weekly session updates:** every time Alexandre confirms the Monday WhatsApp message has been sent (see workflow in `../system_prompt.md`), the matching entry must also be prepended to `sessions.json` here. Same PR rule applies — branch, commit, push, open PR, wait for Alexandre's approval before merging.

**To add a session (weekly update):**
```bash
git checkout main && git pull origin main
git checkout -b session-YYYY-MM-DD
# Edit sessions.json — prepend new entry at top of array
git add sessions.json
git commit -m "séance du DD/MM/YYYY"
git push -u origin session-YYYY-MM-DD
gh pr create --fill   # then merge on GitHub
```

**To update the site layout or logic:**
Do not edit `index.html` directly. Follow the orchestration loop: scope the task, invoke the `implementer` subagent on a feature branch, run the `reviewer`, then push. See *EM Orchestrator* section above.

---

## What NOT to do

- Do not introduce a custom server (Express, Fastify, Flask, etc.) you have to run and maintain. Supabase (Postgres + Auth + Storage) is the only sanctioned backend layer — see *Tech stack & architecture* and *Secrets & Supabase keys* above.
- Do not introduce npm / node_modules / a build pipeline for the frontend. (A `scripts/` folder with its own tooling is acceptable for backend one-off migrations — that's the backend agent's lane.)
- Do not create `admin.html` without explicit instruction. Admin-only data editing (sessions, races, resources) currently happens in **Supabase Studio** — the table editor in the project's Supabase dashboard. The agent definitions still reference `admin.html` as forward-looking guardrails for if/when one is built; today it does not exist.
- Do not remove the base64 logo or replace it with an external URL (site must work offline / file://).
- Do not commit directly to `main` — always go through a feature branch + PR (see *Git workflow*).
- Do not re-add a client-side password gate — it offers no real protection on a static site (see *No access control* under *Tech stack*).
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
