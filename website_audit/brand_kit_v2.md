# Mini brand kit — derapage.xyz V2

> **Direction validée :** B — *Crew Culture Street* (avec discrètes touches de C — *Vintage Parisien*).
> **Public visé :** membres DRC. Le site doit ressembler à un objet qu'on a envie de garder en favori.
> **Contrainte :** vanilla HTML/CSS sur GitHub Pages. Tout ce qui suit est livrable sans framework ni build.

---

## 1. Palette

### Couleurs primaires

| Token | Hex | Usage |
| --- | --- | --- |
| `--drc-cream` | `#F4F1EC` | Background de page (déjà en place) |
| `--drc-ink` | `#0D0D0D` | Texte principal, headlines (déjà en place) |
| `--drc-blue` | `#001EFF` | Couleur primaire — hero, CTA, accents, picto, lien actif |
| `--drc-blue-soft` | `#EEF0FF` | Background des états actifs, hover, surface secondaire |
| `--drc-white` | `#FFFFFF` | Cards, surface au-dessus du cream |

### Couleurs d'accent (parcimonie)

| Token | Hex | Usage |
| --- | --- | --- |
| `--drc-flare` | `#E84A33` | **Accent rare** — Pilier d'urgence, alert, prochain compte à rebours < 7 jours. Rouge dossard, hommage discret à la culture FFA. À utiliser comme un coup de feu, jamais comme couleur de surface. |
| `--drc-bone` | `#E6E0D3` | Variante de surface — séparateurs, contours subtils, fond de carte alternatif |
| `--drc-graphite` | `#5B5B5B` | Texte secondaire, captions, métadonnées |

### Règles d'usage

- **80 % cream + 15 % blue + 5 % ink** sur n'importe quelle vue. Toute couleur d'accent (flare) reste sous 1 % de la surface visible.
- Le `--drc-blue` doit toujours être *saturé pur* — jamais désaturé, jamais en gradient sauf sur le hero `PROCHAINE COURSE` (où le gradient existe déjà).
- Texte sur cream : `--drc-ink` (contraste OK).
- Texte sur blue : `--drc-white` toujours.
- Texte sur blue-soft : `--drc-blue` (état actif).

---

## 2. Typographie

### Familles

| Rôle | Famille | Poids utilisés | Source |
| --- | --- | --- | --- |
| **Display** | **Anton** | 400 (seul disponible) | Google Fonts (gratuit, license OFL) |
| **Sub-display** | **Bebas Neue** | 400 | Google Fonts |
| **Body** | **Inter** | 400, 500, 600, 700 | Google Fonts (déjà chargé) |
| **Mono / Accent** | **JetBrains Mono** | 400, 600 | Google Fonts |

**Import suggéré** (un seul `<link>` ou `@import` en haut du CSS) :

```html
<link href="https://fonts.googleapis.com/css2?family=Anton&family=Bebas+Neue&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
```

Total ~ 75 KB additionnel — acceptable sur GitHub Pages.

### Échelle modulaire (ratio 1.25 — *major third*)

| Token | Taille | Line-height | Famille | Usage |
| --- | --- | --- | --- | --- |
| `--display-xxl` | 96px | 88px | Anton | Compteur hero ("159 JOURS"), countdown |
| `--display-xl` | 64px | 60px | Anton | Titre de page ("CALENDRIER"), date-blocks majeurs |
| `--display-l` | 40px | 40px | Bebas Neue | Titres de section ("PROCHAINE COURSE", "SAISON 01") |
| `--display-m` | 28px | 32px | Bebas Neue | Sous-titres de section, noms de course en hero |
| `--text-xl` | 20px | 28px | Inter 600 | Titres de carte ("10K Tour Eiffel") |
| `--text-l` | 18px | 26px | Inter 500 | Sous-titres, intros de section |
| `--text-m` | 16px | 24px | Inter 400 | Body, descriptions |
| `--text-s` | 14px | 20px | Inter 500 | Métadonnées de carte, badges textuels |
| `--mono-m` | 14px | 20px | JetBrains Mono 400 | Dates, distances, allures, codes ("MAR · 20:15") |
| `--mono-s` | 12px | 16px | JetBrains Mono 600 | Tags, micro-labels, "EST. 2025 · PARIS · FFA" |

