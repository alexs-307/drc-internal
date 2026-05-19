# Handover front-end · derapage.xyz V2

> **À l'attention du dev front.** Pas de framework, pas de build step, vanilla HTML/CSS/JS, hébergement GitHub Pages.
> **Direction validée :** Crew Culture Street (réf. Bridge Runners, Track Mafia, Patta Running Team).
> **Statut :** spec complète, prêt à implémenter.
> **Contact projet :** Alexandre Saillard.

---

## 1. Contexte en 30 secondes

Site interne du **Dérapage Running Club (DRC)** — club parisien FFA, ~45 membres, première saison 2025-2026. Le site sert aux membres pour : (1) voir la prochaine course, (2) consulter l'historique des séances, (3) télécharger les ressources d'entraînement, (4) revoir les moments de la saison 1. **Audience principale : les membres eux-mêmes**, sur mobile en majorité (mardi soir avant la séance).

La V1 actuelle est fonctionnelle mais visuellement neutre. Cette refonte applique une identité forte basée sur la palette du t-shirt club (crème + bleu électrique), une typographie d'inspiration *running années 2000*, et une exploitation des photos de la première saison.

---

## 2. Stack & contraintes

| Item | Décision |
| --- | --- |
| Stack | HTML + CSS + JS vanilla |
| Build | Aucun (pas de bundler, pas de framework) |
| Hosting | GitHub Pages |
| Polices | Google Fonts via `<link>` |
| Pictos | SVG inline (4 fournis, prêts à coller, section 8) |
| JS | Minimal — uniquement pour : VMA persistence (existant à conserver), filtres entraînement, accordéon séances |
| Images | JPEG quality 80, format natif, dans `/photos_saison_01/` (sera fourni par Alex) |
| Compatibilité | Safari iOS 14+, Chrome Android, navigateurs modernes desktop |

**Ne pas introduire :** React, Vue, Tailwind compiled, webpack, npm. Si une question se pose, retomber sur du vanilla.

---

## 3. Plan de fichiers

Structure recommandée (à adapter selon ce qui existe déjà dans le repo) :

```
/index.html                       # tabbed SPA — toutes les sections dans le même fichier
/style.css                        # tokens + composants + media queries
/script.js                        # tab switching, VMA persistence, filtres
/photos_saison_01/                # fourni par Alex (8 photos)
  ├── 01-hero.jpg
  ├── 02-decouverte-club.jpg
  └── ...
/ressources/                      # PDFs existants
  ├── vma-seuil.pdf
  └── renfo-mobilite.pdf
/ressources/previews/             # à générer
  ├── vma-seuil-preview.jpg
  └── renfo-mobilite-preview.jpg
```

Le site reste **single-page** (4 onglets dans le même `index.html`, basculement via JS et `display: none/block` sur les `<section>`).

---

## 4. Ordre d'implémentation recommandé

Découpé en 3 phases pour pouvoir shipper de l'avancement progressivement.

### Phase 1 — Fondations (1 demi-journée)
1. Coller le bloc CSS `:root` (section 5).
2. Ajouter le `<link>` Google Fonts dans `<head>`.
3. Refondre le **header** (wordmark Anton).
4. Refondre la **navigation** (4 pictos SVG, soulignement actif).
5. Refondre le **footer** (laisser tel quel actuellement — juste vérifier que la nouvelle typo s'applique).

À ce stade, l'identité visuelle globale du site bascule. Les sections internes héritent partiellement.

### Phase 2 — Sections de contenu (1 journée)
6. Refondre la page **Calendrier** : hero gradient, cartes course avec date-block Anton.
7. Refondre la page **Entrainement** : titres allégés, tags, filtres optionnels.
8. Refondre la page **Ressources** : remplacer viewer noir par cartes preview, ajouter placeholder Règlement intérieur.
9. Refondre la page **Saison 01** (anciennement Instagram) : nouveau layout éditorial avec photos.

### Phase 3 — Mobile + polish (1 demi-journée)
10. Implémenter les **media queries** (section 7).
11. Tester sur iPhone SE (375 px) et Pixel 7 (412 px).
12. Optimisation chargement (`preconnect` fonts, `loading="lazy"` photos).
13. Pass d'accessibilité (`alt` sur les `<img>`, `aria-current="page"` sur l'onglet actif).

