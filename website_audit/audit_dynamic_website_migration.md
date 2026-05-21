# Audit — Migration from static to dynamic website

> Architecture audit. Research output, no code written.
> Produced by the EM orchestrator. See `CLAUDE.md` → *Infrastructure audit format*.

---

## 1. Current state

- **Architecture**: single `index.html` (2058 lines, inline CSS + inline JS + base64 logo) + `sessions.json` + `ressources/` PDFs + `photos_saison_01/` images. No build, no framework, no bundler. Google Fonts is the only external runtime dependency.
- **Data**: `races[]` is a JS array literal inside `index.html` (line 1650). `sessions.json` is fetched at runtime. PDFs and photos are served as static files.
- **State**: `localStorage` key `drc_vma` is the only persistent state — per-browser, not per-user, no cross-device sync.
- **Auth**: none. The "no access control" decision was made deliberately (a JS gate on a static site is fictional security).
- **Deploy**: GitHub Pages, root of `main`, automatic on push. ~60s deploy. Free.
- **Edit workflow**: every content change is a Git PR. Weekly session entries are mechanical JSON edits. Race calendar is hardcoded JS — every race addition needs a code PR.

## 2. Desired state (three plausible directions)

### Option A — Full dynamic stack (production-grade)
Next.js 15 (App Router) + Supabase (Postgres + Auth + Storage) + Vercel. Member auth, admin dashboard, per-user state, real privacy, content editable via web UI.

### Option B — Static + headless CMS (lowest learning curve)
Astro or Next.js + Sanity/Strapi for editorial content. Site still mostly static-rendered. Content editable by non-devs. No auth unless added separately.

### Option C — Backend-as-a-service, keep vanilla JS (smallest blast radius)
Add Supabase as a runtime dependency. Sessions/races become Supabase tables. Auth via Supabase magic links. Site stays a single `index.html` deployed on GitHub Pages — Supabase calls happen client-side. No build pipeline.

## 3. What gets unlocked vs today

| Capability | Today | Dynamic |
|---|---|---|
| Real privacy on member-only content | ❌ JS gate is bypassable | ✅ Real auth gate at the data layer |
| Per-member state across devices (VMA, race history, attendance) | ❌ localStorage only | ✅ Synced to user record |
| Admin UI to edit sessions/races without Git | ❌ Every update is a PR | ✅ Web form, instant publish |
| Race RSVPs / attendance tracking | ❌ | ✅ |
| Member-uploaded photos | ❌ | ✅ |
| Comments / feed / notifications | ❌ | ✅ |
| Real-time updates (live race results, push) | ❌ | ✅ |
| Search across multiple seasons | Limited (single-tab JS filter) | ✅ Full-text / filtered queries |
| Per-member pace targets in session display | ❌ (one global VMA) | ✅ Pulls each member's VMA when they log in |
| Multi-user editing without Git conflicts | ❌ | ✅ |

The two highest-value unlocks for a 45-member club are likely **(1) killing the weekly PR overhead** (Alexandre edits in a web form, not via Git) and **(2) real per-member state** (each runner sees their own paces, their own race calendar, their own VMA history). Everything else is gravy.

## 4. Gap analysis — Option A (Next.js + Supabase, the production path)

| Area | Current | Target | Change |
|---|---|---|---|
| Hosting | GitHub Pages | Vercel | New project + DNS cutover |
| Build | None | Next.js build pipeline | `package.json`, `npm`, `node_modules`, CI |
| Markup | `index.html` HTML | React/JSX components | Every tab becomes a page; ~2000 lines rewritten as components |
| Styling | Inline CSS w/ custom properties | CSS Modules (preserves tokens cleanly) or Tailwind (faster shipping) | Migrate token system; keep `--blue`, `--bone`, etc. as theme vars |
| Data — races | JS array literal | Postgres `races` table | Schema + migration + admin UI to edit |
| Data — sessions | `sessions.json` | Postgres `sessions` table | Schema + migration + admin UI |
| Data — resources | Hardcoded cards | Postgres `resources` table + Supabase Storage for PDFs | Schema + migration |
| Auth | None | Supabase Auth (magic link) | Login page, profile page, RLS policies |
| State (VMA) | `localStorage` | User record column | Migrate on first login |
| Deploy | Auto on push to `main` | Vercel preview deploys per PR + prod on merge | New CI flow |
| Type safety | None | TypeScript end-to-end | `tsconfig.json`, types for all data |
| Agents | designer / implementer / reviewer | Same trio + maybe a `migration` agent | Update CLAUDE.md to reflect new stack |

