# Audit derapage.xyz — V1 (mai 2026)

> **À l'attention de :** Alexandre Saillard, directeur sportif DRC.
> **Auteur :** assistant IA (Claude), brief « Audit & refonte aesthetic derapage.xyz ».
> **Statut :** v1 — propositions de direction. Une seule direction est à valider avant que je produise les mocks SVG et la mini brand kit.
> **Public visé :** membres actuels DRC (~45). Le site doit les rendre fiers de la saison 1.
> **Contrainte technique :** HTML/CSS vanilla, GitHub Pages, pas de build, pas de framework, JS uniquement si vraiment nécessaire.

---

## 1. Synthèse exécutive

Le site **fonctionne très bien** : architecture claire (4 onglets), contenu utile (36 séances historisées, calendrier saison 26-27, deux PDFs ressources), bonne intuition graphique (cream + bleu électrique = la palette du t-shirt avant même que le brief existe). C'est déjà 70 % du chemin.

Ce qui manque, en revanche, est **l'identité** : le site est lisible mais anonyme. Rien dans la typographie, dans l'imagerie, dans le rythme visuel ne raconte que c'est *DRC, club parisien, saison 1, FFA, Pinettes, Cantal, Montmartre*. Un visiteur ne le devinerait pas. La promesse du brief t-shirt — *« style course à pied années 2000 », « DA street & urbaine », « illustration autour de la saison 1 »* — n'est pas portée par le site.

Trois constats opérationnels :

1. **L'onglet Instagram est un placeholder** (3 lignes + un lien). C'est l'opportunité la plus rapide à transformer en *vitrine* de l'identité visuelle.
2. **Aucune photographie n'apparaît sur le site**, alors que `07_Photos` contient 13 sous-dossiers, dont **deux shoots Montmartre professionnels** (Loïse + Vincent, avec versions retouchées). C'est un gisement d'image inexploité.
3. **Le mobile n'est pas pris en compte spécifiquement** : la navigation horizontale, les blocs de date à gauche, le `INTERNE` en haut à droite — tout est pensé desktop. Or les membres ouvrent ce site sur leur téléphone le mardi à 19 h avant la séance.

**Direction recommandée à valider :** je propose trois directions visuelles en section 6. Avant que je produise les mocks SVG et la mini brand kit, choisis-en une (ou un mix).

---

## 2. Vue d'ensemble — design tokens actuels

Ce que le site utilise déjà (extrait des styles calculés en live) :

| Token | Valeur actuelle | Lecture |
| --- | --- | --- |
| Background corps | `#F4F1EC` | Crème chaud — **bon**, déjà cohérent avec le brief t-shirt |
| Texte principal | `#0D0D0D` | Quasi-noir — neutre, lisible |
| Bleu primaire | `rgb(0, 30, 255)` ≈ `#001EFF` | Bleu électrique pur — **excellent** ; c'est *exactement* le bleu du brief t-shirt |
| Bleu pâle (nav active) | `#EEF0FF` | Bleu très clair, état actif |
| Police corps | `Inter, system-ui` | Sans-serif neutre — **point faible** : ne raconte rien |
| Rayon d'angle | `4px` (badges), `999px` (pills) | Mix classique |

**Bonne nouvelle :** la palette du site est déjà 90 % conforme au brief t-shirt (crème + bleu électrique monochrome). On ne refait pas la couleur — on l'utilise mieux.

**Mauvaise nouvelle :** la typographie Inter est l'option par défaut quand on ne fait pas de choix. Elle n'a pas la dimension *running années 2000*, *street*, *FFA* qui est dans le brief. C'est le levier #1 pour faire passer le site de « clean » à « DRC ».

---

## 3. Audit par section

Chaque recommandation est taguée **S / M / L** :
- **S** = changement CSS ou copie (< 2 h dev)
- **M** = composant à reconstruire / nouveau bloc (½ journée)
- **L** = nouveau pattern, contenu à produire en amont (1+ jour)

### 3.1 En-tête / identité globale

