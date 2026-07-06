// spike/fit-encoder.js
//
// Minimal, dependency-free FIT binary encoder for Garmin *workout* files
// (file_id + workout + workoutStep messages only — no activity/record data).
// Hand-written against the message/field/enum definitions excerpted verbatim
// in spike/reference/fit-profile-excerpt.md (source: Garmin FIT JavaScript SDK
// profile.js, fetched 2026-07-06). Runs unmodified in a browser (loaded via
// <script> in spike/generate.html) or under Node (spike/generate-outputs.js),
// no build step, no bundler.
//
// Public entry point: encodeWorkoutFit({ name, steps, vmaKmh }) -> Uint8Array
//
// `steps` is the structured-step model described in
// .claude/design-briefs/session-structured-steps.md — an array of Step
// objects, where a Step of kind "repeat_group" carries a nested
// `repeat: { count, steps }` body (one level of nesting only; see the brief's
// "known limitations" section on why FIT repeat steps cannot themselves
// nest).

(function (global) {
  "use strict";

  // ---------------------------------------------------------------------
  // Section 1: generic FIT binary primitives (header, CRC, byte writer)
  // ---------------------------------------------------------------------

  // FIT epoch: seconds since UTC 1989-12-31T00:00:00Z (not the Unix epoch).
  const FIT_EPOCH_OFFSET_SEC = Date.UTC(1989, 11, 31, 0, 0, 0) / 1000;

  function unixSecondsToFitDateTime(unixSeconds) {
    return Math.floor(unixSeconds - FIT_EPOCH_OFFSET_SEC);
  }

  // CRC-16 nibble-lookup table, per the FIT protocol's documented algorithm
  // (reproduced in spike/reference/fit-profile-excerpt.md — not copied from a
  // specific source file, re-implemented from the publicly documented table
  // and update routine shipped with the Garmin FIT SDK reference code).
  const CRC_TABLE = [
    0x0000, 0xcc01, 0xd801, 0x1400, 0xf001, 0x3c00, 0x2800, 0xe401,
    0xa001, 0x6c00, 0x7800, 0xb401, 0x5000, 0x9c01, 0x8801, 0x4400,
  ];

  function crc16Update(crc, byte) {
    let tmp = CRC_TABLE[crc & 0xf];
    crc = (crc >> 4) & 0x0fff;
    crc = crc ^ tmp ^ CRC_TABLE[byte & 0xf];

    tmp = CRC_TABLE[crc & 0xf];
    crc = (crc >> 4) & 0x0fff;
    crc = crc ^ tmp ^ CRC_TABLE[(byte >> 4) & 0xf];

    return crc & 0xffff;
  }

  function crc16(bytes, start, end) {
    let crc = 0;
    for (let i = start; i < end; i++) {
      crc = crc16Update(crc, bytes[i]);
    }
    return crc;
  }

  // Small growable byte buffer with little-endian numeric writers — enough
  // for what FIT needs, nothing more.
  class ByteWriter {
    constructor() {
      this.bytes = [];
    }
    u8(v) {
      this.bytes.push(v & 0xff);
    }
    u16(v) {
      this.bytes.push(v & 0xff, (v >> 8) & 0xff);
    }
    u32(v) {
      this.bytes.push(v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff);
    }
    // Fixed-size, null-padded/truncated UTF-8 string field.
    fixedString(str, size) {
      const encoded = utf8Encode(str || "");
      for (let i = 0; i < size; i++) {
        this.bytes.push(i < encoded.length && i < size - 1 ? encoded[i] : 0);
      }
    }
    raw(byteArray) {
      for (const b of byteArray) this.bytes.push(b & 0xff);
    }
    toUint8Array() {
      return new Uint8Array(this.bytes);
    }
  }

  function utf8Encode(str) {
    if (typeof TextEncoder !== "undefined") {
      return Array.from(new TextEncoder().encode(str));
    }
    // Node fallback (should not be needed — Node's global has TextEncoder
    // since v11 — kept only as a defensive fallback).
    return Array.from(Buffer.from(str, "utf8"));
  }

  // ---------------------------------------------------------------------
  // Section 2: FIT base types and "invalid" sentinels
  // (values verified against the public FIT base-type table; see
  // spike/reference/fit-profile-excerpt.md for the message/field/enum
  // numbers that reference these base types)
  // ---------------------------------------------------------------------

  const BASE_TYPE = {
    ENUM: { id: 0x00, size: 1, invalid: 0xff, write: (w, v) => w.u8(v) },
    UINT8: { id: 0x02, size: 1, invalid: 0xff, write: (w, v) => w.u8(v) },
    UINT16: { id: 0x84, size: 2, invalid: 0xffff, write: (w, v) => w.u16(v) },
    UINT32: { id: 0x86, size: 4, invalid: 0xffffffff, write: (w, v) => w.u32(v) },
    UINT32Z: { id: 0x8c, size: 4, invalid: 0x00000000, write: (w, v) => w.u32(v) },
  };

  function stringBaseType(size) {
    return {
      id: 0x07,
      size,
      write: (w, v) => w.fixedString(v, size),
    };
  }

  // ---------------------------------------------------------------------
  // Section 3: message field layouts (mirrors fit-profile-excerpt.md)
  // ---------------------------------------------------------------------

  const GLOBAL_MESG = { FILE_ID: 0, WORKOUT: 26, WORKOUT_STEP: 27 };

  const WKT_NAME_SIZE = 32; // fixed field size for workout.wktName
  const WKT_STEP_NAME_SIZE = 32; // fixed field size for workoutStep.wktStepName

  // Enums (verbatim values, see fit-profile-excerpt.md)
  const FILE_TYPE_WORKOUT = 5;
  const MANUFACTURER_DEVELOPMENT = 255;
  const SPORT_RUNNING = 1;
  const WKT_STEP_DURATION = {
    time: 0,
    distance: 1,
    open: 5,
    repeatUntilStepsCmplt: 6,
  };
  const WKT_STEP_TARGET = { speed: 0, open: 2 };
  const INTENSITY = {
    active: 0,
    rest: 1,
    warmup: 2,
    cooldown: 3,
    recovery: 4,
  };

  const FILE_ID_FIELDS = [
    { num: 0, name: "type", type: BASE_TYPE.ENUM },
    { num: 1, name: "manufacturer", type: BASE_TYPE.UINT16 },
    { num: 2, name: "product", type: BASE_TYPE.UINT16 },
    { num: 3, name: "serialNumber", type: BASE_TYPE.UINT32Z },
    { num: 4, name: "timeCreated", type: BASE_TYPE.UINT32 },
  ];

  const WORKOUT_FIELDS = [
    { num: 4, name: "sport", type: BASE_TYPE.ENUM },
    { num: 5, name: "capabilities", type: BASE_TYPE.UINT32Z },
    { num: 6, name: "numValidSteps", type: BASE_TYPE.UINT16 },
    { num: 8, name: "wktName", type: stringBaseType(WKT_NAME_SIZE) },
  ];

  const WORKOUT_STEP_FIELDS = [
    { num: 254, name: "messageIndex", type: BASE_TYPE.UINT16 },
    { num: 0, name: "wktStepName", type: stringBaseType(WKT_STEP_NAME_SIZE) },
    { num: 1, name: "durationType", type: BASE_TYPE.ENUM },
    { num: 2, name: "durationValue", type: BASE_TYPE.UINT32 },
    { num: 3, name: "targetType", type: BASE_TYPE.ENUM },
    { num: 4, name: "targetValue", type: BASE_TYPE.UINT32 },
    { num: 5, name: "customTargetValueLow", type: BASE_TYPE.UINT32 },
    { num: 6, name: "customTargetValueHigh", type: BASE_TYPE.UINT32 },
    { num: 7, name: "intensity", type: BASE_TYPE.ENUM },
  ];

  function writeDefinitionMessage(writer, localType, globalMesgNum, fields) {
    writer.u8(0x40 | localType); // record header: definition message
    writer.u8(0); // reserved
    writer.u8(0); // architecture: 0 = little endian
    writer.u16(globalMesgNum);
    writer.u8(fields.length);
    for (const f of fields) {
      writer.u8(f.num);
      writer.u8(f.type.size);
      writer.u8(f.type.id);
    }
  }

  function writeDataMessage(writer, localType, fields, values) {
    writer.u8(localType); // record header: data message (bit 6 clear)
    for (const f of fields) {
      const v = values[f.name];
      f.type.write(writer, v === undefined || v === null ? (f.type.invalid !== undefined ? f.type.invalid : 0) : v);
    }
  }

  // ---------------------------------------------------------------------
  // Section 4: structured-model -> flattened FIT workoutStep record list
  // ---------------------------------------------------------------------

  // VMA (km/h) + %VMA -> target speed in m/s.
  function vmaPctToSpeedMs(vmaKmh, pct) {
    return ((vmaKmh * pct) / 100) / 3.6;
  }

  // Pace formatting helper (min/km), used by the on-page preview table too.
  function speedKmhToPace(speedKmh) {
    if (!speedKmh || speedKmh <= 0) return "—";
    const secPerKm = 3600 / speedKmh;
    const min = Math.floor(secPerKm / 60);
    const sec = Math.round(secPerKm % 60);
    return `${min}'${String(sec).padStart(2, "0")}"`;
  }

  // Given a Step.target ({type:"vma_pct", pct, pct_low, pct_high} or null)
  // and a VMA in km/h, compute { lowMs, highMs, lowKmh, highKmh } or null.
  // Band width for a single-point pct: +/-3% relative (see design brief §5).
  const SINGLE_POINT_BAND_PCT = 0.03;

  function resolveTargetSpeedBand(target, vmaKmh) {
    if (!target || target.type !== "vma_pct") return null;
    let pctLow, pctHigh;
    if (target.pct_low != null && target.pct_high != null) {
      pctLow = target.pct_low;
      pctHigh = target.pct_high;
    } else {
      pctLow = target.pct * (1 - SINGLE_POINT_BAND_PCT);
      pctHigh = target.pct * (1 + SINGLE_POINT_BAND_PCT);
    }
    const lowMs = vmaPctToSpeedMs(vmaKmh, pctLow);
    const highMs = vmaPctToSpeedMs(vmaKmh, pctHigh);
    return {
      lowMs,
      highMs,
      lowKmh: lowMs * 3.6,
      highKmh: highMs * 3.6,
    };
  }

  function stepKindToIntensity(kind) {
    switch (kind) {
      case "warmup":
        return INTENSITY.warmup;
      case "cooldown":
        return INTENSITY.cooldown;
      case "work":
        return INTENSITY.active;
      case "recovery":
        // Model does not distinguish r/R at the `kind` level (both are
        // "recovery") — the design brief recommends using step.name /
        // step.recoveryLevel to pick rest vs recovery. See buildFitStepRecord.
        return INTENSITY.rest;
      default:
        return BASE_TYPE.ENUM.invalid;
    }
  }

  // Converts one leaf Step (not repeat_group) into the plain-object "values"
  // used by writeDataMessage for a workoutStep record. `messageIndex` is
  // assigned by the caller (flattenSteps) since it depends on position.
  function buildFitStepRecord(step, vmaKmh, messageIndex) {
    const rec = {
      messageIndex,
      wktStepName: step.name || "",
      intensity:
        step.kind === "recovery" && step.recoveryLevel === "block"
          ? INTENSITY.recovery
          : stepKindToIntensity(step.kind),
    };

    // Duration
    const duration = step.duration || { type: "open", value: null };
    if (duration.type === "time") {
      rec.durationType = WKT_STEP_DURATION.time;
      rec.durationValue = Math.round(duration.value * 1000); // seconds -> ms
    } else if (duration.type === "distance") {
      rec.durationType = WKT_STEP_DURATION.distance;
      rec.durationValue = Math.round(duration.value * 100); // meters -> cm
    } else {
      rec.durationType = WKT_STEP_DURATION.open;
      rec.durationValue = BASE_TYPE.UINT32.invalid;
    }

    // Target
    const band = resolveTargetSpeedBand(step.target, vmaKmh);
    if (band) {
      rec.targetType = WKT_STEP_TARGET.speed;
      rec.targetValue = 0; // 0 = "custom", not a pre-defined speed zone
      rec.customTargetValueLow = Math.round(band.lowMs * 1000); // m/s -> mm/s
      rec.customTargetValueHigh = Math.round(band.highMs * 1000);
    } else {
      rec.targetType = WKT_STEP_TARGET.open;
      rec.targetValue = BASE_TYPE.UINT32.invalid;
      rec.customTargetValueLow = BASE_TYPE.UINT32.invalid;
      rec.customTargetValueHigh = BASE_TYPE.UINT32.invalid;
    }

    return rec;
  }

  // Flattens the structured Step[] model (with at most one level of
  // repeat_group nesting, per the design brief) into an ordered list of FIT
  // workoutStep record objects, assigning messageIndex values and inserting
  // the repeat-control record (durationType=repeatUntilStepsCmplt) after each
  // repeat_group's body. Throws if a nested repeat_group is found (the model
  // requires flattening to have already happened at authoring time — see
  // design brief §6).
  function flattenSteps(steps, vmaKmh) {
    const records = [];

    function pushLeaf(step) {
      const idx = records.length;
      records.push(buildFitStepRecord(step, vmaKmh, idx));
      return idx;
    }

    for (const step of steps) {
      if (step.kind === "repeat_group") {
        const bodySteps = step.repeat && step.repeat.steps ? step.repeat.steps : [];
        if (bodySteps.some((s) => s.kind === "repeat_group")) {
          throw new Error(
            'Nested repeat_group found — flatten at authoring time before encoding (see design brief "known limitations")'
          );
        }
        const firstBodyIndex = records.length;
        for (const bodyStep of bodySteps) {
          pushLeaf(bodyStep);
        }
        // Repeat-control record: jumps back to firstBodyIndex, `count` times.
        const repeatIdx = records.length;
        records.push({
          messageIndex: repeatIdx,
          wktStepName: "",
          durationType: WKT_STEP_DURATION.repeatUntilStepsCmplt,
          durationValue: firstBodyIndex,
          targetType: WKT_STEP_TARGET.open,
          targetValue: step.repeat.count,
          customTargetValueLow: BASE_TYPE.UINT32.invalid,
          customTargetValueHigh: BASE_TYPE.UINT32.invalid,
          intensity: BASE_TYPE.ENUM.invalid, // undefined for this duration type, per SDK comment
        });
      } else {
        pushLeaf(step);
      }
    }

    return records;
  }

  // ---------------------------------------------------------------------
  // Section 5: top-level file assembly
  // ---------------------------------------------------------------------

  function encodeWorkoutFit({ name, steps, vmaKmh, generatedAtUnixSeconds }) {
    const stepRecords = flattenSteps(steps, vmaKmh);

    // --- data records (definitions + data), local message types 0/1/2 ---
    const data = new ByteWriter();

    // file_id
    writeDefinitionMessage(data, 0, GLOBAL_MESG.FILE_ID, FILE_ID_FIELDS);
    writeDataMessage(data, 0, FILE_ID_FIELDS, {
      type: FILE_TYPE_WORKOUT,
      manufacturer: MANUFACTURER_DEVELOPMENT,
      product: 0,
      serialNumber: 0,
      timeCreated: unixSecondsToFitDateTime(
        generatedAtUnixSeconds != null ? generatedAtUnixSeconds : Math.floor(Date.now() / 1000)
      ),
    });

    // workout
    writeDefinitionMessage(data, 1, GLOBAL_MESG.WORKOUT, WORKOUT_FIELDS);
    writeDataMessage(data, 1, WORKOUT_FIELDS, {
      sport: SPORT_RUNNING,
      capabilities: 0,
      numValidSteps: stepRecords.length,
      wktName: name,
    });

    // workoutStep (one definition, N data records — fixed-size fields only,
    // so a single definition message covers every record)
    writeDefinitionMessage(data, 2, GLOBAL_MESG.WORKOUT_STEP, WORKOUT_STEP_FIELDS);
    for (const rec of stepRecords) {
      writeDataMessage(data, 2, WORKOUT_STEP_FIELDS, rec);
    }

    const dataBytes = data.toUint8Array();

    // --- 14-byte file header ---
    const header = new ByteWriter();
    header.u8(14); // header size
    header.u8(0x10); // protocol version 1.0 (upper nibble major, lower nibble minor)
    header.u16(2132); // profile version (informational; not strictly validated on import)
    header.u32(dataBytes.length); // size of the data records section only
    header.raw(utf8Encode(".FIT")); // 4-byte data type tag
    const headerBytesSoFar = header.toUint8Array();
    const headerCrc = crc16(headerBytesSoFar, 0, headerBytesSoFar.length);
    header.u16(headerCrc);

    const headerBytes = header.toUint8Array(); // now 14 bytes

    // --- assemble header + data, then append whole-file CRC ---
    const fileWithoutTrailingCrc = new Uint8Array(headerBytes.length + dataBytes.length);
    fileWithoutTrailingCrc.set(headerBytes, 0);
    fileWithoutTrailingCrc.set(dataBytes, headerBytes.length);

    const fileCrc = crc16(fileWithoutTrailingCrc, 0, fileWithoutTrailingCrc.length);

    const finalFile = new Uint8Array(fileWithoutTrailingCrc.length + 2);
    finalFile.set(fileWithoutTrailingCrc, 0);
    finalFile[fileWithoutTrailingCrc.length] = fileCrc & 0xff;
    finalFile[fileWithoutTrailingCrc.length + 1] = (fileCrc >> 8) & 0xff;

    return finalFile;
  }

  const api = {
    encodeWorkoutFit,
    flattenSteps,
    resolveTargetSpeedBand,
    vmaPctToSpeedMs,
    speedKmhToPace,
    SINGLE_POINT_BAND_PCT,
  };

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  } else {
    global.FitEncoder = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
