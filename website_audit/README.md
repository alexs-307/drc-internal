# DRC · Refonte derapage.xyz · Livrables V2

Direction visuelle validée : **B — Crew Culture Street** (avec touches discrètes de C — Vintage Parisien).

## Pour le dev front-end

Le fichier **`handover_dev.md`** est le point d'entrée unique. Il contient tout : structure HTML, CSS prêt à coller, SVG des pictos, media queries, checklist d'acceptation.

## Pour Alex

Le fichier **`viewer.html`** ouvre les 4 mocks dans le navigateur (double-clic depuis le Finder). C'est la vue de référence à partager.

## Plan complet des fichiers

| Fichier | Pour qui | Contenu |
| --- | --- | --- |
| `handover_dev.md` | dev front | Spec complète d'implémentation, prête à coder |
| `viewer.html` | Alex (vue) | Les 4 mocks SVG inlinés avec les vraies polices |
| `audit_v1.md` | Alex / dev | Audit V1 — pourquoi chaque reco existe |
| `brand_kit_v2.md` | dev | Mini brand kit (palette, typo, composants, voice) |
| `mocks/01_desktop_hero.svg` | dev | Mock Desktop Calendrier |
| `mocks/02_navigation.svg` | dev | Système nav (desktop + mobile + pictos + états) |
| `mocks/03_saison_01.svg` | dev | Section Saison 01 éditoriale |
| `mocks/04_mobile_view.svg` | dev | Vues mobile côte à côte |
| `photos_saison_01/` | Alex (à remplir) | Dossier pour déposer les 8 photos |
| `photos_saison_01/photos_saison_01.md` | Alex + dev | Liste des emplacements, captions, dates |

## Décisions intégrées (feedback Alex)

| Section | Décision |
| --- | --- |
| Saison 01 | Pas de fake grille Insta — mode éditorial avec hero duotone + mosaïque |
| Calendrier | Hero = prochaine course (confirmée ou non) |
| Calendrier hero | Pas de mention « Cantal » (l'événement n'est pas dans le Cantal — juste format weekend long) |
| Entrainement | Pas de bandeau stats |
| Ressources | Pas de catégorisation · placeholder *Règlement intérieur* prévu |
| Footer | Inchangé |
| Pictos nav | SVG inline déjà dessinés (pas de graphiste) · prompts IA fournis pour régénération alternative |

## Ce qu'Alex doit fournir avant le merge dev

- **Photos** : 8 fichiers dans `photos_saison_01/` (voir `photos_saison_01.md` pour les noms attendus et captions)
- **Aperçus PDFs** : capture première page de `vma-seuil.pdf` et `renfo-mobilite.pdf` (placer dans `ressources/previews/`)
- **Confirmations** sur 4 points listés section 11 du `handover_dev.md`

## Prochaines étapes possibles (V3)

- Prototype HTML/CSS fonctionnel (au lieu de SVG static) si le dev souhaite une référence vivante
- Mockup Entraînement (filtres + carte séance ouverte) si on veut pousser plus loin
- Pictos contextuels DRC (montagne, Pinettes, Eiffel, etc.) en V2 enrichie
