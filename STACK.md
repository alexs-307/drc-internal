# STACK.md — How the DRC service works, end to end

> **Purpose.** This is the "how does our website actually work?" brief. `CLAUDE.md` and
> `README.md` tell you *what the rules are* and *how to make a change*. This file explains
> *the machinery underneath* — the pieces, what each one is, why we chose it, and how they
> connect — written for someone who can read code but has never had to *serve a website*
> before. If you inherit DRC, read this once and you'll understand the whole stack.
>
> Written in English (project default for internal docs). Member-facing copy stays French.

---

## 1. The 60-second mental model

DRC's "tech" is five separate services, each doing one job, glued together by a domain name
and some DNS records. None of them is a server we run or maintain.

```
                          a member opens derapage.xyz
                                      │
                                      ▼
        ┌─────────────────────────────────────────────────────────┐
        │  DNS (at OVH)  — "where does derapage.xyz point?"         │
        │  · the website  →  GitHub Pages servers                  │
        │  · sending email →  records that let Resend send as us   │
        └─────────────────────────────────────────────────────────┘
                                      │
                                      ▼
        ┌──────────────────┐   loads the page    ┌──────────────────┐
        │  GitHub Pages    │ ──────────────────▶ │  member's browser │
        │  (the host)      │   one index.html    │  runs the JS      │
        │  serves the file │                     └─────────┬────────┘
        └──────────────────┘                               │
                                       fetches data / signs in (HTTPS)
                                                            ▼
        ┌───────────────────────────────────────────────────────────┐
        │  Supabase  (our "backend")                                 │
        │  · Postgres DB: sessions, races, resources, members        │
        │  · Auth: passwordless magic-link sign-in                   │
        └────────────────────────────┬──────────────────────────────┘
                                      │ "email this magic link"
                                      ▼
        ┌───────────────────────────────────────────────────────────┐
        │  Resend  (email sender / SMTP)                             │
        │  delivers the magic-link email, sent from @derapage.xyz    │
        └───────────────────────────────────────────────────────────┘
```

The five pieces:

| Piece | What it is | What it does for us |
|---|---|---|
| **The website** | One `index.html` file (HTML + CSS + JS) | The whole UI the member sees |
| **GitHub Pages** | Free static-file hosting from GitHub | Puts that file on the internet |
| **OVH Cloud** | Domain registrar + DNS host | We *own* `derapage.xyz` here; DNS records live here |
| **Supabase** | Hosted Postgres database + Auth | Stores sessions/races/resources/members; handles member sign-in |
| **Resend** | Transactional email service (SMTP) | Sends the sign-in emails *as* `@derapage.xyz` |

**The big idea:** there is **no server of ours running anywhere.** We don't rent a machine,
we don't run Node/Express/Flask, we don't patch an OS. We ship one static file and lean on
managed services for the few dynamic things we need (a database and login). That's the whole
philosophy — and the reason the running cost is essentially €0 plus the domain.

---

## 2. What happens when a member opens the site

Walking through one real page load makes the pieces click together.

1. **Typing the address.** A member types `derapage.xyz` (or taps a saved link). The browser
   has no idea where that is yet — a domain name is just a label.
2. **DNS lookup.** The browser asks the global DNS system "what is `derapage.xyz`?" The answer
   comes from **our DNS zone at OVH**, which says: *"for the website, go to GitHub's servers."*
   (See §5 for what DNS is.)
3. **GitHub Pages serves the file.** The browser connects to GitHub Pages over HTTPS and
   downloads `index.html` — one ~230 KB file that contains the markup, all the CSS, all the
   JavaScript, and even the logo (base64-encoded inline). Nothing else is needed to render.
4. **The page runs.** The browser paints the UI immediately from that file. Then the inline
   JavaScript does two network things:
   - **Loads the Supabase JS SDK** from a CDN (`cdn.jsdelivr.net`).
   - **Fetches content from Supabase** — the `sessions`, `races`, and `resources` tables —
     and renders them into the tabs.