### Règles d'usage

- **Anton** est réservé aux *moments forts* : compteur hero, page titles, date-blocks géants. Jamais en body, jamais sur plus de 3-4 mots à la fois.
- **Bebas Neue** prend le relais pour les titres courants — section, sous-section.
- **Inter** reste la voiture de tous les jours (body, listes, descriptions).
- **JetBrains Mono** matérialise la *donnée* — chronos, dates, distances, métadonnées. C'est l'équivalent typographique du chrono manuel : précis, sec, lisible.
- Tracking sur display : `-0.02em` (légèrement serré, ne pas surjouer).
- Tracking sur mono accent (uppercase) : `+0.08em` (espacé, hommage typographie sportive).
- **Uppercase** sur Anton/Bebas Neue et sur les mono accents. **Casse normale** sur Inter.

### Exemple de pairing

```
SAISON 01           ← Bebas Neue, --display-l, uppercase, blue
Le club, en images   ← Inter Medium, --text-l, ink

24-25 OCT 2026      ← Anton, --display-xl, uppercase, ink
WEEKEND DE RENTRÉE  ← Bebas Neue, --display-m, uppercase, ink
Course à confirmer · vote en cours   ← Inter Regular, --text-m, graphite
21,1 KM             ← JetBrains Mono SemiBold, --mono-m, blue
```

---

## 3. Traitement photo

### Principe

Direction B veut une énergie *crew* — donc photos *vivantes*, *moments*, pas studio. Mais on garde une discipline éditoriale pour éviter le mood-board chaotique.

### Trois traitements autorisés (et un seul à la fois par surface)

**Traitement 1 — Couleur intégrale** (par défaut)
- Photo en couleurs naturelles.
- Léger boost contraste, blacks à 5 % (pas écrasés), blancs à 95 % (pas brûlés).
- Aucun filtre. Aucune dominance forcée.
- Format : utiliser le ratio natif du shoot. JPEG quality 80 suffit.
- **Usage :** grille « Saison 1 », photos de séance, courses.

**Traitement 2 — Duotone bleu** (hero, feature moments)
- Photo basculée en duotone `--drc-cream` (highlights) → `--drc-blue` (shadows).
- À utiliser sur 1 à 3 photos *signatures* par page, jamais en grille.
- **Usage :** photo unique en bandeau, ouverture de timeline saison 1.

**Traitement 3 — Noir et blanc + grain** (timeline, archive)
- Conversion N/B contrastée.
- Grain léger ajouté en overlay CSS (ou texture statique 30 % opacity).
- **Usage :** sections rétrospectives, hommages, archives saison 1.

### Crop & cadrage

- Privilégier les *cadres serrés* (visages, mouvement, détail) plutôt que les *plans larges* (paysage, groupe entier de loin).
- Format horizontal pour hero (16:9 ou 3:2).
- Format portrait (3:4) pour cartes en grille mosaïque.
- Carré (1:1) pour les vignettes timeline.

### Sources prioritaires (dans `07_Photos`)

1. `13_Shooting_Montmartre_Vincent / Photos Vincent retouchées` — premier choix pour duotone hero
2. `12_Shooting_Montmartre_Loïse` — photos posées, second choix hero
3. `08_Courses` — photos en course pour la timeline
4. `02_Entrainement` — photos de séance pour la grille Saison 1
5. `05_Events fun` + `11_Photos Soirée Noel` — moments de club, mosaïque
6. `09_Drift award` — moment iconographique de la saison

---

## 4. Système iconographique

> **Hypothèse mise à jour :** pas de graphiste dispo. On utilise des **SVG inline** (déjà dessinés dans `mocks/02_navigation.svg`) en baseline, et on garde une **piste génération IA** comme alternative si le dev veut tester d'autres styles.