**État actuel** (capture desktop) :
- Logo rond bleu avec « D » blanc en haut à gauche
- « Dérapage Running Club » en gras + « Espace interne — saison 2025-2026 » en sous-titre gris
- Pill « 🔒INTERNE » bleu clair en haut à droite

**Ce qui marche :**
- Le logo rond est reconnaissable et joue déjà le rôle de signature visuelle.
- Le mot « Espace interne » pose immédiatement le cadre.

**Ce qui ne marche pas :**
- Le titre est dans la même police (Inter Bold) que tout le reste du site → aucune hiérarchie sensible.
- Le sous-titre « saison 2025-2026 » devrait évoluer chaque saison : c'est un détail à automatiser (variable CSS ou simple constante en haut du HTML).
- Le pill « INTERNE » est petit, fonctionnel mais purement informatif — c'est un emplacement précieux gâché.

**Recommandations :**
- **[M]** Adopter une **police d'affichage** (display) distincte pour le wordmark et les titres : quelque chose de condensé, à inspiration athlétique. Pistes gratuites Google Fonts : *Antonio*, *Oswald*, *Archivo Narrow*, *Anton*. Pour pousser plus *vintage 2000s*, regarder *Big Shoulders Display*, *Bebas Neue*, ou une police monospace pour l'accent (*JetBrains Mono*, *DM Mono*).
- **[S]** Augmenter le contraste typographique entre le wordmark (Display, gros, tracking serré) et le sous-titre (mono ou small caps, espacé).
- **[S]** Remplacer le pill « INTERNE » par une indication plus *DRC* — par exemple un mini compteur de la prochaine séance (« MAR · 20:15 · BERTRAND DAUVIN ») qui ferait écho à la fonction réelle du site (suivi de la semaine).

**Content gap :** aucun à ce stade.

---

### 3.2 Navigation

**État actuel :**
- 4 onglets : 📷 Instagram · 🏁 Calendrier Courses · 💪 Entrainement · 🍞 Ressources
- Style pill, onglet actif en bleu clair + texte bleu primaire
- Emojis en préfixe

**Ce qui marche :**
- 4 onglets, c'est le bon nombre. La structure est claire.
- L'état actif est lisible.