**Quick wins en parallèle** (peuvent se faire à n'importe quel moment, indépendants) : remplacer label « Calendrier Courses » par « Calendrier », logique hero = prochaine course (déjà OK), retirer redondance hero/liste.

---

## 5. CSS — bloc à coller en haut de `style.css`

```css
/* ============================================================
   DRC · V2 design tokens
   ============================================================ */

@import url('https://fonts.googleapis.com/css2?family=Anton&family=Bebas+Neue&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap');

:root {
  /* Couleurs */
  --drc-cream:      #F4F1EC;
  --drc-ink:        #0D0D0D;
  --drc-blue:       #001EFF;
  --drc-blue-soft:  #EEF0FF;
  --drc-white:      #FFFFFF;
  --drc-bone:       #E6E0D3;
  --drc-graphite:   #5B5B5B;
  --drc-flare:      #E84A33;

  /* Typographie */
  --font-display:   'Anton', 'Impact', sans-serif;
  --font-sub:       'Bebas Neue', 'Oswald', sans-serif;
  --font-body:      'Inter', system-ui, -apple-system, sans-serif;
  --font-mono:      'JetBrains Mono', 'Menlo', monospace;

  /* Echelle */
  --display-xxl:    96px;
  --display-xl:     64px;
  --display-l:      40px;
  --display-m:      28px;
  --text-xl:        20px;
  --text-l:         18px;
  --text-m:         16px;
  --text-s:         14px;
  --mono-m:         14px;
  --mono-s:         12px;

  /* Rayons */
  --radius-s:       4px;
  --radius-m:       8px;
  --radius-pill:    999px;

  /* Espacements (multiples de 4) */
  --space-1:        4px;
  --space-2:        8px;
  --space-3:        12px;
  --space-4:        16px;
  --space-6:        24px;
  --space-8:        32px;
  --space-12:       48px;
  --space-16:       64px;
}

/* Reset & base ----------------------------------------------- */
*, *::before, *::after { box-sizing: border-box; }
html { -webkit-font-smoothing: antialiased; }
body {
  margin: 0;
  background: var(--drc-cream);
  color: var(--drc-ink);
  font-family: var(--font-body);
  font-size: var(--text-m);
  line-height: 1.5;
}

/* Hierarchy ------------------------------------------------- */
.display     { font-family: var(--font-display); text-transform: uppercase; letter-spacing: -0.02em; line-height: 0.92; }
.sub-display { font-family: var(--font-sub);     text-transform: uppercase; letter-spacing: 0; line-height: 1.0; }
.mono        { font-family: var(--font-mono);    letter-spacing: 0.08em; }
.mono-up     { font-family: var(--font-mono);    text-transform: uppercase; letter-spacing: 0.12em; }
```

---

## 6. HTML structurel par composant

### 6.1 Header

```html
<header class="drc-header">
  <a class="drc-logo" href="/" aria-label="Accueil DRC">
    <span class="drc-logo-mark" aria-hidden="true">D</span>
    <span class="drc-wordmark">
      <span class="drc-wordmark-top">Dérapage</span>
      <span class="drc-wordmark-bot">Running Club</span>
    </span>
  </a>
  <div class="drc-next-session" aria-label="Prochaine séance">
    <span class="mono-up small">Prochaine séance</span>
    <span class="mono">MAR · 20:15 · B. Dauvin</span>
  </div>
</header>
```

```css
.drc-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-6) var(--space-12);
  border-bottom: 1px solid var(--drc-bone);
}
.drc-logo { display: flex; align-items: center; gap: var(--space-3); text-decoration: none; color: inherit; }
.drc-logo-mark {
  display: inline-flex; align-items: center; justify-content: center;
  width: 48px; height: 48px; border-radius: 50%;
  background: var(--drc-blue); color: var(--drc-white);
  font-family: var(--font-display); font-size: 28px;
}
.drc-wordmark { display: flex; flex-direction: column; line-height: 1.0; }
.drc-wordmark-top { font-family: var(--font-display); font-size: 32px; text-transform: uppercase; letter-spacing: -0.02em; }
.drc-wordmark-bot { font-family: var(--font-display); font-size: 16px; color: var(--drc-blue); text-transform: uppercase; letter-spacing: 0.12em; }
.drc-next-session { display: flex; flex-direction: column; gap: 2px; padding: var(--space-2) var(--space-4); border: 1.5px solid var(--drc-blue); border-radius: var(--radius-s); }
.drc-next-session .mono-up.small { font-size: 9px; color: var(--drc-graphite); }
.drc-next-session .mono { font-size: 11px; color: var(--drc-blue); font-weight: 600; }
```

### 6.2 Navigation (avec pictos SVG inline)

```html
<nav class="drc-nav" aria-label="Sections du site">
  <button class="drc-tab" data-tab="saison" type="button">
    <!-- SVG picto SAISON -->
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
      <rect x="3" y="3" width="18" height="18" rx="1"/>
      <circle cx="12" cy="13" r="4"/>
      <circle cx="17" cy="6" r="0.8" fill="currentColor"/>
    </svg>
    <span>Saison 01</span>
  </button>
  <button class="drc-tab is-active" data-tab="calendrier" type="button" aria-current="page">
    <!-- SVG picto CALENDRIER -->
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
      <line x1="4" y1="2" x2="4" y2="22"/>
      <path d="M4 4 L20 4 L20 14 L4 14 Z"/>
      <line x1="8" y1="4" x2="8" y2="14" stroke-width="0.6"/>
      <line x1="12" y1="4" x2="12" y2="14" stroke-width="0.6"/>
      <line x1="16" y1="4" x2="16" y2="14" stroke-width="0.6"/>
      <line x1="4" y1="7" x2="20" y2="7" stroke-width="0.6"/>
      <line x1="4" y1="10" x2="20" y2="10" stroke-width="0.6"/>
    </svg>
    <span>Calendrier</span>
  </button>
  <button class="drc-tab" data-tab="entrainement" type="button">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
      <circle cx="12" cy="13" r="8"/>
      <line x1="12" y1="2" x2="12" y2="5"/>
      <line x1="12" y1="13" x2="16" y2="9"/>
    </svg>
    <span>Entraînement</span>
  </button>
  <button class="drc-tab" data-tab="ressources" type="button">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
      <path d="M4 2 L15 2 L20 7 L20 22 L4 22 Z"/>
      <path d="M15 2 L15 7 L20 7"/>
      <line x1="7" y1="11" x2="17" y2="11"/>
      <line x1="7" y1="15" x2="17" y2="15"/>
      <line x1="7" y1="19" x2="14" y2="19"/>
    </svg>
    <span>Ressources</span>
  </button>
</nav>
```

```css
.drc-nav {
  display: flex;
  gap: var(--space-8);
  padding: var(--space-6) var(--space-12) 0;
  border-bottom: 1px solid var(--drc-bone);
}
.drc-tab {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  background: none;
  border: none;
  cursor: pointer;
  font-family: var(--font-mono);
  font-size: var(--mono-s);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  color: var(--drc-ink);
  padding: var(--space-3) 0 var(--space-4);
  border-bottom: 2px solid transparent;
  transition: opacity 200ms ease, color 200ms ease, border-color 200ms ease;
}
.drc-tab svg { width: 20px; height: 20px; }
.drc-tab:hover:not(.is-active) { opacity: 0.7; }
.drc-tab.is-active {
  color: var(--drc-blue);
  border-bottom-color: var(--drc-blue);
}
```

JS minimal pour switcher les tabs (à intégrer dans `script.js`) :

```js
document.querySelectorAll('.drc-tab').forEach(btn => {
  btn.addEventListener('click', () => {
    const target = btn.dataset.tab;
    document.querySelectorAll('.drc-tab').forEach(b => b.classList.toggle('is-active', b === btn));
    document.querySelectorAll('[data-section]').forEach(s => s.hidden = s.dataset.section !== target);
    history.replaceState(null, '', '#' + target);
  });
});
// On load, honour the hash
const initial = location.hash.slice(1) || 'calendrier';
document.querySelector(`.drc-tab[data-tab="${initial}"]`)?.click();
```

### 6.3 Page Calendrier — hero + cartes

```html
<section data-section="calendrier" class="drc-page">
  <h1 class="drc-page-title">
    <span class="display drc-title-line-1">2026—2027</span>
    <span class="display drc-title-line-2">en courses</span>
  </h1>
  <p class="drc-page-sub">8 courses · 3 piliers · 1 trail · 1 clôture de saison</p>

  <!-- HERO : prochaine course -->
  <article class="drc-hero">
    <div class="drc-hero-left">
      <p class="mono-up drc-hero-label">Prochaine course</p>
      <h2 class="sub-display drc-hero-title">Weekend de rentrée DRC</h2>
      <p class="mono drc-hero-meta">24—25 OCT 2026 · format weekend long · vote en cours</p>
    </div>
    <div class="drc-hero-countdown" aria-label="Jours restants">
      <span class="display drc-countdown-number">159</span>
      <span class="mono-up drc-countdown-unit">Jours</span>
    </div>
  </article>

  <!-- Liste des courses -->
  <ul class="drc-races">
    <li class="drc-race is-pillar is-current">
      <div class="drc-race-date">
        <span class="display drc-race-day">24-25</span>
        <span class="mono-up drc-race-month">Oct 2026</span>
      </div>
      <div class="drc-race-body">
        <h3 class="sub-display drc-race-title">Weekend de rentrée DRC</h3>
        <div class="drc-race-tags">
          <span class="drc-tag drc-tag-info">Vote en cours</span>
          <span class="drc-meta-italic">Deadline candidatures : 15 juin 2026</span>
        </div>
      </div>
      <span class="drc-status drc-status-pending">À confirmer</span>
    </li>
    <li class="drc-race is-pillar">
      <div class="drc-race-date">
        <span class="display drc-race-day">Mi-nov.</span>
        <span class="mono-up drc-race-month">2026</span>
      </div>
      <div class="drc-race-body">
        <h3 class="sub-display drc-race-title">Semi-marathon de Boulogne</h3>
        <div class="drc-race-tags">
          <span class="drc-tag drc-tag-info">21,1 km</span>
          <span class="drc-tag drc-tag-pillar">Pilier</span>
        </div>
      </div>
      <span class="drc-status drc-status-pending">À confirmer</span>
    </li>
    <!-- ... -->
  </ul>
</section>
```

```css
.drc-page-title { margin: var(--space-12) 0 var(--space-2); }
.drc-title-line-1 { font-size: var(--display-xl); display: block; color: var(--drc-ink); }
.drc-title-line-2 { font-size: var(--display-xl); display: block; color: var(--drc-blue); }
.drc-page-sub { color: var(--drc-graphite); margin: 0 0 var(--space-12); }

.drc-hero {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: var(--space-8);
  align-items: center;
  padding: var(--space-12);
  background: linear-gradient(135deg, var(--drc-blue) 0%, #1438FF 100%);
  border-radius: var(--radius-m);
  color: var(--drc-white);
  position: relative;
  overflow: hidden;
}
.drc-hero::after { /* damier sur le bord droit */
  content: '';
  position: absolute; top: 0; right: 0; bottom: 0; width: 40px;
  background-image: linear-gradient(45deg, rgba(255,255,255,0.3) 25%, transparent 25%, transparent 75%, rgba(255,255,255,0.3) 75%);
  background-size: 16px 16px;
}
.drc-hero-label { opacity: 0.7; margin: 0 0 var(--space-3); font-size: 11px; }
.drc-hero-title { font-size: 48px; margin: 0 0 var(--space-2); }
.drc-hero-meta { opacity: 0.85; margin: 0; font-size: 13px; }
.drc-hero-countdown { display: flex; flex-direction: column; align-items: flex-end; }
.drc-countdown-number { font-size: 120px; line-height: 0.9; }
.drc-countdown-unit { opacity: 0.7; font-size: 12px; }
/* Si countdown < 7 jours, JS ajoute .is-urgent → couleur flare */
.drc-hero.is-urgent .drc-countdown-number { color: var(--drc-flare); }

.drc-races { list-style: none; padding: 0; margin: var(--space-8) 0 0; display: flex; flex-direction: column; gap: var(--space-3); }
.drc-race {
  display: grid;
  grid-template-columns: 160px 1fr auto;
  gap: var(--space-6);
  align-items: center;
  background: var(--drc-white);
  border-radius: var(--radius-m);
  padding: var(--space-6);
  position: relative;
}
.drc-race.is-pillar { border-left: 4px solid var(--drc-blue); padding-left: calc(var(--space-6) - 4px); }
.drc-race.is-current { background: linear-gradient(to right, rgba(238,240,255,0.5), var(--drc-white) 70%); }
.drc-race-day { font-size: 36px; line-height: 1.0; color: var(--drc-ink); }
.drc-race-month { display: block; font-size: 11px; color: var(--drc-graphite); margin-top: 2px; }
.drc-race-title { font-size: 28px; margin: 0 0 var(--space-2); }
.drc-race-tags { display: flex; align-items: center; gap: var(--space-2); flex-wrap: wrap; }
.drc-tag { font-family: var(--font-mono); font-size: 10px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.08em; padding: 2px 8px; border-radius: var(--radius-s); }
.drc-tag-info { background: var(--drc-blue-soft); color: var(--drc-blue); }
.drc-tag-pillar { background: var(--drc-blue); color: var(--drc-white); }
.drc-meta-italic { font-style: italic; font-size: 12px; color: var(--drc-graphite); }
.drc-status { font-family: var(--font-mono); font-size: 10px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.08em; padding: var(--space-2) var(--space-4); border-radius: var(--radius-s); }
.drc-status-pending { border: 1px solid var(--drc-ink); color: var(--drc-ink); }
.drc-status-confirmed { background: var(--drc-ink); color: var(--drc-white); }
```

### 6.4 Page Saison 01

```html
<section data-section="saison" class="drc-page" hidden>
  <h1 class="drc-page-title">
    <span class="sub-display" style="font-size: 120px; display: block;">Saison 01</span>
    <span class="sub-display" style="font-size: 120px; display: block; color: var(--drc-blue);">l'album</span>
  </h1>
  <p class="drc-page-sub">Août 2025 → Juin 2026 · 36 séances, 9 courses, des verres chez Pinettes, un week-end loin de Paris.</p>
  <p class="mono-up drc-est-line">EST. 2025 · PARIS · FFA</p>

  <!-- Hero feature -->
  <article class="drc-album-hero">
    <figure class="drc-album-hero-photo">
      <img src="photos_saison_01/01-hero.jpg" alt="Drift Award — fête de Noël" loading="lazy" />
      <figcaption>
        <h2 class="sub-display">Drift Award — fête de Noël</h2>
        <p class="mono-up small">12 déc 2025 · Photo by Marine</p>
      </figcaption>
    </figure>
    <aside class="drc-album-hero-side">
      <h3 class="sub-display drc-album-hero-side-title">Un moment, parmi beaucoup d'autres.</h3>
      <p>Première soirée de remise des prix maison. Marathon de remerciements, t-shirts, fous rires à Pinettes. Le club avait six mois.</p>
      <div class="drc-album-grid-2">
        <figure>
          <img src="photos_saison_01/02-decouverte-club.jpg" alt="Découverte club" loading="lazy" />
          <figcaption><span class="mono-up small">02 sept 2025</span><span class="sub-display">Découverte club</span></figcaption>
        </figure>
        <figure>
          <img src="photos_saison_01/03-test-vma-1.jpg" alt="Test VMA #1" loading="lazy" />
          <figcaption><span class="mono-up small">14 oct 2025</span><span class="sub-display">Test VMA #1</span></figcaption>
        </figure>
      </div>
      <figure class="drc-album-grid-wide">
        <img src="photos_saison_01/04-cantal-sortie-longue.jpg" alt="Sortie longue — Haut-Cantal" loading="lazy" />
        <figcaption><span class="mono-up small">04—06 avr 2026 · Cantal</span><span class="sub-display">Sortie longue — Haut-Cantal</span></figcaption>
      </figure>
    </aside>
  </article>

  <!-- Mosaïque -->
  <div class="drc-album-section">
    <h3 class="sub-display drc-album-section-title">Printemps 2026 <span class="mono-up drc-album-section-meta">12 semaines · 4 courses pivot</span></h3>
    <div class="drc-album-mosaic">
      <figure class="m-wide">
        <img src="photos_saison_01/05-hybride-seuil-vma.jpg" alt="Hybride seuil → VMA" loading="lazy" />
        <figcaption><span class="mono-up small">17 mars 2026</span><span class="sub-display">Hybride seuil → VMA</span></figcaption>
      </figure>
      <figure class="m-tall">
        <img src="photos_saison_01/06-semi-paris.jpg" alt="Semi de Paris" loading="lazy" />
        <figcaption><span class="mono-up small">02 mars 2026</span><span class="sub-display">Semi de Paris</span></figcaption>
      </figure>
      <figure class="m-medium">
        <img src="photos_saison_01/07-cycle-vma-piste.jpg" alt="Cycle VMA piste" loading="lazy" />
        <figcaption><span class="mono-up small">21 avr 2026</span><span class="sub-display">Cycle VMA · piste</span></figcaption>
      </figure>
      <figure class="m-square">
        <img src="photos_saison_01/08-cloture-cycle.jpg" alt="Clôture du cycle" loading="lazy" />
        <figcaption><span class="mono-up small">12 mai 2026</span><span class="sub-display">Clôture du cycle</span></figcaption>
      </figure>
    </div>
  </div>

  <footer class="drc-album-footer">
    <p>Le quotidien du club, c'est sur Instagram.</p>
    <a href="https://instagram.com/derapagerunningclub" class="drc-link">→ @derapagerunningclub</a>
  </footer>
</section>
```

Le traitement duotone bleu est appliqué en CSS sur la photo hero uniquement :

```css
.drc-album-hero-photo img { width: 100%; display: block; filter: grayscale(1) contrast(1.1); }
.drc-album-hero-photo { position: relative; }
.drc-album-hero-photo::after {
  content: ''; position: absolute; inset: 0;
  background: linear-gradient(135deg, rgba(0,30,255,0.55), rgba(13,13,13,0.55));
  mix-blend-mode: multiply;
  pointer-events: none;
}
```

Mosaïque grid :

```css
.drc-album-mosaic {
  display: grid;
  grid-template-columns: 420px 200px 320px 280px;
  gap: var(--space-3);
}
.drc-album-mosaic figure { position: relative; margin: 0; overflow: hidden; border-radius: var(--radius-s); }
.drc-album-mosaic .m-wide   { height: 260px; }
.drc-album-mosaic .m-tall   { height: 260px; }
.drc-album-mosaic .m-medium { height: 260px; }
.drc-album-mosaic .m-square { height: 260px; }
.drc-album-mosaic figure img { width: 100%; height: 100%; object-fit: cover; display: block; }
.drc-album-mosaic figcaption {
  position: absolute; inset: 0;
  display: flex; flex-direction: column; justify-content: space-between;
  padding: var(--space-3);
  background: linear-gradient(180deg, rgba(0,0,0,0) 60%, rgba(0,0,0,0.55) 100%);
  color: var(--drc-white);
}
.drc-album-mosaic figcaption .mono-up.small { font-size: 9px; }
.drc-album-mosaic figcaption .sub-display { font-size: 20px; }
```

**Fallback si une photo manque** : laisser un `<div class="drc-photo-placeholder">` avec la date + caption en monospace blanche sur fond `linear-gradient(135deg, var(--drc-bone), var(--drc-blue))` — identique au duotone du mock.

### 6.5 Page Entrainement (modifications minimes)

L'existant fonctionne — appliquer juste :
- Titre de section avec la classe `display` ou `sub-display` selon la taille
- Date pills en `var(--font-mono)` `--mono-s` uppercase
- Champ VMA dans une carte avec accent bleu :

```html
<div class="drc-vma-card">
  <label for="vma-input"><span class="sub-display">Ma VMA</span></label>
  <input id="vma-input" type="number" min="8" max="25" step="0.1" placeholder="ex: 17.5" />
  <span class="mono-up">km/h</span>
  <span class="drc-vma-saved">Sauvegardé automatiquement</span>
</div>
```

Optionnel **Phase 2.5 (à creuser uniquement si temps dispo)** — chips de filtre par type de séance :

```html
<div class="drc-filters" role="tablist">
  <button class="drc-chip is-active" data-filter="all">Tout</button>
  <button class="drc-chip" data-filter="vma">VMA</button>
  <button class="drc-chip" data-filter="seuil">Seuil</button>
  <button class="drc-chip" data-filter="hors-les-murs">Hors les murs</button>
  <button class="drc-chip" data-filter="test">Test</button>
</div>
```

Catégoriser les séances via `data-type="vma|seuil|hors-les-murs|test|hybride"` sur chaque `<li>`, et JS filter trivial. **Pas de bandeau stats** (décision Alex).

### 6.6 Page Ressources

```html
<section data-section="ressources" class="drc-page" hidden>
  <h1 class="drc-page-title"><span class="display">La boîte à outils</span></h1>
  <p class="drc-page-sub">Documents internes du club.</p>

  <ul class="drc-resources">
    <li class="drc-resource">
      <img class="drc-resource-preview" src="ressources/previews/vma-seuil-preview.jpg" alt="" />
      <div class="drc-resource-body">
        <h3 class="sub-display">VMA &amp; Seuil</h3>
        <p>Allures de référence · Maj : avril 2026</p>
        <div class="drc-resource-actions">
          <a class="drc-btn" href="ressources/vma-seuil.pdf" target="_blank">Ouvrir</a>
          <a class="drc-btn drc-btn-secondary" href="ressources/vma-seuil.pdf" download>Télécharger</a>
        </div>
      </div>
    </li>
    <li class="drc-resource">
      <img class="drc-resource-preview" src="ressources/previews/renfo-mobilite-preview.jpg" alt="" />
      <div class="drc-resource-body">
        <h3 class="sub-display">Renfo du coureur &amp; mobilité</h3>
        <p>Renforcement &amp; exercices de mobilité · Maj : mars 2026</p>
        <div class="drc-resource-actions">
          <a class="drc-btn" href="ressources/renfo-mobilite.pdf" target="_blank">Ouvrir</a>
          <a class="drc-btn drc-btn-secondary" href="ressources/renfo-mobilite.pdf" download>Télécharger</a>
        </div>
      </div>
    </li>
    <li class="drc-resource is-placeholder">
      <div class="drc-resource-preview drc-resource-preview-empty" aria-hidden="true">PDF</div>
      <div class="drc-resource-body">
        <h3 class="sub-display">Règlement intérieur</h3>
        <p>À venir · Bureau · saison 2025-2026</p>
        <div class="drc-resource-actions">
          <span class="drc-btn drc-btn-disabled" aria-disabled="true">Bientôt disponible</span>
        </div>
      </div>
    </li>
  </ul>
</section>
```

```css
.drc-resources { list-style: none; padding: 0; display: flex; flex-direction: column; gap: var(--space-4); }
.drc-resource { display: grid; grid-template-columns: 120px 1fr; gap: var(--space-6); padding: var(--space-6); background: var(--drc-white); border-radius: var(--radius-m); align-items: center; }
.drc-resource-preview { width: 120px; height: 160px; object-fit: cover; border-radius: var(--radius-s); border: 1px solid var(--drc-bone); }
.drc-resource-preview-empty { display: flex; align-items: center; justify-content: center; background: var(--drc-bone); font-family: var(--font-mono); font-size: 14px; color: var(--drc-graphite); }
.drc-resource.is-placeholder { opacity: 0.6; }
.drc-btn { display: inline-block; padding: var(--space-3) var(--space-6); background: var(--drc-blue); color: var(--drc-white); text-decoration: none; font-family: var(--font-body); font-weight: 600; font-size: 14px; text-transform: uppercase; letter-spacing: 0.05em; border-radius: var(--radius-s); }
.drc-btn:hover { background: var(--drc-ink); }
.drc-btn-secondary { background: transparent; border: 1.5px solid var(--drc-blue); color: var(--drc-blue); }
.drc-btn-secondary:hover { background: var(--drc-blue-soft); color: var(--drc-blue); }
.drc-btn-disabled { background: var(--drc-bone); color: var(--drc-graphite); cursor: not-allowed; }
```

### 6.7 Footer

Pas de modification fonctionnelle (décision Alex). Vérifier juste que les nouvelles fonts s'appliquent. Le séparateur `EST. 2025 · PARIS · FFA` doit rester en `var(--font-mono)` 600 11px letter-spacing 0.12em.

---

## 7. Media queries mobile

Trois breakpoints suffisent :

```css
/* Tablette : empile la nav indicator, réduit la grille races */
@media (max-width: 900px) {
  .drc-header { padding: var(--space-4) var(--space-6); }
  .drc-next-session { display: none; } /* trop d'info sur tablette */
  .drc-races .drc-race { grid-template-columns: 100px 1fr auto; }
}

/* Mobile : layout simplifié */
@media (max-width: 600px) {
  .drc-header { flex-direction: column; align-items: flex-start; gap: var(--space-3); }
  .drc-wordmark-top { font-size: 22px; }
  .drc-wordmark-bot { font-size: 11px; }
  .drc-logo-mark { width: 32px; height: 32px; font-size: 20px; }

  /* Nav scroll horizontal, pas de hamburger */
  .drc-nav {
    flex-wrap: nowrap;
    overflow-x: auto;
    gap: var(--space-6);
    padding: var(--space-3) var(--space-4) 0;
    scrollbar-width: none;
  }
  .drc-nav::-webkit-scrollbar { display: none; }
  .drc-tab { flex-shrink: 0; padding: var(--space-3) 0; min-height: 44px; }

  /* Titres pages */
  .drc-title-line-1, .drc-title-line-2 { font-size: 44px; }
  .drc-page-title { padding: 0 var(--space-4); }
  .drc-page-sub { padding: 0 var(--space-4); }

  /* Hero stacked */
  .drc-hero { grid-template-columns: 1fr; padding: var(--space-6); }
  .drc-hero-title { font-size: 26px; }
  .drc-hero-countdown { flex-direction: row; align-items: baseline; gap: var(--space-3); }
  .drc-countdown-number { font-size: 80px; }

  /* Cartes course : date au-dessus */
  .drc-races .drc-race { grid-template-columns: 1fr; gap: var(--space-3); }
  .drc-race-date { display: flex; align-items: baseline; gap: var(--space-2); }
  .drc-race-day { font-size: 28px; }
  .drc-race-status { align-self: flex-start; }

  /* Album : grille mosaïque en 2 colonnes max */
  .drc-album-mosaic { grid-template-columns: 1fr 1fr; }
  .drc-album-mosaic .m-wide,
  .drc-album-mosaic .m-medium,
  .drc-album-mosaic .m-square,
  .drc-album-mosaic .m-tall { height: 200px; }
  .drc-album-hero { grid-template-columns: 1fr; }

  /* Boutons : cibles tactiles min 44 px */
  .drc-btn { padding: var(--space-3) var(--space-4); min-height: 44px; display: inline-flex; align-items: center; }
}
```

**Tester sur** : iPhone SE 375 px (le plus contraignant en pratique), iPhone 14 390 px, Pixel 7 412 px. DevTools mobile responsive suffit pour la majorité — vrai device sur iPhone d'Alex pour validation finale.

---

## 8. Pictos — alternatives via IA si tu veux changer

Si tu veux **régénérer des pictos différents** (par exemple plus de personnalité, plus crew street), voici les prompts à utiliser. Le résultat doit être un SVG 24×24, stroke 1.5 px, `currentColor`, no fill.

### Outil recommandé : ChatGPT (GPT-4 ou Claude) → demander directement le SVG code

Prompt template :

```
Génère un SVG 24x24 monolinéaire pour une icône de navigation web.
Contraintes strictes :
- viewBox="0 0 24 24"
- fill="none"
- stroke="currentColor"
- stroke-width="1.5"
- stroke-linecap="round" et stroke-linejoin="round"
- Pas de path complexe, formes géométriques simples (line, path, circle, rect)
- Style : minimal, athletic, inspiration retro-running 2000s, lisible à 24px

Sujet : [SUJET CI-DESSOUS]
Retourne uniquement le bloc <svg>...</svg>, rien d'autre.
```

| Onglet | Sujet à mettre dans le prompt |
| --- | --- |
| Saison 01 | « Un appareil photo polaroid stylisé, vu de face, avec un objectif rond au centre et un flash en haut à droite » |
| Calendrier | « Un drapeau à damier monté sur un mât, motif de course de fin, simple » |
| Entraînement | « Un chronomètre rond avec une seule aiguille pointant vers le haut-droite, sans cadran chiffré » |
| Ressources | « Une feuille de papier avec coin replié en haut à droite, deux lignes de texte horizontales à l'intérieur » |

### Outil alternatif : Midjourney / DALL-E pour PNG, à convertir ensuite

Si tu génères en PNG via DALL-E ou Midjourney, ajoute `vector minimal line icon, single color, transparent background, flat 24x24 grid, strong stroke contrast` au prompt. Puis utilise [Vectorizer.AI](https://vectorizer.ai) ou Adobe Illustrator pour convertir en SVG propre.

**Si tu n'as pas le temps :** les SVG fournis section 6.2 sont prêts à coller et passent le test « 24×24, lisibles, cohérents ». Pas besoin de régénérer.

---

## 9. Intégration des photos Saison 01

Alex te fournira un dossier `photos_saison_01/` avec **8 photos** nommées explicitement :

```
01-hero.jpg
02-decouverte-club.jpg
03-test-vma-1.jpg
04-cantal-sortie-longue.jpg
05-hybride-seuil-vma.jpg
06-semi-paris.jpg
07-cycle-vma-piste.jpg
08-cloture-cycle.jpg
```

Le fichier `photos_saison_01.md` (dans le même dossier) liste les captions, dates, et crédits à associer.

**Format de référence dans le HTML** (déjà visible section 6.4) :

```html
<img src="photos_saison_01/01-hero.jpg" alt="Drift Award — fête de Noël" loading="lazy" />
```

**Si une photo manque** : utiliser le fallback placeholder duotone (CSS). Le HTML peut être structuré pour basculer automatiquement :

```html
<figure class="drc-photo" data-fallback="Drift Award — 12 déc 2025">
  <img src="photos_saison_01/01-hero.jpg" alt="..." loading="lazy"
       onerror="this.parentNode.classList.add('drc-photo-fallback')" />
  <figcaption>...</figcaption>
</figure>
```

```css
.drc-photo-fallback img { display: none; }
.drc-photo-fallback { background: linear-gradient(135deg, var(--drc-bone), var(--drc-blue)); position: relative; }
.drc-photo-fallback::before {
  content: attr(data-fallback);
  position: absolute; bottom: 12px; left: 12px;
  font-family: var(--font-mono); font-size: 11px; font-weight: 600;
  color: var(--drc-white); text-transform: uppercase; letter-spacing: 0.12em;
}
```

---

## 10. Checklist d'acceptation

### Visuel
- [ ] Body background `#F4F1EC` partout
- [ ] Wordmark header utilise **Anton** (police d'affichage chargée correctement)
- [ ] Nav : 4 pictos SVG, soulignement bleu sur l'onglet actif, pas de pill background
- [ ] Hero Calendrier : gradient blue, compteur en Anton 120px, damier sur le bord droit
- [ ] Cartes course : date-block Anton, titre Bebas Neue, tags monospace, border-left bleu sur les Piliers
- [ ] Saison 01 : titre `SAISON 01 / L'ALBUM` en Bebas Neue 120 px, photo hero en duotone bleu
- [ ] Footer inchangé sauf la typo qui s'aligne (mono pour `EST. 2025 · PARIS · FFA`)

### Comportement
- [ ] Tab switching fonctionne, URL hash se met à jour (`#saison`, `#calendrier`, etc.)
- [ ] Au refresh, le hash est honoré
- [ ] VMA persistance : champ sauvegardé via `localStorage`, affichage des durées cibles ajusté
- [ ] Compteur jours mis à jour à chaque chargement (JS calcule `Math.floor((targetDate - now) / 86400000)`)

### Mobile
- [ ] Sur 375 px (iPhone SE), tout reste lisible et tactile
- [ ] Nav en scroll horizontal sans hamburger menu
- [ ] Hero stacked (countdown sous le titre, pas à côté)
- [ ] Cibles tactiles min 44×44 px

### Accessibilité (minimum)
- [ ] Tous les `<img>` ont un `alt` significatif (ou `alt=""` si purement décoratif)
- [ ] Onglet actif marqué `aria-current="page"`
- [ ] Contraste texte ≥ 4.5:1 (le bleu `#001EFF` sur cream `#F4F1EC` = 8.6:1 ✓, le `#5B5B5B` sur cream = 5.9:1 ✓)
- [ ] Focus visible sur les boutons et liens (default browser OK ou custom outline)

### Performance
- [ ] Polices avec `display=swap`
- [ ] Photos `loading="lazy"` sauf le hero
- [ ] Pas de JavaScript inutile au chargement (defer si possible)
- [ ] Lighthouse mobile ≥ 90 sur Perf & Accessibilité

---

## 11. Questions à clarifier avant de pousser

À envoyer à Alex avant le merge :
1. **Logo rond actuel** — on conserve le D blanc sur disque bleu tel quel, ou tu veux le réviser ? (le brief t-shirt évoque « revoir le logo avec un DRC »)
2. **`Next session indicator` dans le header** — la valeur (« MAR · 20:15 · B. Dauvin ») doit-elle être dynamique (lue d'un fichier de données partagé avec le WhatsApp du lundi) ou statique pour la V1 ?
3. **VMA personnalisé** — confirmer qu'on conserve le `localStorage` actuel sans changer la clé (sinon les membres perdent leur valeur saisie).
4. **Stats banner** — Alex a dit *non* pour la V1, mais si tu vois une opportunité opportune (ex: en-tête de page Entraînement compté automatiquement), poser la question avant d'ajouter.

---

*Fin du handover. Bonne implémentation. En cas de blocage, ping Alex et il escalade au support projet.*