### Pictos de navigation (4 SVG fournis, prêts à coller)

Tous en stroke linéaire, 1.5px, `currentColor` (héritent de la couleur CSS du parent → bleu si actif, ink sinon). Format 24×24 viewBox.

| Onglet | Picto fourni | Métaphore |
| --- | --- | --- |
| Saison 1 (ex-Instagram) | Polaroid + lentille | Mémoire, photo |
| Calendrier | Drapeau damier sur mât | Course, finish |
| Entrainement | Chronomètre + aiguille | Précision, piste |
| Ressources | Page pliée avec lignes | Doc, manuel |

Le code SVG complet de chaque picto est dans le document de handover (`handover_dev.md`), prêt à copier-coller dans le HTML.

### Pictos contextuels DRC (optionnel — pour personnaliser certaines courses ou sections)

Pas critiques pour la V1. À ajouter en V2 si tu veux pousser plus loin l'univers DRC.

| Picto | Usage |
| --- | --- |
| Montagne | Trail, Course folklore (Cantal) |
| Boule à facettes | Pinettes / soirée |
| Trace de dérapage | Logo en watermark / footer |
| Tour Eiffel stylisée | 10K Tour Eiffel |
| Basilique Montmartre | 10K Montmartre |
| Numéro de dossard | Tag « Pilier » premium |

**Génération via IA :** voir les prompts détaillés dans `handover_dev.md` section 8. Tools recommandés : ChatGPT (DALL-E 3 ou GPT image), Midjourney, ou plus simple — demander à Claude de générer le SVG directement avec un prompt comme :

> *"Génère un SVG 24x24 monolinéaire, stroke 1.5px, no fill, currentColor, représentant [SUJET]. Style : minimal, athletic, inspiration retro-running 2000s. Doit s'inscrire dans une viewBox 24x24 propre."*

---

## 5. Composants primitifs

### 5.1 Wordmark / header

```
DÉRAPAGE        ← Anton, --display-xl, uppercase, ink, tracking -0.02em
RUNNING CLUB    ← Anton, --display-m, uppercase, blue, tracking +0.08em
EST. 2025 · PARIS · FFA   ← JetBrains Mono SemiBold, --mono-s, graphite, uppercase
```

Le logo rond actuel (D blanc sur disque bleu) est conservé à gauche du wordmark.

### 5.2 Nav onglet

État par défaut :
- Picto SVG (24×24, stroke ink)
- Label en JetBrains Mono SemiBold uppercase `--mono-s` (ex: « SAISON 01 », « CALENDRIER », « ENTRAÎNEMENT », « RESSOURCES »)
- Padding 12px 16px

État actif :
- Picto et label en `--drc-blue`
- **Soulignement** 2px de `--drc-blue` en bas, animé (transition 200ms).
- Pas de background coloré, pas de pill (changement vs. existant).

### 5.3 Carte course

```
┌─────────────────────────────────────────────────┐
│  24-25       🏕 WEEKEND DE RENTRÉE              │
│  OCT         Course à confirmer · vote en cours │
│  2026        Deadline candidatures : 15 juin 26 │
│              [À CONFIRMER]                       │
└─────────────────────────────────────────────────┘
```

- Background `--drc-white`, radius 8px, border 1px `--drc-bone`.
- **Date-block gauche** : Anton uppercase, `--display-xl` pour le jour, `--mono-s` pour le mois et l'année.
- **Titre** : Bebas Neue `--display-m` uppercase.
- **Métadonnées** : Inter Regular `--text-m`, graphite.
- **Status pill** à droite : JetBrains Mono `--mono-s` uppercase, fond `--drc-blue-soft`, texte `--drc-blue`. Pour *CONFIRMÉE* : fond cream, texte ink, bordure 1px ink (différentiation discrète).
- Course pilier : border-left 4px `--drc-blue`.