**Ce qui ne marche pas :**
- Les **emojis** font office d'iconographie. C'est rapide à mettre en place, mais ça date le site immédiatement (l'esthétique « emoji décoratif » est une convention 2015-2020, et rend chaque OS un peu différent — l'emoji 🍞 Ressources n'a aucun lien sémantique avec « livres/PDFs »).
- Le label « Calendrier Courses » est long et coupe le rythme par rapport aux trois autres labels (un mot chacun).
- Aucun design mobile : sur 390 px de large, les 4 onglets tiennent encore visuellement mais sans confort tactile (cibles trop petites, pas d'aération).

**Recommandations :**
- **[M]** Remplacer les emojis par des **pictos SVG monolinaires** dans le bleu primaire. 4 picto custom (caméra, drapeau damier, piste/chrono, livre/PDF) ou une lib open-source légère (Lucide, Heroicons, Tabler). Cohérent avec une DA running street.
- **[S]** Raccourcir « Calendrier Courses » en **« Calendrier »** (le contexte rend « courses » évident) → 4 labels d'un mot, rythme net.
- **[S]** Sur mobile : passer la nav en **scroll horizontal** avec snap, ou en tab bar fixe en bas façon app. Cibles tactiles min 44 px de haut.
- **[S]** Ajouter un *underline animé* sur l'onglet actif (1px de bleu primaire en bas) à la place du pill — plus *éditorial / track-side scoreboard*, moins *app generique*.

**Content gap :** 4 pictos SVG à dessiner (peut être confié au graphiste t-shirt ou récupéré en open-source).

---

### 3.3 Instagram — *la section à transformer en priorité*

**État actuel :**
- Titre `Instagram`
- 1 phrase : « Retrouvez l'actualité du club sur notre compte Instagram. »
- 1 lien : `@derapagerunningclub`
- C'est tout. La section fait 250 px de haut.

**Ce qui marche :** rien d'incorrect.

**Ce qui ne marche pas :**
- C'est l'onglet en première position dans la nav (donc le plus exposé) et c'est le plus vide. Asymétrie de valeur perçue.
- Un membre qui clique sur cet onglet *cherche du contenu visuel*. Lui donner un lien externe casse le flow.
- C'est l'endroit naturel pour matérialiser **la saison 1** — exactement la promesse du brief t-shirt.

**Recommandations :**

- **[M] — Option recommandée : grille Instagram-like statique.** Construire à la main une grille 3×N de visuels (extraits de `07_Photos`), avec légende courte (date + 1 phrase). Pas d'embed Instagram dynamique (lourd, JS lourd, contrôle limité). Juste des `<img>` + grille CSS. La grille « ressemble » à Instagram mais reste 100 % statique et rapide. **C'est la transformation #1 du site**.

- **[L] — Option étendue : timeline « Saison 1 ».** Au-dessus de la grille, une frise verticale ou horizontale des grands moments de la saison (Lancement août 25 → Marathon de Paris avril 27), avec photo + 2 lignes de copie + lien vers le post Insta. Permet de raconter l'histoire au-delà du fil chronologique Instagram. *C'est l'élément qui fait que le site « reflète l'esprit de la saison 1 ».*

- **[S]** Renommer l'onglet **« Le club »** ou **« Saison 1 »** plutôt qu'« Instagram » — l'Instagram n'est plus la cible mais une *source* parmi d'autres pour cette section.

- **[S]** Garder le lien `@derapagerunningclub` en footer de section, comme un appel à action discret (« Suis-nous au quotidien sur Instagram »).

**Content gaps à combler :**
- **Sélection curated de ~12-24 photos** parmi les 13 sous-dossiers de `07_Photos`. Mix : training, courses, soirée Noël, shoots Montmartre, Cantal.
- **Pour la timeline (option L) :** liste validée des moments forts de la saison 1 avec date, photo, et caption courte.

---

### 3.4 Calendrier Courses

**État actuel :**
- Bloc hero gradient bleu « PROCHAINE COURSE » avec compteur en jours (159 actuellement)
- Sous-titre : « Saison 2026-2027 · Les courses piliers sont mises en avant. »
- Liste de 8 courses avec date-block à gauche, titre + tags au milieu, status pill à droite
- Bordure bleue à gauche pour les courses *pilier*
- Footer : « EST. 2025 · PARIS · FFA »

**Ce qui marche :**
- Le bloc hero est **la meilleure pièce de design du site actuel** : compteur, drapeau damier, gradient bleu — c'est lisible, joyeux, et ça donne une raison de revenir.
- La distinction `Pilier` vs `À confirmer` vs `Confirmée` est claire.
- Le footer-séparateur `EST. 2025 · PARIS · FFA` est élégant.

**Ce qui ne marche pas :**
- Le compteur affiche 159 jours pour le *Weekend de Rentrée* (24-25 octobre 2026). Or **deux courses** sont *confirmées* (10K Tour Eiffel le 6 décembre) ou *piliers* avant ça. Le hero gagnerait à afficher la **prochaine course confirmée**, pas la prochaine course tout court. Le statut « À confirmer · vote en cours » du weekend de rentrée n'est pas le plus rassurant en hero.
- Le bloc hero répète l'item « Weekend de Rentrée » qui apparaît juste en dessous dans la liste → redondance verticale.
- L'item *Course folklore (Trail)* a un tag « Réf. Trail du Haut-Cantal » qui est utile mais perdu dans la même typographie que tout le reste — on dirait un autre tag.

**Recommandations :**
- **[S]** Logique hero : afficher la **prochaine course de statut `Confirmée`** par défaut. Si aucune n'est confirmée dans les 60 prochains jours, fallback sur la course `Pilier` la plus proche.
- **[S]** Si l'item du hero est déjà dans la liste, le **retirer de la liste** pour éviter la redondance, OU le surligner différemment dans la liste (par exemple un fond légèrement bleuté).
- **[M]** Ajouter une **vue calendrier annuelle** en complément de la liste, en haut de section : une frise horizontale Sept 26 → Juin 27 avec un point par course. Permet de voir la saison d'un coup d'œil. Peut rester très simple (12 colonnes mois × points colorés).
- **[S]** Différencier visuellement le tag « Pilier » (déjà bien fait, fond bleu plein) du tag « Réf. Trail du Haut-Cantal » qui est *métadonnée*, pas une catégorie. Style italique léger ou couleur grise.
- **[S]** Côté typo : passer les date-blocks à gauche (`24-25 OCT 2026`, `06 DÉC 2026`) en **police monospace ou en display condensée**. C'est l'endroit naturel pour un accent typographique fort.

**Content gap :** aucun — la donnée existe déjà dans `events/calendrier_courses_2026-2027.md`.

---

### 3.5 Entrainement

**État actuel :**
- 36 séances historisées depuis août 2025
- Champ « ⚡ Ma VMA » avec sauvegarde automatique (smart !) — quand renseigné, ajuste les durées affichées
- Barre de recherche
- Items collapsibles avec date pill + titre + lieu pin
- Quand ouvert : sections `GROUPE 1 / GROUPE 2`, chauffe / bloc principal / retour au calme

**Ce qui marche :**
- C'est **la section la plus fonctionnelle** du site et **la plus utile aux membres**. À garder telle quelle dans sa logique.
- Le champ VMA persistant est une vraie bonne idée, peu de clubs proposent ça.
- 36 séances → c'est déjà une archive substantielle.

**Ce qui ne marche pas :**
- Visuellement, c'est **une longue liste plate**. Aucun rythme. Aucun moyen de filtrer par type de séance (VMA / Seuil / Hors les murs).
- Le champ VMA est important fonctionnellement mais visuellement banal — il ne donne pas envie d'être rempli (ce qui réduit l'usage de la feature).
- Les libellés de séance répètent souvent les mêmes patterns (« VMA — », « Hybride — », « Hors les murs — ») : on pourrait les afficher en tag plutôt qu'en préfixe textuel.

**Recommandations :**
- **[M]** Ajouter des **chips de filtre** au-dessus de la liste : `Tout` · `VMA` · `Seuil` · `Hors les murs` · `Test`. Implémentable en pur CSS+JS minimal (data-attribute + filter).
- **[S]** Refactor des titres : retirer le préfixe (« VMA — », « Hybride — ») et l'afficher comme **tag** à côté du titre. Le titre devient plus court et plus singulier (« Pyramide en côtes », « 400/300/200 répétés »).
- **[S]** Mettre en valeur le champ VMA : encadré plus distinctif (mini-card avec accent bleu), micro-illustration ou pictogramme custom, et exemple par défaut (« ex: 17.5 ») dans le placeholder.
- **[M]** Pour les séances *Hors les murs*, ajouter un **mini-pictogramme contextuel** (montagne pour Cantal, arbre pour Vincennes, etc.) — appel direct aux motifs du t-shirt.
- **[L]** En tête de section, ajouter un **bandeau-stats saison 1** : « 36 séances · 9 mois d'entraînement · 2 stades · 3 sorties hors les murs » — appel direct à la « saison 1 » du brief.

**Content gap :** le bandeau-stats nécessite que les chiffres soient validés et mis à jour. Petite logique de comptage ou valeurs statiques.

---

### 3.6 Ressources

**État actuel :**
- 2 PDFs embarqués : *VMA & Seuil* et *Renfo du coureur & mobilité*
- Chaque card a : titre + sous-titre + boutons Ouvrir / Télécharger + viewer PDF inline

**Ce qui marche :**
- Le viewer PDF inline est sympa pour consulter rapidement.
- Les actions Ouvrir / Télécharger sont claires.

**Ce qui ne marche pas :**
- L'embed PDF charge un viewer noir avant la première interaction → la première impression de la section est *un grand rectangle noir*.
- Que **2 ressources** — la promesse « Ressources » fait attendre une bibliothèque, là c'est plutôt « 2 PDFs utiles ». Sémantiquement OK, mais le nom de l'onglet sur-promet.
- Pas de catégorisation, pas de date de dernière mise à jour.

**Recommandations :**
- **[S]** Remplacer le viewer inline (rectangle noir) par une **carte preview** : titre, sous-titre, mini-aperçu du PDF en image statique (capture 1ère page), date de dernière mise à jour, boutons Ouvrir/Télécharger. Beaucoup plus léger visuellement.
- **[M]** Préparer la section à accueillir d'autres ressources : organiser en **catégories** (`Entraînement`, `Renforcement`, `Compétition`, `Vie de club`) même si certaines sont vides. Signale la direction et l'intention.
- **[S]** Ajouter une ressource manquante évidente : le **lien vers le canal WhatsApp** (ou rappel des consignes), le **calendrier ICS** des séances, le **règlement intérieur / charte du club**. Toutes les choses qu'un nouveau membre cherche.

**Content gaps :**
- Capture première page des deux PDFs existants.
- Idéalement, 1-2 ressources supplémentaires à produire (charte, ICS, FAQ nouveau membre).

---

### 3.7 Footer

**État actuel :**
- Séparateur centré « ─── EST. 2025 · PARIS · FFA ─── » en bleu, lettre-spacing, monospace-ish
- Ligne en dessous : « Dérapage Running Club · Usage interne uniquement · @derapage_rc »

**Ce qui marche :**
- Le séparateur est l'un des moments graphiquement les plus identitaires du site. À conserver, c'est un actif.

**Ce qui ne marche pas :**
- Beaucoup de blanc en dessous (la page se termine de façon abrupte).
- Pas de signal de qui maintient ce site, pas de mention « Made with 🩵 by … », pas de lien vers le contact du bureau.

**Recommandations :**
- **[S]** Conserver le séparateur `EST. 2025 · PARIS · FFA` tel quel, voire le pousser visuellement (police plus marquée, alignement parfait).
- **[S]** Ajouter sous la ligne actuelle un **mini bloc « le bureau »** ou simplement « Une question ? Écris à [contact] ».
- **[S]** Pied final : signature discrète « Saison 1 · 2025-2026 · Made by le bureau DRC ».
- **[M]** Inclure les logos partenaires (Pinettes ? FFA ?) en petit, si pertinent.

**Content gap :** aucun bloquant.

---

### 3.8 Expérience mobile

**État actuel :** le site ne semble pas avoir de **media queries mobiles** déclarées (le layout reste identique en redimensionnant). Or les membres consultent ce site **majoritairement sur téléphone** (mardi soir, transports, etc.).

**Recommandations :**
- **[M]** Ajouter une feuille de breakpoints simple : `< 600px` (mobile), `600-900` (tablette), `> 900` (desktop).
- **[M]** Mobile, prio absolue :
  - Nav en scroll horizontal ou tab bar fixe basse.
  - Hero `PROCHAINE COURSE` qui se réduit en empilement (icône + titre + compteur sur 3 lignes).
  - Items séance / course : date pill au-dessus du titre, pas à côté.
  - Boutons et liens : cible tactile minimum 44 × 44 px.
- **[S]** Test sur iPhone SE (375 px) et Pixel 7 (412 px) — les deux extrêmes courants.

**Content gap :** aucun.

---

## 4. Tableau récapitulatif des recommandations

| Section | Action clé | Difficulté |
| --- | --- | --- |
| En-tête | Adopter une police display + accent typo | M |
| En-tête | Pill « INTERNE » → indicateur prochaine séance | S |
| Nav | Remplacer emojis par pictos SVG | M |
| Nav | Mobile : scroll horizontal ou tab bar | S |
| Instagram | Grille 3×N statique tirée de `07_Photos` | M |
| Instagram | Timeline Saison 1 | L |
| Instagram | Renommer l'onglet « Saison 1 » ou « Le club » | S |
| Calendrier | Hero = prochaine course **confirmée** | S |
| Calendrier | Frise calendrier annuelle | M |
| Calendrier | Typo display sur les date-blocks | S |
| Entrainement | Filtres par type de séance | M |
| Entrainement | Titre nettoyé + tags | S |
| Entrainement | Bandeau stats saison 1 | L |
| Ressources | Cartes avec preview au lieu de viewer noir | S |
| Ressources | Catégoriser + élargir | M |
| Footer | Bloc bureau + contact | S |
| Mobile | Breakpoints + nav mobile | M |
| Global | Système typographique cohérent | M |
| Global | Pictos custom DRC (track, Pinettes, montagne…) | L |

**Quick wins (S, < 2 h chacun) :** typo des date-blocks, hero = prochaine confirmée, label « Calendrier » au lieu de « Calendrier Courses », ressources en cartes preview, footer bureau, underline animé nav.

**Investissements moyens (M, ½ journée chacun) :** pictos SVG nav, grille Instagram, filtres entraînement, breakpoints mobile, frise calendrier annuelle.

**Gros chantiers (L) :** timeline saison 1, bandeau stats, pictos custom DRC (montagne, Pinettes, piste, drift trace) — ce sont eux qui font passer du site « élégant » au site « *signé DRC* ».

---

## 5. Content gaps à combler avant / pendant le build

| Asset manquant | Pour quelle section | Qui peut produire |
| --- | --- | --- |
| Sélection curated 12-24 photos saison 1 | Instagram (grille) | Alex + bureau, depuis `07_Photos` (privilégier shoots Montmartre Vincent / Loïse retouchées) |
| Liste validée des moments forts saison 1 (date · photo · caption) | Instagram (timeline option L) | Alex |
| 4 pictos SVG nav (caméra ou play, drapeau damier, piste/chrono, livre/PDF) | Navigation | Graphiste t-shirt (cohérent) ou Lucide open-source |
| Pictos contextuels DRC (montagne Cantal, Pinettes, Vincennes…) | Entrainement (hors les murs) + accents globaux | Graphiste t-shirt — c'est *exactement* ce qu'il dessine déjà |
| Capture première page des 2 PDFs ressources | Ressources (cartes preview) | Alex (capture d'écran) |
| Charte / règlement intérieur en PDF | Ressources | Bureau |
| Calendrier ICS des séances | Ressources | Auto-généré depuis les données |
| Texte stats saison 1 (36 séances, X membres, X courses…) | Entrainement (bandeau) + Instagram (timeline) | Alex |
| Contact bureau (mail / lien WhatsApp d'aide) | Footer | Alex |

---

## 6. Trois directions visuelles à comparer

Toutes partent du brief t-shirt : **crème + bleu électrique monochrome**, illustration street/urbaine, *saison 1*. Elles divergent dans le ton typographique et la densité de l'imagerie. Choisis-en une (ou un mix) et je produis les mocks SVG + brand kit contre cette direction.

### Direction A — *Track & Field éditorial* (éditorial / premium-leaning)

**Référence visuelle :** Tracksmith, Bandit Running, District Vision, Soar Running.

**Ton :** sobriété éditoriale, place très importante à la photographie noir & blanc ou virée bleu/crème, typographie display sérifée ou condensée à l'ancienne. Le site ressemble à un *magazine de course* plus qu'à une app.

**Typo proposée :**
- Display : *Söhne Breit*, *GT America Condensed*, ou (en gratuit) **Big Shoulders Display** / **Antonio**.
- Corps : *Inter* (gardé) ou bascule sur **Söhne** / **Söhne Mono**.
- Accent : monospace pour les data points (date-blocks, distances, allures) — **JetBrains Mono** ou **DM Mono**.

**Force :** très chic, vieillit bien, valorise les photos pro (les deux shoots Montmartre y trouvent leur écrin idéal).
**Risque :** peut paraître *froid* ou *trop sérieux* — manque l'énergie « street fun » du brief t-shirt.
**Quand la choisir :** si tu veux que le site projette *l'ambition sportive* du club avant tout.

---

### Direction B — *Crew Culture Street* (community / crew-leaning)

**Référence visuelle :** Bridge Runners (NYC), Track Mafia (Londres), NSC, Patta Running Team, Distance Athletics.

**Ton :** énergie *crew*, typographie street display, accents graphiques bold, collages photo, motifs typographiques (DRC, EST. 2025, dossards), arrangement plus libre, plus de couleur d'accent. Le site est *l'extension digitale du t-shirt et du shooting Drift Award*.

**Typo proposée :**
- Display : police forte, condensée, presque varsity / lettering athlétique → **Anton**, **Bebas Neue**, **Big Shoulders Stencil**, ou si payant **Druk Wide**.
- Corps : **Inter** (gardé) ou **Söhne**.
- Accent : police *bitmap-ish* ou monospace pour les chronos et data → **VT323**, **JetBrains Mono**.

**Force :** colle pile au brief t-shirt (« style course à pied années 2000 », « DA street & urbaine »), donne le sentiment d'appartenance recherché. Le site, les sweats, l'Instagram et le t-shirt parlent la même langue.
**Risque :** peut vieillir plus vite si la mode street running évolue. Le rendu dépend beaucoup de la qualité des illustrations (donc du graphiste t-shirt).
**Quand la choisir :** si l'objectif est *rendre les membres fiers et que la saison 1 soit immortalisée sur le site* — c'est ma recommandation par défaut au vu du brief.

---

### Direction C — *Athlétisme Vintage Parisien* (Paris-rooted)

**Référence visuelle :** la Montgolfière (cité en brief), Patta x Paris collabs, les visuels FFA des années 80-2000, les vieux dossards de la Course du Patrimoine, l'iconographie Stade Charléty / La Cipale.

**Ton :** *running des années 90-2000 en France*. Couleurs : crème, bleu FFA, accent rouge ponctuel. Typo : grasses condensées, italique sportive, lettrages tracés à la main, numéros de dossard, drapeaux damiers, tracés de piste. Beaucoup de motifs graphiques (vignettes, séparateurs, médailles fictives).

**Typo proposée :**
- Display : police *condensée italique sportive* → **Saira Condensed**, **Barlow Condensed Italic**, **Oswald Italic**.
- Corps : **Inter** (gardé).
- Accent : numéros style dossard → **Antonio Black** ou **Big Shoulders Display Black**.

**Force :** très distinctif, ancrage parisien lisible, raconte l'idée *FFA, club affilié, héritage*. Très peu de clubs digital-native parisiens ont cette direction.
**Risque :** peut tomber dans le pastiche si surjoué. Exige discipline graphique.
**Quand la choisir :** si tu veux différencier DRC des autres crews parisiens en jouant la carte *club affilié, école française d'athlé*, plus que *crew international*.

---

### Tableau récap des directions

| | A. Éditorial | B. Crew Street | C. Vintage FFA |
| --- | --- | --- | --- |
| Énergie | Posée, premium | Bold, chaleureuse | Référencée, sportive |
| Compatibilité brief t-shirt | Bonne | **Excellente** | Très bonne |
| Place de la photo | Centrale, pro | Mixée avec graphisme | Secondaire |
| Place de l'illustration | Discrète | **Centrale** | Centrale (motifs) |
| Risque de vieillir | Faible | Moyen | Moyen |
| Effort dev | Moyen | Moyen-fort | Moyen-fort |
| Recommandation | Si focus = ambition | **Par défaut (vu brief)** | Si focus = singularité parisienne |

---

## 7. Prochaines étapes

1. **Toi (Alex) :**
   - Choisis une direction (A / B / C ou un mix précis).
   - Confirme la liste des content gaps que tu peux fournir vs ceux à commissionner.
   - Indique le périmètre du V1 (toutes les recos, ou seulement les *quick wins* + la direction visuelle).

2. **Moi (en V2 du livrable, après ton retour) :**
   - Mocks SVG : homepage hero, nav redesigned, une section content redesigned, vue mobile.
   - Mini brand kit : palette finale, système typographique, traitement photo, composants, voice notes — assez pour que le dev front étende le redesign aux sections non mockées.
   - Optionnel : un fichier HTML/CSS *design comp* unique que le dev peut ouvrir comme référence vivante.

3. **Front-end dev (après V2) :**
   - Implémenter les *quick wins* en parallèle pendant que la direction visuelle se finalise (ils sont indépendants).
   - Puis appliquer le redesign visuel à partir des mocks et de la brand kit.

---

*Fin du document. Prêt à recevoir tes retours pour passer en V2.*
