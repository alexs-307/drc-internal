-- =============================================================================
-- 0002_seed_initial_data.sql
-- DRC Internal — seed initial public-content data
-- Tables seeded: resources (2 rows), races (8 rows), sessions (36 rows)
-- One-shot seed — do not re-run (no idempotency guard; re-running creates
-- duplicate rows).
-- =============================================================================


-- ----------------------------------------------------------------------------
-- Resources (2 rows)
-- Titles and descriptions copied verbatim from index.html .resource-body
-- blocks (lines 1559–1573). Placeholder card ("Règlement intérieur") is NOT
-- seeded — no PDF exists yet.
-- ----------------------------------------------------------------------------
INSERT INTO public.resources (title, description, pdf_path, preview_path, display_order) VALUES
  (
    'VMA & Seuil',
    'Allures de référence · Mise à jour : avril 2026',
    'ressources/vma_seuil.pdf',
    'ressources/vma_seuil_preview.png',
    10
  ),
  (
    'Renfo du coureur & mobilité',
    'Renforcement & exercices de mobilité · Mise à jour : mars 2026',
    'ressources/renfo_du_coureur.pdf',
    'ressources/renfo_du_coureur_preview.png',
    20
  );


-- ----------------------------------------------------------------------------
-- Races (8 rows)
-- Source: races[] JS array literal in index.html starting at line 1650.
-- Mapping:
--   approx: false  →  date = dateStr::date,  date_label = NULL
--   approx: true   →  date = NULL,            date_label = approxText
-- Emoji stripped from `name` per cleanName() in the JS (⭐, 🏕).
-- `url` is always NULL — no race links exist in the source data.
-- ----------------------------------------------------------------------------
INSERT INTO public.races (name, type, date, date_label, pillar, confirmed, note, url) VALUES
  (
    'Weekend de Rentrée DRC',
    'Weekend long · vote en cours',
    '2026-10-24',
    NULL,
    false,
    false,
    'Deadline candidatures : 15 juin 2026',
    NULL
  ),
  (
    'Semi-marathon de Boulogne',
    '21.1km',
    NULL,
    'Mi-novembre 2026',
    true,
    false,
    NULL,
    NULL
  ),
  (
    '10K Tour Eiffel',
    '10km',
    '2026-12-06',
    NULL,
    false,
    true,
    NULL,
    NULL
  ),
  (
    '10K de Montmartre',
    '10km',
    NULL,
    'Mi-janvier 2027',
    false,
    false,
    NULL,
    NULL
  ),
  (
    'Course folklore (Trail)',
    'Trail · à confirmer',
    NULL,
    'Fév–Mars 2027',
    false,
    false,
    'Réf. Trail du Haut-Cantal',
    NULL
  ),
  (
    'Semi-marathon de Paris',
    '21.1km',
    NULL,
    'Début mars 2027',
    true,
    false,
    NULL,
    NULL
  ),
  (
    'Marathon de Paris',
    '42.2km',
    NULL,
    'Mi-avril 2027',
    true,
    false,
    NULL,
    NULL
  ),
  (
    'Course de clôture de saison',
    '~10km',
    NULL,
    'Mai–Juin 2027',
    false,
    false,
    NULL,
    NULL
  );


-- ----------------------------------------------------------------------------
-- Sessions (36 rows, most recent first — matches sessions.json order)
-- Dollar-quoted strings preserve newlines and apostrophes without escaping.
-- g3 and suggestion are NULL where sessions.json has null.
-- ----------------------------------------------------------------------------
INSERT INTO public.sessions (date, label, venue, g12, g3, suggestion) VALUES
  (
    '2026-05-19',
    'Hors les murs — Pyramide en côtes (Vincennes)',
    'Métro Château de Vincennes',
    $txt$Chauffe : 20' footing ensemble (jusqu'à la zone de travail) · 15' gammes en côtes

Bloc principal — 2 blocs de :
100m à 110% VMA / 200m à 100% VMA / 300m à 100% VMA / 200m à 100% VMA / 100m à 110% VMA
Récup : 100m en trottinant entre chaque effort / Récup bloc : 4'

Retour au métro — G1/G2 : 3 × 3' allure 90% VMA / Récup 1'30$txt$,
    $txt$Chauffe identique

