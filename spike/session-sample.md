# Session sample data — provenance and raw rows

> Source: `git show 855bfd7~1:sessions.json` — the last commit before `855bfd7`
> ("feat: cut frontend over to Supabase reads (sessions, races, resources) (#17)"), i.e. the
> final state of the retired `sessions.json` file, pre-Supabase-cutover. The live Supabase
> `public.sessions` table is not reachable from this environment, so this git-history snapshot
> is used as the self-contained data source for the spike. Rows are copied verbatim (French
> text unchanged); only the three sessions relevant to this spike are included below (the full
> file has 36 rows).

## Chosen session (encoded by the spike): `2026-05-05`

```json
{
  "date": "2026-05-05",
  "label": "Progressivité d'allure — Tempo → VMA",
  "venue": "Bertrand Dauvin",
  "g12": "Chauffe : 20' EF · 15' gammes · 2 lignes droites\n\nBloc principal :\n3 × (900m à 80% VMA / 600m à 90% VMA / 300m à 100% VMA)\nr = 2' entre les courses · R = 3' entre les séries\n\nRetour au calme : 5' jog léger",
  "g3": "Chauffe identique\n\nBloc principal :\n2 séries seulement (au lieu de 3)\n3 × (900m à 80% VMA / 600m à 90% VMA / 300m à 100% VMA)\n\nRetour au calme : 5' jog léger",
  "suggestion": null
}
```

## Stress-test session (modeled in the brief only, not encoded to FIT): `2026-05-19`

```json
{
  "date": "2026-05-19",
  "label": "Hors les murs — Pyramide en côtes (Vincennes)",
  "venue": "Métro Château de Vincennes",
  "g12": "Chauffe : 20' footing ensemble (jusqu'à la zone de travail) · 15' gammes en côtes\n\nBloc principal — 2 blocs de :\n100m à 110% VMA / 200m à 100% VMA / 300m à 100% VMA / 200m à 100% VMA / 100m à 110% VMA\nRécup : 100m en trottinant entre chaque effort / Récup bloc : 4'\n\nRetour au métro — G1/G2 : 3 × 3' allure 90% VMA / Récup 1'30",
  "g3": "Chauffe identique\n\nBloc principal — 2 blocs de :\n100m à 110% VMA / 200m à 100% VMA / 300m à 100% VMA / 200m à 100% VMA / 100m à 110% VMA\nRécup : 100m en trottinant entre chaque effort / Récup bloc : 4'\n\nRetour en footing ensemble",
  "suggestion": "20' de footing\nTravail tempo 10K : 1k / 2k / 1k / 2k à 90% VMA — Récup 2'30 entre les blocs"
}
```

## Pattern-variation reference (glanced at for the mapping table, not encoded): `2026-04-07`

```json
{
  "date": "2026-04-07",
  "label": "Cycle VMA — Variations 300/200",
  "venue": "Bertrand Dauvin",
  "g12": "Chauffe : 20' EF · 15' gammes · 2 lignes droites\n\nBloc principal (4k de travail) :\n300/200/300/200 | r = 1' | à 100% VMA · recup bloc = 3'\n200/300/200/300 | r = 1' | à 100% VMA · recup bloc = 3'\n200/300/200/300 | r = 1' | à 100% VMA · recup bloc = 3'\n200/300/200/300 | r = 1' | à 100% VMA",
  "g3": "Chauffe identique\n\nBloc principal (3k de travail) :\n300/200/300/200 | r = 1' | à 100% VMA · recup bloc = 3'\n200/300/200/300 | r = 1' | à 100% VMA · recup bloc = 3'\n200/300/200/300 | r = 1' | à 100% VMA",
  "suggestion": "20' de footing progressif · Accélérations\n3 × 2' à 90% VMA | r = 1'\n3 × 4' à 80% VMA | r = 1'30\n3 × 2' à 90% VMA | r = 1'"
}
```

This row shows the same "300/200/300/200" block repeated four times, but with an *alternating
starting order* on the last three repetitions (300/200/300/200 vs 200/300/200/300) — a
different repeat irregularity than the 2026-05-19 pyramid. It corroborates that back-to-back
identical-looking blocks in DRC session text are not always a clean literal repeat; see the
brief's mapping-table discussion for how this is handled.