5. **Optional: signing in.** If the member uses the **Compte** tab, the page asks Supabase
   Auth to email them a magic link; Supabase hands that email to **Resend**, which delivers
   it from a `@derapage.xyz` address. Clicking the link brings them back signed in.

That's the entire system. Steps 1–4 are how *any* visitor sees content; step 5 is the only
"logged-in" part.

---

## 3. The website — one HTML file, no build step

**What it is.** A single `index.html`. The CSS lives in one `<style>` block, the JavaScript
in `<script>` tags, the logo is a base64 PNG baked into the HTML. The only things loaded from
outside are Google Fonts and the Supabase JS SDK, both from CDNs. There is **no build step**:
no npm, no bundler, no framework, no compile. What's in the file is exactly what ships.

**Why we chose it.**
- **A static site is the cheapest, most durable thing you can put online.** A plain HTML file
  has no server to crash, no dependencies to keep patched, no runtime to pay for. It will
  still work in ten years.
- **No build step = no rot.** Build tools (webpack, Vite, etc.) need maintenance: versions
  drift, lockfiles break, `node_modules` goes stale. By editing the final file directly, a
  future maintainer can open `index.html`, change a line, and ship — no toolchain to resurrect.
- **One file is easy to host.** Static hosts (like GitHub Pages) just serve files. One file
  means one thing to deploy and reason about.
- **It's enough.** DRC needs to *show* data (sessions, races, resources) and let ~45 members
  sign in. None of that requires a framework. Vanilla JS + `fetch()` to Supabase covers it.

**The trade-off** (so you know what we gave up): everything lives in one big file, so it's
long, and there's no component reuse or hot-reload niceties. For a site this size that's a
good deal. **Do not add a framework or build pipeline without a real reason** — that decision
is load-bearing for the whole "no maintenance" promise. (This is also a hard rule in `CLAUDE.md`.)

**Kept unlisted, not private.** The page carries `<meta name="robots" content="noindex,
nofollow">` so search engines skip it. That keeps it *unlisted*. It is **not** access-controlled
at this layer — anyone with the URL can load the file. Real access control, when we want it,
comes from Supabase (see §6). (Note: there is currently **no** `robots.txt` or `.nojekyll`
file in the repo, despite older notes mentioning them; the `noindex` meta tag is what's
actually doing the work today.)

---

## 4. GitHub Pages — the host (what "hosting" even means)

**What "hosting" means.** For a website to be reachable, the file has to sit on a computer
that is always on and connected to the internet, listening for browsers asking for it. That
computer is a *web server*; renting/using one is *hosting*. You could run your own, but then
you'd own the uptime, security patches, and bills.

**What GitHub Pages is.** GitHub Pages is GitHub's free static-hosting feature. You push files
to a Git repository; GitHub serves them on the web. That's it. No server for us to manage.

**How ours is wired.**
- Repository: **`alexs-307/drc-internal`** on GitHub.
- Pages serves the **`main` branch, root directory**. Whatever is on `main` is what's live.
- **Deploy is automatic:** push to `main` → GitHub rebuilds and the new version is live in
  about a minute. There is no separate "deploy" command.
