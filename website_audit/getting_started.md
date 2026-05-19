# Getting started — Front-end engineer

> **À toi de jouer.** Tout ce qu'il faut pour cloner le repo, lancer le dev local, implémenter la refonte V2 (Direction B — Crew Culture Street), pousser une PR, et déployer en prod.
>
> **Tu n'as besoin d'aucun outil exotique :** git, un éditeur (VS Code ou autre), un navigateur. Pas de build, pas de Node, pas de npm.

---

## 1. Repo en 30 secondes

| Item | Détail |
| --- | --- |
| Repo | `alexs-307/drc-internal` (privé) |
| URL | https://github.com/alexs-307/drc-internal |
| Branche prod | `main` — auto-deploy GitHub Pages |
| Domaine | derapage.xyz (CNAME) |
| Stack | HTML + CSS + JS inline dans un seul `index.html` (~1100 lignes, ~174 KB) |
| Données | `sessions.json` (entraînements) chargé via `fetch()` au runtime |
| Statique | `ressources/` (PDFs), logo en base64 dans le HTML |
| Build | **Aucun**. Pas de bundler, pas de framework. Vanilla pur. |
| Polices | Google Fonts via `<link>` dans `<head>` |

**Contraintes dures** (à respecter pour ne pas casser quelque chose) :
- Le site doit pouvoir s'ouvrir en `file://` → le logo reste en base64 inline, les styles restent dans un `<style>` interne, les scripts restent dans un `<script>` interne. **Pas de fichiers CSS/JS externes locaux.**
- `Calendrier` reste l'onglet ouvert par défaut.
- Tout le texte member-facing est en **français**.
- Pas de SEO, ne pas toucher au `<meta name="robots" content="noindex, nofollow">`.

---

## 2. Ce qu'il faut lire (dans cet ordre)

Avant de coder, parcours :

1. **Ce fichier** — workflow et conventions.
2. **`website_audit/handover_dev.md`** — la spec complète (CSS, HTML, SVG pictos, media queries, checklist).
3. **`website_audit/brand_kit_v2.md`** — le système de design (palette, typo, composants).
4. **`website_audit/viewer.html`** — ouvre-le dans un navigateur pour voir les 4 mocks en taille réelle avec les vraies polices.
5. **`website_audit/mocks/*.svg`** — les mocks individuels (utiles pour vérifier des dimensions précises).
6. **`website_audit/audit_v1.md`** — uniquement si tu veux comprendre le *pourquoi* d'une décision.
7. **`website_audit/photos_saison_01/photos_saison_01.md`** — les 8 emplacements photo de la section Saison 01.