### 5.4 Hero "Prochaine course"

- Fond gradient `--drc-blue` (`#001EFF` → `#0010C0` ou similaire, diagonal). À conserver.
- Motif damier en colonne droite (à conserver).
- Compteur jours : Anton `--display-xxl`, white, alignement droite.
- Label "PROCHAINE COURSE" : JetBrains Mono SemiBold `--mono-s`, uppercase, white avec 60% opacity.
- Titre course : Bebas Neue `--display-l` ou `--display-xl`, white, uppercase.
- Si compteur < 7 jours : passer le compteur en `--drc-flare` (`#E84A33`). C'est *l'unique* moment où le rouge apparaît.

### 5.5 Tag / badge

Trois variantes seulement :

- **Tag distance** (ex: "21.1 KM") : JetBrains Mono SemiBold `--mono-s`, fond `--drc-blue-soft`, texte `--drc-blue`, radius 4px, padding 2px 8px.
- **Tag catégorie** (ex: "PILIER") : Bebas Neue `--mono-s` taille, fond `--drc-blue` solid, texte white, radius 4px.
- **Tag métadonnée** (ex: "Réf. Trail du Haut-Cantal") : Inter Italic `--text-s`, graphite, sans fond, sans border. Discret.

### 5.6 Bouton

- **Primary** : Inter SemiBold uppercase tracking +0.05em, fond `--drc-blue`, texte white, padding 12px 24px, radius 4px. Hover : fond `--drc-ink`.
- **Secondary** : même typo, fond transparent, border 1.5px `--drc-blue`, texte `--drc-blue`. Hover : fond `--drc-blue-soft`.
- **Link** : Inter Medium underline, `--drc-blue`. Hover : `--drc-ink`.

### 5.7 Carte ressource (PDF)

```
┌──────────────────────────────────────┐
│ [aperçu page 1 PDF, 80×112px, blur]  │
│                                      │
│ VMA & SEUIL                          │
│ Allures de référence                 │
│ Maj : avril 2026                     │
│                                      │
│ [Ouvrir]   [Télécharger]             │
└──────────────────────────────────────┘
```

- Aperçu remplace le viewer noir actuel.
- Titre : Bebas Neue `--display-m`.
- Sous-titre + maj : Inter `--text-s`, graphite.

### 5.8 Footer

**Sans modification** par décision Alex. Conserver `EST. 2025 · PARIS · FFA` tel quel.

---

## 6. Voice & ton (court)

Le ton existe déjà — il est dans `whatsapp_history.md`. Trois règles à transposer sur le site :

1. **Tutoiement direct, chaleureux, énergique.** « Lisez bien ce message », « pensez à prendre », « à demain en pleine forme ». Le site doit parler comme Alex sur WhatsApp.
2. **Pas d'emoji décoratif dans le corps**, mais OK en *signature* (🔥 en fin de message, ⚠️ pour alert). Sur le site : zéro emoji dans la nav (remplacés par picto SVG), mais OK ponctuellement dans le contenu si justifié (le 🏕 du Weekend de Rentrée est OK).
3. **Une promesse par bloc.** Pas de « En savoir plus » mou. Si c'est un CTA, c'est explicite : « Ouvrir le PDF », « Voir le calendrier complet », « Postule pour le weekend ».

Headlines de section (Direction B, ton crew) — propositions :

- Saison 1 → **« LE CLUB, EN IMAGES »** ou **« SAISON 01 · L'ALBUM »**
- Calendrier → **« 2026—2027 EN COURSES »**
- Entrainement → **« 9 MOIS DE PISTE »** ou **« L'HISTORIQUE DES SÉANCES »**
- Ressources → **« DOCS UTILES »** ou **« LA BOÎTE À OUTILS »**

---

## 7. Récapitulatif tokens CSS

Bloc à coller en haut du `style.css` :

```css
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

  /* Échelle */
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
```

---

*Fin du brand kit. Les mocks SVG qui suivent appliquent strictement ces règles.*