- **HTTPS is automatic:** GitHub provisions a free TLS certificate (Let's Encrypt) for
  `derapage.xyz`, so the site is served over `https://`. ("Enforce HTTPS" is on in repo
  Settings → Pages.)
- **The `CNAME` file** in the repo root contains the single line `derapage.xyz`. This is how
  GitHub Pages knows our custom domain — it's the link between "this repo" and "this domain."
  Don't delete it, or the custom domain detaches.

**Why GitHub Pages.** Free, zero-maintenance, integrates with the Git workflow we already use
(every change is a branch + PR — see `CLAUDE.md`), and handles HTTPS for us. For a static
members' site it's the path of least resistance.

**The one rule that matters here:** `main` *is* production. Never commit straight to `main` —
every change goes through a feature branch and a PR so the live site stays stable and every
change is reviewable. (Full workflow in `CLAUDE.md`.)

---

## 5. The domain name & DNS — OVH

This is the part most people find fuzzy, so here it is from first principles.

### 5.1 What a domain name and a registrar are

`derapage.xyz` is a **domain name** — a human-friendly label. Domain names are leased, not
bought outright: you pay a yearly fee to a **registrar** to hold the rights to it. **Ours is
registered at OVH Cloud.** If that yearly renewal lapses, the domain can be lost — so the OVH
account and its billing are genuinely critical assets. Treat the OVH login like a key to the
building.

> **OVH ≠ our web host.** This trips people up. OVH is where we *own the name* and *manage DNS*.
> OVH does **not** serve our website — GitHub Pages does. We use OVH only for the domain and
> its DNS records. (OVH also sells servers and hosting; we don't use those parts.)

### 5.2 What DNS is

Computers don't talk in names, they talk in IP addresses (like `185.199.108.153`). **DNS
(Domain Name System) is the internet's phone book:** it translates `derapage.xyz` into the
address of the machine that should answer. When you change "where the domain points," you're
editing **DNS records** in the domain's **DNS zone**.

Our DNS zone is **managed at OVH** (OVH dashboard → the `derapage.xyz` zone). Each record is a
row that answers one kind of question. The ones that matter for us fall into two groups:

**Group A — records that make the website load** (point the domain at GitHub Pages):
- Because `derapage.xyz` is an *apex/root* domain (no `www.`), it uses **`A` records** (IPv4),
  and usually **`AAAA` records** (IPv6), pointing at **GitHub's published Pages IP addresses**.
- Together with the in-repo `CNAME` file (§4), these are what make typing `derapage.xyz` show
  our site. The exact IPs to use are whatever **GitHub's current Pages documentation** lists —
  don't hard-code values from memory; copy them from GitHub's docs, because they can change.

**Group B — records that let us send email as `@derapage.xyz`** (for Resend; see §7):
- A small set of **`TXT` records** (and possibly a `CNAME`/`MX` on a sending subdomain) that
  prove to the world that Resend is *allowed* to send mail on our behalf. These are
  **SPF / DKIM / DMARC** records. You don't write them by hand — **Resend's dashboard generates
  the exact records to paste into the OVH zone.**

> Note: Supabase is **not** in our DNS zone. The site talks to Supabase at its own address
> (`https://zglyzryhckxbwsivlotu.supabase.co`), which Supabase hosts. We don't manage DNS for it.

### 5.3 How to check DNS is correct

DNS changes aren't instant — they **propagate** across the internet over minutes to hours
(sometimes up to a day) because servers cache old answers for a "TTL" period. To verify what
the world currently sees, use **[dnschecker.org](https://dnschecker.org)**: enter
`derapage.xyz`, pick the record type (`A`, `TXT`, etc.), and it shows the answer from servers
around the globe. If the site "isn't pointing right" or "emails won't verify," this is the
first place to look — confirm the live records match what GitHub / Resend told you to set.

---

## 6. Supabase — the backend (database + auth)

**What a "backend" is.** The website (§3) is just files in a browser — it can't permanently
store anything or check who someone is. For that you need a **backend**: a database to hold
data, and an auth system to identify users. Instead of building and running our own server for
this, we use **Supabase**, a hosted service that gives us both, ready-made.

**What we use it for.**
- **Postgres database** (a real SQL database) with four tables:
  - `sessions` — the weekly track sessions (powers the Entrainement tab)
  - `races` — the season race calendar (powers the Calendrier tab)
  - `resources` — the club's PDF documents (powers the Ressources tab)
  - `members` — member records, created on first sign-in
  - The schema lives in version control under `supabase/migrations/` — that's the source of
    truth for the table shapes.
- **Auth** — passwordless **magic-link** sign-in. A member enters their email, gets a one-time
  link, clicks it, and they're signed in. No passwords to store or reset. (Full UX in
  `.claude/design-briefs/supabase-auth-signin.md`.)

**How the website talks to it.** `index.html` imports the Supabase JS SDK from a CDN and calls
Supabase directly from the browser (`supabase.from('sessions').select(...)`, `supabase.auth
.signInWithOtp(...)`). There is no middle layer.

**The two keys (and why one is safe in the browser).** Supabase gives every project two API
keys, handled very differently:
- The **publishable key** (`sb_publishable_…`) is *meant* to be public — it sits right in
  `index.html`. On its own it can only do what our security rules allow.
- The **secret key** (`sb_secret_…`) is an admin master key that ignores all security rules.
  It **never** goes in the browser or the repo — only in a local `.env` (mode 600), used by
  helper scripts like `supabase/scripts/insert_session.sh`.
- What makes the publishable key safe is **Row Level Security (RLS)**: database-side rules that
  say who can read/write what. Today reads are public (`USING (true)`); a members-only gate
  (reads restricted to signed-in members) is in progress. **Security lives in the database via
  RLS, never in browser JS** — a client-side check on a static page is trivially bypassed.
  (Full key handling and the "if a key leaks, rotate it" procedure are in `CLAUDE.md` →
  *Secrets & Supabase keys*.)

**Why Supabase.** It replaces a whole custom server (API + database + login) with one managed
service that the browser can call directly. It has a generous free tier, the data model is
plain Postgres (portable, not proprietary), and it keeps us inside the "nothing of ours to run
or maintain" philosophy.

**Where you administer it.** The **Supabase dashboard** (a.k.a. Supabase Studio) is the web
control panel — log in there to browse/edit table rows, manage auth users (invite members),
run migrations, and configure the SMTP settings that point at Resend.

---

## 7. Resend — sending email as the club

**The problem it solves.** Magic-link sign-in (§6) only works if the email actually lands in
the member's inbox. Supabase has a built-in mailer, but it's heavily rate-limited (a handful of
emails per hour) and sends from a generic address with mediocre deliverability. For inviting
and signing in ~45 members, that's not enough.

**What Resend is.** Resend is a **transactional email service** — an **SMTP** provider. SMTP is
the standard protocol for *sending* email. We point Supabase's "custom SMTP" setting at Resend,
so every auth email (invites, magic links) is dispatched through Resend and arrives **from a
`@derapage.xyz` address**, reliably and without the tight rate limit.

**Important — Resend is send-only.** It is **not a mailbox.** There is no `contact@derapage.xyz`
inbox a member could write *to*; Resend only *sends* the automated auth emails. If the club ever
wants a real, readable inbox, that's a separate service (e.g. a mail-hosting product) — Resend
won't provide it.

**Why it needs DNS records.** To stop spammers from forging "from `@derapage.xyz`" addresses,
mail providers check DNS for proof that the sender is authorized. So Resend asks us to add a few
records to the OVH zone — **SPF, DKIM, DMARC** (§5.2, Group B). Once those verify, mail from
Resend is trusted as genuinely from us. Resend's dashboard generates the exact records; you
paste them into OVH and confirm with dnschecker.org.

**Why Resend.** Free tier (thousands of emails/month — far more than 45 members need), simple
domain verification, and it plugs straight into Supabase's SMTP settings. It upgrades email
deliverability without adding anything for us to run.

---

## 8. How the pieces connect — three flows

Concrete request paths, so the glue is obvious.

**Flow A — viewing content (any visitor):**
```
browser → DNS(OVH) resolves derapage.xyz → GitHub Pages serves index.html
        → page JS fetches sessions/races/resources from Supabase (publishable key, RLS-gated)
        → tabs render
```

**Flow B — signing in (a member):**
```
member enters email in Compte tab → page calls Supabase Auth (signInWithOtp)
        → Supabase hands the email to Resend (SMTP) → Resend delivers it from @derapage.xyz
        → member clicks the link → returns to derapage.xyz signed in
        → (first time only) fills name/birthdate → saved to the members table
```

**Flow C — publishing a weekly session (the Monday workflow):**
```
Monday message confirmed sent → drc-publish-session skill runs
        → supabase/scripts/insert_session.sh inserts a row into public.sessions (uses the secret key, locally)
        → live site shows it on the next page load (no deploy, no repo change)
```
Note Flow C does **not** touch GitHub Pages: session data lives in Supabase, so adding one is a
database write, not a website change. Only *layout/logic* changes go through the GitHub
branch → PR → deploy path.

---

## 9. Who controls what — the accounts that matter

If you inherit DRC, these are the logins that *are* the infrastructure. Losing access to any of
them is a real problem; guard the credentials accordingly.

| Service | What it controls | Where you manage it | If access is lost… |
|---|---|---|---|
| **GitHub** (`alexs-307/drc-internal`) | The website code + hosting | github.com repo Settings → Pages | Can't deploy changes; site keeps running on last-deployed version |
| **OVH Cloud** | The domain `derapage.xyz` + DNS zone | OVH dashboard | Domain could lapse/expire; site & email break — **most critical** |
| **Supabase** | Database + member auth | Supabase dashboard (Studio) | Site shows no data; nobody can sign in |
| **Resend** | Sending auth emails | Resend dashboard | Magic-link emails stop arriving; existing sessions still valid |

**Dependency chain to keep in mind:** the **domain (OVH)** is the linchpin — it points to both
the website (GitHub) and authorizes email (Resend). If the domain lapses, everything visible to
members breaks at once. Renew it on time.

---

## 10. Why this stack, in one paragraph

DRC is a ~45-member club, not a startup. The guiding choice was **maximize what we get for zero
ongoing maintenance and ~zero cost.** A static HTML file on GitHub Pages gives a fast, durable,
free website with nothing to patch. Supabase gives a real database and real login without us
running a server. Resend gives reliable branded email without a mail server. The only recurring
cost and the only thing that can "expire" is the domain at OVH. Every piece is a managed service
the browser talks to directly, glued together by DNS — which is exactly why the whole thing
keeps running with almost no attention.

---

## 11. Mini-glossary

- **Static site** — a website made of fixed files (HTML/CSS/JS) served as-is, with no server
  generating pages per request.
- **Host / hosting** — the always-on computer that serves your files to browsers. Ours is
  GitHub Pages.
- **Domain / registrar** — `derapage.xyz` is the domain; the registrar (OVH) is who you lease
  it from yearly.
- **DNS / DNS zone / DNS record** — the system that maps a domain to the servers behind it. The
  "zone" is the set of records for one domain; each record answers one question (`A` = which
  IPv4, `TXT` = text proofs like SPF/DKIM/DMARC, etc.). Ours is at OVH.
- **Propagation / TTL** — DNS changes take time to spread because old answers are cached for a
  "time to live." Check current state with dnschecker.org.
- **HTTPS / TLS certificate** — encryption for the connection; the padlock. GitHub Pages issues
  ours automatically.
- **Backend** — the server-side part that stores data and checks identity. Ours is Supabase
  (we don't run it).
- **Postgres** — the SQL database engine Supabase uses.
- **Auth / magic link** — signing in by clicking a one-time emailed link instead of a password.
- **RLS (Row Level Security)** — database rules deciding who can read/write which rows; our real
  access control.
- **Publishable vs secret key** — public browser-safe Supabase key vs. private admin key (local
  only, never shipped).
- **SMTP** — the protocol for *sending* email. Resend is our SMTP provider.
- **SPF / DKIM / DMARC** — DNS records proving an email sender is authorized to send as our
  domain; how we stop forgery and land in inboxes.
- **CDN** — a network that serves common files (here: Google Fonts, the Supabase SDK) quickly
  from servers near the user.

---

*See also: `CLAUDE.md` (operating rules + how to make changes), `README.md` (quick stack
summary), `supabase/migrations/` (database schema), `.claude/design-briefs/` (per-feature specs).*