Le repo a aussi un **`CLAUDE.md`** et un **`README.md`** racine — utile mais partiellement obsolète (mentionne 3 onglets, alors qu'il y en a 4 maintenant). Réfère-toi au code et au handover, pas à ces docs racine.

---

## 3. Setup local (5 minutes)

### Prérequis

- `git` installé
- Un éditeur — VS Code recommandé (extensions utiles : *Live Server*, *Prettier*)
- Un navigateur récent (Safari/Chrome/Firefox)
- Optionnel : Python 3 pour servir le repo en local (utile pour `sessions.json` qui se charge via `fetch()` — selon ton navigateur, `file://` peut bloquer `fetch()`)

### Cloner

Avant de cloner, demande à Alex de t'ajouter comme **collaborator** sur le repo (Settings → Collaborators → Add people). Une fois invité :

```bash
# Avec SSH si tu as déjà ta clé enregistrée sur GitHub :
git clone git@github.com:alexs-307/drc-internal.git
cd drc-internal

# Ou avec HTTPS + token perso :
git clone https://github.com/alexs-307/drc-internal.git
cd drc-internal
```

### Lancer en local

**Option 1 — simple (Safari/Chrome tolèrent `file://` pour `fetch`) :**

```bash
open index.html      # macOS
xdg-open index.html  # Linux
```

**Option 2 — serveur local (recommandé pour `fetch()` propre) :**

```bash
python3 -m http.server 4321
# → http://localhost:4321
```

Ou via VS Code → clic droit sur `index.html` → *Open with Live Server* (auto-reload à chaque sauvegarde).

Tu devrais voir le site actuel s'afficher avec ses 4 onglets (Instagram / Calendrier / Entrainement / Ressources).

---

## 4. Architecture du fichier — où injecter quoi

Le fichier `index.html` est organisé ainsi :

| Lignes (approx.) | Bloc | Quoi y mettre |
| --- | --- | --- |
| 1-8 | `<head>` | Meta tags, **`<link>` Google Fonts** (ajouter Anton + Bebas Neue + JetBrains Mono à la liste existante) |
| 9-605 | `<style>` | **CSS** — `:root` tokens existent déjà (lignes 11-27), ajouter les nouveaux. Composants à refondre dans la suite du bloc. |
| 605-756 | `<body>` markup | Header, nav, 4 panneaux (tab-instagram / tab-calendar / tab-sessions / tab-resources) |
| 757-1119 | `<script>` | JS — tab switching, fetch sessions, VMA persistance, search filter |

**Convention forte** : tu modifies **uniquement `index.html`**. Pas de nouveaux fichiers CSS / JS séparés. Pas de réorganisation en plusieurs fichiers (la contrainte file:// l'empêche).

### Tokens existants vs V2

Le fichier a déjà ces tokens (`<style>` lignes 11-27) — la plupart correspondent au brand kit V2 :

| Token actuel | Valeur | Statut V2 |
| --- | --- | --- |
| `--blue` | `#001EFF` | ✅ Conserver |
| `--blue-light` | `#3348FF` | ✅ Conserver (utile pour le gradient hero) |
| `--blue-faint` | `#EEF0FF` | ✅ Conserver (renommé `--drc-blue-soft` dans le brand kit mais identique) |
| `--peach` | `#FFE1D2` | ⚠️ Conserver pour l'instant (utilisé ailleurs) mais ne pas l'étendre. Le nouveau accent est `--drc-flare: #E84A33` (à utiliser uniquement pour countdown < 7 jours). |
| `--bg` | `#F4F1EC` | ✅ Identique au brand kit |
| `--bg-grid` | `#ECE7DE` | ✅ Conserver |
| `--text` | `#0D0D0D` | ✅ Conserver |
| `--text-muted` | `#5A5A5A` | ✅ Conserver (= `--drc-graphite`) |
| `--border` | `#E2DED6` | ✅ Conserver (= `--drc-bone`) |
| `--radius` | `10px` | ⚠️ Brand kit V2 utilise `8px` pour les cartes — à toi de juger sur cas par cas (10px reste OK partout) |
| `--display` | `Space Grotesk` | ⚠️ **À remplacer** par Bebas Neue + ajouter Anton et JetBrains Mono. Voir section 5.1 |

**Décision pragmatique :** garde les tokens existants tels quels, **ajoute** les nouveaux du brand kit en complément, ne renomme rien. Tu utilises `--blue` ou `--drc-blue`, peu importe — ce sont des alias. Préfère l'existant pour éviter de tout casser.

---

## 5. Workflow d'implémentation

### 5.1 Première étape — typographie (15 minutes)

Modifier le `<link>` Google Fonts ligne 8 pour y ajouter les nouvelles polices :

```html
<link href="https://fonts.googleapis.com/css2?family=Anton&family=Bebas+Neue&family=Inter:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400&family=JetBrains+Mono:wght@400;500;600&family=Space+Grotesk:wght@500;600;700&display=swap" rel="stylesheet">
```

(Anton et Bebas Neue ajoutés, Space Grotesk conservé temporairement pour ne rien casser ailleurs.)

Dans `:root`, **ajouter** :

```css
--font-display:   'Anton', 'Impact', sans-serif;
--font-sub:       'Bebas Neue', 'Oswald', sans-serif;
--font-body:      'Inter', system-ui, -apple-system, sans-serif;
--font-mono:      'JetBrains Mono', 'Menlo', monospace;
--drc-flare:      #E84A33;
```

Vérifier que la page se charge encore correctement — rien n'a changé visuellement mais les polices sont disponibles pour la suite.

### 5.2 Phase 1 — fondations (½ journée)

Suit la section 4 du **`handover_dev.md`** :

1. Header : wordmark Anton (lignes 30-40 environ du HTML actuel).
2. Navigation : remplacer les emojis (`📸 🏁 💪 📚`) par les 4 SVG pictos (handover §6.2).
3. Footer : laisser tel quel (intouché par décision Alex).
4. **Renommer l'onglet Instagram → Saison 01 :**
   - `data-tab="instagram"` → `data-tab="saison"`
   - `id="tab-instagram"` → `id="tab-saison"`
   - Le label affiché → « Saison 01 »
   - **Backward compat :** dans le JS qui lit `location.hash`, accepter aussi `#instagram` et le rediriger vers `#saison` (au cas où des bookmarks existent — discutable, voir avec Alex).

Commit Phase 1 quand tu vois le header, la nav et les pictos refaits.

### 5.3 Phase 2 — sections de contenu (1 journée)

5. **Calendrier** : refondre hero gradient + cartes course (handover §6.3). Penser à :
   - Le hero affiche la prochaine course **quel que soit son statut** (confirmée ou non). Ne pas filtrer par `confirmed: true`.
   - Pas de mention « Cantal » dans le hero — le Weekend de Rentrée n'est pas dans le Cantal. La meta du hero peut être : `format weekend long · vote en cours` (ou ce qui correspond au statut actuel).
   - Compteur `< 7 jours` → class `is-urgent` + couleur `--drc-flare`.

6. **Entrainement** : adapter typo et tags (handover §6.5). Conserver le JS VMA persistence (`localStorage.drc_vma`) et `annotateVMA()` — c'est du code fonctionnel important.

7. **Ressources** : remplacer les viewers PDF par des cartes preview + ajouter le placeholder *Règlement intérieur* (handover §6.6).

8. **Saison 01** : refonte complète (handover §6.4). Photos depuis `photos_saison_01/` (Alex les fournit séparément).

Commit Phase 2 quand toutes les sections sont en V2.

### 5.4 Phase 3 — mobile + polish (½ journée)

9. Media queries (handover §7).
10. Test sur iPhone SE (375 px) et Pixel 7 (412 px) via DevTools.
11. Pass accessibilité : `alt` sur les `<img>`, `aria-current="page"` sur l'onglet actif.
12. Lighthouse mobile : viser ≥ 90 Perf + A11y.

---

## 6. Tester en local

À chaque commit :

- [ ] Recharge `index.html` (Cmd+R) — pas de console error
- [ ] Tab switching fonctionne, hash URL se met à jour
- [ ] VMA persistance OK : entre une valeur, recharge, elle est toujours là
- [ ] Compteur jours juste : `Math.floor((targetDate - now) / 86400000)` → vérifier sur la prochaine course
- [ ] Aucun emoji décoratif dans la nav (remplacés par SVG)
- [ ] Polices chargées : ouvrir DevTools → Network → filter `fonts.gstatic` → 4 fichiers loaded (Anton, Bebas Neue, Inter, JetBrains Mono)
- [ ] Layout mobile : DevTools → Toggle device toolbar → 375 px, 390 px, 412 px
- [ ] `file://` test : ouvre `index.html` directement (sans serveur) → tout fonctionne (sauf peut-être `sessions.json` selon le navigateur)

Outils utiles :
- DevTools → Lighthouse → Mobile audit
- DevTools → Rendering → *Emulate vision deficiencies* pour vérifier le contraste

---

## 7. Branch + PR + merge → prod

### 7.1 Stratégie de branche

Vu l'ampleur (3 phases), je recommande **3 branches successives**, chacune mergée avant la suivante. Évite une PR monolithique impossible à reviewer.

```bash
# Phase 1
git checkout main && git pull
git checkout -b feat/v2-phase-1-fondations
# … coder Phase 1 …
git add index.html
git commit -m "feat(v2): typo + header wordmark + nav pictos SVG + rename Saison 01"
git push -u origin feat/v2-phase-1-fondations
# → ouvrir une PR sur GitHub

# Phase 2 (après merge Phase 1)
git checkout main && git pull
git checkout -b feat/v2-phase-2-sections
# … coder Phase 2 …

# Phase 3 (après merge Phase 2)
git checkout main && git pull
git checkout -b feat/v2-phase-3-mobile
# … coder Phase 3 …
```

Convention de commit : préfixes `feat(v2):`, `fix(v2):`, `style(v2):`, `chore(v2):`. Messages en anglais ou français au choix, courts (≤ 72 caractères).

### 7.2 Ouvrir la PR

Sur github.com → ton fork ou ta branche → bouton « Compare & pull request » → cible `main`.

Template PR à utiliser :

```markdown
## Phase X — [titre]

### Changements
- …
- …

### Test
- [ ] Tab switching OK
- [ ] VMA persistance OK
- [ ] Polices chargées
- [ ] Mobile 375 px OK

### Captures
[avant / après ou screenshots des sections modifiées]

### Notes pour Alex
- Question éventuelle / décision à valider
```

Demander à Alex en review (`@alexs-307`). Le repo n'a pas de CI pour l'instant — la review est manuelle.

### 7.3 Déployer en prod

Le déploiement est **automatique** :

1. La PR est mergée sur `main`.
2. GitHub Pages détecte le push et redéploie.
3. **Délai : ~1 minute** entre le merge et la mise en prod.
4. Vérifier sur https://derapage.xyz (vider le cache si besoin : Cmd+Shift+R).

**Aucune autre action manuelle requise.** Pas de build à lancer, pas de FTP, pas de fichier à uploader.

### 7.4 En cas de bug en prod

Le rollback est trivial :

```bash
git checkout main && git pull
git revert <sha-du-commit-bugué>
git push origin main
```

Re-déploiement auto en ~1 minute. Pas besoin de toucher GitHub Pages — c'est le repo qui pilote tout.

---

## 8. Notes spécifiques au repo

### 8.1 `sessions.json` — données entraînement

Le fichier `sessions.json` est édité **directement sur GitHub** par Alex chaque lundi (via l'UI web). Ne pas refactor son schéma. Si tu changes la façon dont il est consommé, **discuter avec Alex avant**.

Format actuel d'une entrée :

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

### 8.2 Logo

Le logo rond DRC est **embarqué en base64** dans le HTML (autour de la ligne 615 environ, dans le header). Ne pas le remplacer par un `<img src="logo.png">` — ça casserait le mode `file://`.

Si tu dois mettre à jour le logo (Alex t'enverra peut-être une nouvelle version), encode-le en base64 d'abord :

```bash
base64 -i logo.png | pbcopy  # macOS, met le base64 dans le clipboard
```

Puis remplace la chaîne dans le HTML.

### 8.3 `annotateVMA()` — fonction sensible

Cette fonction parse le contenu des séances et injecte des badges avec les allures cibles. Les regex sont dans le README racine. **Ne pas la casser** — elle est utilisée à chaque rendu de séance. Si tu refactor le markup des séances, teste qu'elle s'applique toujours correctement (entre une valeur VMA, ouvre une séance type « VMA — 400m répétés », vérifie que les `400m à 100% VMA` deviennent des badges).

### 8.4 Backward compat des hashes URL

Si tu renommes l'onglet Instagram → Saison 01, certains membres peuvent avoir bookmarké `derapage.xyz/#instagram`. Le JS de tab switching peut ajouter un alias :

```js
const initial = location.hash.slice(1) || 'calendar';
const aliased = initial === 'instagram' ? 'saison' : initial;
document.querySelector(`.tab-btn[data-tab="${aliased}"]`)?.click();
```

À discuter avec Alex — s'il dit que personne ne bookmarque, autant ignorer.

### 8.5 PDFs Ressources

Les 2 PDFs sont dans `ressources/` à la racine. Pour les previews en V2, tu peux soit :
- Demander à Alex de fournir des `previews/vma-seuil-preview.jpg` (capture première page)
- Ou les générer toi-même : `sips -s format jpeg --resampleHeightWidthMax 480 ressources/vma-seuil.pdf --out ressources/previews/vma-seuil-preview.jpg` (macOS).

### 8.6 Photos Saison 01

Alex doit déposer 8 photos dans `website_audit/photos_saison_01/`. **Avant le merge de la Phase 2**, déplace-les vers une location de production claire :

```bash
mkdir -p photos
mv website_audit/photos_saison_01/*.jpg photos/
# Puis update les <img src> dans le HTML pour pointer sur photos/01-hero.jpg etc.
```

Le dossier `website_audit/` peut rester dans le repo comme archive de référence, ou être déplacé dans une branche `audit-archive` si tu veux nettoyer la racine. À toi de voir avec Alex.

---

## 9. Si tu es bloqué

Hiérarchie de résolution :

1. **Re-lis le bloc concerné** dans `handover_dev.md` et vérifie la spec ;
2. **Re-regarde le mock** SVG correspondant dans `mocks/` ou via `viewer.html` ;
3. **Cherche un précédent** dans l'historique git (`git log --all --oneline | head -30`) — il y a déjà eu plusieurs itérations design ;
4. **Demande à Alex** sur le canal de comm habituel.

Si tu veux une décision design alternative (par exemple un picto différent, une couleur en plus, etc.), propose à Alex avec un screenshot de l'alternative — il tranche vite.

Bonne chance, et amuse-toi avec le projet. C'est un repo simple, propre, qui mérite sa nouvelle identité.

— *Alex (via Claude)*
