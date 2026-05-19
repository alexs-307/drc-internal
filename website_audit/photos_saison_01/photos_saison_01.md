# Photos Saison 01 — feuille de remplissage

> **Pour Alex :** déposer les fichiers photo dans ce même dossier (`photos_saison_01/`), avec les noms exacts indiqués dans la colonne *Filename attendu* ci-dessous. Le dev front lira ce fichier markdown + le dossier pour les intégrer.
>
> **Pour le dev :** chaque entrée correspond à un emplacement précis du mock 03 (Saison 01 — l'album). Les filenames sont conventionnels ; tu peux référencer `photos_saison_01/01-hero-drift-award.jpg` directement dans le HTML.
>
> **Format recommandé :** JPEG quality 80, format natif du shoot, dimensions native ≥ 1600px côté long. Le rendu duotone bleu est appliqué côté CSS (`mix-blend-mode: multiply` ou `filter`), pas besoin de pré-traiter.

---

## Emplacement 01 — Hero principal (gros bandeau 780×440)

- **Filename attendu :** `01-hero.jpg`
- **Position dans le mock :** moitié gauche, en haut, juste sous le titre `SAISON 01 / L'ALBUM`
- **Traitement :** duotone bleu (`#001EFF` ombres, `#F4F1EC` highlights) appliqué CSS
- **Source suggérée :** `13_Shooting_Montmartre_Vincent / Photos Vincent retouchées` (un cliché signature)
- **Caption (à compléter) :** *DRIFT AWARD — Fête de Noël*
- **Date (à compléter) :** *12 déc. 2025*
- **Crédit photo (à compléter) :** *Photo by Marine*

## Emplacement 02 — Mini photo carré (200×160) · colonne droite haut-gauche

- **Filename attendu :** `02-decouverte-club.jpg`
- **Position :** colonne droite, ligne 1, gauche
- **Source suggérée :** `01_Lancement photos stylées` ou `02_Entrainement`
- **Caption :** *Découverte club*
- **Date :** *02 sept. 2025*

## Emplacement 03 — Mini photo carré (200×160) · colonne droite haut-droite

- **Filename attendu :** `03-test-vma-1.jpg`
- **Position :** colonne droite, ligne 1, droite
- **Source suggérée :** `02_Entrainement`
- **Caption :** *Test VMA #1*
- **Date :** *14 oct. 2025*

## Emplacement 04 — Photo large (420×160) · colonne droite ligne 2

- **Filename attendu :** `04-cantal-sortie-longue.jpg`
- **Position :** colonne droite, ligne 2, pleine largeur
- **Source suggérée :** `07_Sorties longues WE` (séjour Cantal)
- **Caption :** *Sortie longue — Haut-Cantal*
- **Date :** *04-06 avr. 2026*

## Emplacement 05 — Mosaïque ligne « Printemps 2026 » · photo large (420×260)

- **Filename attendu :** `05-hybride-seuil-vma.jpg`
- **Position :** mosaïque ligne 1, première colonne
- **Source suggérée :** `02_Entrainement` (séance piste)
- **Caption :** *Hybride seuil → VMA*
- **Date :** *17 mars 2026*

## Emplacement 06 — Mosaïque · photo portrait tall (200×260)

- **Filename attendu :** `06-semi-paris.jpg`
- **Position :** mosaïque ligne 1, deuxième colonne (format portrait)
- **Source suggérée :** `08_Courses` (Semi de Paris)
- **Traitement :** duotone bleu/noir (la plus contrastée)
- **Caption :** *Semi de Paris*
- **Date :** *02 mars 2026*

## Emplacement 07 — Mosaïque · photo large (320×260)

- **Filename attendu :** `07-cycle-vma-piste.jpg`
- **Position :** mosaïque ligne 1, troisième colonne
- **Source suggérée :** `02_Entrainement` (séance piste bertrand dauvin)
- **Caption :** *Cycle VMA · piste*
- **Date :** *21 avr. 2026*

## Emplacement 08 — Mosaïque · photo carrée (280×260)

- **Filename attendu :** `08-cloture-cycle.jpg`
- **Position :** mosaïque ligne 1, quatrième colonne
- **Source suggérée :** `02_Entrainement` (Test VMA — Clôture de cycle)
- **Caption :** *Clôture du cycle*
- **Date :** *12 mai 2026*

---

## Remarques

- **Si une photo manque** au moment du build, le dev affiche un placeholder duotone uni (rect cream → blue) avec la date et la caption en monospace blanche par-dessus — exactement comme dans le mock SVG. Le code prévoit ce cas de fallback.
- **Si tu veux ajouter d'autres moments** (au-delà des 8 emplacements ci-dessus), on ajoute des emplacements `09-...`, `10-...` etc. dans une seconde mosaïque « Été 2026 » ou « Été-Automne ». Le pattern de layout est répétable.
- **Crédits photo** : par convention DRC, on affiche le crédit en monospace blanche 10px, en bas à droite de la photo hero uniquement. Sur la mosaïque, on n'affiche pas le crédit (trop dense).

## Checklist pour Alex

- [x] Déposer les 8 photos dans ce dossier avec les filenames indiqués
- [x] Compléter les captions et dates ci-dessus si besoin de précision
- [ ] Valider les crédits photo (qui a shooté quoi)
- [ ] Signaler au dev si on ajoute des emplacements supplémentaires

---

## Mapping intégré sur le site (PR `add-photos-saison-01`)

Les 8 photos livrées par Alex ne portaient pas les filenames de la spec. Voici la correspondance source → emplacement, avec les captions/dates effectivement utilisées dans `index.html`.

| Slot | Fichier source | Renommé en | Caption finale | Date affichée |
|---|---|---|---|---|
| 01 | `drift_award.jpeg` | `01-hero.jpg` | DRIFT AWARD · Fête de Noël | 12 déc 2025 |
| 02 | `drc_sticker_lifestyle.jpeg` | `02-decouverte-club.jpg` | DRC au feu rouge | 02 sept 2025 |
| 03 | `drc_watch_turnoff_post_run.jpeg` | `03-test-vma-1.jpg` | Récup post-effort | 14 oct 2025 |
| 04 | `drc_after_race.jpg` | `04-cantal-sortie-longue.jpg` | L'esprit du Drift | 04 avr 2026 · Montmartre |
| 05 | `drc_track.jpeg` | `05-hybride-seuil-vma.jpg` | Séance piste · seuil → VMA | 17 mars 2026 |
| 06 | `drc_medal_holders.jpg` | `06-semi-paris.jpg` | 10K de Montmartre — finishers | 02 mars 2026 |
| 07 | `drc_cross_training.jpeg` | `07-cycle-vma-piste.jpg` | Renfo collectif · piste | 21 avr 2026 |
| 08 | `drc_sticker_phone_lifestyle.jpeg` | `08-cloture-cycle.jpg` | Saison bouclée | 12 mai 2026 |

> Les filenames cibles (`01-hero.jpg`, etc.) ont été conservés tels que référencés dans `index.html` pour ne pas toucher les `<img src>`. Seuls les `<figcaption>` et `alt` ont été mis à jour.
> Note : la date du slot 06 est restée `02 mars 2026` (héritée de la spec Semi de Paris) — à corriger si le 10K de Montmartre a eu lieu à une autre date.