Bloc principal — 2 blocs de :
100m à 110% VMA / 200m à 100% VMA / 300m à 100% VMA / 200m à 100% VMA / 100m à 110% VMA
Récup : 100m en trottinant entre chaque effort / Récup bloc : 4'

Retour en footing ensemble$txt$,
    $txt$20' de footing
Travail tempo 10K : 1k / 2k / 1k / 2k à 90% VMA — Récup 2'30 entre les blocs$txt$
  ),
  (
    '2026-05-12',
    'Test VMA — Clôture de cycle',
    'Bertrand Dauvin',
    $txt$Chauffe (~20')
Test VMA sur piste : évaluation des progrès du cycle
Retour au calme : footing léger + récupération ensemble$txt$,
    NULL,
    $txt$Footing continu avec variation 12k
3k EF // 3k 80% VMA // 3k 90% VMA // 3k EF$txt$
  ),
  (
    '2026-05-05',
    'Progressivité d''allure — Tempo → VMA',
    'Bertrand Dauvin',
    $txt$Chauffe : 20' EF · 15' gammes · 2 lignes droites

Bloc principal :
3 × (900m à 80% VMA / 600m à 90% VMA / 300m à 100% VMA)
r = 2' entre les courses · R = 3' entre les séries

Retour au calme : 5' jog léger$txt$,
    $txt$Chauffe identique

Bloc principal :
2 séries seulement (au lieu de 3)
3 × (900m à 80% VMA / 600m à 90% VMA / 300m à 100% VMA)

Retour au calme : 5' jog léger$txt$,
    NULL
  ),
  (
    '2026-04-28',
    'Séance hybride VMA — Test chaussures ACT',
    'Bertrand Dauvin',
    $txt$Chauffe : 15' footing · 10' gammes · 2 lignes droites 100m

Bloc 1 – Chaussures perso :
5 × 1' à VMA / 1' EF — Récup 5'

Bloc 2 – Chaussures ACT :
2 × 3' à 80-85% VMA (r = 1'30 EF) — Récup 5'

Bloc 3 – Chaussures ACT (si sensations OK) :
5 × 1' à VMA / 1' EF$txt$,
    $txt$Idem G1/G2 mais Bloc 1 = 4 × 1' à VMA / 1' EF$txt$,
    $txt$20' footing progressif
Accélérations progressives
3 × 2k Allure 10K r = 1'30"$txt$
  ),
  (
    '2026-04-21',
    'Cycle VMA — Résistance + relance',
    'Bertrand Dauvin',
    $txt$Chauffe : 20' EF · 15' gammes · 2 lignes droites

Format VMA G1/G2 — Bloc principal :
4 blocs de : 500m à 95% VMA / 400m à 100% VMA / 300m à 100% VMA
r = 1'15 entre répétitions · recup bloc = 4'

➡ Résistance + relance, intensité croissante$txt$,
    $txt$Chauffe identique

Format VMA G3 — Bloc principal :
3 blocs de : 500m à 95% VMA / 400m à 100% VMA / 300m à 100% VMA
r = 1'15 · recup bloc = 4'

(+ Format récup marathon dispo pour les marathoniens de retour)$txt$,
    $txt$20' de footing progressif · Accélérations
3 × 1' Vite 100% VMA / 1' Lent (EF) · Récup 2'
12' Tempo Allure 10k (~90% VMA) · Récup 2'
3 × 1' vite (à VMA) / 1' lent (EF)$txt$
  ),
  (
    '2026-04-14',
    'Cycle VMA — 400m répétés',
    'Bertrand Dauvin',
    $txt$Chauffe : 20' EF · 15' gammes · 2 lignes droites

Bloc principal :
2 blocs : (6 × 400m à 100% VMA | r = 1')
r bloc = 4' · (12 × 400m au total)

➡ VMA sur distances intermédiaires, volume conséquent$txt$,
    $txt$Chauffe identique

Bloc principal :
2 blocs : (4 × 400m à 100% VMA | r = 1')
r bloc = 4' · (8 × 400m au total)

(+ Format récup post-marathon disponible)$txt$,
    $txt$20' de footing progressif
Accélérations brèves de 20" dans l'allure cible
3 × 6' allure 90% VMA (recup 3' EF)$txt$
  ),
  (
    '2026-04-07',
    'Cycle VMA — Variations 300/200',
    'Bertrand Dauvin',
    $txt$Chauffe : 20' EF · 15' gammes · 2 lignes droites

Bloc principal (4k de travail) :
300/200/300/200 | r = 1' | à 100% VMA · recup bloc = 3'
200/300/200/300 | r = 1' | à 100% VMA · recup bloc = 3'
200/300/200/300 | r = 1' | à 100% VMA · recup bloc = 3'
200/300/200/300 | r = 1' | à 100% VMA$txt$,
    $txt$Chauffe identique

Bloc principal (3k de travail) :
300/200/300/200 | r = 1' | à 100% VMA · recup bloc = 3'
200/300/200/300 | r = 1' | à 100% VMA · recup bloc = 3'
200/300/200/300 | r = 1' | à 100% VMA$txt$,
    $txt$20' de footing progressif · Accélérations
3 × 2' à 90% VMA | r = 1'
3 × 4' à 80% VMA | r = 1'30
3 × 2' à 90% VMA | r = 1'$txt$
  ),
  (
    '2026-03-31',
    'Cycle VMA — Ouverture · 300m répétés',
    'Bertrand Dauvin',
    $txt$Chauffe : 20' EF · 15' gammes · 2 lignes droites

Bloc principal (format standard) :
2 blocs : 7 × 300m à 100% VMA | recup = 45''
recup entre blocs = 3'30 en footing EF
Au total : 14 × 300m$txt$,
    $txt$Chauffe identique

Bloc principal (option légère) :
2 blocs : 5 × 300m à 100% VMA | recup = 45''
recup entre blocs = 3'30 en footing EF
Au total : 10 × 300m

(+ Format marathon spé : 4 × 2000m allure marathon r = 2')$txt$,
    $txt$20' de footing progressif · 2-3 lignes droites
4 blocs de 4' à 90% VMA | récup 2' en trottinant$txt$
  ),
  (
    '2026-03-24',
    'Hybride SV2 haute → VMA',
    'Bertrand Dauvin',
    $txt$Chauffe : 20' EF · 15' gammes · 2 lignes droites

Bloc principal G1/G2 :
2 blocs : 2 × 800m à 90% VMA | r = 1'30
           2 × 400m à 100% VMA | r = 1'15
R = 3'30 entre blocs$txt$,
    $txt$Chauffe identique

Bloc principal G3 :
2 blocs : 2 × 800m à 90% VMA | r = 1'30
           1 × 400m à 100% VMA | r = 1'15
R = 3'30 entre blocs

(+ Format marathon : 3 × (1500m allure marathon / r = 1' / 900m allure semi))$txt$,
    NULL
  ),
  (
    '2026-03-17',
    'Hybride seuil → VMA (multi-formats)',
    'Bertrand Dauvin',
    $txt$Format hybride standard G1/G2 :
Chauffe : 20' EF · 15' gammes · 2 lignes droites

Bloc principal :
3 × 1km à 90% VMA | r = 1'30 · recup bloc = 3'
4 × 400m à 100% VMA | r = 1'15$txt$,
    $txt$Format hybride léger G3 :
Chauffe identique

Bloc principal :
2 × 1km à 90% VMA | r = 1'30 · recup bloc = 3'
3 × 400m à 100% VMA | r = 1'15

(+ Format marathon : 10 × 800m allure semi r = 1'30)$txt$,
    NULL
  ),
  (
    '2026-03-10',
    'Multi-format : récup semi + marathon + piste + renfo',
    'Bertrand Dauvin',
    $txt$Format piste G1/G2 (volume ~4300m) :
Chauffe : 15' footing + 10' gammes
3 × 900m à 90% VMA | r = 1'30 · recup bloc = 3'
8 × 200m à 100-110% VMA | récup 100m en trottinant

+ 20' renforcement musculaire en fin de séance (Valentino & Bastien kiné)$txt$,
    $txt$Format piste G3 (volume ~3000m) :
Chauffe identique
2 × 900m à 90% VMA | r = 1'30 · recup bloc = 3'
6 × 200m à 100-110% VMA | récup 100m en trottinant

(+ Format récup semi et format marathon spé disponibles)
+ 20' renforcement musculaire pour tous$txt$,
    NULL
  ),
  (
    '2026-03-03',
    'Rappel allures semi + hybride seuil/VMA',
    'Bertrand Dauvin',
    $txt$Chauffe : 20' EF · Gammes · 2 lignes droites

Format hybride :
2km à 90% VMA r = 2'30"
(8 × 300m à VMA | récup 100m en trottinant) r = 2'30"
1km à 90% VMA$txt$,
    $txt$Chauffe identique

Format hybride léger :
1km à 90% VMA r = 2'30"
(8 × 300m à VMA | récup 100m en trottinant) r = 2'30"
1km à 90% VMA

(Format allures semi réservé aux coureurs du semi de Paris)$txt$,
    NULL
  ),
  (
    '2026-02-24',
    'Hybride : allure semi + explosif',
    'Bertrand Dauvin',
    $txt$Chauffe : 20' footing · 10' gammes · 2 lignes droites

Option G1/G2 :
1500m allure semi (80-85% VMA) | r = 2'30"
4 × 600m allure 10k (~90% VMA) | r = 1'20
1500m allure semi (80-85% VMA)$txt$,
    $txt$Chauffe identique

Option G3 :
1500m allure semi (80-85% VMA) | r = 2'30"
4 × 400m allure 10k (~90% VMA) | r = 1'20
1500m allure semi (80-85% VMA)

(Groupe récup trailers : 2 × (6 × 100m lignes droites) + footing)$txt$,
    NULL
  ),
  (
    '2026-02-17',
    'Répétition d''allures — Seuil',
    'Bertrand Dauvin',
    $txt$Chauffe : 20' footing · 15' gammes · 2 accélérations

Bloc principal G1/G2 :
3 × 8' allure semi (80-85% VMA) / récup = 2'

Retour au calme : 5' jog léger$txt$,
    $txt$Chauffe identique

Bloc principal G3 :
3 × 6' allure semi (80-85% VMA) / récup = 2'

Retour au calme : 5' jog léger$txt$,
    NULL
  ),
  (
    '2026-02-10',
    'Séance d''allures — Régulateur de vitesse',
    'Bertrand Dauvin',
    $txt$Chauffe : 20' footing · 15' gammes · 2 lignes droites

Bloc principal G1/G2 :
3 × (500m allure 10k ~90% VMA / r = 1'20 / 1500m allure semi ~80% VMA / r = 2')$txt$,
    $txt$Chauffe identique

Bloc principal G3 :
2 × (500m allure 10k ~90% VMA / r = 1'20 / 1500m allure semi ~80% VMA / r = 2')$txt$,
    NULL
  ),
  (
    '2026-02-03',
    'Côtes + SV2 basse',
    'Max Roussie',
    $txt$Chauffe : 20' EF · 15' gammes (en côte) · 2 accélérations

Bloc principal option 1 :
2 blocs complets de (8 × 100m côte à 110-120% VMA + 6' à SV2 basse ~80-85% VMA)
Récup 4' entre chaque bloc$txt$,
    $txt$Chauffe identique

Bloc principal option 2 (légère) :
2 blocs complets de (8 × 70m côte à 110-120% VMA + 6' à ~80% VMA)
Récup 4' entre chaque bloc$txt$,
    NULL
  ),
  (
    '2026-01-27',
    'VMA — 400/300/200 répétés',
    'Max Roussie',
    $txt$Chauffe : 20' EF · 15' gammes · 2 lignes droites

Bloc principal :
4 × (400m / 300m / 200m)
Récup de 1' entre chaque course · 3'30 entre chaque bloc
Allures : 400m à 100% VMA · 300m à 110% VMA · 200m à 110-120% VMA$txt$,
    NULL,
    NULL
  ),
  (
    '2026-01-20',
    'Séance light + renforcement musculaire',
    'Max Roussie',
    $txt$Chauffe : 20' EF · 20' gammes

Bloc principal :
8 × 1' entre 85 et 90% VMA (recup = 1' EF très cool)

Initiation renforcement musculaire :
3 ateliers de 8' chacun (animés par les experts du club)$txt$,
    NULL,
    NULL
  ),
  (
    '2026-01-13',
    'Rappel allures — Avant 10K Montmartre',
    'Max Roussie',
    $txt$Chauffe : 20' EF · 15-20' gammes · 2 accélérations

Bloc principal :
2 × 200m à 110% VMA | récupération complète 1'
6 × 500m à allure 10k / 90% VMA | récup complète (temps effort = temps récup)

Option plus facile : 5 × 500m$txt$,
    NULL,
    NULL
  ),
  (
    '2026-01-06',
    'Retour de trêve — Seuil 6 × 4''',
    'Max Roussie',
    $txt$Chauffe : 20' footing · 15' gammes

Bloc principal :
6 × 4' de seuil (1er au 3ème : 85% VMA / 4ème au 6ème : 90% VMA)
Récup 1'30

Option plus facile : 4 ou 5 blocs$txt$,
    NULL,
    NULL
  ),
  (
    '2025-12-16',
    'Dernière séance 2025 — Cadeau de Noël (VP)',
    'Max Roussie',
    $txt$Chauffe : 20' footing · 15' gammes

Bloc principal :
3 × (1000m à 90% VMA / r = 2' / 400m à 100% VMA)
Récup 3' entre chaque bloc

Retour au calme : 5' jog léger$txt$,
    NULL,
    NULL
  ),
  (
    '2025-12-09',
    'Rappel de puissance — 400m',
    'Max Roussie',
    $txt$Pour tous : 20' footing · 15' gammes

Bloc principal (hors récup) :
12 × 400m à 100% VMA (r = 100m en trottinant)
Retour au calme : 5' jog léger$txt$,
    $txt$Groupe récup (coureurs du weekend) :
4 × 4' r = 2' en EF footing cool (~75-80% VMA max)
2-4 lignes droites 100m / 100m marche$txt$,
    NULL
  ),
  (
    '2025-12-02',
    'Hybride 400/800/400',
    'Max Roussie',
    $txt$Chauffe : 20' footing (15' chill + 5' rapide) · 20' gammes/travail de pieds

Bloc principal :
3 × (400m / 800m / 400m)
Récup : 45" après 400m · 1'15 après 800m (récup active)
Allure 800m : 90% VMA · Allure 400m : 100% VMA
⚠ Pas de bloc de récup entre les séquences, ça s'enchaîne$txt$,
    NULL,
    NULL
  ),
  (
    '2025-11-25',
    'Séance mixte à intensité variable',
    'Max Roussie',
    $txt$Chauffe : 20' footing · 15' gammes

Bloc principal :
6' à 80% VMA · r = 1'
2 × 4' à 90% VMA · r = 2'
3 × 1'30 à 95-100% VMA · r = 1'30
6' à 80% VMA$txt$,
    NULL,
    NULL
  ),
  (
    '2025-11-18',
    'Récup + 2 × (6 × 400m VMA) + rattrapage test',
    'Max Roussie',
    $txt$Chauffe : 20' footing cool · Gammes

Bloc principal :
2 × (6 × 400m récup 45") | Bloc récup 5' entre les deux séries
Allure → VMA sur les 400

Séance récup (coureurs du weekend) :
2 × (6 × 100m lignes droites sur pelouse) / 100m marche entre chaque

Rattrapage test VMA possible : 2 × 3' avec 15' récup entre les 2$txt$,
    NULL,
    NULL
  ),
  (
    '2025-11-11',
    'Hors les murs — Forêt de Vincennes',
    'Métro Château de Vincennes',
    $txt$RDV : 11h00 au terminus Ligne 1 — Château de Vincennes

Chauffe : 20' EF depuis l'arrêt de métro vers le Polygone
Gammes : 10-15'

Bloc principal (tous) :
3 × 1000m allure 10k (85-90% VMA) · récup 3' / récup bloc 4'
5 × 30'' à la sensation (max 95% VMA, sous forme de lignes droites)

Format semi :
6 × 4' allure semi · récup 2'$txt$,
    NULL,
    NULL
  ),
  (
    '2025-11-04',
    'VMA 5 × 3'' + 6 × 1'' / 1'' — Double bloc',
    'Max Roussie',
    $txt$Chauffe : 15' footing + 5' rapide · Gammes · 2 lignes droites 100m

Bloc principal :
5 × 3' à 90% VMA / récup 1'
Récup bloc : 4'
6 × 1' vite / 1' récup lent (EF)$txt$,
    $txt$Groupe récup (coureurs du weekend) :
15' easy jog · 10' gammes · 2 petites lignes droites
2 × (8 × 45'' vite ≤95% VMA / 1' récup EF)$txt$,
    NULL
  ),
  (
    '2025-10-28',
    'VMA — 5 × (200m / 1000m)',
    'Max Roussie',
    $txt$Chauffe : 15' footing + 5' rapide · Gammes · 2 accélérations

Bloc principal :
5 × (200m à 120% VMA / r = 1' / 1000m à SV2 85-90% VMA)
Récup bloc : 2'30$txt$,
    NULL,
    NULL
  ),
  (
    '2025-10-21',
    '4 × 4'' + 8 × 200m VMA',
    'Max Roussie',
    $txt$Chauffe · Gammes

Bloc principal :
4 × 4' à 90% VMA / R = 2' / récup bloc 4'
8 × 200m à 120% VMA / R = 1'$txt$,
    $txt$Séance récup (coureurs du 20k) :
2 blocs de 8 × 30 secs à VMA (sous forme de lignes droites) / r = 30 secs
Récup bloc : 4' en EF$txt$,
    NULL
  ),
  (
    '2025-10-14',
    'Test VMA',
    'Max Roussie',
    $txt$Test VMA — infos données sur place par Valentino.
Débrief chez Pinettes après la séance 🍻$txt$,
    NULL,
    NULL
  ),
  (
    '2025-10-07',
    '4 × 400m + 2 × 800m SV2 + 4 × 400m',
    'Max Roussie',
    $txt$Chauffe : ~15' footing · 20' gammes

Bloc principal :
4 × 400m à 110% VMA | récup 1'
Bloc récup 3'
2 × 800m SV2 | récup 1'30
Bloc récup 3'
4 × 400m à 110% VMA | récup 1'$txt$,
    NULL,
    NULL
  ),
  (
    '2025-09-30',
    'Développement VMA — 2 × (6 × 300m)',
    'Max Roussie',
    $txt$Chauffe : 15' footing · 25' gammes + 2 lignes droites

Bloc principal :
2 blocs de 6 × 300m / récup 100m (≥45 secs) entre chaque 300m
Récup 4' entre les 2 blocs
Allure : 95% VMA (VMA théorique en attendant le test du 7/10)$txt$,
    NULL,
    NULL
  ),
  (
    '2025-09-16',
    '4 × 2''/1'' + 6 × 1''/1'' + 8 × 30''''/30''''',
    'Max Roussie',
    $txt$Chauffe : ~15' footing + 5' rapide · 20' gammes

Bloc principal :
4 × 2' vite / 1' lent · récup 3'
6 × 1' vite / 1' lent · récup 3'
8 × 30'' vite / 30'' lent$txt$,
    NULL,
    NULL
  ),
  (
    '2025-09-09',
    'Grande rentrée avec Valentino — 7 × 2''/1''',
    'Bertrand Dauvin',
    $txt$Chauffe : ~15' footing + 5' rapide · 30' gammes

Bloc principal :
7 × 2' vite / 1' lent (21 min)

Retour au calme$txt$,
    NULL,
    NULL
  ),
  (
    '2025-09-02',
    'Découverte club — Lent/Rapide/Lent',
    'Max Roussie',
    $txt$Chauffe (~15') · Gammes (5')

Bloc principal (~25') :
4 × 1' vite / 30'' récup
6 × 45'' vite / 30'' récup
8 × 30'' vite / 30'' récup
+ 2 séries gammes sur piste intercalées
+ Challenge PPG (5')$txt$,
    NULL,
    NULL
  ),
  (
    '2025-08-26',
    'Reprise été — 2 × (8'' de 30''''/30'''')',
    'Max Roussie',
    $txt$Chauffe (15') · Gammes (12')

Bloc principal :
2 × (8' de 30''/30'' à VMA)
Récup 2' entre les 2 blocs

Challenge PPG (10') · Retour au calme (~10')$txt$,
    NULL,
    NULL
  );


-- =============================================================================
-- ROLLBACK INSTRUCTIONS (comment only — do not execute unless intentional)
--
-- To wipe the seeded data (e.g. before re-running on a fresh schema):
--
--   DELETE FROM public.sessions;
--   DELETE FROM public.races;
--   DELETE FROM public.resources;
--
-- DO NOT use TRUNCATE — would also reset sequences if any are added later.
-- =============================================================================
