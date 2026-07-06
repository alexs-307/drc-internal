// spike/session-model.js
//
// Hard-coded structured-step model for the one real DRC session this spike
// encodes: 2026-05-05, "Progressivité d'allure — Tempo → VMA" (Bertrand
// Dauvin). Raw source text and provenance: spike/session-sample.md.
// Model shape documented in full in
// .claude/design-briefs/session-structured-steps.md (§2/§3).
//
// Loaded as a plain <script> in spike/generate.html and via require() in the
// Node output-generation script — same file, no build step either way.

(function (global) {
  "use strict";

  const SESSION_META = {
    date: "2026-05-05",
    label: "Progressivité d'allure — Tempo → VMA",
    venue: "Bertrand Dauvin",
  };

  // Shared warmup + cooldown, identical for G1/G2 and G3 per the source text
  // ("Chauffe identique" / "Retour au calme : 5' jog léger" in both).
  function warmupSteps() {
    return [
      {
        kind: "warmup",
        name: "Échauffement EF",
        duration: { type: "time", value: 20 * 60 },
        target: null,
      },
      {
        kind: "warmup",
        name: "Gammes",
        duration: { type: "time", value: 15 * 60 },
        target: null,
      },
      {
        kind: "warmup",
        name: "2 lignes droites",
        duration: { type: "open", value: null },
        target: null,
      },
    ];
  }

  function cooldownStep() {
    return {
      kind: "cooldown",
      name: "Retour au calme",
      duration: { type: "time", value: 5 * 60 },
      target: null,
    };
  }

  // The repeated 900m/600m/300m sequence with r=2' between runs, R=3' between
  // series. `count` differs between G1/G2 (3) and G3 (2) — see design brief §1.
  function mainRepeatGroup(count) {
    return {
      kind: "repeat_group",
      name: "Série 900/600/300",
      duration: null,
      target: null,
      repeat: {
        count,
        steps: [
          {
            kind: "work",
            name: "900m à 80% VMA",
            duration: { type: "distance", value: 900 },
            target: { type: "vma_pct", pct: 80, pct_low: null, pct_high: null },
          },
          {
            kind: "recovery",
            name: "Récup r",
            recoveryLevel: "rep",
            duration: { type: "time", value: 2 * 60 },
            target: null,
          },
          {
            kind: "work",
            name: "600m à 90% VMA",
            duration: { type: "distance", value: 600 },
            target: { type: "vma_pct", pct: 90, pct_low: null, pct_high: null },
          },
          {
            kind: "recovery",
            name: "Récup r",
            recoveryLevel: "rep",
            duration: { type: "time", value: 2 * 60 },
            target: null,
          },
          {
            kind: "work",
            name: "300m à 100% VMA",
            duration: { type: "distance", value: 300 },
            target: { type: "vma_pct", pct: 100, pct_low: null, pct_high: null },
          },
          {
            kind: "recovery",
            name: "Récup R (série)",
            recoveryLevel: "block",
            duration: { type: "time", value: 3 * 60 },
            target: null,
          },
        ],
      },
    };
  }

  function buildSteps(group) {
    const count = group === "g3" ? 2 : 3;
    return [...warmupSteps(), mainRepeatGroup(count), cooldownStep()];
  }

  const SESSION = {
    meta: SESSION_META,
    groups: {
      g12: {
        label: "G1/G2 (3 séries)",
        steps: buildSteps("g12"),
      },
      g3: {
        label: "G3 (2 séries)",
        steps: buildSteps("g3"),
      },
    },
  };

  if (typeof module !== "undefined" && module.exports) {
    module.exports = SESSION;
  } else {
    global.DrcSessionModel = SESSION;
  }
})(typeof window !== "undefined" ? window : globalThis);