## 5. Risk and complexity

- **Loss of single-file simplicity.** Currently anyone can clone, open `index.html` in a browser, and see the site. Post-migration: `npm install`, `npm run dev`, port 3000. That's a real DX cost for a club where the maintainer values being able to edit in GitHub's web UI.
- **Vendor concentration.** Supabase + Vercel are both well-funded and Postgres is portable, but it's still two new vendor dependencies. Mitigation: Supabase data exports cleanly to any Postgres host.
- **Auth complexity.** RLS policies are the #1 source of footguns. A misconfigured policy can leak data across members or lock out the admin. Worth a separate review pass.
- **Cost creep.** Free tiers cover 45 members easily. Vercel free: 100GB bandwidth/mo. Supabase free: 500MB DB, 1GB storage, 50K auth users. Realistically you won't pay. But pricing tiers can change.
- **Migration is hard to reverse.** Once content lives in Postgres, going back to static means exporting + re-templating. Pick a stable content moment.
- **The hardest part isn't code.** It's the data-model decisions (race schema, session schema, member schema) — those should be designed before implementation begins.

## 6. Recommended sequence

If Option A is chosen, ship in independent PRs (Vercel preview deploys each one):

1. **PR 1 — scaffolding.** New Next.js + TypeScript + Supabase project, empty home page, deploy pipeline, Supabase project provisioned. Static site still lives at the current URL.
2. **PR 2 — auth.** Magic-link login, profile page, RLS skeleton.
3. **PR 3 — migrate `races[]`.** Postgres table, Calendrier page reads from it. Admin route (auth-gated) to CRUD races.
4. **PR 4 — migrate `sessions.json`.** Same pattern. VMA persisted to member record. Admin UI for weekly session entries.
5. **PR 5 — migrate Ressources + Saison 01.** PDFs into Supabase Storage. Photos either stay as Vercel static assets or move to Storage.
6. **PR 6 — member features (post-migration polish).** RSVPs, attendance, comments — whichever lands first on the value curve.
7. **PR 7 — DNS cutover, archive static repo.**

**Recommendation, given DRC's actual constraints** (45 members, one part-time maintainer, content stability still emerging): start with **Option C** — Supabase added as a runtime dependency to the existing `index.html`. This kills the weekly-PR overhead and adds real auth, with zero build pipeline and zero rewrite. If after 6 months the club wants member dashboards / RSVPs / per-member views, then graduate to Option A. Option B is the wrong shape (it solves editor UX but not auth or per-member state, which are the two real wins).

**Recommended stack if/when you go to Option A:** TypeScript + Next.js 15 (App Router) + Supabase + Tailwind (because the design tokens are simple and Tailwind speeds component work) + Vercel. Not React Router, not Remix, not Astro — Next.js is the conservative default and has the strongest Supabase integration story.

## 7. Out of scope for this audit

- Mobile app (native or PWA)
- Strava / Garmin integrations
- Payment (race signup fees)
- Email/SMS notification pipeline
- Internationalization (the site stays French)
- Analytics + cookie consent (separate audit)

**Effort estimate**:
- Option C (Supabase + keep vanilla JS): 20-30 implementer hours
- Option A (full Next.js + Supabase): 60-100 implementer hours, spread over 6-8 PRs
