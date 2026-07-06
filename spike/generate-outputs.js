// spike/generate-outputs.js
//
// Node runner that produces spike/output/*.fit using the exact same
// fit-encoder.js + session-model.js modules loaded by spike/generate.html in
// the browser — no separate re-implementation, no build step. Run with the
// environment's stock `node` binary:
//
//   node spike/generate-outputs.js
//
// Reference VMA is fixed at 16.0 km/h (see spike/README.md) so the committed
// output files are reproducible without opening the page.

"use strict";

const fs = require("fs");
const path = require("path");

const FitEncoder = require("./fit-encoder.js");
const session = require("./session-model.js");

const REFERENCE_VMA_KMH = 16.0;
const OUTPUT_DIR = path.join(__dirname, "output");
// Fixed generation timestamp so the committed .fit files are byte-for-byte
// reproducible across re-runs (the spike page itself uses "now" instead).
const FIXED_GENERATED_AT_UNIX = Date.UTC(2026, 6, 6, 12, 0, 0) / 1000;

if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

for (const group of ["g12", "g3"]) {
  const groupData = session.groups[group];
  const bytes = FitEncoder.encodeWorkoutFit({
    name: `${session.meta.label} (${groupData.label})`,
    steps: groupData.steps,
    vmaKmh: REFERENCE_VMA_KMH,
    generatedAtUnixSeconds: FIXED_GENERATED_AT_UNIX,
  });
  const outPath = path.join(OUTPUT_DIR, `progressivite-allure-2026-05-05-${group}.fit`);
  fs.writeFileSync(outPath, Buffer.from(bytes));
  console.log(`Wrote ${outPath} (${bytes.length} bytes, VMA=${REFERENCE_VMA_KMH} km/h)`);
}
